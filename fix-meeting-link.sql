-- =====================================================================
-- FIX: Regenerate Meeting Link for Emir ↔ Aysu16 Match
-- =====================================================================
-- Purpose: Remove invalid /mini/meeting/<id> link and trigger regeneration
-- Run this in: Supabase Dashboard → SQL Editor
-- =====================================================================

DO $$
DECLARE
  v_match_id UUID;
  v_old_link TEXT;
  v_status TEXT;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'FIX: Regenerate Meeting Link';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';

  -- Find the match
  SELECT id, meeting_link, status
  INTO v_match_id, v_old_link, v_status
  FROM public.matches
  WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
     OR (user_a_fid = 1394398 AND user_b_fid = 543581)
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_match_id IS NULL THEN
    RAISE NOTICE '❌ No match found between Emir (543581) and Aysu16 (1394398)';
    RETURN;
  END IF;

  RAISE NOTICE 'Match ID: %', v_match_id;
  RAISE NOTICE 'Current status: %', v_status;
  RAISE NOTICE 'Current meeting link: %', COALESCE(v_old_link, '(null)');
  RAISE NOTICE '';

  -- Check if link needs fixing
  IF v_old_link IS NULL THEN
    RAISE NOTICE '⚠️ No meeting link exists - will be generated on next API call';
  ELSIF v_old_link LIKE '%/mini/meeting/%' THEN
    RAISE NOTICE '🔧 Clearing invalid internal link...';

    -- Clear the bad meeting link
    UPDATE public.matches
    SET
      meeting_link = NULL,
      scheduled_at = NULL
    WHERE id = v_match_id;

    RAISE NOTICE '✓ Invalid link cleared';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps to regenerate link:';
    RAISE NOTICE '';
    RAISE NOTICE 'Option A - Via API (Recommended):';
    RAISE NOTICE '  1. Create test endpoint to regenerate:';
    RAISE NOTICE '     POST http://localhost:3000/api/matches/%/regenerate-link', v_match_id;
    RAISE NOTICE '';
    RAISE NOTICE 'Option B - Manual trigger:';
    RAISE NOTICE '  Call the scheduleMatch() function from meeting-service.ts';
    RAISE NOTICE '';
    RAISE NOTICE 'Option C - Re-accept (if match not fully accepted):';
    RAISE NOTICE '  Have one user accept again to trigger meeting generation';
  ELSE
    RAISE NOTICE '✓ Meeting link looks valid: %', v_old_link;
    RAISE NOTICE '   No fix needed - link should work';
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;

-- =====================================================================
-- OPTION: Manually Set a Fallback Link (Temporary Solution)
-- =====================================================================
-- Uncomment the block below if you want to set a temporary Google Meet link

/*
DO $$
DECLARE
  v_match_id UUID;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'Setting temporary Google Meet link...';

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
      meeting_link = 'https://meet.google.com/new',
      scheduled_at = NOW()
    WHERE id = v_match_id;

    RAISE NOTICE '✓ Temporary Google Meet link set';
    RAISE NOTICE '  Users can click "Join Meeting" to create a new room';
  END IF;

  RAISE NOTICE '';
END $$;
*/

-- =====================================================================
-- Verify the fix
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'Current match state:';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  id,
  status,
  a_accepted,
  b_accepted,
  meeting_link,
  scheduled_at,
  CASE
    WHEN meeting_link IS NULL THEN '⏳ Link will be generated'
    WHEN meeting_link LIKE '%/mini/meeting/%' THEN '❌ Still has bad link'
    WHEN meeting_link LIKE 'https://meet.google.com/%' THEN '✓ Google Meet'
    WHEN meeting_link LIKE '%whereby%' THEN '✓ Whereby'
    WHEN meeting_link LIKE '%huddle01%' THEN '✓ Huddle01'
    ELSE '✓ External link'
  END as link_status
FROM public.matches
WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
   OR (user_a_fid = 1394398 AND user_b_fid = 543581)
ORDER BY created_at DESC
LIMIT 1;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'FIX COMPLETE';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'If meeting_link is NULL, it will be regenerated when:';
  RAISE NOTICE '  • The respond API is called again';
  RAISE NOTICE '  • A manual regenerate endpoint is called';
  RAISE NOTICE '  • You run the manual trigger SQL above';
  RAISE NOTICE '';
  RAISE NOTICE 'The new link will use:';
  RAISE NOTICE '  1. Whereby (if WHEREBY_API_KEY is configured) ✓';
  RAISE NOTICE '  2. Huddle01 (if HUDDLE01_API_KEY is configured) ✓';
  RAISE NOTICE '  3. Google Meet (fallback)';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
