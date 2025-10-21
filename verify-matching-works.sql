-- =====================================================================
-- VERIFICATION: End-to-End Matching Flow
-- =====================================================================
-- Test users: 11111 (alice), 22222 (bob)
-- Run these queries step-by-step to verify complete flow
-- =====================================================================

\echo '===================================================================='
\echo 'STEP 1: Verify Test Users Exist with Proper Data'
\echo '===================================================================='

SELECT
  fid,
  username,
  SUBSTRING(bio, 1, 50) AS bio_preview,
  jsonb_array_length(COALESCE(traits, '[]'::jsonb)) AS trait_count,
  CASE
    WHEN bio IS NOT NULL AND bio <> ''
      AND jsonb_array_length(COALESCE(traits, '[]'::jsonb)) >= 5
    THEN '✅ ELIGIBLE'
    ELSE '❌ NOT ELIGIBLE'
  END AS eligibility_status
FROM users
WHERE fid IN (11111, 22222)
ORDER BY fid;

-- Expected: Both users should show '✅ ELIGIBLE'

\echo ''
\echo '===================================================================='
\echo 'STEP 2: Check Match Scoring Manually'
\echo '===================================================================='

SELECT
  11111 AS user_a_fid,
  22222 AS user_b_fid,
  public.calculate_trait_similarity(
    (SELECT traits FROM users WHERE fid = 11111),
    (SELECT traits FROM users WHERE fid = 22222)
  ) AS trait_similarity,
  CASE
    WHEN public.calculate_trait_similarity(
      (SELECT traits FROM users WHERE fid = 11111),
      (SELECT traits FROM users WHERE fid = 22222)
    ) >= 0.10
    THEN '✅ PASSES threshold (0.10)'
    ELSE '❌ FAILS threshold'
  END AS score_status;

-- Expected: trait_similarity should be high (e.g., 1.0 if all traits match)

\echo ''
\echo '===================================================================='
\echo 'STEP 3: Check for Blocking Conditions'
\echo '===================================================================='

-- 3a. Check cooldown
SELECT
  'Cooldown Check' AS check_name,
  public.check_match_cooldown(11111, 22222) AS is_blocked,
  CASE
    WHEN public.check_match_cooldown(11111, 22222) THEN '❌ BLOCKED by active cooldown'
    ELSE '✅ OK - no cooldown'
  END AS status;

-- 3b. Check open matches in last 24h
WITH open_matches AS (
  SELECT
    id,
    status,
    created_at,
    NOW() - created_at AS age
  FROM matches
  WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
    AND status IN ('proposed', 'accepted_by_a', 'accepted_by_b')
    AND created_at > NOW() - INTERVAL '24 hours'
)
SELECT
  'Open Match Check' AS check_name,
  COUNT(*) > 0 AS is_blocked,
  CASE
    WHEN COUNT(*) > 0 THEN '❌ BLOCKED by open match'
    ELSE '✅ OK - no open match'
  END AS status,
  COUNT(*) AS open_match_count
FROM open_matches;

-- 3c. Check pending proposal count
SELECT
  'Pending Count Check' AS check_name,
  public.count_pending_matches(11111) AS alice_pending,
  public.count_pending_matches(22222) AS bob_pending,
  CASE
    WHEN public.count_pending_matches(11111) >= 3 THEN '❌ Alice has too many'
    WHEN public.count_pending_matches(22222) >= 3 THEN '❌ Bob has too many'
    ELSE '✅ OK - both under limit (3)'
  END AS status;

-- Expected:
-- Cooldown: ✅ OK
-- Open Match: ✅ OK (0 open matches)
-- Pending Count: ✅ OK

\echo ''
\echo '===================================================================='
\echo 'STEP 4: After Running Auto-Match, Verify New Proposal'
\echo '===================================================================='
\echo 'Run this AFTER calling POST /api/matches/auto-run'
\echo ''

-- Find the newest match
SELECT
  id,
  user_a_fid,
  user_b_fid,
  status,
  created_by,
  rationale->>'score' AS match_score,
  rationale->>'traitSimilarity' AS trait_sim,
  rationale->>'bioSimilarity' AS bio_sim,
  a_accepted,
  b_accepted,
  created_at,
  NOW() - created_at AS age
FROM matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC
LIMIT 1;

-- Expected:
-- status = 'proposed'
-- created_by = 'system'
-- match_score >= 0.10
-- a_accepted = false
-- b_accepted = false

\echo ''
\echo '===================================================================='
\echo 'STEP 5: Test Acceptance Flow'
\echo '===================================================================='

\echo 'Step 5a: User A accepts (should change to accepted_by_a)'

-- Get the latest proposed match
DO $$
DECLARE
  match_id UUID;
BEGIN
  SELECT id INTO match_id
  FROM matches
  WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
    AND status = 'proposed'
  ORDER BY created_at DESC
  LIMIT 1;

  IF match_id IS NULL THEN
    RAISE NOTICE '❌ No proposed match found. Run auto-matching first!';
  ELSE
    RAISE NOTICE 'Found match: %', match_id;
  END IF;
END $$;

-- User A accepts
UPDATE matches
SET a_accepted = true
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status = 'proposed'
RETURNING
  id,
  status AS new_status,
  a_accepted,
  b_accepted,
  CASE
    WHEN status = 'accepted_by_a' THEN '✅ Correct - status is accepted_by_a'
    ELSE '❌ Wrong - status should be accepted_by_a'
  END AS validation;

-- Expected: status should change to 'accepted_by_a'

\echo ''
\echo 'Step 5b: User B accepts (should change to accepted)'

-- User B accepts
UPDATE matches
SET b_accepted = true
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status = 'accepted_by_a'
RETURNING
  id,
  status AS new_status,
  a_accepted,
  b_accepted,
  CASE
    WHEN status = 'accepted' THEN '✅ Correct - status is accepted'
    ELSE '❌ Wrong - status should be accepted'
  END AS validation;

-- Expected: status should change to 'accepted'

\echo ''
\echo '===================================================================='
\echo 'STEP 6: Test Decline Flow and Cooldown'
\echo '===================================================================='

\echo 'Step 6a: Decline the match'

-- Decline the match
UPDATE matches
SET status = 'declined'
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status = 'accepted'
RETURNING
  id,
  status,
  CASE
    WHEN status = 'declined' THEN '✅ Correct - status is declined (NOT reverted!)'
    WHEN status = 'accepted' THEN '❌ BUG - status reverted to accepted'
    ELSE '❓ Unexpected status'
  END AS validation;

-- Expected: status should be 'declined' (not revert to 'accepted')

\echo ''
\echo 'Step 6b: Verify cooldown was created'

-- Check cooldown
SELECT
  id,
  user_a_fid,
  user_b_fid,
  declined_at,
  cooldown_until,
  cooldown_until > NOW() AS is_active,
  EXTRACT(DAYS FROM (cooldown_until - declined_at)) AS cooldown_days,
  CASE
    WHEN cooldown_until > NOW() AND EXTRACT(DAYS FROM (cooldown_until - declined_at)) = 7
    THEN '✅ Correct - 7-day cooldown is active'
    WHEN cooldown_until > NOW()
    THEN '⚠️  Cooldown active but wrong duration'
    ELSE '❌ No active cooldown found'
  END AS validation
FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY declined_at DESC
LIMIT 1;

-- Expected:
-- is_active = true
-- cooldown_days = 7
-- validation = ✅ Correct

\echo ''
\echo 'Step 6c: Verify cooldown blocks new matches'

SELECT
  'Cooldown Blocking Test' AS test_name,
  public.check_match_cooldown(11111, 22222) AS is_blocked,
  CASE
    WHEN public.check_match_cooldown(11111, 22222) THEN '✅ Correct - cooldown blocks matching'
    ELSE '❌ Wrong - cooldown should block'
  END AS validation;

-- Expected: is_blocked = true, validation = ✅ Correct

\echo ''
\echo '===================================================================='
\echo 'SUCCESS CRITERIA SUMMARY'
\echo '===================================================================='
\echo ''
\echo '✅ Step 1: Both users are eligible for matching'
\echo '✅ Step 2: Trait similarity calculates correctly (>= threshold)'
\echo '✅ Step 3: No blocking conditions initially'
\echo '✅ Step 4: New "proposed" match is created by auto-matching'
\echo '✅ Step 5: Acceptance flow works (proposed → accepted_by_a → accepted)'
\echo '✅ Step 6: Decline creates 7-day cooldown that blocks future matches'
\echo ''
\echo 'If all steps show ✅, your matching system is working correctly!'
\echo '===================================================================='

-- =====================================================================
-- BONUS: Comprehensive System Check
-- =====================================================================

\echo ''
\echo '===================================================================='
\echo 'BONUS: Comprehensive System Check'
\echo '===================================================================='

-- Check triggers are installed
SELECT
  trigger_name,
  event_manipulation,
  action_timing,
  CASE
    WHEN trigger_name = 'check_match_acceptance' AND action_timing = 'BEFORE'
    THEN '✅ Correct timing'
    WHEN trigger_name IN ('trg_match_decline', 'trg_match_cancel') AND action_timing = 'AFTER'
    THEN '✅ Correct timing'
    ELSE '⚠️  Check timing'
  END AS validation
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'matches'
  AND trigger_name IN ('check_match_acceptance', 'trg_match_decline', 'trg_match_cancel')
ORDER BY action_timing, trigger_name;

-- Check functions exist
SELECT
  proname AS function_name,
  CASE
    WHEN proname IN (
      'check_match_cooldown',
      'calculate_trait_similarity',
      'get_matchable_users',
      'count_pending_matches',
      'update_match_status',
      'handle_match_decline',
      'add_cooldown_on_cancel'
    )
    THEN '✅ Exists'
    ELSE '⚠️  Check function'
  END AS validation
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN (
    'check_match_cooldown',
    'calculate_trait_similarity',
    'get_matchable_users',
    'count_pending_matches',
    'update_match_status',
    'handle_match_decline',
    'add_cooldown_on_cancel'
  )
ORDER BY proname;

\echo ''
\echo '===================================================================='
\echo 'VERIFICATION COMPLETE!'
\echo '===================================================================='
