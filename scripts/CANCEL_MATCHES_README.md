# Cancel User Matches - Safe SQL Guide

## Quick Start

To cancel all pending/awaiting matches for **FID: 543581**, follow these steps:

### Option 1: Quick Script (Fastest)
Use: `cancel-matches-quick.sql`

1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy queries from `cancel-matches-quick.sql` one by one
3. Follow the numbered order: 1️⃣ → 2️⃣ → 3️⃣ → 4️⃣ → COMMIT → 5️⃣

### Option 2: Detailed Script (Most Safe)
Use: `cancel-user-matches.sql`

- Includes both snake_case and camelCase versions
- More detailed comments and safety checks
- Includes bonus queries for analysis

---

## Step-by-Step Instructions

### Step 1: Check Column Names
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'matches';
```

**Why?** Confirms if your DB uses `user_a_fid` (snake_case) or `userAFid` (camelCase).

**Expected:** You should see columns like:
- `id`
- `user_a_fid` or `userAFid`
- `user_b_fid` or `userBFid`
- `status`
- `updated_at` or `updatedAt`

---

### Step 2: Preview Matches
```sql
SELECT
    id,
    user_a_fid,
    user_b_fid,
    status,
    created_at
FROM matches
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b')
ORDER BY created_at DESC;
```

**Why?** Shows you exactly which matches will be cancelled.

**Review:** Make sure these are the matches you want to cancel.

---

### Step 3: Count Matches
```sql
SELECT COUNT(*) as total_to_cancel
FROM matches
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');
```

**Why?** Quick sanity check on the number of matches.

---

### Step 4: Cancel Matches (Transaction)
```sql
BEGIN;

UPDATE matches
SET status = 'cancelled', updated_at = now()
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');

-- Verify
SELECT id, status, updated_at
FROM matches
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status = 'cancelled'
  AND updated_at > now() - interval '1 minute';

-- ✅ If it looks good:
COMMIT;

-- ❌ If something is wrong:
-- ROLLBACK;
```

**Important:**
- Nothing is permanent until you run `COMMIT;`
- If the verification looks wrong, run `ROLLBACK;` instead
- You can only commit or rollback ONCE per transaction

---

### Step 5: Final Verification
```sql
SELECT
    status,
    COUNT(*) as count
FROM matches
WHERE user_a_fid = 543581 OR user_b_fid = 543581
GROUP BY status;
```

**Expected:** You should see a row with `status = 'cancelled'` and the count matching Step 3.

---

## Understanding Match Statuses

Your app uses these status values:

| Status | Meaning | Should Cancel? |
|--------|---------|----------------|
| `proposed` | Initial state, waiting for response | ✅ Yes |
| `pending` | Waiting for action | ✅ Yes |
| `accepted_by_a` | User A accepted, B hasn't | ✅ Yes |
| `accepted_by_b` | User B accepted, A hasn't | ✅ Yes |
| `accepted` | Both accepted, chat room created | ❌ No (already active) |
| `declined` | Someone declined | ❌ No (already resolved) |
| `cancelled` | Already cancelled | ❌ No (already done) |
| `completed` | Meeting finished | ❌ No (already done) |

The SQL queries target only: `pending`, `proposed`, `accepted_by_a`, `accepted_by_b`

---

## Safety Features

### Transaction Protection
- All updates use `BEGIN;` ... `COMMIT;`
- Changes are NOT saved until you explicitly run `COMMIT;`
- Run `ROLLBACK;` to undo if something looks wrong

### RLS (Row Level Security)
- **Good news:** RLS doesn't apply when using Supabase SQL Editor
- You're using the `postgres` role, which bypasses RLS
- All rows are visible and updatable
- This is normal and safe for admin operations

### Verification Steps
- Every update includes a verification SELECT
- Check the output before committing
- Count should match your expectations

---

## Cancel a Single Match

If you want to cancel just one specific match by ID:

```sql
BEGIN;

UPDATE matches
SET status = 'cancelled', updated_at = now()
WHERE id = 'YOUR-MATCH-ID-HERE'
  AND (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');

SELECT id, status, updated_at FROM matches WHERE id = 'YOUR-MATCH-ID-HERE';

COMMIT;
```

**Replace** `'YOUR-MATCH-ID-HERE'` with the actual match UUID.

---

## Troubleshooting

### Issue: Column not found
**Error:** `column "user_a_fid" does not exist`

**Solution:** Your DB uses camelCase. Use this instead:
```sql
WHERE (userAFid = 543581 OR userBFid = 543581)
```

See `cancel-user-matches.sql` for camelCase versions (uncomment them).

---

### Issue: No matches found
**Possible reasons:**
1. User has no pending matches (all are accepted/completed/declined)
2. FID is wrong (check if 543581 is correct)
3. Wrong status values (check what statuses exist)

**Check all matches:**
```sql
SELECT status, COUNT(*)
FROM matches
WHERE user_a_fid = 543581 OR user_b_fid = 543581
GROUP BY status;
```

---

### Issue: Transaction already committed/rolled back
**Cause:** You already ran `COMMIT;` or `ROLLBACK;`

**Solution:** Run the entire transaction again (starting from `BEGIN;`)

---

## Backup & Recovery

### Before Running (Recommended)
1. Supabase Dashboard → Database → Backups
2. Click "Create Snapshot"
3. Wait for snapshot to complete
4. Then run your SQL

### After Running (If You Need to Undo)
- You **cannot** undo after `COMMIT;`
- Restore from snapshot if needed
- Or manually update status back (if you have the original data)

---

## Command Summary

```bash
# Location of scripts:
scripts/cancel-matches-quick.sql       # Concise version
scripts/cancel-user-matches.sql        # Detailed version
scripts/CANCEL_MATCHES_README.md       # This guide

# Where to run:
Supabase Dashboard → SQL Editor

# Execution order:
1. Check columns
2. Preview matches
3. Count matches
4. BEGIN transaction
5. UPDATE matches
6. Verify in transaction
7. COMMIT (or ROLLBACK)
8. Final verification
```

---

## What Happens After Cancellation?

### In the Database
- Match `status` changes to `'cancelled'`
- `updated_at` is set to current timestamp
- Match remains in the database (not deleted)

### In the App
- User will see match as "Cancelled" in their inbox
- No action buttons will be shown
- Match appears in the "Declined" or "Cancelled" tab (depending on UI logic)

### Chat Rooms
- If a chat room was already created (status was `'accepted'`), it's not affected
- This query only cancels matches in pending/proposed states
- Accepted matches are NOT cancelled by this script

---

## Quick Reference

### Preview Only (Safe, Read-Only)
```sql
-- See what will be cancelled
SELECT id, status FROM matches
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');
```

### Cancel All Pending
```sql
-- Full transaction
BEGIN;
UPDATE matches SET status = 'cancelled', updated_at = now()
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');
COMMIT;
```

### Verify After
```sql
-- Check what was changed
SELECT COUNT(*) FROM matches
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status = 'cancelled';
```

---

## Need Help?

1. **Unsure about column names?** → Run Step 1 first
2. **Want to see without changing?** → Run Steps 2-3 only
3. **Ready to cancel?** → Run Step 4 (BEGIN → UPDATE → COMMIT)
4. **Made a mistake?** → Use `ROLLBACK;` before `COMMIT;`
5. **Need to undo?** → Restore from Supabase snapshot

---

## Files Included

- **`cancel-matches-quick.sql`** - Fast, concise version
- **`cancel-user-matches.sql`** - Detailed version with both naming conventions
- **`CANCEL_MATCHES_README.md`** - This guide

**Use the quick version** for fast execution.
**Use the detailed version** for safety and analysis.

---

**Ready?** Open `cancel-matches-quick.sql` and start with query 1️⃣! 🚀
