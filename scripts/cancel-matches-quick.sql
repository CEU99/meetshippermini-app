-- ============================================================================
-- QUICK CANCEL MATCHES FOR FID: 543581
-- ============================================================================
-- Copy-paste these queries one by one into Supabase SQL Editor
-- ============================================================================

-- 1️⃣ CHECK COLUMN NAMES (Run first!)
-- ============================================================================
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'matches'
ORDER BY ordinal_position;


-- 2️⃣ PREVIEW MATCHES TO CANCEL (Read-only, safe)
-- ============================================================================
SELECT
    id,
    user_a_fid,
    user_b_fid,
    status,
    created_at,
    updated_at,
    CASE
        WHEN user_a_fid = 543581 THEN 'User A'
        WHEN user_b_fid = 543581 THEN 'User B'
    END as user_role
FROM matches
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b')
ORDER BY created_at DESC;


-- 3️⃣ COUNT MATCHES (How many will be affected?)
-- ============================================================================
SELECT COUNT(*) as total_to_cancel
FROM matches
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');


-- 4️⃣ CANCEL MATCHES (Transaction - Safe)
-- ============================================================================
BEGIN;

UPDATE matches
SET status = 'cancelled', updated_at = now()
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status IN ('pending', 'proposed', 'accepted_by_a', 'accepted_by_b');

-- Check what was updated
SELECT id, user_a_fid, user_b_fid, status, updated_at
FROM matches
WHERE (user_a_fid = 543581 OR user_b_fid = 543581)
  AND status = 'cancelled'
  AND updated_at > now() - interval '1 minute';

-- ✅ If it looks good, run:
COMMIT;

-- ❌ If something is wrong, run instead:
-- ROLLBACK;


-- 5️⃣ VERIFY (After commit)
-- ============================================================================
SELECT
    status,
    COUNT(*) as count
FROM matches
WHERE user_a_fid = 543581 OR user_b_fid = 543581
GROUP BY status
ORDER BY count DESC;


-- ============================================================================
-- SINGLE MATCH CANCEL (by ID)
-- ============================================================================
-- Replace 'YOUR-MATCH-ID-HERE' with actual match ID

/*
BEGIN;

UPDATE matches
SET status = 'cancelled', updated_at = now()
WHERE id = 'YOUR-MATCH-ID-HERE'
  AND (user_a_fid = 543581 OR user_b_fid = 543581);

SELECT id, status, updated_at FROM matches WHERE id = 'YOUR-MATCH-ID-HERE';

COMMIT;
-- Or ROLLBACK;
*/


-- ============================================================================
-- NOTES
-- ============================================================================
-- • RLS doesn't apply in SQL Editor (you're using postgres role)
-- • Transaction is safe - nothing happens until you COMMIT
-- • Run queries in order: 1️⃣ → 2️⃣ → 3️⃣ → 4️⃣ → COMMIT → 5️⃣
-- • Adjust status values if your app uses different names
-- ============================================================================
