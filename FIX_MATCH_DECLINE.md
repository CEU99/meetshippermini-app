# Fix: Match Decline - "Failed to update match" Error

## Problem Summary

When trying to decline a pending match in the inbox, the application shows the error: **"Failed to update match"**

### Error Details
- Error Type: `Console ApiError`
- Location: `lib/api-client.ts:41`
- Triggered by: `app/mini/inbox/page.tsx:209` (handleRespond function)
- API Endpoint: `POST /api/matches/:id/respond`

## Diagnostic Steps

### Step 1: Run the Diagnostic Script

First, let's identify the exact cause of the error:

```bash
# Get a match ID from your inbox or database
# Then run the diagnostic script:
node scripts/diagnose-match-decline.js <your-match-id>
```

This script will:
1. Check if the match exists
2. Verify the match status is valid for decline
3. Test the decline update operation
4. Show detailed error information if it fails
5. Revert the test change

### Step 2: Check the Console Output

When you try to decline a match, check your development console for detailed logs.

The API route at `app/api/matches/[id]/respond/route.ts:144-161` logs:
- Error code
- Error message
- Error details
- Error hint

Look for lines like:
```
[API] Respond: Error updating match: { error: ..., code: ..., message: ... }
```

## Common Causes and Solutions

### Cause 1: RLS Policy Blocking Update

**Symptoms:**
- Error code: `42501`
- Message contains "policy" or "permission denied"

**Solution:**

The matches table may have RLS enabled with restrictive policies. Run this SQL in Supabase Dashboard:

```sql
-- Check if RLS is enabled on matches table
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'matches';

-- If rowsecurity is true, check policies
SELECT * FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'matches';

-- Option 1: Disable RLS (if not needed)
ALTER TABLE matches DISABLE ROW LEVEL SECURITY;

-- Option 2: Add service role policy (if RLS needed)
CREATE POLICY "Service role full access on matches"
  ON matches
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');
```

### Cause 2: Status Constraint Violation

**Symptoms:**
- Error code: `23514`
- Message: "check constraint violated"

**Solution:**

The status value 'declined' may not be in the allowed constraint. Run this SQL:

```sql
-- Check current status constraint
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'matches'::regclass AND contype = 'c' AND conname LIKE '%status%';

-- Update constraint to include 'declined'
ALTER TABLE matches DROP CONSTRAINT IF EXISTS matches_status_check;
ALTER TABLE matches ADD CONSTRAINT matches_status_check
  CHECK (status IN (
    'proposed',
    'accepted_by_a',
    'accepted_by_b',
    'accepted',
    'declined',
    'cancelled',
    'completed',
    'pending'
  ));
```

### Cause 3: Trigger Interfering with Update

**Symptoms:**
- Update seems to work but returns no data
- Logs show "Update succeeded but no data returned"

**Solution:**

Check for triggers that might be interfering:

```sql
-- List all triggers on matches table
SELECT tgname, tgenabled, pg_get_triggerdef(oid)
FROM pg_trigger
WHERE tgrelid = 'matches'::regclass AND tgisinternal = false;

-- Temporarily disable problematic triggers
-- ALTER TABLE matches DISABLE TRIGGER <trigger_name>;
```

### Cause 4: Foreign Key or Data Issue

**Symptoms:**
- Error code: `23503`
- Message about foreign key constraint

**Solution:**

Check data integrity:

```sql
-- Verify match exists and has valid foreign keys
SELECT
  m.*,
  ua.username as user_a_username,
  ub.username as user_b_username
FROM matches m
LEFT JOIN users ua ON m.user_a_fid = ua.fid
LEFT JOIN users ub ON m.user_b_fid = ub.fid
WHERE m.id = '<your-match-id>';
```

## Quick Fix: Comprehensive RLS Policy Update

If you determine it's an RLS issue, here's a comprehensive fix:

**File:** `fix-match-decline-rls.sql`

```sql
-- Fix Match Decline RLS Issue
-- This ensures service role can update matches

-- Check current RLS status
DO $$
BEGIN
  RAISE NOTICE 'Checking RLS on matches table...';
END $$;

SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'matches';

-- If RLS is enabled, ensure service role has access
-- Drop old restrictive policies if they exist
DROP POLICY IF EXISTS "Service role can manage matches" ON matches;
DROP POLICY IF EXISTS "Service role full access on matches" ON matches;

-- Don't create a service role policy - let service role bypass RLS automatically
-- OR if you need explicit policy:
-- CREATE POLICY "Service role bypass" ON matches FOR ALL
--   USING (auth.role() = 'service_role')
--   WITH CHECK (auth.role() = 'service_role');

-- Ensure authenticated users can update their matches
DROP POLICY IF EXISTS "Users can update their matches" ON matches;

CREATE POLICY "Users can update their matches" ON matches
  FOR UPDATE
  USING (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  )
  WITH CHECK (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );

-- Verify policies
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'matches'
ORDER BY policyname;

-- Test update with service role (should work)
-- UPDATE matches SET status = 'declined' WHERE id = '<test-id>';
-- ROLLBACK;  -- Don't actually change it
```

## Testing the Fix

After applying the fix:

1. **Start your dev server:**
   ```bash
   pnpm run dev
   ```

2. **Open the inbox:**
   ```
   http://localhost:3000/mini/inbox
   ```

3. **Try to decline a pending match:**
   - Click on a match with status "Pending"
   - Click "Decline"
   - Optionally add a reason

4. **Check the console:**
   - Look for success logs:
     ```
     [API] Respond: Match updated successfully
     ```

5. **Verify in database:**
   ```sql
   SELECT id, status, message, a_accepted, b_accepted
   FROM matches
   WHERE status = 'declined'
   ORDER BY updated_at DESC
   LIMIT 5;
   ```

## Additional Debugging

If the issue persists, add more logging to the API route:

**Edit:** `app/api/matches/[id]/respond/route.ts`

Add before line 137:

```typescript
console.log('[DEBUG] About to update match:', {
  matchId: id,
  updateData,
  currentStatus: match.status,
  isUserA,
  isUserB,
  userFid,
});
```

Add after line 142:

```typescript
console.log('[DEBUG] Update query completed:', {
  hasData: !!updatedMatch,
  hasError: !!updateError,
  errorCode: updateError?.code,
});
```

## Prevention

To prevent similar issues in the future:

1. **Always test RLS policies when using service role**
2. **Use the diagnostic scripts before deploying**
3. **Keep constraint definitions in sync with code**
4. **Monitor API error logs in production**

## Files Created

- ✅ `scripts/diagnose-match-decline.js` - Diagnostic tool
- ✅ `FIX_MATCH_DECLINE.md` - This documentation

## Related Issues

This issue is similar to the match suggestions problem where:
- RLS policies were blocking service role operations
- Solution: Remove service role policies to allow bypass

## Support

If none of these solutions work:

1. Run the diagnostic script and share the output
2. Check Supabase Dashboard → Database → Tables → matches → Policies
3. Share the exact error message from the API logs
4. Verify your `SUPABASE_SERVICE_ROLE_KEY` is correct in `.env.local`

---

**Status:** Diagnostic ready, awaiting error details
**Priority:** High (blocks core feature)
**Next Steps:** Run diagnostic script with actual match ID
