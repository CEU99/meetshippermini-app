-- ============================================================================
-- SAFE MATCH CANCELLATION SCRIPT FOR USER FID: 543581
-- ============================================================================
-- Purpose: Cancel all pending/awaiting matches for a specific user
-- Target FID: 543581
-- Safe to run: Uses transactions and includes verification steps
-- Run in: Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- STEP 1: Check Column Names (Run this first!)
-- ============================================================================
-- This will show you the actual column names in your matches table
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'matches'
ORDER BY ordinal_position;

-- Expected columns (will be either camelCase or snake_case):
-- - id
-- - user_a_fid or userAFid
-- - user_b_fid or userBFid
-- - status
-- - created_at or createdAt
-- - updated_at or updatedAt
-- etc.


-- ============================================================================
-- STEP 2: PREVIEW - List matches to be cancelled (SNAKE_CASE VERSION)
-- ============================================================================
-- Run this first to see what will be affected
-- This is a READ-ONLY query, safe to run

SELECT
    id,
    user_a_fid,
    user_b_fid,
    status,
    created_by_fid,
    message,
    created_at,
    updated_at,
    -- Show who this user is in the match
    CASE
        WHEN user_a_fid = 543581 THEN 'User A'
        WHEN user_b_fid = 543581 THEN 'User B'
        ELSE 'Not found'
    END as user_role
FROM matches
WHERE
    (user_a_fid = 543581 OR user_b_fid = 543581)
    AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b')
ORDER BY created_at DESC;

-- ============================================================================
-- STEP 2: PREVIEW - List matches to be cancelled (CAMELCASE VERSION)
-- ============================================================================
-- Use this if your columns are camelCase (uncomment if needed)

/*
SELECT
    id,
    userAFid,
    userBFid,
    status,
    createdByFid,
    message,
    createdAt,
    updatedAt,
    -- Show who this user is in the match
    CASE
        WHEN userAFid = 543581 THEN 'User A'
        WHEN userBFid = 543581 THEN 'User B'
        ELSE 'Not found'
    END as userRole
FROM matches
WHERE
    (userAFid = 543581 OR userBFid = 543581)
    AND status IN ('pending', 'proposed', 'acceptedByA', 'acceptedByB')
ORDER BY createdAt DESC;
*/


-- ============================================================================
-- STEP 3: COUNT - How many matches will be affected?
-- ============================================================================
-- SNAKE_CASE VERSION
SELECT
    COUNT(*) as matches_to_cancel,
    COUNT(CASE WHEN user_a_fid = 543581 THEN 1 END) as as_user_a,
    COUNT(CASE WHEN user_b_fid = 543581 THEN 1 END) as as_user_b,
    string_agg(DISTINCT status, ', ') as statuses_found
FROM matches
WHERE
    (user_a_fid = 543581 OR user_b_fid = 543581)
    AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');

-- CAMELCASE VERSION (uncomment if needed)
/*
SELECT
    COUNT(*) as matchesToCancel,
    COUNT(CASE WHEN userAFid = 543581 THEN 1 END) as asUserA,
    COUNT(CASE WHEN userBFid = 543581 THEN 1 END) as asUserB,
    string_agg(DISTINCT status, ', ') as statusesFound
FROM matches
WHERE
    (userAFid = 543581 OR userBFid = 543581)
    AND status IN ('pending', 'proposed', 'acceptedByA', 'acceptedByB');
*/


-- ============================================================================
-- STEP 4: CANCEL MATCHES - Safe Update with Transaction (SNAKE_CASE)
-- ============================================================================
-- This will update the matches to 'cancelled' status
-- Run in a transaction for safety

BEGIN;

-- Show what we're about to update
SELECT
    id,
    user_a_fid,
    user_b_fid,
    status as current_status,
    'cancelled' as new_status
FROM matches
WHERE
    (user_a_fid = 543581 OR user_b_fid = 543581)
    AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');

-- Perform the update
UPDATE matches
SET
    status = 'cancelled',
    updated_at = now()
WHERE
    (user_a_fid = 543581 OR user_b_fid = 543581)
    AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');

-- Verify the update
SELECT
    id,
    user_a_fid,
    user_b_fid,
    status,
    updated_at
FROM matches
WHERE
    (user_a_fid = 543581 OR user_b_fid = 543581)
    AND status = 'cancelled'
    AND updated_at > now() - interval '1 minute';

-- If everything looks good, commit:
COMMIT;

-- If something looks wrong, rollback instead:
-- ROLLBACK;


-- ============================================================================
-- STEP 4: CANCEL MATCHES - Safe Update with Transaction (CAMELCASE)
-- ============================================================================
-- Use this version if your columns are camelCase

/*
BEGIN;

-- Show what we're about to update
SELECT
    id,
    userAFid,
    userBFid,
    status as currentStatus,
    'cancelled' as newStatus
FROM matches
WHERE
    (userAFid = 543581 OR userBFid = 543581)
    AND status IN ('pending', 'proposed', 'acceptedByA', 'acceptedByB');

-- Perform the update
UPDATE matches
SET
    status = 'cancelled',
    updatedAt = now()
WHERE
    (userAFid = 543581 OR userBFid = 543581)
    AND status IN ('pending', 'proposed', 'acceptedByA', 'acceptedByB');

-- Verify the update
SELECT
    id,
    userAFid,
    userBFid,
    status,
    updatedAt
FROM matches
WHERE
    (userAFid = 543581 OR userBFid = 543581)
    AND status = 'cancelled'
    AND updatedAt > now() - interval '1 minute';

COMMIT;
-- Or ROLLBACK if needed
*/


-- ============================================================================
-- STEP 5: VERIFY - Final verification after commit (SNAKE_CASE)
-- ============================================================================
-- Run this after committing to confirm changes

SELECT
    id,
    user_a_fid,
    user_b_fid,
    status,
    updated_at,
    created_at,
    CASE
        WHEN user_a_fid = 543581 THEN 'User A'
        WHEN user_b_fid = 543581 THEN 'User B'
    END as user_role
FROM matches
WHERE
    (user_a_fid = 543581 OR user_b_fid = 543581)
    AND status = 'cancelled'
ORDER BY updated_at DESC;

-- CAMELCASE VERSION (uncomment if needed)
/*
SELECT
    id,
    userAFid,
    userBFid,
    status,
    updatedAt,
    createdAt,
    CASE
        WHEN userAFid = 543581 THEN 'User A'
        WHEN userBFid = 543581 THEN 'User B'
    END as userRole
FROM matches
WHERE
    (userAFid = 543581 OR userBFid = 543581)
    AND status = 'cancelled'
ORDER BY updatedAt DESC;
*/


-- ============================================================================
-- STEP 6: ALL MATCHES SUMMARY - See all matches for this user (SNAKE_CASE)
-- ============================================================================
-- Get a complete overview of all matches for FID 543581

SELECT
    status,
    COUNT(*) as count,
    MAX(updated_at) as most_recent,
    MIN(created_at) as oldest
FROM matches
WHERE user_a_fid = 543581 OR user_b_fid = 543581
GROUP BY status
ORDER BY count DESC;


-- ============================================================================
-- BONUS: Cancel a SINGLE match by ID (if needed)
-- ============================================================================
-- Use this if you want to cancel just one specific match
-- Replace 'YOUR_MATCH_ID' with the actual match ID

/*
-- Preview the match
SELECT
    id,
    user_a_fid,
    user_b_fid,
    status,
    message,
    created_at,
    updated_at
FROM matches
WHERE id = 'YOUR_MATCH_ID';

-- Cancel it
UPDATE matches
SET
    status = 'cancelled',
    updated_at = now()
WHERE id = 'YOUR_MATCH_ID'
  AND (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');

-- Verify
SELECT
    id,
    user_a_fid,
    user_b_fid,
    status,
    updated_at
FROM matches
WHERE id = 'YOUR_MATCH_ID';
*/


-- ============================================================================
-- SAFETY NOTES
-- ============================================================================
-- 1. RLS (Row Level Security):
--    - When running from Supabase SQL Editor, you're using the postgres role
--    - RLS policies do NOT apply to postgres/service_role
--    - All rows are visible and updatable
--    - This is safe for admin operations
--
-- 2. Transaction Safety:
--    - The UPDATE is wrapped in BEGIN/COMMIT
--    - If something looks wrong, run ROLLBACK instead of COMMIT
--    - No changes are permanent until you explicitly COMMIT
--
-- 3. Status Values:
--    - Common status values: 'pending', 'proposed', 'accepted_by_a', 'accepted_by_b'
--    - Adjust the IN clause if your app uses different status names
--    - Run STEP 2 first to see what statuses exist
--
-- 4. Column Names:
--    - Run STEP 1 first to verify if you're using snake_case or camelCase
--    - Then use the appropriate version of each query
--    - Most Next.js apps use snake_case in Supabase
--
-- 5. Backup:
--    - Consider taking a snapshot in Supabase Dashboard before bulk updates
--    - Dashboard → Database → Backups → Create Snapshot
--
-- 6. Undo (if needed):
--    - You cannot undo after COMMIT
--    - If you need to restore, use a database snapshot
--    - Or manually update status back to original values if you have the data
--
-- ============================================================================


-- ============================================================================
-- EXECUTION CHECKLIST
-- ============================================================================
-- ☐ 1. Run STEP 1 to verify column names
-- ☐ 2. Run STEP 2 to preview matches (SELECT only)
-- ☐ 3. Run STEP 3 to see count (SELECT only)
-- ☐ 4. Review the results - does it look correct?
-- ☐ 5. Run STEP 4 (BEGIN transaction)
-- ☐ 6. Review the transaction output
-- ☐ 7. If correct, run COMMIT; if wrong, run ROLLBACK;
-- ☐ 8. Run STEP 5 to verify final state
-- ☐ 9. Run STEP 6 to see summary of all matches
-- ☐ 10. Done!
-- ============================================================================


-- ============================================================================
-- QUICK REFERENCE: Status Values in Your App
-- ============================================================================
-- Based on your codebase, these are the known status values:
-- - 'proposed'        : Initial state when match is created
-- - 'pending'         : Waiting for response
-- - 'accepted_by_a'   : User A accepted, waiting for User B
-- - 'accepted_by_b'   : User B accepted, waiting for User A
-- - 'accepted'        : Both accepted (chat room created)
-- - 'declined'        : One user declined
-- - 'cancelled'       : Match was cancelled
-- - 'completed'       : Meeting/chat completed
-- ============================================================================
