# 🚨 EMERGENCY DIAGNOSTIC GUIDE

## Current Situation

You're getting `SCHEMA_CACHE_ERROR` when trying to save your profile, even after:
- ✅ Running `supabase-add-profile-fields-v2.sql`
- ✅ Creating `reload_pgrst_schema()` function
- ✅ Verifying the function exists

**The logs show:**
```
🔄 Reloading PostgREST schema cache...
✅ Schema cache reloaded
🔄 Retrying update after cache reload...
❌ Schema cache error persists after reload
```

This means **something is still wrong** with either:
1. The columns don't actually exist in the database
2. The cache reload isn't working as expected
3. There's a timing issue

---

## 🔬 Step 1: Verify Database State (DO THIS FIRST!)

Run this in Supabase SQL Editor:

```sql
-- Check if bio and traits columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN ('bio', 'traits');
```

### Possible Results:

#### ✅ Result A: Two rows returned
```
bio     | text
traits  | jsonb
```
**Meaning:** Columns exist! Problem is cache.
**Action:** Go to Step 2.

#### ❌ Result B: Zero rows returned
```
(no rows)
```
**Meaning:** Columns DON'T exist! Migration didn't actually run or failed silently.
**Action:** Go to Step 3.

#### ⚠️ Result C: Only one row returned
```
bio | text
```
**Meaning:** Only `bio` exists, `traits` is missing.
**Action:** Go to Step 3.

---

## 🔧 Step 2: If Columns Exist (Result A)

The columns exist but cache is stale. Try this:

### Option 1: Manual Cache Reload (Quick Fix)

Run in Supabase SQL Editor:
```sql
SELECT reload_pgrst_schema();
```

Wait 2-3 seconds, then try saving your profile again.

### Option 2: Nuclear Option (If Option 1 fails)

Run this to force a complete cache reload:
```sql
-- Notify PostgREST multiple times
SELECT pg_notify('pgrst', 'reload schema');
SELECT pg_notify('pgrst', 'reload config');

-- Wait 2 seconds (just sit here for 2 seconds)

-- Verify it worked by querying
SELECT fid, username, bio, traits
FROM users
WHERE fid = 543581;  -- Replace with your FID
```

If the SELECT query works without error, cache is reloaded!

### Option 3: Check Function Permissions

The RPC might be failing silently due to permissions:

```sql
-- Check current permissions
SELECT grantee, privilege_type
FROM information_schema.routine_privileges
WHERE routine_name = 'reload_pgrst_schema';

-- Grant to all roles
GRANT EXECUTE ON FUNCTION reload_pgrst_schema() TO anon, authenticated, service_role;
```

Then try saving profile again.

---

## 📝 Step 3: If Columns DON'T Exist (Result B or C)

The migration didn't actually run or failed. Here's what to do:

### 1. Check if migration already ran partially

```sql
-- See what columns actually exist
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;
```

### 2. Run the complete migration again

Copy and paste **`supabase-add-profile-fields-v2.sql`** into Supabase SQL Editor and click RUN.

**Look for these success messages:**
```
✅ Added bio column
✅ Added traits column
✅ Notified PostgREST to reload schema cache
```

If you see **errors**, screenshot them and we'll fix it.

### 3. Verify it worked

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN ('bio', 'traits');
```

Should return:
```
bio     | text
traits  | jsonb
```

### 4. Try saving profile again

Go to `/profile/edit` and click Save.

---

## 🧪 Step 4: Test API Directly (Advanced Debugging)

If everything above checks out but still failing, test the API directly:

### Test 1: Can you query the columns directly?

Run in Supabase SQL Editor:
```sql
SELECT fid, username, bio, traits
FROM users
WHERE fid = 543581;  -- Your FID
```

**If this works:** Database is fine, problem is API layer.
**If this fails:** Database columns missing or RLS blocking.

### Test 2: Can you UPDATE directly?

```sql
UPDATE users
SET bio = 'Test bio', traits = '["Trader", "Investor", "Hodler", "Whale", "Smart-money"]'::jsonb
WHERE fid = 543581;  -- Your FID

-- Verify it worked
SELECT fid, bio, traits
FROM users
WHERE fid = 543581;
```

**If this works:** Database is fine, API has a bug.
**If this fails:** Check error message for clues.

---

## 🔍 Step 5: Check Server Logs (Latest Updates)

I've added more detailed logging. After your next save attempt, check the server console for:

```
🔄 Reloading PostgREST schema cache...
✅ RPC call succeeded, result: null
⏳ Waiting 1.5 seconds for cache propagation...
✅ Schema cache should be reloaded
🔄 Retrying update after cache reload...
❌ Retry failed with error: { ... full error details ... }
```

The full error details will tell us exactly what's failing.

---

## 💡 Most Likely Causes (Ranked)

Based on the logs, here are the most likely causes:

### 1. **Cache Reload Timing** (60% likely)
- The 500ms wait wasn't enough
- I've increased it to 1.5 seconds
- Try saving profile again with the updated code

### 2. **Columns Don't Actually Exist** (30% likely)
- Migration failed silently
- Run diagnostic query from Step 1
- Re-run migration if needed

### 3. **RPC Permission Issue** (8% likely)
- Function exists but can't be called
- Check permissions in Step 2, Option 3

### 4. **Multiple Supabase Projects** (2% likely)
- You're checking one project but app uses another
- Verify `.env.local` matches Supabase dashboard project

---

## 📋 Quick Checklist

Run through this checklist:

- [ ] Run `test-supabase-columns.sql` diagnostic
- [ ] Verify bio and traits columns exist
- [ ] Verify `reload_pgrst_schema()` function exists
- [ ] Run manual cache reload: `SELECT reload_pgrst_schema();`
- [ ] Wait 2-3 seconds after reload
- [ ] Try saving profile again
- [ ] Check server logs for detailed error
- [ ] If still failing, run direct SQL UPDATE test

---

## 🚀 What I've Updated

### File: `app/api/profile/route.ts`

**Changes:**
1. ✅ Increased cache reload wait time: 500ms → 1.5 seconds
2. ✅ Added detailed RPC call logging
3. ✅ Added retry error logging with full JSON
4. ✅ Better error messages

**New logs you'll see:**
```
✅ RPC call succeeded, result: null
⏳ Waiting 1.5 seconds for cache propagation...
❌ Retry failed with error: { "code": "...", "message": "..." }
```

---

## 📁 Files to Use

1. **`test-supabase-columns.sql`** ⭐ **RUN THIS FIRST** - Diagnostic queries
2. **`supabase-add-profile-fields-v2.sql`** - Re-run if columns missing
3. **`supabase-reload-schema-rpc.sql`** - Re-run if function missing
4. **`EMERGENCY-DIAGNOSTIC-GUIDE.md`** - This file

---

## 🎯 Next Steps

### **Immediate Actions:**

1. Run `test-supabase-columns.sql` in Supabase SQL Editor
2. Screenshot the results
3. Based on results, follow either Step 2 or Step 3
4. Try saving profile again
5. Check server logs for new detailed errors

### **If Still Failing:**

Share with me:
1. Results from `test-supabase-columns.sql`
2. Server logs showing the retry error
3. Any error messages from Supabase SQL Editor

---

**Status:** Waiting for diagnostic results to determine next fix! 🔬
