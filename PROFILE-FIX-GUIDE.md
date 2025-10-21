# Profile Features - Complete Fix Guide

## 🚨 Problem Identified

The server logs clearly show:
```
Error code: 42703
Error message: column users.traits does not exist
```

And also:
```
Error code: PGRST204
Error message: Could not find the 'traits' column of 'users' in the schema cache
```

**Root Cause:** The `bio` and `traits` columns **do not actually exist** in your Supabase database, despite what may have been attempted earlier.

---

## ✅ Solution: Run the V2 Migration

I've created a bulletproof migration file that:
- ✅ Checks if columns exist before adding them
- ✅ Sets proper defaults and constraints
- ✅ Creates GIN index for fast trait queries
- ✅ **Reloads PostgREST schema cache** (fixes PGRST204 error)
- ✅ Is idempotent (safe to run multiple times)

---

## 📋 Step-by-Step Fix Instructions

### Step 1: Verify Current State (Optional)

First, check what columns currently exist:

1. Go to: https://supabase.com/dashboard
2. Select project: **mpsnsxmznxvoqcslcaom**
3. Click: **SQL Editor** → **New Query**
4. Copy and paste: **`verify-profile-columns.sql`**
5. Click: **RUN**

This will show you which columns exist. You'll likely see that `bio` and `traits` are missing.

### Step 2: Run the V2 Migration

1. Go to: https://supabase.com/dashboard
2. Select project: **mpsnsxmznxvoqcslcaom**
3. Click: **SQL Editor** → **New Query**
4. Copy and paste the **entire contents** of: **`supabase-add-profile-fields-v2.sql`**
5. Click: **RUN** (or press Ctrl/Cmd + Enter)

### Step 3: Verify Success

After running the migration, you should see output like:

```
✅ Added bio column
✅ Added traits column
✅ Set default values for existing rows
✅ Added traits array type constraint
✅ Added traits length constraint (0-10 items)
✅ Added GIN index on traits column
✅ Added column comments
✅ Notified PostgREST to reload schema cache

==============================================
✅ MIGRATION COMPLETED SUCCESSFULLY!
==============================================
```

The query at the bottom will show:
```
bio     | text  | YES | null
traits  | jsonb | YES | '[]'::jsonb
```

### Step 4: Test the Application

1. **Refresh your browser** (clear cache if needed)
2. Go to: http://localhost:3000
3. Sign in with Farcaster
4. Go to Dashboard
5. Click **"Edit Profile"**
6. You should now see:
   - ✅ Bio textarea (working)
   - ✅ 50 trait buttons (working)
   - ✅ No errors in console

7. **Test saving:**
   - Enter a bio
   - Select 5-10 traits
   - Click "Save Profile"
   - Should redirect to Dashboard
   - Bio and trait cards should display

---

## 🔧 What Was Fixed

### 1. API Route Improvements (`/app/api/profile/route.ts`)

**Fixed:**
- ✅ Removed `JSON.stringify(traits)` - Supabase handles JSONB conversion
- ✅ Added explicit error handling for column not found (42703)
- ✅ Added explicit error handling for schema cache errors (PGRST204)
- ✅ All responses now return proper JSON with `Content-Type: application/json`
- ✅ Better error messages with migration instructions
- ✅ Comprehensive logging for debugging

### 2. Database Migration V2 (`supabase-add-profile-fields-v2.sql`)

**Key improvements over V1:**
- ✅ Uses `DO $$ BEGIN ... END $$` blocks for idempotency
- ✅ Checks if columns/constraints/indexes exist before creating
- ✅ **Includes `NOTIFY pgrst, 'reload schema'`** to fix cache issues
- ✅ Better error messages and progress logging
- ✅ Wrapped in transaction (BEGIN/COMMIT)
- ✅ Verification queries at the end

---

## 🧪 Verification Checklist

After running the migration, verify:

- [ ] Migration ran without errors
- [ ] Verification query shows `bio` and `traits` columns
- [ ] `/profile/edit` page loads without errors
- [ ] Console shows no API errors
- [ ] Bio textarea is editable
- [ ] All 50 trait buttons are visible and clickable
- [ ] Save button works
- [ ] Dashboard displays bio and trait cards

---

## 🔍 Common Issues & Solutions

### Issue 1: "Column does not exist" after running migration

**Symptoms:**
- Migration appears successful but column still missing
- Error 42703 persists

**Solution:**
- You may have run migration on wrong project
- Verify project ID in Supabase dashboard matches: **mpsnsxmznxvoqcslcaom**
- Check your `.env.local` matches the project
- Re-run the migration on the correct project

### Issue 2: "Schema cache out of sync" (PGRST204)

**Symptoms:**
- Columns exist but API still fails
- Error PGRST204

**Solution:**
The V2 migration includes `NOTIFY pgrst, 'reload schema'` which fixes this. If it persists:
1. Re-run the migration
2. Or manually run: `NOTIFY pgrst, 'reload schema';`
3. Or restart Supabase project (nuclear option)

### Issue 3: Old migration file confusion

**Solution:**
- **Ignore** `supabase-add-profile-fields.sql` (V1)
- **Use** `supabase-add-profile-fields-v2.sql` (V2)
- V2 includes the cache reload command which V1 lacked

---

## 📊 Database Schema (After Migration)

```sql
-- users table structure
CREATE TABLE users (
  fid INTEGER PRIMARY KEY,
  username TEXT NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,                          -- NEW: User biography
  traits JSONB DEFAULT '[]'::jsonb,  -- NEW: User traits array
  user_code CHAR(10),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Constraints
ALTER TABLE users
  ADD CONSTRAINT traits_is_array_chk
  CHECK (jsonb_typeof(traits) = 'array');

ALTER TABLE users
  ADD CONSTRAINT traits_length_chk
  CHECK (jsonb_array_length(traits) >= 0 AND jsonb_array_length(traits) <= 10);

-- Index for fast trait queries
CREATE INDEX idx_users_traits ON users USING GIN (traits);
```

---

## 🎯 Expected Behavior (After Fix)

### GET /api/profile
```json
{
  "fid": 543581,
  "username": "cengizhaneu",
  "displayName": "Cengizhan",
  "pfpUrl": "https://...",
  "bio": "Crypto trader and builder",
  "userCode": "8658599966",
  "traits": ["Trader", "Investor", "Builder", "Alpha-hunter", "Smart-money"]
}
```

### PATCH /api/profile
**Request:**
```json
{
  "bio": "Updated bio text",
  "traits": ["Trader", "Scalper", "Analyst", "Chartist", "Speculator"]
}
```

**Response:**
```json
{
  "success": true,
  "profile": {
    "fid": 543581,
    "username": "cengizhaneu",
    "displayName": "Cengizhan",
    "pfpUrl": "https://...",
    "bio": "Updated bio text",
    "userCode": "8658599966",
    "traits": ["Trader", "Scalper", "Analyst", "Chartist", "Speculator"]
  }
}
```

---

## 📁 Files Reference

### Must Run (In Order)
1. **`verify-profile-columns.sql`** (optional) - Check current state
2. **`supabase-add-profile-fields-v2.sql`** ⭐ **RUN THIS** - Adds columns

### Updated Code Files (Already Applied)
- ✅ `app/api/profile/route.ts` - Fixed API endpoints
- ✅ `lib/constants/traits.ts` - Trait definitions
- ✅ `app/profile/edit/page.tsx` - Edit Profile page
- ✅ `app/dashboard/page.tsx` - Dashboard display
- ✅ `components/providers/FarcasterAuthProvider.tsx` - Auth provider
- ✅ `app/api/auth/session/route.ts` - Session handler

### Documentation
- `PROFILE-FIX-GUIDE.md` - This file
- `PROFILE-FEATURES-SUMMARY.md` - Complete feature overview
- `PROFILE-FEATURES-SETUP.md` - Original setup guide

---

## 🚀 Quick Start (TL;DR)

1. Go to Supabase Dashboard → SQL Editor
2. Run `supabase-add-profile-fields-v2.sql`
3. Refresh your app
4. Test `/profile/edit`
5. Done! ✅

---

## 💡 Why Previous Attempts Failed

The original migration file (`supabase-add-profile-fields.sql`) was missing a critical command:

```sql
NOTIFY pgrst, 'reload schema';
```

This command tells PostgREST (Supabase's API layer) to reload its schema cache. Without it, even though columns exist in PostgreSQL, the API layer doesn't know about them and returns PGRST204 errors.

The V2 migration includes this fix.

---

## 📞 Still Having Issues?

If the migration runs successfully but you still see errors:

1. **Check server logs:**
   - Look at the terminal running `npm run dev`
   - The API route now logs detailed error information

2. **Verify Supabase project:**
   - Ensure `.env.local` points to correct project
   - Project ID should be: **mpsnsxmznxvoqcslcaom**

3. **Check browser console:**
   - Look for network errors
   - Check if requests are reaching the API

4. **Run verification query:**
   - Use `verify-profile-columns.sql` to confirm columns exist
   - Check that `traits` shows as `jsonb` type with default `'[]'::jsonb`

---

**Status:** Ready to fix - just run the V2 migration! 🎉
