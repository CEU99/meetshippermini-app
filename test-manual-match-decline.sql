-- =====================================================================
-- Manual Match Test: Emir Declines Alice's Request
-- =====================================================================
-- This script tests the DECLINE flow when Emir declines Alice's match request
-- Run this AS AN ALTERNATIVE to test-manual-match-accept.sql
-- (After running test-manual-match-alice-emir.sql)
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
  CASE
    WHEN m.status NOT IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending') THEN '❌ FAIL: Match not in valid state for decline'
    ELSE '✅ PASS: Match ready for decline'
  END as validation
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 2: EMIR DECLINES THE MATCH
-- =====================================================================

-- Emir declines the match with an optional reason
UPDATE public.matches
SET
  status = 'declined',
  message = COALESCE(message, '') || CASE WHEN message IS NOT NULL AND message != '' THEN E'\n\n' ELSE '' END ||
            'Decline reason: Not interested at this time, thank you for reaching out.',
  updated_at = NOW()
WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
  AND status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending')
RETURNING
  id,
  user_a_fid,
  user_b_fid,
  status,
  message,
  '✅ Emir declined the match' as result;

-- =====================================================================
-- STEP 3: VERIFY STATUS IS 'DECLINED'
-- =====================================================================

-- Check if decline persisted (should NOT be overridden by trigger)
SELECT
  m.id,
  m.status,
  m.a_accepted,
  m.b_accepted,
  CASE
    WHEN m.status = 'declined' THEN '✅ PASS: Status correctly set to declined'
    ELSE '❌ FAIL: Status should be declined but is: ' || m.status
  END as validation
FROM public.matches m
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 4: VERIFY COOLDOWN WAS CREATED
-- =====================================================================

-- Check if cooldown trigger fired and created cooldown entry
SELECT
  mc.id,
  mc.user_a_fid,
  ua.username as user_a,
  mc.user_b_fid,
  ub.username as user_b,
  mc.declined_at,
  mc.cooldown_until,
  EXTRACT(EPOCH FROM (mc.cooldown_until - NOW())) / 86400 as days_remaining,
  CASE
    WHEN mc.cooldown_until > NOW() THEN '✅ PASS: Cooldown active for 7 days'
    ELSE '❌ FAIL: Cooldown expired or not set'
  END as validation
FROM public.match_cooldowns mc
LEFT JOIN public.users ua ON mc.user_a_fid = ua.fid
LEFT JOIN public.users ub ON mc.user_b_fid = ub.fid
WHERE (mc.user_a_fid = 1111 AND mc.user_b_fid = 543581)
   OR (mc.user_a_fid = 543581 AND mc.user_b_fid = 1111)
ORDER BY mc.declined_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 5: CREATE SYSTEM MESSAGES FOR DECLINE
-- =====================================================================

-- Message for Alice (the requester)
INSERT INTO public.messages (
  match_id,
  sender_fid,
  content,
  is_system_message
)
SELECT
  m.id,
  1111,  -- Alice's FID
  'Your match request was declined.',
  true
FROM public.matches m
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
  AND m.status = 'declined'
ORDER BY m.created_at DESC
LIMIT 1;

-- Message for Emir (the decliner)
INSERT INTO public.messages (
  match_id,
  sender_fid,
  content,
  is_system_message
)
SELECT
  m.id,
  543581,  -- Emir's FID
  'Match declined by cengizhaneu: Not interested at this time, thank you for reaching out.',
  true
FROM public.matches m
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
  AND m.status = 'declined'
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 6: VERIFY MESSAGES
-- =====================================================================

-- Check all messages for this match
SELECT
  msg.id,
  msg.sender_fid,
  u.username as sender,
  msg.content,
  msg.is_system_message,
  msg.created_at,
  '📬 Messages After Decline' as view
FROM public.messages msg
LEFT JOIN public.users u ON msg.sender_fid = u.fid
WHERE msg.match_id IN (
  SELECT id FROM public.matches
  WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
)
ORDER BY msg.created_at ASC;

-- =====================================================================
-- STEP 7: CHECK INBOX VIEWS AFTER DECLINE
-- =====================================================================

-- What Alice sees (should see declined status)
SELECT
  m.id as match_id,
  ub.username as other_user,
  m.status,
  m.message,
  m.a_accepted,
  m.b_accepted,
  CASE
    WHEN m.status = 'declined' THEN '✅ PASS: Alice sees match was declined'
    ELSE '⚠️  Unexpected status: ' || m.status
  END as validation,
  '📥 Alice''s View' as inbox
FROM public.matches m
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
WHERE m.user_a_fid = 1111 AND m.user_b_fid = 543581
ORDER BY m.created_at DESC
LIMIT 1;

-- What Emir sees (should see declined status)
SELECT
  m.id as match_id,
  ua.username as other_user,
  m.status,
  m.message,
  m.a_accepted,
  m.b_accepted,
  CASE
    WHEN m.status = 'declined' THEN '✅ PASS: Emir sees match was declined'
    ELSE '⚠️  Unexpected status: ' || m.status
  END as validation,
  '📥 Emir''s View' as inbox
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
WHERE m.user_a_fid = 1111 AND m.user_b_fid = 543581
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 8: TEST COOLDOWN PREVENTION
-- =====================================================================

-- Try to create a new match (should be blocked by cooldown check)
DO $$
DECLARE
  v_in_cooldown BOOLEAN;
BEGIN
  -- Check if cooldown exists
  SELECT public.check_match_cooldown(1111, 543581)
  INTO v_in_cooldown;

  IF v_in_cooldown THEN
    RAISE NOTICE '✅ PASS: Cooldown check prevents new match';
    RAISE NOTICE '   Alice cannot create another match with Emir for 7 days';
  ELSE
    RAISE NOTICE '❌ FAIL: Cooldown check failed - new match would be allowed';
  END IF;
END $$;

-- Demonstrate that cooldown check works
SELECT
  public.check_match_cooldown(1111, 543581) as has_cooldown,
  CASE
    WHEN public.check_match_cooldown(1111, 543581) THEN '✅ PASS: Cooldown active'
    ELSE '❌ FAIL: Cooldown not active'
  END as validation;

-- =====================================================================
-- STEP 9: VERIFY DECLINED MATCH NOT IN ACTIVE INBOX
-- =====================================================================

-- Count active matches for Alice (should exclude declined)
SELECT
  COUNT(*) as active_match_count,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ PASS: Declined match not in active inbox'
    ELSE '⚠️  WARNING: Declined match still showing as active'
  END as validation
FROM public.matches m
WHERE (m.user_a_fid = 1111 OR m.user_b_fid = 1111)
  AND m.status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending', 'accepted');

-- Count active matches for Emir (should exclude declined)
SELECT
  COUNT(*) as active_match_count,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ PASS: Declined match not in active inbox'
    ELSE '⚠️  WARNING: Declined match still showing as active'
  END as validation
FROM public.matches m
WHERE (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
  AND m.status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending', 'accepted');

-- =====================================================================
-- STEP 10: FINAL VERIFICATION - COMPLETE DECLINE FLOW
-- =====================================================================

-- Check final state
SELECT
  m.id,
  ua.username as alice,
  ub.username as emir,
  m.status,
  m.a_accepted,
  m.b_accepted,
  m.message,
  EXISTS(
    SELECT 1 FROM public.match_cooldowns mc
    WHERE (mc.user_a_fid = 1111 AND mc.user_b_fid = 543581)
       OR (mc.user_a_fid = 543581 AND mc.user_b_fid = 1111)
    AND mc.cooldown_until > NOW()
  ) as cooldown_active,
  CASE
    WHEN m.status = 'declined' AND EXISTS(
      SELECT 1 FROM public.match_cooldowns mc
      WHERE (mc.user_a_fid = 1111 AND mc.user_b_fid = 543581)
         OR (mc.user_a_fid = 543581 AND mc.user_b_fid = 1111)
      AND mc.cooldown_until > NOW()
    ) THEN '✅ PASS: Complete decline flow successful'
    ELSE '❌ FAIL: Decline flow incomplete'
  END as validation
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- SUMMARY
-- =====================================================================

DO $$
DECLARE
  v_status TEXT;
  v_cooldown_exists BOOLEAN;
  v_message_count INT;
  v_cooldown_days NUMERIC;
BEGIN
  -- Get match status
  SELECT status
  INTO v_status
  FROM public.matches
  WHERE user_a_fid = 1111 AND user_b_fid = 543581
  ORDER BY created_at DESC
  LIMIT 1;

  -- Check cooldown
  SELECT public.check_match_cooldown(1111, 543581)
  INTO v_cooldown_exists;

  -- Get cooldown days remaining
  SELECT EXTRACT(EPOCH FROM (cooldown_until - NOW())) / 86400
  INTO v_cooldown_days
  FROM public.match_cooldowns
  WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
     OR (user_a_fid = 543581 AND user_b_fid = 1111)
  ORDER BY declined_at DESC
  LIMIT 1;

  -- Count messages
  SELECT COUNT(*)
  INTO v_message_count
  FROM public.messages msg
  WHERE msg.match_id IN (
    SELECT id FROM public.matches
    WHERE user_a_fid = 1111 AND user_b_fid = 543581
  );

  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '✅ DECLINE FLOW TEST COMPLETED';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Final State:';
  RAISE NOTICE '  • Match status: %', v_status;
  RAISE NOTICE '  • Cooldown active: %', v_cooldown_exists;
  RAISE NOTICE '  • Days until cooldown expires: %.1f', COALESCE(v_cooldown_days, 0);
  RAISE NOTICE '  • Total messages: %', v_message_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Expected Results:';
  RAISE NOTICE '  ✅ Emir sees match request from Alice';
  RAISE NOTICE '  ✅ Emir declines → status becomes declined';
  RAISE NOTICE '  ✅ Cooldown created (7 days)';
  RAISE NOTICE '  ✅ Alice receives decline notification';
  RAISE NOTICE '  ✅ Emir sees decline confirmation';
  RAISE NOTICE '  ✅ Match removed from active inbox';
  RAISE NOTICE '  ✅ New matches between Alice-Emir blocked for 7 days';
  RAISE NOTICE '';
  RAISE NOTICE 'To test cooldown expiration, run:';
  RAISE NOTICE '  UPDATE public.match_cooldowns';
  RAISE NOTICE '  SET cooldown_until = NOW() - INTERVAL ''1 day''';
  RAISE NOTICE '  WHERE (user_a_fid = 1111 AND user_b_fid = 543581);';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
