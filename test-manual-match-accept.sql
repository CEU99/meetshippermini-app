-- =====================================================================
-- Manual Match Test: Emir Accepts Alice's Request
-- =====================================================================
-- This script tests the ACCEPT flow when Emir accepts Alice's match request
-- Run this AFTER test-manual-match-alice-emir.sql
-- =====================================================================

-- =====================================================================
-- STEP 1: VERIFY MATCH EXISTS AND IS IN PROPOSED STATE
-- =====================================================================

-- Check current match state
SELECT
  m.id,
  m.user_a_fid,
  ua.username as alice,
  m.user_b_fid,
  ub.username as emir,
  m.status,
  m.a_accepted as alice_accepted,
  m.b_accepted as emir_accepted,
  m.meeting_link,
  CASE
    WHEN m.status NOT IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending') THEN '❌ FAIL: Match not in valid state for acceptance'
    ELSE '✅ PASS: Match ready for acceptance'
  END as validation
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 2: EMIR ACCEPTS THE MATCH
-- =====================================================================

-- Emir (user_b_fid = 543581) accepts the match
UPDATE public.matches
SET
  b_accepted = true,
  updated_at = NOW()
WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
  AND status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending')
RETURNING
  id,
  user_a_fid,
  user_b_fid,
  status,
  a_accepted,
  b_accepted,
  '✅ Emir accepted' as result;

-- =====================================================================
-- STEP 3: VERIFY STATUS UPDATED BY TRIGGER
-- =====================================================================

-- Check if trigger updated the status correctly
-- Expected: status should be 'accepted_by_b' (since only Emir accepted)
SELECT
  m.id,
  m.status,
  m.a_accepted as alice_accepted,
  m.b_accepted as emir_accepted,
  CASE
    WHEN m.status = 'accepted_by_b' THEN '✅ PASS: Status correctly updated to accepted_by_b'
    WHEN m.status = 'accepted' THEN '⚠️  WARNING: Status is accepted (both accepted?)'
    ELSE '❌ FAIL: Status incorrect: ' || m.status
  END as validation
FROM public.matches m
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 4: CREATE SYSTEM MESSAGE FOR ACCEPTANCE
-- =====================================================================

-- Simulate the API creating a system message when Emir accepts
INSERT INTO public.messages (
  match_id,
  sender_fid,
  content,
  is_system_message
)
SELECT
  m.id,
  543581,  -- Emir's FID
  'cengizhaneu accepted the match! Waiting for your response.',
  true
FROM public.matches m
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 5: VERIFY MESSAGES IN INBOX
-- =====================================================================

-- Check all messages for this match
SELECT
  msg.id,
  msg.sender_fid,
  u.username as sender,
  msg.content,
  msg.is_system_message,
  msg.created_at,
  '📬 Messages' as view
FROM public.messages msg
LEFT JOIN public.users u ON msg.sender_fid = u.fid
WHERE msg.match_id IN (
  SELECT id FROM public.matches
  WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
)
ORDER BY msg.created_at ASC;

-- =====================================================================
-- STEP 6: CHECK INBOX VIEWS
-- =====================================================================

-- What Alice sees (should see that Emir accepted, waiting for her)
SELECT
  m.id as match_id,
  ub.username as other_user,
  m.status,
  m.a_accepted as i_accepted,
  m.b_accepted as they_accepted,
  CASE
    WHEN m.b_accepted = true AND m.a_accepted = false THEN '✅ PASS: Alice sees Emir accepted, waiting for her'
    ELSE '⚠️  Unexpected state'
  END as validation,
  '📥 Alice''s View' as inbox
FROM public.matches m
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
WHERE m.user_a_fid = 1111 AND m.user_b_fid = 543581
ORDER BY m.created_at DESC
LIMIT 1;

-- What Emir sees (should see that he accepted, waiting for Alice)
SELECT
  m.id as match_id,
  ua.username as other_user,
  m.status,
  m.b_accepted as i_accepted,
  m.a_accepted as they_accepted,
  CASE
    WHEN m.b_accepted = true AND m.a_accepted = false THEN '✅ PASS: Emir sees he accepted, waiting for Alice'
    ELSE '⚠️  Unexpected state'
  END as validation,
  '📥 Emir''s View' as inbox
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
WHERE m.user_a_fid = 1111 AND m.user_b_fid = 543581
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 7: NOW ALICE ACCEPTS (BOTH ACCEPT)
-- =====================================================================

-- Alice accepts the match (both users now accepted)
UPDATE public.matches
SET
  a_accepted = true,
  updated_at = NOW()
WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
  AND status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending')
RETURNING
  id,
  status,
  a_accepted,
  b_accepted,
  '✅ Alice accepted' as result;

-- =====================================================================
-- STEP 8: VERIFY FINAL STATUS IS 'ACCEPTED'
-- =====================================================================

-- Check if both accepted triggers final 'accepted' status
SELECT
  m.id,
  m.status,
  m.a_accepted,
  m.b_accepted,
  CASE
    WHEN m.status = 'accepted' AND m.a_accepted = true AND m.b_accepted = true
      THEN '✅ PASS: Both accepted, status is accepted'
    ELSE '❌ FAIL: Status should be accepted but is: ' || m.status
  END as validation
FROM public.matches m
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 9: SIMULATE MEETING LINK GENERATION
-- =====================================================================

-- In real flow, the API would call scheduleMatch() which generates a meeting link
-- For testing, we'll simulate this by updating the match with a mock meeting link
UPDATE public.matches
SET
  meeting_link = 'https://cal.com/meet/alice-emir-' || substr(md5(random()::text), 1, 8),
  scheduled_at = NOW() + INTERVAL '1 day',
  updated_at = NOW()
WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
  AND status = 'accepted'
RETURNING
  id,
  meeting_link,
  scheduled_at,
  '✅ Meeting link generated' as result;

-- =====================================================================
-- STEP 10: CREATE MEETING LINK MESSAGES FOR BOTH USERS
-- =====================================================================

-- Get the meeting link
DO $$
DECLARE
  v_match_id UUID;
  v_meeting_link TEXT;
BEGIN
  SELECT id, meeting_link
  INTO v_match_id, v_meeting_link
  FROM public.matches
  WHERE user_a_fid = 1111 AND user_b_fid = 543581
  ORDER BY created_at DESC
  LIMIT 1;

  -- Message for Alice
  INSERT INTO public.messages (match_id, sender_fid, content, is_system_message)
  VALUES (
    v_match_id,
    1111,
    '🎉 Match accepted! Both parties agreed to meet. Your meeting link: ' || v_meeting_link,
    true
  );

  -- Message for Emir
  INSERT INTO public.messages (match_id, sender_fid, content, is_system_message)
  VALUES (
    v_match_id,
    543581,
    '🎉 Match accepted! Both parties agreed to meet. Your meeting link: ' || v_meeting_link,
    true
  );

  RAISE NOTICE '✅ Meeting link messages created for both users';
END $$;

-- =====================================================================
-- STEP 11: FINAL VERIFICATION - COMPLETE FLOW
-- =====================================================================

-- Check final match state
SELECT
  m.id,
  ua.username as alice,
  ub.username as emir,
  m.status,
  m.a_accepted,
  m.b_accepted,
  m.meeting_link,
  m.scheduled_at,
  CASE
    WHEN m.status = 'accepted'
         AND m.a_accepted = true
         AND m.b_accepted = true
         AND m.meeting_link IS NOT NULL
      THEN '✅ PASS: Complete acceptance flow successful'
    ELSE '❌ FAIL: Acceptance flow incomplete'
  END as validation
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 1;

-- Check all messages (should show complete conversation)
SELECT
  msg.sender_fid,
  u.username as sender,
  msg.content,
  msg.is_system_message,
  msg.created_at,
  '📬 Complete Message History' as view
FROM public.messages msg
LEFT JOIN public.users u ON msg.sender_fid = u.fid
WHERE msg.match_id IN (
  SELECT id FROM public.matches
  WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
)
ORDER BY msg.created_at ASC;

-- Check inbox for both users (should see accepted match with meeting link)
SELECT
  m.id,
  CASE
    WHEN m.user_a_fid = 1111 THEN 'Alice''s Inbox'
    ELSE 'Emir''s Inbox'
  END as inbox,
  m.status,
  m.meeting_link,
  (SELECT COUNT(*) FROM public.messages WHERE match_id = m.id) as message_count
FROM public.matches m
WHERE (m.user_a_fid = 1111 OR m.user_b_fid = 1111)
   OR (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
ORDER BY m.created_at DESC;

-- =====================================================================
-- SUMMARY
-- =====================================================================

DO $$
DECLARE
  v_status TEXT;
  v_meeting_link TEXT;
  v_message_count INT;
BEGIN
  SELECT status, meeting_link
  INTO v_status, v_meeting_link
  FROM public.matches
  WHERE user_a_fid = 1111 AND user_b_fid = 543581
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT COUNT(*)
  INTO v_message_count
  FROM public.messages msg
  WHERE msg.match_id IN (
    SELECT id FROM public.matches
    WHERE user_a_fid = 1111 AND user_b_fid = 543581
  );

  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '✅ ACCEPTANCE FLOW TEST COMPLETED';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Final State:';
  RAISE NOTICE '  • Match status: %', v_status;
  RAISE NOTICE '  • Meeting link: %', COALESCE(v_meeting_link, 'NOT GENERATED');
  RAISE NOTICE '  • Total messages: %', v_message_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Expected Results:';
  RAISE NOTICE '  ✅ Emir sees match request from Alice';
  RAISE NOTICE '  ✅ Emir accepts → status becomes accepted_by_b';
  RAISE NOTICE '  ✅ Alice sees Emir accepted, waiting for her';
  RAISE NOTICE '  ✅ Alice accepts → status becomes accepted';
  RAISE NOTICE '  ✅ Meeting link generated';
  RAISE NOTICE '  ✅ Both users receive meeting link message';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
