# User Code System - Quick Start

## TL;DR

Your app can't create User IDs yet because the `user_code` column doesn't exist in your Supabase database.

**Fix:** Run the SQL migration in Supabase (takes 30 seconds)

---

## The Issue

The error you're seeing:
```
Error: column users.user_code does not exist (code: 42703)
```

This happens because:
1. The app code expects a `user_code` column in the `users` table
2. That column doesn't exist yet in your Supabase database
3. You need to run a SQL migration to create it

---

## The Solution

### Step 1: Run the SQL Migration (Required)

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your project (should match `mpsnsxmznxvoqcslcaom`)

2. **Open SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query" button

3. **Copy and Run the Migration**
   - Open file: `supabase-user-code-complete.sql`
   - Copy ALL the SQL (entire file)
   - Paste into Supabase SQL Editor
   - Click "RUN" (or Cmd/Ctrl + Enter)

4. **Wait for Success**
   - Should complete in 1-2 seconds
   - You'll see NOTICE messages about column, constraint, index created
   - Any existing users will get codes assigned

---

### Step 2: Verify Project Match

After you sign in again, check your **server logs** (terminal where `npm run dev` is running).

You should see:
```
=== SUPABASE CONNECTION DEBUG ===
URL: https://mpsnsxmznxvoqcslcaom.supabase.co
Project ID: mpsnsxmznxvoqcslcaom
Has Anon Key: true
Has Service Key: true
================================
```

**Important:** The Project ID in the logs should match the project where you ran the SQL migration.

If they don't match:
- Check your `.env.local` file
- Make sure `NEXT_PUBLIC_SUPABASE_URL` points to the correct project
- Restart your dev server

---

### Step 3: Test the App

**Before Migration:**
- Dashboard shows yellow badge: "Migration Required"
- Console shows: "❌ DATABASE MIGRATION REQUIRED"
- Session API returns 200 but with `userCode: null`

**After Migration:**
1. Clear browser cookies (or use incognito mode)
2. Go to http://localhost:3000
3. Sign in with Farcaster
4. Go to Dashboard
5. You should see:
   - Purple badge with "User ID"
   - Your unique 10-digit code (e.g., `0123456789`)
   - No errors in console

---

## Verification Queries

After running the migration, verify it worked:

### Quick Check
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'user_code';
```
Should return 1 row.

### Check Your User
```sql
SELECT fid, username, user_code
FROM users
ORDER BY created_at DESC
LIMIT 10;
```
All users should have 10-digit codes.

### Full Verification
See `VERIFICATION-GUIDE.md` for comprehensive tests.

---

## What Changed

I've made your app resilient to the missing column:

### Before (Your Issue)
- App crashed with 500 error when column missing
- No helpful error messages
- Dashboard stuck on "Generating..."

### After (Fixed)
- ✅ App doesn't crash if column missing
- ✅ Shows helpful errors: "❌ DATABASE MIGRATION REQUIRED"
- ✅ Dashboard shows yellow "Migration Required" badge
- ✅ Debug logs show which Supabase project you're connecting to
- ✅ Session still works, just without user_code
- ✅ After migration, automatically generates and shows user codes

---

## Files You Need

1. **`supabase-user-code-complete.sql`** ⭐
   - The migration you need to run
   - Creates column, constraint, index, trigger, and function
   - Backfills existing users
   - Safe to run multiple times (idempotent)

2. **`VERIFICATION-GUIDE.md`**
   - Detailed testing instructions
   - Verification SQL queries
   - Troubleshooting guide

3. **`QUICK-START.md`** (this file)
   - Quick reference for fixing the issue

---

## Expected Outcome

After running the migration:

✅ **Database:**
- Column `users.user_code` exists (CHAR(10))
- Format constraint ensures exactly 10 digits
- Unique index prevents duplicates
- Trigger auto-generates codes on user insert
- All existing users have codes

✅ **App Behavior:**
- New users get codes automatically on first login
- Dashboard shows 10-digit User ID in purple badge
- No more 42703 errors
- Server logs show successful code generation

✅ **What You'll See:**
```
User ID: 0123456789
```
Instead of:
```
User ID: Migration Required
```

---

## Troubleshooting

### Still seeing "Migration Required"?

**Problem:** Migration ran but app still shows yellow badge.

**Solution:**
1. Clear browser cookies (or use incognito)
2. Sign in again
3. Check server logs for "SUPABASE CONNECTION DEBUG"
4. Verify the Project ID matches where you ran migration

### Error: "column users.user_code does not exist"

**Problem:** Migration didn't run successfully, or ran on wrong project.

**Solution:**
1. Check `.env.local` - verify `NEXT_PUBLIC_SUPABASE_URL`
2. Go to that Supabase project in dashboard
3. Run `supabase-user-code-complete.sql` again
4. Restart your dev server

### Different project IDs in logs vs dashboard?

**Problem:** App connects to Project A, but you ran migration in Project B.

**Solution:**
1. Look at server logs: "Project ID: xxxxxxx"
2. Go to that project in Supabase dashboard
3. Run the migration there
4. Or update `.env.local` to point to the correct project

---

## Support

If you're still stuck:

1. Check `VERIFICATION-GUIDE.md` for detailed troubleshooting
2. Run the verification queries to see what's missing
3. Check server logs for debug output
4. Ensure your `.env.local` matches the Supabase project you're using

---

## Summary

**Problem:** `user_code` column doesn't exist → 42703 errors → "Generating..." forever

**Solution:** Run `supabase-user-code-complete.sql` in Supabase SQL Editor

**Result:** Unique 10-digit User IDs for all users

**Time:** 30 seconds to fix
