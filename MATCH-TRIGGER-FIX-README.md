# Match Trigger Fix - Complete Guide

## Problem Summary

**Symptoms:**
- When updating a match status to `'cancelled'` or `'declined'`, the status reverts back to `'accepted'`
- Cooldown rows are never created in `match_cooldowns` table
- The cooldown triggers (`trg_match_decline`, `trg_match_cancel`) never fire

**Root Cause:**
The `update_match_status()` function runs as a **BEFORE UPDATE** trigger and unconditionally overwrites the status to `'accepted'` when both `a_accepted` and `b_accepted` are `TRUE`. This happens even when you're trying to manually cancel or decline a match.

Since the status gets overridden before the row is written to the database, the **AFTER UPDATE** cooldown triggers see `NEW.status = 'accepted'` instead of `'cancelled'`/`'declined'`, so they never insert cooldown rows.

## The Solution

The fix involves three key changes:

### 1. **Guard Clause in `update_match_status()`**
```sql
-- Skip automatic status logic if manually setting to declined/cancelled
IF NEW.status IN ('declined', 'cancelled') THEN
  RETURN NEW;  -- Let the manual change persist
END IF;
```

This prevents the trigger from overriding intentional status changes.

### 2. **Proper Trigger Ordering**
- **BEFORE UPDATE**: `check_match_acceptance` → handles automatic status transitions
- **AFTER UPDATE**: `trg_match_decline` → creates cooldown for declined matches
- **AFTER UPDATE**: `trg_match_cancel` → creates cooldown for cancelled matches

### 3. **Unique Constraint for Idempotency**
Added `UNIQUE(user_a_fid, user_b_fid)` constraint to `match_cooldowns` table to support `INSERT ... ON CONFLICT` for safe, idempotent cooldown creation.

---

## Installation Steps

### Step 1: Apply the Fix
Run the migration script in your Supabase SQL Editor:

```bash
# Copy the contents of this file and run in Supabase
supabase-fix-match-triggers.sql
```

Or via command line:
```bash
psql <your-connection-string> -f supabase-fix-match-triggers.sql
```

### Step 2: Verify Installation
Check that triggers are properly configured:

```sql
SELECT * FROM public.verify_trigger_fix();
```

Expected output:
| trigger_name | trigger_timing | trigger_event | function_name |
|---|---|---|---|
| check_match_acceptance | BEFORE | UPDATE | update_match_status() |
| trg_match_decline | AFTER | UPDATE | handle_match_decline() |
| trg_match_cancel | AFTER | UPDATE | add_cooldown_on_cancel() |
| update_matches_updated_at | BEFORE | UPDATE | update_updated_at_column() |

### Step 3: Run Tests
Execute the comprehensive test suite:

```bash
psql <your-connection-string> -f test-match-trigger-fix.sql
```

Or in Supabase SQL Editor, copy and run `test-match-trigger-fix.sql`.

---

## What Changed

### Functions Modified

#### `update_match_status()` (supabase-fix-match-triggers.sql:11-52)
**Before:**
```sql
-- Unconditionally set status to 'accepted' if both accepted
IF NEW.a_accepted = TRUE AND NEW.b_accepted = TRUE THEN
  NEW.status = 'accepted';
END IF;
```

**After:**
```sql
-- Respect manual status changes first
IF NEW.status IN ('declined', 'cancelled') THEN
  RETURN NEW;
END IF;

-- Then apply automatic logic
IF NEW.a_accepted IS TRUE AND NEW.b_accepted IS TRUE
   AND NEW.status NOT IN ('declined', 'cancelled') THEN
  NEW.status := 'accepted';
END IF;
```

#### `handle_match_decline()` (supabase-fix-match-triggers.sql:58-81)
Unified function that handles both `'declined'` and `'cancelled'` statuses, with proper state transition checking.

#### `add_cooldown_on_cancel()` (supabase-fix-match-triggers.sql:87-112)
Dedicated function for cancel-specific logic with idempotent `INSERT ... ON CONFLICT`.

---

## Testing Scenarios

The test script covers these scenarios:

| Test | Scenario | Expected Result |
|------|----------|-----------------|
| **Test 1** | Normal acceptance flow (proposed → accepted_by_a → accepted) | Status transitions correctly, no cooldown |
| **Test 2** | Cancel an accepted match | Status stays `'cancelled'`, cooldown created |
| **Test 3** | Decline a proposed match | Status stays `'declined'`, cooldown created |
| **Test 4** | Decline a partially accepted match | Status changes to `'declined'`, cooldown created |
| **Test 5** | Check cooldown function | Returns `TRUE` in both directions |
| **Test 6** | Update match without status change | Status remains `'accepted'`, no cooldown |

---

## Verification Commands

### Check Current Trigger Configuration
```sql
SELECT
  tgname AS trigger_name,
  CASE
    WHEN tgtype::INTEGER & 2 = 2 THEN 'BEFORE'
    ELSE 'AFTER'
  END AS timing,
  tgfoid::regprocedure AS function_name
FROM pg_trigger
WHERE tgrelid = 'public.matches'::regclass
  AND tgname NOT LIKE 'RI_%'
ORDER BY timing, tgname;
```

### Test Manual Cancellation
```sql
-- Create a test match
INSERT INTO matches (user_a_fid, user_b_fid, status, a_accepted, b_accepted, created_by)
VALUES (99991, 99992, 'proposed', true, true, 'system')
RETURNING id, status;

-- Cancel it
UPDATE matches
SET status = 'cancelled'
WHERE user_a_fid = 99991 AND user_b_fid = 99992
RETURNING id, status;  -- Should show 'cancelled'

-- Check cooldown was created
SELECT * FROM match_cooldowns
WHERE user_a_fid = 99991 AND user_b_fid = 99992;
```

### Check Active Cooldowns
```sql
SELECT
  user_a_fid,
  user_b_fid,
  declined_at,
  cooldown_until,
  cooldown_until > NOW() AS is_active,
  EXTRACT(DAYS FROM (cooldown_until - declined_at)) AS days_duration
FROM match_cooldowns
WHERE cooldown_until > NOW()
ORDER BY declined_at DESC;
```

---

## Troubleshooting

### Issue: Status still reverting to 'accepted'

**Diagnosis:**
```sql
-- Check which version of update_match_status is active
SELECT prosrc
FROM pg_proc
WHERE proname = 'update_match_status';
```

**Solution:**
Re-run the fix script. Make sure you're using the Supabase SQL Editor or have proper permissions.

### Issue: Cooldowns not being created

**Diagnosis:**
```sql
-- Check if triggers are attached
SELECT tgname, tgfoid::regprocedure
FROM pg_trigger
WHERE tgrelid = 'matches'::regclass
  AND tgname IN ('trg_match_decline', 'trg_match_cancel');
```

**Solution:**
Verify triggers exist. If not, re-run lines 126-153 from `supabase-fix-match-triggers.sql`.

### Issue: Duplicate cooldown entries

**Diagnosis:**
```sql
-- Check for duplicates
SELECT user_a_fid, user_b_fid, COUNT(*)
FROM match_cooldowns
GROUP BY user_a_fid, user_b_fid
HAVING COUNT(*) > 1;
```

**Solution:**
The unique constraint should prevent this. If you see duplicates, manually clean them:
```sql
-- Keep most recent, delete older ones
DELETE FROM match_cooldowns
WHERE id NOT IN (
  SELECT DISTINCT ON (user_a_fid, user_b_fid) id
  FROM match_cooldowns
  ORDER BY user_a_fid, user_b_fid, declined_at DESC
);
```

---

## Rollback (If Needed)

If you need to revert to the original behavior:

```sql
-- Restore original update_match_status (no guard clause)
CREATE OR REPLACE FUNCTION public.update_match_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.a_accepted = TRUE AND NEW.b_accepted = TRUE THEN
    NEW.status = 'accepted';
  END IF;
  RETURN NEW;
END;
$$;
```

⚠️ **Warning:** This will bring back the original bug where cancelled/declined statuses get overridden.

---

## Performance Impact

**Minimal to None:**
- Added one early-return check (`IF NEW.status IN (...)`) in the BEFORE trigger
- Triggers already existed; we just fixed their logic
- The unique constraint on `match_cooldowns` adds negligible overhead
- No additional table scans or joins

---

## Future Considerations

### Option 1: Consolidated Cooldown Trigger
Consider merging `trg_match_decline` and `trg_match_cancel` into a single trigger if they have identical logic.

### Option 2: Status Transition Table
For complex workflows, consider adding a `match_status_history` table to track all status changes:

```sql
CREATE TABLE match_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  old_status TEXT,
  new_status TEXT,
  changed_by TEXT,
  changed_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Option 3: Soft Deletes
Instead of `'cancelled'` status, consider using a `deleted_at` timestamp column for better audit trails.

---

## Summary

✅ **What's Fixed:**
- Manual status updates to `'declined'` and `'cancelled'` now persist
- Cooldown triggers fire correctly when matches are declined or cancelled
- 7-day cooldowns are properly created in `match_cooldowns` table
- Normal acceptance flow (`proposed` → `accepted_by_a` → `accepted`) still works

✅ **What to Do:**
1. Run `supabase-fix-match-triggers.sql`
2. Run `test-match-trigger-fix.sql` to verify
3. Test in your application

✅ **Files Created:**
- `supabase-fix-match-triggers.sql` - The migration/fix
- `test-match-trigger-fix.sql` - Comprehensive test suite
- `MATCH-TRIGGER-FIX-README.md` - This guide

---

## Questions?

If you encounter any issues:

1. Check trigger configuration with `SELECT * FROM verify_trigger_fix();`
2. Review function source: `SELECT prosrc FROM pg_proc WHERE proname = 'update_match_status';`
3. Run the test suite to identify which scenario is failing
4. Check PostgreSQL logs for any trigger errors

The fix is designed to be idempotent and safe to run multiple times.
