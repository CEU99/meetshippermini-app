-- =====================================================================
-- VERIFICATION: End-to-End Matching Flow (Supabase Compatible)
-- =====================================================================
-- Test users: 11111 (alice), 22222 (bob)
-- Run these queries in Supabase SQL Editor
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 1: Verify Test Users Exist with Proper Data';
  RAISE NOTICE '====================================================================';
END $$;

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

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 2: Check Match Scoring Manually';
  RAISE NOTICE '====================================================================';
END $$;

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

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 3: Check for Blocking Conditions';
  RAISE NOTICE '====================================================================';
END $$;

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

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 4: After Running Auto-Match, Verify New Proposal';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Run this AFTER calling POST /api/matches/auto-run';
  RAISE NOTICE '';
END $$;

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

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 5: Test Acceptance Flow (Manual)';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Run these updates manually to test the flow';
END $$;

-- Get the latest proposed match ID
DO $$
DECLARE
  match_id UUID;
  match_status TEXT;
BEGIN
  SELECT id, status INTO match_id, match_status
  FROM matches
  WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
    AND status = 'proposed'
  ORDER BY created_at DESC
  LIMIT 1;

  IF match_id IS NULL THEN
    RAISE NOTICE '❌ No proposed match found. Run auto-matching first!';
  ELSE
    RAISE NOTICE '✅ Found proposed match: %', match_id;
    RAISE NOTICE '';
    RAISE NOTICE 'To test acceptance flow, run these queries:';
    RAISE NOTICE '';
    RAISE NOTICE '-- Step 5a: User A accepts';
    RAISE NOTICE 'UPDATE matches SET a_accepted = true WHERE id = ''%'';', match_id;
    RAISE NOTICE '';
    RAISE NOTICE '-- Step 5b: User B accepts';
    RAISE NOTICE 'UPDATE matches SET b_accepted = true WHERE id = ''%'';', match_id;
  END IF;
END $$;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'STEP 6: Test Decline Flow (Manual)';
  RAISE NOTICE '====================================================================';
END $$;

-- Get the latest accepted match ID
DO $$
DECLARE
  match_id UUID;
BEGIN
  SELECT id INTO match_id
  FROM matches
  WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
    AND status = 'accepted'
  ORDER BY created_at DESC
  LIMIT 1;

  IF match_id IS NOT NULL THEN
    RAISE NOTICE 'To test decline flow, run:';
    RAISE NOTICE '';
    RAISE NOTICE 'UPDATE matches SET status = ''declined'' WHERE id = ''%'';', match_id;
    RAISE NOTICE '';
    RAISE NOTICE 'Then verify cooldown was created:';
    RAISE NOTICE 'SELECT * FROM match_cooldowns WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));';
  ELSE
    RAISE NOTICE 'No accepted match found. Complete acceptance flow first.';
  END IF;
END $$;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'BONUS: Comprehensive System Check';
  RAISE NOTICE '====================================================================';
END $$;

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

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'VERIFICATION COMPLETE!';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'SUCCESS CRITERIA:';
  RAISE NOTICE '  ✅ Step 1: Both users are eligible for matching';
  RAISE NOTICE '  ✅ Step 2: Trait similarity calculates correctly';
  RAISE NOTICE '  ✅ Step 3: No blocking conditions initially';
  RAISE NOTICE '  ✅ Step 4: New "proposed" match is created by auto-matching';
  RAISE NOTICE '  ✅ Step 5: Acceptance flow works (manual test)';
  RAISE NOTICE '  ✅ Step 6: Decline creates cooldown (manual test)';
  RAISE NOTICE '';
  RAISE NOTICE 'If all steps show ✅, your matching system is working correctly!';
  RAISE NOTICE '====================================================================';
END $$;
