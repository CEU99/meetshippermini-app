# Bootstrap Script Fix - User Code Conflict

## 🚨 Error

```
ERROR:  23505: duplicate key value violates unique constraint "users_user_code_key"
DETAIL:  Key (user_code)=(6287777951) already exists.
```

## 🔍 Root Cause

The `user_code` column has a UNIQUE constraint, and Alice (FID 1111) already exists in the database with `user_code = '6287777951'`.

This happens because:
1. Dev login endpoint auto-creates users when you login
2. You logged in as Alice before running the bootstrap script
3. User code was already assigned

## ✅ Solution (3 Options)

### Option 1: Use Simple Bootstrap (Recommended)

This version updates ONLY bio and traits, keeps existing user_code:

```bash
psql <your-connection-string> -f bootstrap-dev-users-simple.sql
```

**What it does:**
- ✅ Updates bio for Alice and Emir
- ✅ Updates traits (7 traits each)
- ✅ Does NOT touch user_code (keeps existing values)
- ✅ Safe to run multiple times

### Option 2: Use Fixed Bootstrap

The original script is now fixed to handle conflicts:

```bash
psql <your-connection-string> -f bootstrap-dev-users.sql
```

**What it does:**
- ✅ Updates bio and traits
- ✅ Keeps existing user_code if present
- ✅ Only sets user_code if NULL
- ✅ Shows notice if user_code differs

### Option 3: Manual SQL Update

If you just want bio and traits without running a script:

```sql
-- Update Alice
UPDATE users
SET
  bio = 'Test user for manual matching. Interested in web3, startups, and meeting new people.',
  traits = '["Founder", "Web3", "Builder", "Open Source", "Community", "Design", "Product"]'::jsonb,
  updated_at = NOW()
WHERE fid = 1111;

-- Update Emir
UPDATE users
SET
  bio = 'Builder and entrepreneur. Building cool stuff in web3.',
  traits = '["Founder", "Builder", "Web3", "Startups", "Product", "Tech", "Innovation"]'::jsonb,
  updated_at = NOW()
WHERE fid = 543581;

-- Verify
SELECT fid, username, bio, jsonb_array_length(traits) as trait_count
FROM users
WHERE fid IN (1111, 543581);
```

## 🔍 Check Current State

Before running anything, check what's already in the database:

```sql
SELECT
  fid,
  username,
  display_name,
  user_code,
  bio IS NOT NULL as has_bio,
  jsonb_array_length(COALESCE(traits, '[]'::jsonb)) as trait_count
FROM users
WHERE fid IN (1111, 543581);
```

**What you need:**
- ✅ `has_bio = true` (bio exists)
- ✅ `trait_count >= 5` (at least 5 traits)
- User code can be anything (doesn't need to match)

## ✅ Verification

After running the bootstrap:

```sql
-- Check bio and traits
SELECT
  fid,
  username,
  LEFT(bio, 50) as bio_preview,
  jsonb_array_length(traits) as trait_count,
  CASE
    WHEN bio IS NOT NULL AND jsonb_array_length(traits) >= 5
    THEN '✅ Ready'
    ELSE '❌ Not ready'
  END as status
FROM users
WHERE fid IN (1111, 543581);
```

**Expected:**
```
 fid    | username     | bio_preview                        | trait_count | status
--------+--------------+------------------------------------+-------------+---------
 1111   | alice        | Test user for manual matching...   | 7           | ✅ Ready
 543581 | cengizhaneu  | Builder and entrepreneur...        | 7           | ✅ Ready
```

## 🎯 Why We Need This

Some parts of the app check:
1. User has bio text (not NULL, not empty)
2. User has >= 5 traits (for matchmaking algorithm)

Without these, users may not appear in match results or cause errors.

## 📋 Quick Reference

| File | Purpose | Updates user_code? |
|------|---------|-------------------|
| `bootstrap-dev-users-simple.sql` | Bio + traits only | No ✅ |
| `bootstrap-dev-users.sql` | Full profile (safe) | Only if NULL |
| Manual SQL | Quick fix | No |

## 🚀 Recommended Flow

```bash
# 1. Check current state
psql <conn> -c "SELECT fid, username, bio IS NOT NULL as has_bio, jsonb_array_length(traits) as trait_count FROM users WHERE fid IN (1111, 543581);"

# 2. If has_bio=false or trait_count<5, run simple bootstrap
psql <conn> -f bootstrap-dev-users-simple.sql

# 3. Verify
psql <conn> -c "SELECT fid, username, jsonb_array_length(traits) as traits FROM users WHERE fid IN (1111, 543581);"

# 4. Continue with dev auth testing
# http://localhost:3000/api/dev/login?fid=1111&username=alice...
```

## 💡 Understanding User Codes

**What is `user_code`?**
- 10-digit unique code for each user
- Used for invites/referrals
- Set automatically on first login
- Has UNIQUE constraint in database

**Do user codes need to match?**
- No! The specific value doesn't matter
- As long as it exists and is unique
- Dev login will create one if missing
- Bootstrap scripts now preserve existing codes

## 🐛 Still Having Issues?

If you see other errors:

1. **Foreign key constraint:**
   ```
   ERROR: update or delete on table "users" violates foreign key constraint
   ```

   **Cause:** User has related data (matches, messages)
   **Fix:** Don't delete, just UPDATE bio and traits

2. **NOT NULL constraint:**
   ```
   ERROR: null value in column "username" violates not-null constraint
   ```

   **Cause:** Trying to INSERT without required fields
   **Fix:** Use UPDATE instead, or provide all required fields

3. **User doesn't exist:**
   ```
   UPDATE 0 (no rows updated)
   ```

   **Fix:** User hasn't been created yet, login first:
   ```
   http://localhost:3000/api/dev/login?fid=1111&username=alice...
   ```
   Then run bootstrap

## ✅ Summary

**The fix:** Use `bootstrap-dev-users-simple.sql` which only updates bio and traits, leaving user_code alone.

**Why it works:** Doesn't try to change the UNIQUE user_code that's already assigned.

**Result:** Users have bio + traits needed for matching, without any conflicts.

Run it now:
```bash
psql <connection-string> -f bootstrap-dev-users-simple.sql
```

Done! 🎉
