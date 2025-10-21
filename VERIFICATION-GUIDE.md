# User Code System - Verification Guide

## Step 1: Run the Migration

1. Open Supabase Dashboard: https://supabase.com/dashboard
2. Select your project (the one matching your `NEXT_PUBLIC_SUPABASE_URL`)
3. Click **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy ALL contents from `supabase-user-code-complete.sql`
6. Paste into the editor
7. Click **RUN** (or Cmd/Ctrl + Enter)

You should see output like:
```
NOTICE:  Added user_code column
NOTICE:  Added format constraint
NOTICE:  Added unique index
NOTICE:  Generated user_code: 0123456789 for fid: 123
...
```

---

## Step 2: Verify the Migration

### Check Column Exists

```sql
SELECT
  column_name,
  data_type,
  character_maximum_length,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'user_code';
```

**Expected result:**
| column_name | data_type | character_maximum_length | is_nullable |
|-------------|-----------|-------------------------|-------------|
| user_code   | character | 10                      | YES         |

---

### Check Constraint Exists

```sql
SELECT conname, pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conname = 'user_code_format_chk';
```

**Expected result:**
| conname              | definition                                            |
|---------------------|-------------------------------------------------------|
| user_code_format_chk | CHECK ((user_code ~ '^[0-9]{10}$'::text) OR ...) |

---

### Check Index Exists

```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE indexname = 'users_user_code_key';
```

**Expected result:**
| indexname           | indexdef                                                |
|--------------------|---------------------------------------------------------|
| users_user_code_key | CREATE UNIQUE INDEX users_user_code_key ON ... |

---

### Check Trigger Exists

```sql
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trg_set_user_code';
```

**Expected result:**
| trigger_name        | event_manipulation | action_timing |
|--------------------|-------------------|---------------|
| trg_set_user_code   | INSERT            | BEFORE        |

---

### Check All Users Have Codes

```sql
SELECT
  COUNT(*) as total_users,
  COUNT(user_code) as users_with_codes,
  COUNT(*) - COUNT(user_code) as users_without_codes
FROM users;
```

**Expected result:**
- `users_without_codes` should be **0**
- All users should have codes

---

### Check for Duplicates

```sql
SELECT user_code, COUNT(*) as count
FROM users
WHERE user_code IS NOT NULL
GROUP BY user_code
HAVING COUNT(*) > 1;
```

**Expected result:**
- **0 rows** (no duplicates should exist)

---

### View Sample Codes

```sql
SELECT fid, username, user_code
FROM users
ORDER BY created_at DESC
LIMIT 10;
```

**Expected result:**
- Each user should have a unique 10-digit code like `0123456789`
- All codes should be exactly 10 digits with leading zeros

---

## Step 3: Find Your FID

To test with your specific user, you need to find your Farcaster ID (FID).

### Option A: Check the browser console
1. Sign in to the app
2. Open browser console (F12)
3. Look for the debug logs showing your FID

### Option B: Check the database
```sql
SELECT fid, username, user_code
FROM users
WHERE username = 'YOUR_USERNAME';
```
Replace `YOUR_USERNAME` with your Farcaster username.

---

## Step 4: Verify Your User

Once you have your FID, run this query:

```sql
SELECT fid, username, user_code, created_at
FROM users
WHERE fid = YOUR_FID;
```

**Expected result:**
- Your user should have a 10-digit `user_code`
- Example: `user_code = '0123456789'`

---

## Step 5: Test the App

### Before Migration
- Dashboard shows: "Migration Required" (yellow badge)
- Console logs show: "❌ DATABASE MIGRATION REQUIRED"
- Session API logs show which Supabase project it's connecting to

### After Migration
1. **Clear browser cookies** (or use incognito)
2. Go to http://localhost:3000
3. Sign in with Farcaster
4. Navigate to Dashboard
5. **You should see:**
   - Purple badge with "User ID"
   - Your unique 10-digit code displayed
   - No errors in console

### Check Server Logs
Look for these success messages:
```
=== SUPABASE CONNECTION DEBUG ===
URL: https://mpsnsxmznxvoqcslcaom.supabase.co
Project ID: mpsnsxmznxvoqcslcaom
...
✅ Successfully assigned user_code 0123456789 to user 123
```

---

## Step 6: Verify Project Match

The debug logs will show which Supabase project your app is connecting to.

**Check this matches your dashboard URL:**
- App connects to: `https://mpsnsxmznxvoqcslcaom.supabase.co`
- Dashboard URL: `https://supabase.com/project/mpsnsxmznxvoqcslcaom`

The project ID (`mpsnsxmznxvoqcslcaom`) should match in both places.

If they don't match:
1. Check your `.env.local` file
2. Ensure `NEXT_PUBLIC_SUPABASE_URL` matches the project where you ran the migration
3. Restart your dev server

---

## Troubleshooting

### Still seeing "Migration Required"?

**Check 1:** Did the migration run successfully?
```sql
SELECT COUNT(*) FROM users WHERE user_code IS NOT NULL;
```
Should return a number > 0

**Check 2:** Is your app connecting to the right project?
- Look at server logs for "SUPABASE CONNECTION DEBUG"
- Compare the URL to where you ran the migration

**Check 3:** Did you clear cookies and re-login?
- Clear browser cookies
- Or use incognito mode
- Sign in again

### Error: "column users.user_code does not exist"

This means the migration didn't run or ran on a different project.

**Solution:**
1. Verify you're running the migration in the correct Supabase project
2. Check the project URL matches `NEXT_PUBLIC_SUPABASE_URL` in `.env.local`
3. Re-run the migration: `supabase-user-code-complete.sql`

### Codes are not 10 digits

**Check:**
```sql
SELECT fid, username, user_code, LENGTH(user_code) as length
FROM users
WHERE LENGTH(user_code) != 10;
```

This should return 0 rows. If not, the constraint isn't working.

**Fix:**
Re-run the complete migration.

---

## Success Criteria

✅ All checks pass:
- [ ] Column `user_code` exists (char(10))
- [ ] Format constraint exists (10 digits only)
- [ ] Unique index exists (no duplicates)
- [ ] Trigger exists (auto-generates on insert)
- [ ] All existing users have codes
- [ ] No duplicate codes exist
- [ ] App connects to correct Supabase project
- [ ] Dashboard shows 10-digit User ID (not "Migration Required")
- [ ] Server logs show successful code generation
- [ ] No 42703 errors in console or logs

---

## Quick Test Script

Run this entire block to verify everything:

```sql
-- Verification Test Suite
DO $$
DECLARE
  column_exists BOOLEAN;
  constraint_exists BOOLEAN;
  index_exists BOOLEAN;
  trigger_exists BOOLEAN;
  users_without_codes INT;
  duplicate_codes INT;
BEGIN
  -- Check column
  SELECT EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'user_code'
  ) INTO column_exists;

  -- Check constraint
  SELECT EXISTS(
    SELECT 1 FROM pg_constraint WHERE conname = 'user_code_format_chk'
  ) INTO constraint_exists;

  -- Check index
  SELECT EXISTS(
    SELECT 1 FROM pg_indexes WHERE indexname = 'users_user_code_key'
  ) INTO index_exists;

  -- Check trigger
  SELECT EXISTS(
    SELECT 1 FROM information_schema.triggers
    WHERE trigger_name = 'trg_set_user_code'
  ) INTO trigger_exists;

  -- Check users without codes
  SELECT COUNT(*) - COUNT(user_code) INTO users_without_codes FROM users;

  -- Check duplicates
  SELECT COUNT(*) INTO duplicate_codes FROM (
    SELECT user_code, COUNT(*)
    FROM users
    WHERE user_code IS NOT NULL
    GROUP BY user_code
    HAVING COUNT(*) > 1
  ) duplicates;

  -- Report results
  RAISE NOTICE '=== USER CODE VERIFICATION ===';
  RAISE NOTICE 'Column exists: %', column_exists;
  RAISE NOTICE 'Constraint exists: %', constraint_exists;
  RAISE NOTICE 'Index exists: %', index_exists;
  RAISE NOTICE 'Trigger exists: %', trigger_exists;
  RAISE NOTICE 'Users without codes: %', users_without_codes;
  RAISE NOTICE 'Duplicate codes: %', duplicate_codes;

  IF column_exists AND constraint_exists AND index_exists AND
     trigger_exists AND users_without_codes = 0 AND duplicate_codes = 0 THEN
    RAISE NOTICE '✅ ALL CHECKS PASSED!';
  ELSE
    RAISE NOTICE '❌ SOME CHECKS FAILED - Review above';
  END IF;
END $$;
```

This will output a summary like:
```
NOTICE:  === USER CODE VERIFICATION ===
NOTICE:  Column exists: true
NOTICE:  Constraint exists: true
NOTICE:  Index exists: true
NOTICE:  Trigger exists: true
NOTICE:  Users without codes: 0
NOTICE:  Duplicate codes: 0
NOTICE:  ✅ ALL CHECKS PASSED!
```
