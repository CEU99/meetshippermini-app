# Fix: "Failed to update match" - Decline Button Issue

## Problem Identified ✅

When declining a match, you get this error:
```
Error Code: 23505
Message: duplicate key value violates unique constraint "uniq_cooldown_pair"
Details: Key (LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid))=(11111, 543581) already exists
```

### Root Cause
When you decline a match, a database trigger tries to create a "cooldown" entry to prevent re-matching the same users for 7 days. However, if a cooldown already exists for these users (from a previous decline), the trigger tries to INSERT a duplicate row, violating the unique constraint.

**The trigger function needs to be updated to UPSERT (update if exists, insert if not) instead of just INSERT.**

## Quick Fix (Copy & Paste) 🚀

### Step 1: Open Supabase Dashboard
1. Go to: https://mpsnsxmznxvoqcslcaom.supabase.co
2. Navigate to: **SQL Editor** → **New Query**

### Step 2: Run This SQL

**RECOMMENDED:** Copy the entire contents of the file `fix-decline-MINIMAL.sql` and paste it into the SQL editor, then click **RUN**.

This is a minimal fix that just updates the function - no testing code.

**OR** copy this code directly:

```sql
-- Quick Fix: Update the cooldown trigger function
CREATE OR REPLACE FUNCTION public.add_match_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_min_fid BIGINT;
  v_max_fid BIGINT;
  v_existing_id UUID;
BEGIN
  -- Only add cooldown when status changes TO 'declined'
  IF NEW.status = 'declined' AND (OLD.status IS NULL OR OLD.status IS DISTINCT FROM 'declined') THEN

    -- Normalize the FID order
    v_min_fid := LEAST(NEW.user_a_fid, NEW.user_b_fid);
    v_max_fid := GREATEST(NEW.user_a_fid, NEW.user_b_fid);

    -- Check if cooldown already exists
    SELECT id INTO v_existing_id
    FROM public.match_cooldowns
    WHERE LEAST(user_a_fid, user_b_fid) = v_min_fid
      AND GREATEST(user_a_fid, user_b_fid) = v_max_fid;

    IF v_existing_id IS NOT NULL THEN
      -- Update existing cooldown
      UPDATE public.match_cooldowns
      SET
        declined_at = NOW(),
        cooldown_until = NOW() + INTERVAL '7 days'
      WHERE id = v_existing_id;
    ELSE
      -- Insert new cooldown
      INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
      VALUES (v_min_fid, v_max_fid, NOW(), NOW() + INTERVAL '7 days');
    END IF;
  END IF;

  RETURN NEW;
END;
$$;
```

### Step 3: Test the Fix

1. Start your dev server (if not already running):
   ```bash
   pnpm run dev
   ```

2. Navigate to: http://localhost:3000/mini/inbox

3. Click **Decline** on a pending match

4. You should see:
   - ✅ No more "Failed to update match" error
   - ✅ Match status changes to "declined"
   - ✅ Success message appears

## What This Fix Does

**Before:**
```
Decline Match → Trigger fires → INSERT cooldown → ❌ ERROR: Duplicate key
```

**After:**
```
Decline Match → Trigger fires → Check if cooldown exists
  ├─ Exists? → UPDATE cooldown (reset 7 day timer)
  └─ Doesn't exist? → INSERT new cooldown
→ ✅ SUCCESS
```

## Technical Details

### Files Modified
- ✅ `fix-decline-cooldown-issue.sql` - Comprehensive database fix

### What Changed
1. **Database Trigger Function** (`add_match_cooldown`)
   - Now checks if cooldown exists before inserting
   - Updates existing cooldown instead of causing duplicate key error
   - Properly normalizes FID order using LEAST/GREATEST

### Why This Happened
- Previous trigger used `ON CONFLICT DO NOTHING` but it wasn't working
- The unique constraint is on a computed column expression `(LEAST(...), GREATEST(...))`
- Simple `ON CONFLICT` doesn't work well with expression-based constraints
- Solution: Explicitly check for existence and update if found

## Verification

After applying the fix, you can verify it worked:

```sql
-- Check the updated function
SELECT proname, prosrc
FROM pg_proc
WHERE proname = 'add_match_cooldown';

-- The function should now contain:
-- - "SELECT id INTO v_existing_id"
-- - "IF v_existing_id IS NOT NULL THEN"
-- - "UPDATE public.match_cooldowns"
```

## Rollback (If Needed)

If you need to revert:

```sql
-- Restore old function (not recommended)
CREATE OR REPLACE FUNCTION public.add_match_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'declined' AND (OLD.status IS DISTINCT FROM 'declined') THEN
    INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid)
    VALUES (NEW.user_a_fid, NEW.user_b_fid)
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;
```

## Testing Script

You can test the fix before applying it to your app:

```bash
# Check for pending matches
node scripts/check-pending-matches.js

# Test declining a specific match (diagnostic only)
node scripts/diagnose-match-decline.js <match-id>
```

## Support

If the issue persists after applying the fix:

1. Check Supabase logs:
   - Dashboard → Logs → Postgres Logs
   - Look for any errors related to match_cooldowns

2. Verify the function was updated:
   ```sql
   \df+ add_match_cooldown
   ```

3. Check for existing duplicate cooldowns:
   ```sql
   SELECT
     LEAST(user_a_fid, user_b_fid) as min_fid,
     GREATEST(user_a_fid, user_b_fid) as max_fid,
     COUNT(*) as duplicate_count
   FROM match_cooldowns
   GROUP BY LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid)
   HAVING COUNT(*) > 1;
   ```

---

**Status:** ✅ Fix Ready
**Priority:** 🔴 Critical (blocks core functionality)
**Impact:** Fixes decline button for ALL users
**Time to Apply:** < 2 minutes
