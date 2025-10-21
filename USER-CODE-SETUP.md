# User Code System - Setup Guide

This document explains the 10-digit user code system and how to set it up.

## Overview

Every user gets a unique 10-digit numeric code (e.g., `0123456789`) that is:
- ✅ Automatically generated on first login
- ✅ Guaranteed unique across all users
- ✅ Exactly 10 digits (with leading zeros if needed)
- ✅ Stored in the database linked to their Farcaster FID
- ✅ Displayed prominently on their Dashboard

## Setup Instructions

### Step 1: Run the Database Migration

**CRITICAL**: You MUST run this SQL in your Supabase dashboard before the system will work.

1. Go to your Supabase project: https://supabase.com/dashboard
2. Select your project (`meetshipper`)
3. Click **SQL Editor** in the left sidebar
4. Click "New Query"
5. Open the file `supabase-user-code-migration.sql` from this project
6. Copy ALL the SQL code
7. Paste it into the Supabase SQL Editor
8. Click **RUN** or press Ctrl/Cmd + Enter

**What this does:**
- Adds `user_code` column to `users` table
- Creates format constraint (exactly 10 digits)
- Creates unique index (prevents duplicates)
- Creates PostgreSQL function `gen_unique_user_code()` to generate codes
- Creates trigger to auto-generate code on user insert
- Backfills existing users with codes

### Step 2: Verify the Migration

Run this query in Supabase SQL Editor to verify:

\`\`\`sql
-- Check table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'user_code';

-- Check all users have codes
SELECT COUNT(*) as total_users,
       COUNT(user_code) as users_with_codes,
       COUNT(user_code) - COUNT(*) as missing_codes
FROM users;

-- View some sample codes
SELECT fid, username, user_code
FROM users
LIMIT 10;
\`\`\`

Expected results:
- Column `user_code` exists with type `character(10)`
- All users should have codes (`missing_codes = 0`)
- All codes should be exactly 10 digits

### Step 3: Test the System

1. **Clear your browser session:**
   - Sign out if you're logged in
   - Clear browser cookies (or use incognito mode)

2. **Sign in with Farcaster:**
   - Go to http://localhost:3000
   - Click "Sign in with Farcaster"
   - Scan the QR code with Warpcast
   - Approve the sign-in

3. **Check the Dashboard:**
   - You should be redirected to `/dashboard`
   - You should see a purple badge with your User ID
   - The code should be exactly 10 digits (e.g., `0123456789`)

4. **Verify in Database:**
   \`\`\`sql
   SELECT fid, username, user_code
   FROM users
   WHERE fid = YOUR_FID;
   \`\`\`

5. **Test Uniqueness:**
   - Have another user sign in (or create test account)
   - Verify they get a different code
   - Check in database that no codes are duplicated:
   \`\`\`sql
   SELECT user_code, COUNT(*)
   FROM users
   GROUP BY user_code
   HAVING COUNT(*) > 1;
   -- Should return 0 rows
   \`\`\`

## How It Works

### Database-Side Generation (Primary Method)

The PostgreSQL trigger automatically generates a unique code when a new user is inserted:

\`\`\`sql
CREATE TRIGGER trg_set_user_code
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION set_user_code_before_insert();
\`\`\`

**Process:**
1. User signs in for the first time
2. Backend calls \`UPSERT\` on users table
3. If it's an INSERT (new user), the trigger fires
4. Function \`gen_unique_user_code()\` generates a random 10-digit code
5. Function checks if code already exists in database
6. If exists, generates a new one (loops until unique)
7. Code is automatically set before insert completes

### Fallback Method (Just in Case)

If the trigger doesn't fire (shouldn't happen), the backend has a fallback:

\`\`\`typescript
// lib/user-code.ts
async function ensureUserCode(fid: number): Promise<string>
\`\`\`

**Process:**
1. After user upsert, backend checks if user has a code
2. If no code exists, generates one manually
3. Retries up to 5 times if collision occurs
4. Updates the user record with the code

### Frontend Display

The Dashboard fetches the user code and displays it:

\`\`\`typescript
// Dashboard shows:
User ID: [0123456789]
\`\`\`

If code is temporarily missing (shouldn't happen), shows "Generating..."

## File Structure

### Database
- \`supabase-user-code-migration.sql\` - Complete DB migration

### Backend
- \`lib/user-code.ts\` - User code utilities and fallback logic
- \`lib/supabase.ts\` - User interface with \`user_code\` field
- \`lib/types.ts\` - FarcasterUser interface with \`userCode\`
- \`lib/auth.ts\` - SessionData interface with \`userCode\`
- \`app/api/auth/session/route.ts\` - Generates code on login

### Frontend
- \`components/providers/FarcasterAuthProvider.tsx\` - Fetches user code
- \`app/dashboard/page.tsx\` - Displays user code badge

## Troubleshooting

### Code Not Appearing on Dashboard

**Symptoms:** Dashboard shows "Generating..." or no code

**Solutions:**
1. Check if migration was run: \`SELECT * FROM users WHERE fid = YOUR_FID\`
2. Manually generate code:
   \`\`\`sql
   UPDATE users
   SET user_code = gen_unique_user_code()
   WHERE fid = YOUR_FID AND user_code IS NULL;
   \`\`\`
3. Clear cookies and sign in again

### Duplicate Code Error

**Symptoms:** Error about unique constraint violation

**Solutions:**
1. Should never happen due to loop in \`gen_unique_user_code()\`
2. If it does, check for manually inserted data
3. Regenerate code:
   \`\`\`sql
   UPDATE users
   SET user_code = gen_unique_user_code()
   WHERE user_code = 'DUPLICATE_CODE';
   \`\`\`

### Trigger Not Firing

**Symptoms:** New users don't get codes automatically

**Solutions:**
1. Verify trigger exists:
   \`\`\`sql
   SELECT * FROM information_schema.triggers
   WHERE trigger_name = 'trg_set_user_code';
   \`\`\`
2. If missing, re-run the migration
3. Fallback will still work via \`ensureUserCode()\`

### Wrong Code Length

**Symptoms:** Codes less than 10 digits

**Solutions:**
1. Should be prevented by format constraint
2. Check constraint exists:
   \`\`\`sql
   SELECT constraint_name, check_clause
   FROM information_schema.check_constraints
   WHERE constraint_name = 'user_code_format_chk';
   \`\`\`
3. Regenerate invalid codes:
   \`\`\`sql
   UPDATE users
   SET user_code = gen_unique_user_code()
   WHERE LENGTH(user_code) != 10;
   \`\`\`

## Verification Queries

### Check All Users Have Codes
\`\`\`sql
SELECT
  COUNT(*) as total_users,
  COUNT(user_code) as users_with_codes,
  SUM(CASE WHEN user_code IS NULL THEN 1 ELSE 0 END) as missing_codes
FROM users;
\`\`\`

### Check for Duplicates
\`\`\`sql
SELECT user_code, COUNT(*) as count
FROM users
WHERE user_code IS NOT NULL
GROUP BY user_code
HAVING COUNT(*) > 1;
\`\`\`

### Check Format Validity
\`\`\`sql
SELECT fid, username, user_code, LENGTH(user_code) as length
FROM users
WHERE user_code IS NOT NULL
  AND (LENGTH(user_code) != 10 OR user_code !~ '^[0-9]{10}$');
\`\`\`

### View Distribution of Codes
\`\`\`sql
SELECT
  LEFT(user_code, 1) as first_digit,
  COUNT(*) as count
FROM users
WHERE user_code IS NOT NULL
GROUP BY LEFT(user_code, 1)
ORDER BY first_digit;
\`\`\`

## Acceptance Criteria Checklist

- [ ] Migration SQL has been run in Supabase
- [ ] \`users.user_code\` column exists
- [ ] Column has CHAR(10) type
- [ ] Unique index exists on \`user_code\`
- [ ] Format constraint enforces 10 digits
- [ ] Trigger \`trg_set_user_code\` exists
- [ ] Function \`gen_unique_user_code()\` exists
- [ ] All existing users have codes
- [ ] New users automatically get codes on first login
- [ ] Dashboard displays "User ID: XXXXXXXXXX"
- [ ] No duplicate codes exist
- [ ] Codes are exactly 10 digits with leading zeros

## Next Steps

After setup is complete:

1. Test with multiple users
2. Monitor for any errors in Supabase logs
3. Verify uniqueness with production load
4. Consider adding user code to user profile API responses
5. Optionally add copy-to-clipboard functionality on Dashboard

## Support

If you encounter issues:

1. Check Supabase SQL Editor logs for errors
2. Check Next.js console for backend errors
3. Check browser console for frontend errors
4. Verify all migration steps completed successfully
5. Try the verification queries above
