-- =====================================================================
-- TEST: Emir Accepts Match from Aysu16
-- =====================================================================
-- Purpose: Simulate Emir clicking "Accept" on the match
-- Run this in: Supabase Dashboard → SQL Editor
-- =====================================================================

DO $$
DECLARE
  v_match_id UUID;
  v_user_a_fid BIGINT;
  v_user_b_fid BIGINT;
  v_emir_fid BIGINT := 543581;
  v_aysu_fid BIGINT := 1394398;
  v_emir_is_a BOOLEAN;
  v_status TEXT;
  v_a_accepted BOOLEAN;
  v_b_accepted BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'TEST: Emir Accepts Match';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';

  -- Find the match
  SELECT id, user_a_fid, user_b_fid, status, a_accepted, b_accepted
  INTO v_match_id, v_user_a_fid, v_user_b_fid, v_status, v_a_accepted, v_b_accepted
  FROM public.matches
  WHERE (user_a_fid = v_emir_fid AND user_b_fid = v_aysu_fid)
     OR (user_a_fid = v_aysu_fid AND user_b_fid = v_emir_fid)
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_match_id IS NULL THEN
    RAISE NOTICE '❌ ERROR: No match found between Emir (543581) and Aysu16 (1394398)';
    RAISE NOTICE '';
    RAISE NOTICE 'Create a match first using:';
    RAISE NOTICE '  INSERT INTO matches (user_a_fid, user_b_fid, created_by_fid, status, created_by, rationale)';
    RAISE NOTICE '  VALUES (1394398, 543581, 1394398, ''proposed'', ''manual'',';
    RAISE NOTICE '          ''{"manualMatch": true, "score": 1.0}''::jsonb);';
    RETURN;
  END IF;

  RAISE NOTICE '✓ Match found:';
  RAISE NOTICE '  Match ID: %', v_match_id;
  RAISE NOTICE '  Current status: %', v_status;
  RAISE NOTICE '  User A (FID %): % (accepted: %)', v_user_a_fid,
               (SELECT username FROM users WHERE fid = v_user_a_fid), v_a_accepted;
  RAISE NOTICE '  User B (FID %): % (accepted: %)', v_user_b_fid,
               (SELECT username FROM users WHERE fid = v_user_b_fid), v_b_accepted;
  RAISE NOTICE '';

  -- Check if Emir already accepted
  v_emir_is_a := (v_user_a_fid = v_emir_fid);

  IF (v_emir_is_a AND v_a_accepted) OR (NOT v_emir_is_a AND v_b_accepted) THEN
    RAISE NOTICE '⚠️  Emir has already accepted this match';
    RETURN;
  END IF;

  -- Perform the accept action
  IF v_emir_is_a THEN
    RAISE NOTICE 'Updating: Emir (User A) accepts the match...';
    UPDATE public.matches
    SET a_accepted = true
    WHERE id = v_match_id;
  ELSE
    RAISE NOTICE 'Updating: Emir (User B) accepts the match...';
    UPDATE public.matches
    SET b_accepted = true
    WHERE id = v_match_id;
  END IF;

  RAISE NOTICE '✓ Update executed';
  RAISE NOTICE '';

  -- Fetch updated match
  SELECT status, a_accepted, b_accepted
  INTO v_status, v_a_accepted, v_b_accepted
  FROM public.matches
  WHERE id = v_match_id;

  RAISE NOTICE 'Updated match state:';
  RAISE NOTICE '  Status: %', v_status;
  RAISE NOTICE '  A accepted: %', v_a_accepted;
  RAISE NOTICE '  B accepted: %', v_b_accepted;
  RAISE NOTICE '';

  -- Check if both accepted
  IF v_a_accepted AND v_b_accepted THEN
    RAISE NOTICE '🎉 BOTH USERS ACCEPTED!';
    RAISE NOTICE '';

    IF v_status = 'accepted' THEN
      RAISE NOTICE '✓ Status automatically updated to "accepted" by trigger';
    ELSE
      RAISE NOTICE '⚠️  Status is still "%", should be "accepted"', v_status;
      RAISE NOTICE '   Check if update_match_status() trigger exists';
    END IF;

    -- Check if meeting link exists
    DECLARE
      v_meeting_link TEXT;
    BEGIN
      SELECT meeting_link INTO v_meeting_link
      FROM public.matches
      WHERE id = v_match_id;

      IF v_meeting_link IS NOT NULL THEN
        RAISE NOTICE '✓ Meeting link: %', v_meeting_link;
      ELSE
        RAISE NOTICE '⚠️  No meeting link generated yet';
        RAISE NOTICE '   API should generate this after both accept';
      END IF;
    END;
  ELSE
    RAISE NOTICE '⏳ Waiting for other party to accept';
    IF v_emir_is_a THEN
      RAISE NOTICE '   Aysu16 needs to accept';
    ELSE
      RAISE NOTICE '   Aysu16 has already accepted, waiting was on Emir';
    END IF;
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'TEST COMPLETE';
  RAISE NOTICE '=============================================================';
END $$;

-- Show the match in match_details view
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'Match in match_details view:';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  id,
  user_a_username,
  user_b_username,
  status,
  a_accepted,
  b_accepted,
  meeting_link,
  created_by,
  rationale->>'manualMatch' as is_manual_match
FROM public.match_details
WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
   OR (user_a_fid = 1394398 AND user_b_fid = 543581)
ORDER BY created_at DESC
LIMIT 1;
