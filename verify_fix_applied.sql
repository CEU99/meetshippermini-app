-- ============================================================================
-- VERIFICATION SCRIPT: Check if Decline Fix is Applied
-- ============================================================================
-- Run this to confirm the fix was successfully applied
-- ============================================================================

DO $$
DECLARE
  index_exists BOOLEAN;
  function_correct BOOLEAN;
  trigger_exists BOOLEAN;
  duplicate_cooldowns INTEGER;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'VERIFICATION: Decline Fix Status';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';

  -- Check 1: Unique index exists
  SELECT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'match_cooldowns'
      AND indexname = 'uniq_cooldown_pair'
  ) INTO index_exists;

  IF index_exists THEN
    RAISE NOTICE '✅ Check 1: Unique index "uniq_cooldown_pair" exists';
  ELSE
    RAISE WARNING '❌ Check 1: Unique index "uniq_cooldown_pair" NOT FOUND!';
  END IF;

  -- Check 2: Function contains proper UPSERT logic
  SELECT pg_get_functiondef('public.add_match_cooldown()'::regprocedure)
    LIKE '%ON CONFLICT%LEAST%GREATEST%'
  INTO function_correct;

  IF function_correct THEN
    RAISE NOTICE '✅ Check 2: Function has proper UPSERT with normalized FIDs';
  ELSE
    RAISE WARNING '❌ Check 2: Function does NOT have proper UPSERT logic!';
  END IF;

  -- Check 3: Trigger is enabled
  SELECT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'match_declined_cooldown'
      AND tgrelid = 'public.matches'::regclass
      AND tgenabled = 'O'  -- O = enabled
  ) INTO trigger_exists;

  IF trigger_exists THEN
    RAISE NOTICE '✅ Check 3: Trigger "match_declined_cooldown" is enabled';
  ELSE
    RAISE WARNING '❌ Check 3: Trigger "match_declined_cooldown" NOT ENABLED!';
  END IF;

  -- Check 4: No duplicate cooldowns
  SELECT COUNT(*) INTO duplicate_cooldowns
  FROM (
    SELECT
      LEAST(user_a_fid, user_b_fid) as min_fid,
      GREATEST(user_a_fid, user_b_fid) as max_fid,
      COUNT(*) as cnt
    FROM match_cooldowns
    GROUP BY min_fid, max_fid
    HAVING COUNT(*) > 1
  ) duplicates;

  IF duplicate_cooldowns = 0 THEN
    RAISE NOTICE '✅ Check 4: No duplicate cooldowns found';
  ELSE
    RAISE WARNING '❌ Check 4: Found % duplicate cooldown pair(s)!', duplicate_cooldowns;
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

  -- Final verdict
  IF index_exists AND function_correct AND trigger_exists AND duplicate_cooldowns = 0 THEN
    RAISE NOTICE '🎉 ALL CHECKS PASSED - Decline fix is properly applied!';
    RAISE NOTICE '';
    RAISE NOTICE 'Your database is ready. The decline 500 error is FIXED.';
  ELSE
    RAISE WARNING '⚠ SOME CHECKS FAILED - Please review the errors above';
    RAISE NOTICE '';
    RAISE NOTICE 'You may need to re-run FIX_DECLINE_FINAL.sql';
  END IF;

  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
END $$;

-- Show some statistics
DO $$
DECLARE
  total_matches INTEGER;
  declined_matches INTEGER;
  total_cooldowns INTEGER;
  active_cooldowns INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_matches FROM matches;
  SELECT COUNT(*) INTO declined_matches FROM matches WHERE status = 'declined';
  SELECT COUNT(*) INTO total_cooldowns FROM match_cooldowns;
  SELECT COUNT(*) INTO active_cooldowns FROM match_cooldowns WHERE cooldown_until > NOW();

  RAISE NOTICE 'Current Database Statistics:';
  RAISE NOTICE '  Total matches: %', total_matches;
  RAISE NOTICE '  Declined matches: %', declined_matches;
  RAISE NOTICE '  Total cooldowns: %', total_cooldowns;
  RAISE NOTICE '  Active cooldowns: %', active_cooldowns;
  RAISE NOTICE '';
END $$;
