-- =====================================================================
-- DIAGNOSTIC: Meeting Link Issue (Emir ↔ Aysu16)
-- =====================================================================
-- Purpose: Diagnose why "Join Meeting" button shows 404
-- Issue: meeting_link contains /mini/meeting/<id> instead of real URL
-- Run this in: Supabase Dashboard → SQL Editor
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'DIAGNOSTIC: Meeting Link Issue';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Testing match between:';
  RAISE NOTICE '  • Emir (@cengizhaneu) - FID: 543581';
  RAISE NOTICE '  • Aysu16 (@aysu16) - FID: 1394398';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;

-- =====================================================================
-- CHECK 1: Verify Match Exists and Both Accepted
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 1: Match Status';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  m.id,
  m.status,
  m.a_accepted,
  m.b_accepted,
  m.meeting_link,
  m.scheduled_at,
  m.created_at,
  CASE
    WHEN m.meeting_link IS NULL THEN '❌ No meeting link'
    WHEN m.meeting_link LIKE '%/mini/meeting/%' THEN '⚠️ Internal link (404 expected)'
    WHEN m.meeting_link LIKE 'https://meet.google.com/%' THEN '✓ Google Meet link'
    WHEN m.meeting_link LIKE 'https://%.whereby.%' THEN '✓ Whereby link'
    WHEN m.meeting_link LIKE 'https://%.huddle01.%' THEN '✓ Huddle01 link'
    ELSE '? Unknown link type'
  END as link_status
FROM public.matches m
WHERE (m.user_a_fid = 543581 AND m.user_b_fid = 1394398)
   OR (m.user_a_fid = 1394398 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 5;

-- =====================================================================
-- CHECK 2: Verify Both Users Accepted
-- =====================================================================

DO $$
DECLARE
  v_match_id UUID;
  v_status TEXT;
  v_a_accepted BOOLEAN;
  v_b_accepted BOOLEAN;
  v_meeting_link TEXT;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 2: Acceptance Status';
  RAISE NOTICE '-------------------------------------------------------------';

  SELECT id, status, a_accepted, b_accepted, meeting_link
  INTO v_match_id, v_status, v_a_accepted, v_b_accepted, v_meeting_link
  FROM public.matches
  WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
     OR (user_a_fid = 1394398 AND user_b_fid = 543581)
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_match_id IS NULL THEN
    RAISE NOTICE '❌ No match found between Emir and Aysu16';
    RETURN;
  END IF;

  RAISE NOTICE 'Match ID: %', v_match_id;
  RAISE NOTICE 'Status: %', v_status;
  RAISE NOTICE 'User A accepted: %', v_a_accepted;
  RAISE NOTICE 'User B accepted: %', v_b_accepted;
  RAISE NOTICE 'Meeting link: %', COALESCE(v_meeting_link, '(null)');
  RAISE NOTICE '';

  IF v_a_accepted AND v_b_accepted THEN
    RAISE NOTICE '✓ Both users have accepted';
    IF v_status = 'accepted' THEN
      RAISE NOTICE '✓ Status is "accepted"';
    ELSE
      RAISE NOTICE '⚠️ Status is "%", should be "accepted"', v_status;
    END IF;

    IF v_meeting_link IS NULL THEN
      RAISE NOTICE '❌ PROBLEM: No meeting link generated!';
      RAISE NOTICE '   → Backend scheduleMatch() may have failed';
      RAISE NOTICE '   → Check API logs for errors';
    ELSIF v_meeting_link LIKE '%/mini/meeting/%' THEN
      RAISE NOTICE '❌ PROBLEM: Meeting link points to internal route';
      RAISE NOTICE '   → Link: %', v_meeting_link;
      RAISE NOTICE '   → This route does not exist (404 error)';
      RAISE NOTICE '   → Need to regenerate with real API (Whereby/Huddle01)';
    ELSE
      RAISE NOTICE '✓ Meeting link looks valid: %', v_meeting_link;
    END IF;
  ELSE
    RAISE NOTICE '⚠️ Not both users have accepted yet';
    RAISE NOTICE '   User A accepted: %', v_a_accepted;
    RAISE NOTICE '   User B accepted: %', v_b_accepted;
  END IF;
END $$;

-- =====================================================================
-- CHECK 3: Check System Messages
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 3: System Messages';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  msg.id,
  msg.content,
  msg.is_system_message,
  msg.created_at,
  u.username as sender_username
FROM public.messages msg
LEFT JOIN public.users u ON msg.sender_fid = u.fid
WHERE msg.match_id IN (
  SELECT id FROM public.matches
  WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
     OR (user_a_fid = 1394398 AND user_b_fid = 543581)
)
ORDER BY msg.created_at DESC
LIMIT 10;

-- =====================================================================
-- CHECK 4: Verify match_details View
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 4: match_details View';
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
  scheduled_at,
  created_by
FROM public.match_details
WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
   OR (user_a_fid = 1394398 AND user_b_fid = 543581)
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================================
-- SUMMARY & RECOMMENDATIONS
-- =====================================================================

DO $$
DECLARE
  v_match_id UUID;
  v_meeting_link TEXT;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'DIAGNOSTIC SUMMARY';
  RAISE NOTICE '=============================================================';

  SELECT id, meeting_link
  INTO v_match_id, v_meeting_link
  FROM public.matches
  WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
     OR (user_a_fid = 1394398 AND user_b_fid = 543581)
  ORDER BY created_at DESC
  LIMIT 1;

  RAISE NOTICE '';
  RAISE NOTICE 'Issue Identified:';

  IF v_meeting_link IS NULL THEN
    RAISE NOTICE '  ❌ No meeting link generated';
    RAISE NOTICE '';
    RAISE NOTICE 'Solution:';
    RAISE NOTICE '  1. Backend fix: Update meeting-service.ts to use real APIs';
    RAISE NOTICE '  2. Re-accept the match OR run fix-meeting-link.sql';
  ELSIF v_meeting_link LIKE '%/mini/meeting/%' THEN
    RAISE NOTICE '  ❌ Meeting link points to non-existent internal route';
    RAISE NOTICE '  Current link: %', v_meeting_link;
    RAISE NOTICE '';
    RAISE NOTICE 'Solution:';
    RAISE NOTICE '  1. Backend fix: Update meeting-service.ts (✓ Already fixed)';
    RAISE NOTICE '  2. Regenerate link: Run fix-meeting-link.sql';
    RAISE NOTICE '  3. Or: Both users decline and re-accept the match';
  ELSE
    RAISE NOTICE '  ✓ Meeting link looks valid';
    RAISE NOTICE '  Link: %', v_meeting_link;
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '  1. Run: fix-meeting-link.sql (to update existing match)';
  RAISE NOTICE '  2. Test: Visit /mini/inbox and click "Join Meeting"';
  RAISE NOTICE '  3. Verify: Link opens external meeting provider';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
