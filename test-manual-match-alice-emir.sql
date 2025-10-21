-- =====================================================================
-- Manual Match Test: Alice → Emir
-- =====================================================================
-- This script tests the manual match flow end-to-end
--
-- Test Users:
--   Alice (Sender):
--     - Username: @alice
--     - FID: 1111
--     - User Code: 6287777951
--
--   Emir (Target):
--     - Name: Emir Cengizhan Ulu
--     - Username: @cengizhaneu
--     - FID: 543581
--     - User Code: 7189696562
--
-- Introduction Message:
--   "Sizinle tanışmak istiyorum proje hakkında konuşmak istiyorum zaman ayırırsanız bugün görüşelim"
-- =====================================================================

-- =====================================================================
-- STEP 0: SETUP - Ensure test users exist
-- =====================================================================

-- Insert or update Alice
INSERT INTO public.users (fid, username, display_name, avatar_url, bio)
VALUES (
  1111,
  'alice',
  'Alice',
  'https://i.imgur.com/placeholder-alice.jpg',
  'Test user Alice - interested in matching'
)
ON CONFLICT (fid) DO UPDATE SET
  username = EXCLUDED.username,
  display_name = EXCLUDED.display_name,
  updated_at = NOW();

-- Insert or update Emir (if needed - he should already exist)
INSERT INTO public.users (fid, username, display_name, avatar_url, bio)
VALUES (
  543581,
  'cengizhaneu',
  'Emir Cengizhan Ulu',
  'https://i.imgur.com/placeholder-emir.jpg',
  'Builder and entrepreneur'
)
ON CONFLICT (fid) DO UPDATE SET
  username = EXCLUDED.username,
  display_name = EXCLUDED.display_name,
  updated_at = NOW();

-- Verify users exist
SELECT
  fid,
  username,
  display_name,
  bio IS NOT NULL as has_bio
FROM public.users
WHERE fid IN (1111, 543581)
ORDER BY fid;

-- =====================================================================
-- STEP 1: CLEANUP - Remove existing test data
-- =====================================================================

-- Delete existing matches between Alice and Emir
DELETE FROM public.matches
WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
   OR (user_a_fid = 543581 AND user_b_fid = 1111);

-- Delete cooldown entries between these users
DELETE FROM public.match_cooldowns
WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
   OR (user_a_fid = 543581 AND user_b_fid = 1111);

-- Verify cleanup
SELECT 'Cleanup complete' as status;

-- =====================================================================
-- STEP 2: PRE-FLIGHT CHECKS
-- =====================================================================

-- Check for cooldown (should be false after cleanup)
SELECT
  public.check_match_cooldown(1111, 543581) as has_cooldown,
  CASE
    WHEN public.check_match_cooldown(1111, 543581) THEN '❌ FAIL: Cooldown exists'
    ELSE '✅ PASS: No cooldown'
  END as result;

-- Check pending matches count for Alice
SELECT
  public.count_pending_matches(1111) as alice_pending_count,
  CASE
    WHEN public.count_pending_matches(1111) >= 3 THEN '⚠️  WARNING: Alice has max pending matches'
    ELSE '✅ PASS: Alice can create new match'
  END as result;

-- Check pending matches count for Emir
SELECT
  public.count_pending_matches(543581) as emir_pending_count,
  CASE
    WHEN public.count_pending_matches(543581) >= 3 THEN '⚠️  WARNING: Emir has max pending matches'
    ELSE '✅ PASS: Emir can receive new match'
  END as result;

-- =====================================================================
-- STEP 3: CREATE MANUAL MATCH REQUEST
-- =====================================================================

-- Alice creates a manual match request to Emir
INSERT INTO public.matches (
  user_a_fid,
  user_b_fid,
  created_by_fid,
  created_by,
  status,
  message,
  rationale,
  a_accepted,
  b_accepted
)
VALUES (
  1111,  -- Alice (sender)
  543581,  -- Emir (target)
  1111,  -- Created by Alice
  'user',  -- Manual match
  'proposed',
  'Sizinle tanışmak istiyorum proje hakkında konuşmak istiyorum zaman ayırırsanız bugün görüşelim',
  jsonb_build_object(
    'score', 0,
    'manualMatch', true,
    'requestedBy', 1111,
    'introductionMessage', 'Sizinle tanışmak istiyorum proje hakkında konuşmak istiyorum zaman ayırırsanız bugün görüşelim'
  ),
  false,  -- Alice hasn't "accepted" (she initiated)
  false   -- Emir hasn't accepted yet
)
RETURNING
  id as match_id,
  user_a_fid,
  user_b_fid,
  status,
  message,
  created_at;

-- =====================================================================
-- STEP 4: CREATE SYSTEM MESSAGE FOR THE MATCH
-- =====================================================================

-- Create the initial system message showing the introduction
-- (uses subquery to get the most recent match ID)
INSERT INTO public.messages (
  match_id,
  sender_fid,
  content,
  is_system_message
)
SELECT
  id,
  1111,
  'Match request: "Sizinle tanışmak istiyorum proje hakkında konuşmak istiyorum zaman ayırırsanız bugün görüşelim"',
  true
FROM public.matches
WHERE user_a_fid = 1111 AND user_b_fid = 543581
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 5: VERIFY MATCH CREATION
-- =====================================================================

-- Check the created match
SELECT
  m.id,
  m.user_a_fid,
  ua.username as user_a_username,
  m.user_b_fid,
  ub.username as user_b_username,
  m.status,
  m.message,
  m.a_accepted,
  m.b_accepted,
  m.created_by,
  m.rationale,
  m.created_at,
  '✅ Match created successfully' as result
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
   OR (m.user_a_fid = 543581 AND m.user_b_fid = 1111)
ORDER BY m.created_at DESC
LIMIT 1;

-- Check messages for the match
SELECT
  msg.id as message_id,
  msg.match_id,
  msg.sender_fid,
  u.username as sender_username,
  msg.content,
  msg.is_system_message,
  msg.created_at,
  '✅ System message created' as result
FROM public.messages msg
LEFT JOIN public.users u ON msg.sender_fid = u.fid
WHERE msg.match_id IN (
  SELECT id FROM public.matches
  WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
     OR (user_a_fid = 543581 AND user_b_fid = 1111)
)
ORDER BY msg.created_at DESC;

-- =====================================================================
-- STEP 6: VERIFY "INBOX" VIEWS
-- =====================================================================

-- What Emir sees in his inbox (he should see the match request)
SELECT
  m.id as match_id,
  CASE
    WHEN m.user_a_fid = 543581 THEN m.user_b_fid
    ELSE m.user_a_fid
  END as other_user_fid,
  CASE
    WHEN m.user_a_fid = 543581 THEN ub.username
    ELSE ua.username
  END as other_user_username,
  CASE
    WHEN m.user_a_fid = 543581 THEN ub.display_name
    ELSE ua.display_name
  END as other_user_display_name,
  m.status,
  m.message,
  CASE
    WHEN m.user_a_fid = 543581 THEN m.a_accepted
    ELSE m.b_accepted
  END as i_accepted,
  CASE
    WHEN m.user_a_fid = 543581 THEN m.b_accepted
    ELSE m.a_accepted
  END as they_accepted,
  m.created_at,
  '📥 Emir''s Inbox' as view_name
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
  AND m.status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending')
ORDER BY m.created_at DESC;

-- What Alice sees in her inbox (she should see the pending request)
SELECT
  m.id as match_id,
  CASE
    WHEN m.user_a_fid = 1111 THEN m.user_b_fid
    ELSE m.user_a_fid
  END as other_user_fid,
  CASE
    WHEN m.user_a_fid = 1111 THEN ub.username
    ELSE ua.username
  END as other_user_username,
  CASE
    WHEN m.user_a_fid = 1111 THEN ub.display_name
    ELSE ua.display_name
  END as other_user_display_name,
  m.status,
  m.message,
  CASE
    WHEN m.user_a_fid = 1111 THEN m.a_accepted
    ELSE m.b_accepted
  END as i_accepted,
  CASE
    WHEN m.user_a_fid = 1111 THEN m.b_accepted
    ELSE m.a_accepted
  END as they_accepted,
  m.created_at,
  '📥 Alice''s Inbox' as view_name
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 1111 OR m.user_b_fid = 1111)
  AND m.status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending')
ORDER BY m.created_at DESC;

-- =====================================================================
-- SUMMARY
-- =====================================================================

DO $$
DECLARE
  match_count INT;
  message_count INT;
BEGIN
  SELECT COUNT(*) INTO match_count
  FROM public.matches
  WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
     OR (user_a_fid = 543581 AND user_b_fid = 1111);

  SELECT COUNT(*) INTO message_count
  FROM public.messages msg
  WHERE msg.match_id IN (
    SELECT id FROM public.matches
    WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
       OR (user_a_fid = 543581 AND user_b_fid = 1111)
  );

  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '✅ MANUAL MATCH TEST COMPLETED';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Results:';
  RAISE NOTICE '  • Matches created: %', match_count;
  RAISE NOTICE '  • Messages created: %', message_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '  1. Run test-manual-match-accept.sql to test Emir accepting';
  RAISE NOTICE '  2. Run test-manual-match-decline.sql to test Emir declining';
  RAISE NOTICE '';
  RAISE NOTICE 'Expected: Emir should see match request in his inbox';
  RAISE NOTICE '          Alice should see pending request in her inbox';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
