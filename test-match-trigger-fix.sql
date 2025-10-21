-- =====================================================================
-- TEST SCRIPT: Match Status & Cooldown Trigger Fix
-- =====================================================================
-- This script tests the fix for match status override and cooldown issues
-- Run this AFTER applying supabase-fix-match-triggers.sql
-- =====================================================================

-- Clean up any existing test data
DELETE FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

DELETE FROM public.matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

-- Ensure test users exist
INSERT INTO public.users (fid, username, display_name, bio)
VALUES
  (11111, 'testuser_a', 'Test User A', 'Test bio for user A'),
  (22222, 'testuser_b', 'Test User B', 'Test bio for user B')
ON CONFLICT (fid) DO UPDATE SET
  username = EXCLUDED.username,
  display_name = EXCLUDED.display_name,
  bio = EXCLUDED.bio;

-- =====================================================================
-- TEST 1: Normal acceptance flow should still work
-- =====================================================================

\echo '==================================================================='
\echo 'TEST 1: Normal Acceptance Flow'
\echo '==================================================================='

-- Create a proposed match
INSERT INTO public.matches (user_a_fid, user_b_fid, status, a_accepted, b_accepted, created_by)
VALUES (11111, 22222, 'proposed', false, false, 'system')
RETURNING id, status, a_accepted, b_accepted, created_at;

\echo 'Match created with status: proposed'

-- User A accepts
UPDATE public.matches
SET a_accepted = true, updated_at = NOW()
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status != 'cancelled'
ORDER BY created_at DESC
LIMIT 1
RETURNING id, status, a_accepted, b_accepted;

\echo 'After user A accepts, status should be: accepted_by_a'

-- User B accepts
UPDATE public.matches
SET b_accepted = true, updated_at = NOW()
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status != 'cancelled'
ORDER BY created_at DESC
LIMIT 1
RETURNING id, status, a_accepted, b_accepted;

\echo 'After user B accepts, status should be: accepted'

-- Check no cooldown was created
SELECT COUNT(*) AS cooldown_count
FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

\echo 'Cooldown count should be 0 for accepted matches'

-- =====================================================================
-- TEST 2: Cancelling an accepted match should create cooldown
-- =====================================================================

\echo ''
\echo '==================================================================='
\echo 'TEST 2: Cancel Accepted Match'
\echo '==================================================================='

-- Get the match ID for reference
DO $$
DECLARE
  match_id UUID;
BEGIN
  SELECT id INTO match_id
  FROM public.matches
  WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  ORDER BY created_at DESC
  LIMIT 1;

  RAISE NOTICE 'Testing cancellation for match ID: %', match_id;
END $$;

-- Cancel the match
UPDATE public.matches
SET status = 'cancelled', updated_at = NOW()
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC
LIMIT 1
RETURNING id, status, a_accepted, b_accepted, updated_at;

\echo 'Status should remain: cancelled (not reverted to accepted)'

-- Check if cooldown was created
SELECT
  id,
  user_a_fid,
  user_b_fid,
  declined_at,
  cooldown_until,
  (cooldown_until - declined_at) AS cooldown_duration
FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY declined_at DESC
LIMIT 1;

\echo 'A cooldown row should exist with ~7 days duration'

-- =====================================================================
-- TEST 3: Declining a proposed match should create cooldown
-- =====================================================================

\echo ''
\echo '==================================================================='
\echo 'TEST 3: Decline Proposed Match'
\echo '==================================================================='

-- Clean up previous test
DELETE FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

DELETE FROM public.matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

-- Create new proposed match
INSERT INTO public.matches (user_a_fid, user_b_fid, status, a_accepted, b_accepted, created_by)
VALUES (11111, 22222, 'proposed', false, false, 'system')
RETURNING id, status, a_accepted, b_accepted;

\echo 'Created new proposed match'

-- Decline the match immediately
UPDATE public.matches
SET status = 'declined', updated_at = NOW()
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC
LIMIT 1
RETURNING id, status, a_accepted, b_accepted;

\echo 'Status should be: declined'

-- Check cooldown
SELECT
  id,
  user_a_fid,
  user_b_fid,
  declined_at,
  cooldown_until,
  cooldown_until > NOW() AS is_active
FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY declined_at DESC
LIMIT 1;

\echo 'A cooldown row should exist and be active'

-- =====================================================================
-- TEST 4: Declining partially accepted match should create cooldown
-- =====================================================================

\echo ''
\echo '==================================================================='
\echo 'TEST 4: Decline Partially Accepted Match'
\echo '==================================================================='

-- Clean up
DELETE FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

DELETE FROM public.matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

-- Create match
INSERT INTO public.matches (user_a_fid, user_b_fid, status, a_accepted, b_accepted, created_by)
VALUES (11111, 22222, 'proposed', false, false, 'system');

-- User A accepts (status should become accepted_by_a)
UPDATE public.matches
SET a_accepted = true, updated_at = NOW()
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC
LIMIT 1
RETURNING id, status, a_accepted, b_accepted;

\echo 'User A accepted, status should be: accepted_by_a'

-- Now decline it
UPDATE public.matches
SET status = 'declined', updated_at = NOW()
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC
LIMIT 1
RETURNING id, status, a_accepted, b_accepted;

\echo 'Status should be: declined (not reverted to accepted_by_a)'

-- Check cooldown
SELECT COUNT(*) AS cooldown_count
FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND cooldown_until > NOW();

\echo 'Should have 1 active cooldown'

-- =====================================================================
-- TEST 5: Verify cooldown prevents new matches
-- =====================================================================

\echo ''
\echo '==================================================================='
\echo 'TEST 5: Cooldown Check Function'
\echo '==================================================================='

-- Check if cooldown exists
SELECT public.check_match_cooldown(11111, 22222) AS has_cooldown;

\echo 'Should return TRUE (cooldown is active)'

-- Check reverse order
SELECT public.check_match_cooldown(22222, 11111) AS has_cooldown_reverse;

\echo 'Should return TRUE (cooldown works in both directions)'

-- =====================================================================
-- TEST 6: Edge case - Updating accepted match without status change
-- =====================================================================

\echo ''
\echo '==================================================================='
\echo 'TEST 6: Update Match Without Status Change'
\echo '==================================================================='

-- Clean up and create fresh accepted match
DELETE FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

DELETE FROM public.matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

INSERT INTO public.matches (user_a_fid, user_b_fid, status, a_accepted, b_accepted, created_by)
VALUES (11111, 22222, 'proposed', false, false, 'system');

UPDATE public.matches
SET a_accepted = true, b_accepted = true, updated_at = NOW()
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC
LIMIT 1;

\echo 'Created accepted match'

-- Update some other field without changing status
UPDATE public.matches
SET meeting_link = 'https://meet.example.com/test', updated_at = NOW()
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC
LIMIT 1
RETURNING id, status, meeting_link;

\echo 'Status should remain: accepted'

-- Verify no cooldown was created
SELECT COUNT(*) AS cooldown_count
FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

\echo 'Should still have 0 cooldowns'

-- =====================================================================
-- TEST SUMMARY
-- =====================================================================

\echo ''
\echo '==================================================================='
\echo 'TEST SUMMARY'
\echo '==================================================================='

SELECT
  'Test Users' AS test_item,
  COUNT(*) AS count
FROM public.users
WHERE fid IN (11111, 22222)

UNION ALL

SELECT
  'Test Matches' AS test_item,
  COUNT(*) AS count
FROM public.matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))

UNION ALL

SELECT
  'Active Cooldowns' AS test_item,
  COUNT(*) AS count
FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND cooldown_until > NOW();

\echo ''
\echo 'Trigger configuration:'
SELECT * FROM public.verify_trigger_fix();

-- =====================================================================
-- CLEANUP (Optional - comment out if you want to inspect data)
-- =====================================================================

\echo ''
\echo 'Cleaning up test data...'

DELETE FROM public.match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

DELETE FROM public.matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

-- Optionally remove test users
-- DELETE FROM public.users WHERE fid IN (11111, 22222);

\echo ''
\echo '==================================================================='
\echo 'TEST COMPLETE'
\echo '==================================================================='
\echo ''
\echo 'Expected Results:'
\echo '  - Test 1: Status progresses proposed → accepted_by_a → accepted'
\echo '  - Test 2: Cancelled status persists, cooldown created'
\echo '  - Test 3: Declined status persists, cooldown created'
\echo '  - Test 4: Declined overrides accepted_by_a, cooldown created'
\echo '  - Test 5: Cooldown check returns TRUE in both directions'
\echo '  - Test 6: Status remains accepted, no cooldown on non-status updates'
\echo ''
\echo 'If all tests pass, the fix is working correctly!'
\echo '==================================================================='
