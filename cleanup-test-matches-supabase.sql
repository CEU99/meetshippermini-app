-- =====================================================================
-- CLEANUP: Remove test matches between users for fresh testing
-- =====================================================================
-- Run this in Supabase SQL Editor to reset test data
-- Safe to run multiple times
-- =====================================================================

-- =====================================================================
-- STEP 1: View current state
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 1: Current Matches';
  RAISE NOTICE '====================================================================';
END $$;

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

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 2: Current Cooldowns';
  RAISE NOTICE '====================================================================';
END $$;

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
-- STEP 3: Delete cooldowns (allows immediate re-matching)
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 3: Deleting cooldowns...';
  RAISE NOTICE '====================================================================';
END $$;

DELETE FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

-- =====================================================================
-- STEP 4: Archive old completed matches
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 4: Archiving completed matches...';
  RAISE NOTICE '====================================================================';
END $$;

-- Mark accepted matches as completed (optional, for cleaner data)
UPDATE matches
SET status = 'completed'
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status = 'accepted'
RETURNING id, status;

-- =====================================================================
-- STEP 5 (OPTIONAL): Delete old test matches
-- =====================================================================
-- Uncomment this section if you want to completely remove old matches
-- WARNING: This deletes match history permanently

/*
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 5: Deleting old matches (OPTIONAL)...';
  RAISE NOTICE '====================================================================';
END $$;

DELETE FROM matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status IN ('completed', 'cancelled', 'declined')
RETURNING id, status;
*/

-- =====================================================================
-- STEP 6: Verify cleanup
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 6: Verification';
  RAISE NOTICE '====================================================================';
END $$;

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
-- STEP 7: Check eligibility
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 7: Eligibility Check';
  RAISE NOTICE '====================================================================';
END $$;

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

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'CLEANUP COMPLETE!';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Expected state after cleanup:';
  RAISE NOTICE '  • active_cooldowns = 0';
  RAISE NOTICE '  • open_matches = 0';
  RAISE NOTICE '  • Cooldown check = OK';
  RAISE NOTICE '  • Open match check = OK';
  RAISE NOTICE '  • Pending count = OK';
  RAISE NOTICE '';
  RAISE NOTICE 'You can now run auto-matching and expect a new proposal.';
  RAISE NOTICE '====================================================================';
END $$;
