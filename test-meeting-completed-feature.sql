-- =====================================================================
-- TEST: Meeting Completed Feature (Emir ↔ Aysu16)
-- =====================================================================
-- Purpose: Test the complete flow of marking a meeting as completed
-- Run this in: Supabase Dashboard → SQL Editor
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'TEST: Meeting Completed Feature';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Testing with:';
  RAISE NOTICE '  • Emir (@cengizhaneu) - FID: 543581';
  RAISE NOTICE '  • Aysu16 (@aysu16) - FID: 1394398';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;

-- =====================================================================
-- TEST 1: Verify Schema Installation
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 1: Verify Schema Installation';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

-- Check completion columns exist
SELECT
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'matches'
  AND column_name IN ('a_completed', 'b_completed', 'completed_at')
ORDER BY column_name;

-- Check trigger exists
SELECT
  trigger_name,
  event_manipulation,
  action_timing
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'matches'
  AND trigger_name = 'check_match_completion';

-- =====================================================================
-- TEST 2: Find Existing Match
-- =====================================================================

DO $$
DECLARE
  v_match_id UUID;
  v_status TEXT;
  v_a_accepted BOOLEAN;
  v_b_accepted BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 2: Find Existing Match';
  RAISE NOTICE '-------------------------------------------------------------';

  SELECT id, status, a_accepted, b_accepted
  INTO v_match_id, v_status, v_a_accepted, v_b_accepted
  FROM public.matches
  WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
     OR (user_a_fid = 1394398 AND user_b_fid = 543581)
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_match_id IS NULL THEN
    RAISE NOTICE '⚠️  No existing match found';
    RAISE NOTICE 'Creating test match...';
  ELSE
    RAISE NOTICE '✓ Found match: %', v_match_id;
    RAISE NOTICE '  Status: %', v_status;
    RAISE NOTICE '  User A accepted: %', v_a_accepted;
    RAISE NOTICE '  User B accepted: %', v_b_accepted;
  END IF;
END $$;

-- Show current match state
SELECT
  id,
  user_a_fid,
  user_b_fid,
  status,
  a_accepted,
  b_accepted,
  a_completed,
  b_completed,
  meeting_link IS NOT NULL as has_meeting_link,
  completed_at,
  created_at
FROM public.matches
WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
   OR (user_a_fid = 1394398 AND user_b_fid = 543581)
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================================
-- TEST 3: Simulate User A Marks as Completed
-- =====================================================================

DO $$
DECLARE
  v_match_id UUID;
  v_user_a_fid BIGINT;
  v_emir_is_a BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 3: Emir Marks Meeting as Completed';
  RAISE NOTICE '-------------------------------------------------------------';

  SELECT id, user_a_fid
  INTO v_match_id, v_user_a_fid
  FROM public.matches
  WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
     OR (user_a_fid = 1394398 AND user_b_fid = 543581)
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_match_id IS NULL THEN
    RAISE NOTICE '❌ No match found to test with';
    RETURN;
  END IF;

  v_emir_is_a := (v_user_a_fid = 543581);

  IF v_emir_is_a THEN
    RAISE NOTICE 'Emir is User A - updating a_completed...';
    UPDATE public.matches
    SET a_completed = true
    WHERE id = v_match_id;
  ELSE
    RAISE NOTICE 'Emir is User B - updating b_completed...';
    UPDATE public.matches
    SET b_completed = true
    WHERE id = v_match_id;
  END IF;

  RAISE NOTICE '✓ Update executed';
END $$;

-- Show state after User A marks as completed
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'State after Emir marks as completed:';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  id,
  status,
  a_completed,
  b_completed,
  completed_at IS NOT NULL as has_completed_at,
  CASE
    WHEN status = 'completed' THEN '✓ Status is completed'
    WHEN a_completed AND b_completed THEN '⚠️ Both completed but status not updated'
    WHEN a_completed OR b_completed THEN '⏳ Waiting for other party'
    ELSE '❌ No one marked as completed'
  END as completion_status
FROM public.matches
WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
   OR (user_a_fid = 1394398 AND user_b_fid = 543581)
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================================
-- TEST 4: Simulate User B Marks as Completed
-- =====================================================================

DO $$
DECLARE
  v_match_id UUID;
  v_user_a_fid BIGINT;
  v_emir_is_a BOOLEAN;
  v_aysu_is_b BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 4: Aysu16 Marks Meeting as Completed';
  RAISE NOTICE '-------------------------------------------------------------';

  SELECT id, user_a_fid
  INTO v_match_id, v_user_a_fid
  FROM public.matches
  WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
     OR (user_a_fid = 1394398 AND user_b_fid = 543581)
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_match_id IS NULL THEN
    RAISE NOTICE '❌ No match found to test with';
    RETURN;
  END IF;

  v_emir_is_a := (v_user_a_fid = 543581);
  v_aysu_is_b := NOT v_emir_is_a;

  IF v_aysu_is_b THEN
    -- Aysu is User A in this case
    RAISE NOTICE 'Aysu is User A - updating a_completed...';
    UPDATE public.matches
    SET a_completed = true
    WHERE id = v_match_id;
  ELSE
    -- Aysu is User B
    RAISE NOTICE 'Aysu is User B - updating b_completed...';
    UPDATE public.matches
    SET b_completed = true
    WHERE id = v_match_id;
  END IF;

  RAISE NOTICE '✓ Update executed';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️ Trigger should now set status to completed automatically';
END $$;

-- Show final state after both mark as completed
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'Final state after both mark as completed:';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  id,
  status,
  a_completed,
  b_completed,
  completed_at,
  CASE
    WHEN status = 'completed' AND a_completed AND b_completed THEN '✅ SUCCESS: Match completed correctly'
    WHEN status = 'completed' AND (NOT a_completed OR NOT b_completed) THEN '⚠️ Status is completed but flags not set'
    WHEN status != 'completed' AND a_completed AND b_completed THEN '❌ FAIL: Both completed but status not updated (trigger issue?)'
    ELSE '⏳ Partial completion'
  END as test_result
FROM public.matches
WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
   OR (user_a_fid = 1394398 AND user_b_fid = 543581)
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================================
-- TEST 5: Verify match_details View
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 5: Verify match_details View';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  id,
  user_a_username,
  user_b_username,
  status,
  a_completed,
  b_completed,
  completed_at,
  meeting_link
FROM public.match_details
WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
   OR (user_a_fid = 1394398 AND user_b_fid = 543581)
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================================
-- TEST 6: Test Completion Query (for Completed Tab)
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'TEST 6: Query Completed Matches (for UI)';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

-- This simulates what the frontend /api/matches?scope=completed will return
SELECT
  id,
  user_a_username,
  user_b_username,
  status,
  completed_at,
  created_at
FROM public.match_details
WHERE status = 'completed'
  AND (user_a_fid = 543581 OR user_b_fid = 543581 OR user_a_fid = 1394398 OR user_b_fid = 1394398)
ORDER BY completed_at DESC;

-- =====================================================================
-- RESET (Optional - Uncomment to reset test state)
-- =====================================================================

/*
DO $$
DECLARE
  v_match_id UUID;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'RESET: Resetting test match to accepted state';
  RAISE NOTICE '-------------------------------------------------------------';

  SELECT id
  INTO v_match_id
  FROM public.matches
  WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
     OR (user_a_fid = 1394398 AND user_b_fid = 543581)
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_match_id IS NOT NULL THEN
    UPDATE public.matches
    SET
      status = 'accepted',
      a_completed = FALSE,
      b_completed = FALSE,
      completed_at = NULL
    WHERE id = v_match_id;

    RAISE NOTICE '✓ Match reset to accepted state';
    RAISE NOTICE '  Match ID: %', v_match_id;
  ELSE
    RAISE NOTICE '⚠️ No match found to reset';
  END IF;
END $$;
*/

-- =====================================================================
-- SUMMARY
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'TEST COMPLETE';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Verification checklist:';
  RAISE NOTICE '  1. Schema has a_completed, b_completed columns';
  RAISE NOTICE '  2. Trigger check_match_completion exists';
  RAISE NOTICE '  3. Match status transitions to completed';
  RAISE NOTICE '  4. completed_at timestamp set automatically';
  RAISE NOTICE '  5. match_details view includes completion fields';
  RAISE NOTICE '  6. Can query completed matches for UI';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps - Test in UI:';
  RAISE NOTICE '  1. Login as Emir: http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu';
  RAISE NOTICE '  2. Go to inbox: http://localhost:3000/mini/inbox';
  RAISE NOTICE '  3. Click "Meeting Completed" button';
  RAISE NOTICE '  4. Login as Aysu16: http://localhost:3000/api/dev/login?fid=1394398&username=aysu16';
  RAISE NOTICE '  5. Click "Meeting Completed" button';
  RAISE NOTICE '  6. Verify match appears in Completed tab';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
