# Schema Cache Error - Complete Fix Guide

## 🚨 Problem

After running the migration to add `bio` and `traits` columns, you're getting:

```
SCHEMA_CACHE_ERROR
"Schema cache error. Please re-run the database migration or contact support."
```

This happens because PostgREST (Supabase's API layer) caches the database schema and doesn't automatically reload after DDL changes like `ALTER TABLE`.

---

## ✅ Solution Implemented

I've implemented **Option B** (durable RPC-based auto-recovery):

### 1. **Created RPC Function** (`supabase-reload-schema-rpc.sql`)

This creates a function in your database to reload the schema cache:

```sql
CREATE OR REPLACE FUNCTION reload_pgrst_schema()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT pg_notify('pgrst', 'reload schema');
$$;
```

### 2. **Updated API Handlers** (`app/api/profile/route.ts`)

Both GET and PATCH handlers now:
- ✅ Detect PGRST204 errors (schema cache issue)
- ✅ Automatically call `reload_pgrst_schema()` RPC
- ✅ Wait 500ms for cache to reload
- ✅ Retry the failed query once
- ✅ Return friendly error if retry also fails

---

## 📋 Setup Steps

### Step 1: Create the RPC Function

Run this in Supabase SQL Editor:

1. Go to: https://supabase.com/dashboard
2. Select project: **mpsnsxmznxvoqcslcaom**
3. Click: **SQL Editor** → **New Query**
4. Copy and paste: **`supabase-reload-schema-rpc.sql`**
5. Click: **RUN**

You should see:
```
✅ Schema reload RPC created successfully!
Function: reload_pgrst_schema()
```

### Step 2: (Optional) Manually Reload Cache Once

If you want immediate relief, run this in SQL Editor:

```sql
SELECT reload_pgrst_schema();
```

Then try saving your profile again.

### Step 3: Test the Feature

1. Go to: http://localhost:3000/profile/edit
2. Enter bio and select 5-10 traits
3. Click "Save Profile"

**Expected behavior:**
- First attempt might show "Schema cache error..."
- API automatically reloads cache and retries
- Second attempt succeeds
- Redirects to Dashboard with updated profile

---

## 🔍 Verification

Run these queries in Supabase SQL Editor to verify everything is set up correctly:

### 1. Check Columns Exist

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name='users' AND column_name IN ('bio','traits');
```

**Expected:**
```
bio     | text
traits  | jsonb
```

### 2. Check RPC Function Exists

```sql
SELECT proname AS function_name
FROM pg_proc
WHERE proname = 'reload_pgrst_schema';
```

**Expected:**
```
reload_pgrst_schema
```

### 3. Test the Function

```sql
SELECT reload_pgrst_schema();
```

**Expected:** Returns nothing (success)

### 4. Check Your Profile Data

```sql
SELECT fid, username, bio, traits
FROM users
WHERE fid = 543581;  -- Replace with your FID
```

---

## 🎯 How It Works

### Normal Flow (No Error)

```
User clicks Save
  ↓
PATCH /api/profile
  ↓
Supabase UPDATE query
  ↓
Success → Return { ok: true }
```

### Error Recovery Flow (PGRST204)

```
User clicks Save
  ↓
PATCH /api/profile
  ↓
Supabase UPDATE query
  ↓
Error: PGRST204 (schema cache)
  ↓
Call reload_pgrst_schema() RPC
  ↓
Wait 500ms
  ↓
Retry UPDATE query
  ↓
Success → Return { ok: true }
```

---

## 🧪 Testing

### Test Case 1: First Save After Migration

1. Run migration: `supabase-add-profile-fields-v2.sql`
2. Do NOT run `reload_pgrst_schema()` manually
3. Visit `/profile/edit` and try to save

**Expected:**
- ⚠️  Server logs show: "Schema cache error detected, attempting reload..."
- ✅ Server logs show: "Schema cache reloaded"
- ✅ Server logs show: "Retrying update after cache reload..."
- ✅ Success! Profile saved
- ✅ Redirect to Dashboard

### Test Case 2: Subsequent Saves

1. Visit `/profile/edit` again
2. Change bio or traits
3. Click "Save Profile"

**Expected:**
- ✅ No schema cache error
- ✅ Direct success
- ✅ Redirect to Dashboard

### Test Case 3: RPC Function Missing

If the RPC function doesn't exist:

1. Try to save profile
2. API attempts to call `reload_pgrst_schema()`
3. RPC call fails (function not found)
4. Returns error with helpful message:

```json
{
  "error": "SCHEMA_CACHE_ERROR",
  "message": "Schema cache could not be reloaded. Please run: SELECT reload_pgrst_schema(); ...",
  "troubleshootingSteps": [
    "Run: SELECT reload_pgrst_schema(); in Supabase SQL Editor",
    "If function does not exist, run: supabase-reload-schema-rpc.sql",
    "Wait 1-2 seconds and try saving again"
  ]
}
```

---

## 📁 Files Reference

### SQL Migrations

1. **`supabase-add-profile-fields-v2.sql`** - Adds bio/traits columns
2. **`supabase-reload-schema-rpc.sql`** - Creates reload function ⭐ **RUN THIS**

### Verification

3. **`verify-schema-and-permissions.sql`** - Check setup

### API Code

4. **`app/api/profile/route.ts`** - Auto-recovery logic implemented

### Documentation

5. **`SCHEMA-CACHE-FIX-GUIDE.md`** - This file

---

## 🔧 Troubleshooting

### Issue: Still getting SCHEMA_CACHE_ERROR

**Solution 1: Verify RPC function exists**
```sql
SELECT proname FROM pg_proc WHERE proname = 'reload_pgrst_schema';
```

If not found, run `supabase-reload-schema-rpc.sql`.

**Solution 2: Manually reload cache**
```sql
SELECT reload_pgrst_schema();
```

**Solution 3: Check server logs**
Look for:
- "🔄 Reloading PostgREST schema cache..."
- "✅ Schema cache reloaded"
- "❌ Failed to reload schema cache" (indicates RPC issue)

### Issue: RPC Permission Error

If you get a permission error when calling the RPC:

```sql
-- Grant permissions to service role (if needed)
GRANT EXECUTE ON FUNCTION reload_pgrst_schema() TO service_role;
```

### Issue: Profile Saves But Dashboard Doesn't Update

This means the save succeeded but the Dashboard fetch is still using cached schema.

**Solution:**
```sql
SELECT reload_pgrst_schema();
```

Then refresh the Dashboard page.

---

## 🎉 Benefits

1. **Auto-Recovery** - API automatically fixes schema cache issues
2. **No Manual Intervention** - First save after migration "just works"
3. **Future-Proof** - Any future DDL changes won't break the API
4. **User-Friendly** - Clear error messages if something goes wrong
5. **Durable** - RPC function persists across deployments

---

## 📝 Summary

**What you need to do:**

1. ✅ Run `supabase-reload-schema-rpc.sql` in Supabase SQL Editor (once)
2. ✅ Try saving your profile again
3. ✅ Done!

**What happens automatically:**

- API detects schema cache errors
- Calls `reload_pgrst_schema()` RPC
- Retries the failed query
- Success!

---

## 🚀 Next Steps

After running the RPC migration:

1. Test saving a profile
2. Verify Dashboard displays bio and traits
3. Future migrations won't cause this issue again!

---

**Status:** ✅ Complete - Just run the RPC migration!
**Time to Fix:** 1 minute (run SQL, test)
