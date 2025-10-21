-- =====================================================================
-- CLEANUP: Remove test matches between users for fresh testing
-- =====================================================================
-- Run this to reset test data between 11111 and 22222
-- Safe to run multiple times
-- =====================================================================

BEGIN;

-- =====================================================================
-- STEP 1: View current state
-- =====================================================================

\echo '===================================================================='
\echo 'STEP 1: Current Matches'
\echo '===================================================================='

SELECT
  id,
  user_a_fid,
  user_b_fid,
  status,
  created_at,
  a_accepted,
  b_accepted,
  created_by
FROM matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC;

\echo ''
\echo '===================================================================='
\echo 'STEP 2: Current Cooldowns'
\echo '===================================================================='

SELECT
  id,
  user_a_fid,
  user_b_fid,
  declined_at,
  cooldown_until,
  cooldown_until > NOW() AS is_active,
  EXTRACT(DAYS FROM (cooldown_until - declined_at)) AS cooldown_days
FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY declined_at DESC;

-- =====================================================================
-- STEP 2: Delete cooldowns (allows immediate re-matching)
-- =====================================================================

\echo ''
\echo '===================================================================='
\echo 'STEP 3: Deleting cooldowns...'
\echo '===================================================================='

DELETE FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

-- =====================================================================
-- STEP 3: Archive old completed matches
-- =====================================================================

\echo ''
\echo '===================================================================='
\echo 'STEP 4: Archiving completed matches...'
\echo '===================================================================='

-- Mark accepted matches as completed (optional, for cleaner data)
UPDATE matches
SET status = 'completed'
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status = 'accepted'
RETURNING id, status;

-- =====================================================================
-- STEP 4 (OPTIONAL): Delete old test matches
-- =====================================================================

-- Uncomment this section if you want to completely remove old matches
-- WARNING: This deletes match history permanently

-- \echo ''
-- \echo '===================================================================='
-- \echo 'STEP 5: Deleting old matches (OPTIONAL)...'
-- \echo '===================================================================='

-- DELETE FROM matches
-- WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
--   AND status IN ('completed', 'cancelled', 'declined')
-- RETURNING id, status;

-- =====================================================================
-- STEP 5: Verify cleanup
-- =====================================================================

\echo ''
\echo '===================================================================='
\echo 'STEP 6: Verification'
\echo '===================================================================='

SELECT
  COUNT(*) FILTER (WHERE status IN ('proposed', 'accepted_by_a', 'accepted_by_b')) AS open_matches,
  COUNT(*) FILTER (WHERE status = 'accepted') AS accepted_matches,
  COUNT(*) FILTER (WHERE status = 'completed') AS completed_matches,
  COUNT(*) FILTER (WHERE status IN ('declined', 'cancelled')) AS closed_matches,
  COUNT(*) AS total_matches
FROM matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

SELECT
  COUNT(*) FILTER (WHERE cooldown_until > NOW()) AS active_cooldowns,
  COUNT(*) FILTER (WHERE cooldown_until <= NOW()) AS expired_cooldowns,
  COUNT(*) AS total_cooldowns
FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

-- =====================================================================
-- STEP 6: Check eligibility
-- =====================================================================

\echo ''
\echo '===================================================================='
\echo 'STEP 7: Eligibility Check'
\echo '===================================================================='

-- Check if users can be matched now
SELECT
  'Cooldown check' AS check_type,
  public.check_match_cooldown(11111, 22222) AS result,
  CASE
    WHEN public.check_match_cooldown(11111, 22222) THEN 'BLOCKED by cooldown'
    ELSE 'OK - no cooldown'
  END AS status;

SELECT
  'Open match check' AS check_type,
  EXISTS (
    SELECT 1 FROM matches
    WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
      AND status IN ('proposed', 'accepted_by_a', 'accepted_by_b')
      AND created_at > NOW() - INTERVAL '24 hours'
  ) AS result,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM matches
      WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
        AND status IN ('proposed', 'accepted_by_a', 'accepted_by_b')
        AND created_at > NOW() - INTERVAL '24 hours'
    )
    THEN 'BLOCKED by open match'
    ELSE 'OK - no open match'
  END AS status;

SELECT
  'Pending count' AS check_type,
  public.count_pending_matches(11111) AS alice_pending,
  public.count_pending_matches(22222) AS bob_pending,
  CASE
    WHEN public.count_pending_matches(11111) >= 3 THEN 'Alice has too many'
    WHEN public.count_pending_matches(22222) >= 3 THEN 'Bob has too many'
    ELSE 'OK - both under limit'
  END AS status;

COMMIT;

\echo ''
\echo '===================================================================='
\echo 'CLEANUP COMPLETE!'
\echo '===================================================================='
\echo ''
\echo 'Expected state after cleanup:'
\echo '  • active_cooldowns = 0'
\echo '  • open_matches = 0'
\echo '  • Cooldown check = OK'
\echo '  • Open match check = OK'
\echo '  • Pending count = OK'
\echo ''
\echo 'You can now run auto-matching and expect a new proposal to be created.'
\echo '===================================================================='
