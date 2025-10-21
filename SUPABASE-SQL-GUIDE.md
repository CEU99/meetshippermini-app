# Supabase SQL Files - Quick Guide

## 🎯 The Issue You Hit

The original SQL files (`cleanup-test-matches.sql` and `verify-matching-works.sql`) use **psql-specific commands** like `\echo` which don't work in Supabase SQL Editor.

**Error you saw:**
```
ERROR: 42601: syntax error at or near "\"
```

## ✅ Solution: Use Supabase-Compatible Versions

I've created Supabase-compatible versions that use `RAISE NOTICE` instead of `\echo`.

---

## 📋 File Guide

| Original (psql) | Supabase Version | Use When |
|-----------------|------------------|----------|
| `cleanup-test-matches.sql` | `cleanup-test-matches-supabase.sql` | In Supabase SQL Editor ✅ |
| `verify-matching-works.sql` | `verify-matching-works-supabase.sql` | In Supabase SQL Editor ✅ |
| `cleanup-test-matches.sql` | `cleanup-test-matches.sql` | Command line with `psql` |
| `verify-matching-works.sql` | `verify-matching-works.sql` | Command line with `psql` |

---

## 🚀 How to Use in Supabase

### **Step 1: Clean Test Data**

1. Open **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy entire contents of `cleanup-test-matches-supabase.sql`
4. Paste into editor
5. Click **RUN** (or Cmd/Ctrl + Enter)

**Expected Output:**
- Results tab shows matches, cooldowns, verification counts
- Logs tab shows NOTICE messages like:
  ```
  NOTICE:  ====================================================================
  NOTICE:  STEP 1: Current Matches
  NOTICE:  ====================================================================
  ```

**What it does:**
- Shows current matches/cooldowns
- Deletes cooldowns between test users
- Archives old completed matches
- Verifies eligibility for matching

---

### **Step 2: Test Auto-Matching** (Local Terminal)

```bash
# In your project directory
./test-auto-match.sh
```

Or manual:
```bash
curl -X POST http://localhost:3000/api/dev/login \
  -H "Content-Type: application/json" \
  -d '{"fid": 11111, "username": "alice"}' \
  -c cookies.txt

curl -X POST http://localhost:3000/api/matches/auto-run -b cookies.txt
```

**Expected:** `"matchesCreated": 1` ✅

---

### **Step 3: Verify in Supabase**

1. **Supabase SQL Editor** → **New Query**
2. Copy `verify-matching-works-supabase.sql`
3. Paste and **RUN**

**Expected Output:**
- ✅ Step 1: Both users eligible
- ✅ Step 2: Trait similarity high
- ✅ Step 3: No blocking conditions
- ✅ Step 4: New proposed match exists
- Instructions for manual testing Steps 5 & 6

---

## 💡 Quick Verification Query

Don't want to run the whole script? Use this quick check:

```sql
-- Quick check: Did auto-matching work?
SELECT
  id,
  status,
  created_by,
  rationale->>'score' AS score,
  created_at,
  NOW() - created_at AS age
FROM matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC
LIMIT 1;
```

**Expected after auto-match:**
- `status = 'proposed'`
- `created_by = 'system'`
- `score = 0.7` (or similar)
- Recent timestamp (just created)

---

## 🔍 Checking Notices/Logs in Supabase

When you run the scripts:

1. **Results tab** shows query results (tables)
2. **Logs tab** shows NOTICE messages (the step headers)

If you don't see NOTICE messages:
- They might be hidden by default
- Click the **Logs** tab at the bottom of the SQL Editor
- Or check your browser console

---

## 📊 Expected Flow

```
1. Run: cleanup-test-matches-supabase.sql (Supabase)
   ↓
   [Cooldowns deleted, old matches archived]

2. Run: ./test-auto-match.sh (Local terminal)
   ↓
   [Auto-matching creates proposal]

3. Run: verify-matching-works-supabase.sql (Supabase)
   ↓
   [Verify match was created, check triggers]
```

---

## 🐛 Troubleshooting

### Still getting syntax errors?

**Check for:**
- `\echo` → Should be `RAISE NOTICE`
- `\i` → Not supported in Supabase
- `:variable` → Not supported in Supabase

**Solution:** Use the `-supabase.sql` versions!

### Not seeing NOTICE messages?

They're in the **Logs** tab, not Results tab. Look at the bottom of the SQL Editor.

### Want to use psql instead?

```bash
# Get your connection string from Supabase
psql "postgresql://..." -f cleanup-test-matches.sql
psql "postgresql://..." -f verify-matching-works.sql
```

The original files (without `-supabase`) work fine in `psql`.

---

## 📝 File Comparison

### Original (psql)
```sql
\echo 'Step 1: Checking...'
SELECT * FROM users;
```

### Supabase Version
```sql
DO $$
BEGIN
  RAISE NOTICE 'Step 1: Checking...';
END $$;

SELECT * FROM users;
```

**Key Difference:**
- `\echo` → `RAISE NOTICE` inside `DO $$ ... $$` block
- Same logic, just different syntax for output

---

## ✅ Summary

**Use These in Supabase SQL Editor:**
- ✅ `cleanup-test-matches-supabase.sql`
- ✅ `verify-matching-works-supabase.sql`

**Use These in Terminal with psql:**
- ✅ `cleanup-test-matches.sql`
- ✅ `verify-matching-works.sql`

**Both versions do the same thing, just different syntax for compatibility!**

---

## 🎯 Quick Start for Supabase

```sql
-- 1. Clean (run in Supabase)
-- Paste: cleanup-test-matches-supabase.sql

-- 2. Test (run in terminal)
./test-auto-match.sh

-- 3. Verify (run in Supabase)
-- Paste: verify-matching-works-supabase.sql
```

**That's it!** The `-supabase` versions are ready to use. 🚀
