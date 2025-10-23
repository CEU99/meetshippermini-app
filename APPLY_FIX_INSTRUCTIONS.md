# How to Apply the Decline Fix

## The Problem
- Error: `duplicate key value violates unique constraint "uniq_cooldown_pair"`
- Happens when declining a match for a user pair that already has a cooldown
- Root cause: Trigger function doesn't handle existing cooldown records

## The Solution
The fix has been created in `FIX_DECLINE_FINAL.sql`. It will:
1. ✅ Clean up old problematic constraints
2. ✅ Remove duplicate cooldown records (keeping most recent)
3. ✅ Create proper unique index on normalized FID pairs
4. ✅ Update trigger function with true UPSERT logic
5. ✅ Ensure repeated declines work without errors

## Apply the Fix

### Option 1: Via Supabase Dashboard (Recommended)
1. Go to your Supabase Dashboard
2. Navigate to: **SQL Editor**
3. Open the file `FIX_DECLINE_FINAL.sql`
4. Copy and paste its contents into the SQL editor
5. Click **Run**
6. You should see success messages confirming the fix

### Option 2: Via Command Line
```bash
# Set your database connection string
export DATABASE_URL="postgresql://postgres:[YOUR-PASSWORD]@db.mpsnsxmznxvoqcslcaom.supabase.co:5432/postgres"

# Apply the fix
psql "$DATABASE_URL" -f FIX_DECLINE_FINAL.sql
```

Replace `[YOUR-PASSWORD]` with your actual Supabase database password.

## Verification

After applying, the output should show:
- ✓ Updated add_match_cooldown() function
- ✓ Created unique index: uniq_cooldown_pair
- ✓ No duplicate pairs detected
- 🎉 You can now decline matches without errors!

## What Changed

### Before:
```sql
INSERT INTO match_cooldowns (user_a_fid, user_b_fid)
VALUES (NEW.user_a_fid, NEW.user_b_fid)
ON CONFLICT DO NOTHING;  -- ❌ Doesn't work properly
```

### After:
```sql
INSERT INTO match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
VALUES (
  LEAST(user_a_fid, user_b_fid),    -- ✅ Normalized
  GREATEST(user_a_fid, user_b_fid), -- ✅ Normalized
  NOW(),
  NOW() + INTERVAL '7 days'
)
ON CONFLICT (
  LEAST(user_a_fid, user_b_fid),
  GREATEST(user_a_fid, user_b_fid)
)
DO UPDATE SET
  declined_at = NOW(),
  cooldown_until = GREATEST(match_cooldowns.cooldown_until, NOW() + INTERVAL '7 days');
```

## Testing

After applying the fix, test by:
1. Decline a match between two users (e.g., FID 123 and FID 456)
2. Try declining the same match again
3. Should succeed without errors
4. Check that cooldown was updated (not duplicated)

## Questions?

If you encounter any issues, check:
- Does the trigger `match_declined_cooldown` exist?
- Does the index `uniq_cooldown_pair` exist?
- Are there any remaining duplicate cooldowns?

Run this query to verify:
```sql
-- Check for duplicates
SELECT
  LEAST(user_a_fid, user_b_fid) as min_fid,
  GREATEST(user_a_fid, user_b_fid) as max_fid,
  COUNT(*) as count
FROM match_cooldowns
GROUP BY LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid)
HAVING COUNT(*) > 1;
```

Should return 0 rows.
