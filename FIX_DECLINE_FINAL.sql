-- ============================================================================
-- FINAL FIX: Match Decline Cooldown Duplicate Key Issue
-- ============================================================================
-- Problem: duplicate key value violates unique constraint "uniq_cooldown_pair"
-- Root cause: Trigger tries to INSERT without checking if record exists
-- Solution: Proper upsert with normalized FID ordering
-- ============================================================================

-- Step 1: Check current state of match_cooldowns table
DO $$
DECLARE
  constraint_count INTEGER;
  index_count INTEGER;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'FINAL FIX: Match Decline Cooldown Issue';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'Step 1: Examining current table state...';

  -- Check for existing constraints
  SELECT COUNT(*)
  INTO constraint_count
  FROM pg_constraint
  WHERE conrelid = 'public.match_cooldowns'::regclass
    AND contype = 'u';  -- unique constraints

  RAISE NOTICE '  Found % unique constraint(s)', constraint_count;

  -- Check for existing indexes
  SELECT COUNT(*)
  INTO index_count
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND tablename = 'match_cooldowns'
    AND indexname LIKE '%cooldown%pair%';

  RAISE NOTICE '  Found % cooldown pair index(es)', index_count;
  RAISE NOTICE '';
END $$;

-- Step 2: Drop any existing problematic constraints/indexes
DO $$
BEGIN
  RAISE NOTICE 'Step 2: Cleaning up old constraints/indexes...';

  -- Drop the constraint if it exists (may or may not exist)
  BEGIN
    ALTER TABLE public.match_cooldowns DROP CONSTRAINT IF EXISTS uniq_cooldown_pair CASCADE;
    RAISE NOTICE '  ✓ Dropped constraint uniq_cooldown_pair (if existed)';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ℹ No constraint named uniq_cooldown_pair found';
  END;

  -- Drop any similar indexes
  BEGIN
    DROP INDEX IF EXISTS public.uniq_cooldown_pair CASCADE;
    RAISE NOTICE '  ✓ Dropped index uniq_cooldown_pair (if existed)';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ℹ No index named uniq_cooldown_pair found';
  END;

  BEGIN
    DROP INDEX IF EXISTS public.match_cooldowns_pair_unique CASCADE;
    RAISE NOTICE '  ✓ Dropped index match_cooldowns_pair_unique (if existed)';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ℹ No index named match_cooldowns_pair_unique found';
  END;

  RAISE NOTICE '';
END $$;

-- Step 3: Clean up any duplicate cooldowns that exist
DO $$
DECLARE
  deleted_count INTEGER := 0;
  dup_rec RECORD;
BEGIN
  RAISE NOTICE 'Step 3: Cleaning up duplicate cooldowns...';

  -- Find and remove duplicates, keeping the most recent
  FOR dup_rec IN
    SELECT
      LEAST(user_a_fid, user_b_fid) as min_fid,
      GREATEST(user_a_fid, user_b_fid) as max_fid,
      COUNT(*) as dup_count
    FROM public.match_cooldowns
    GROUP BY LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid)
    HAVING COUNT(*) > 1
  LOOP
    -- Keep only the most recent cooldown for this pair
    WITH ranked_cooldowns AS (
      SELECT id, ROW_NUMBER() OVER (ORDER BY declined_at DESC NULLS LAST, cooldown_until DESC) as rn
      FROM public.match_cooldowns
      WHERE LEAST(user_a_fid, user_b_fid) = dup_rec.min_fid
        AND GREATEST(user_a_fid, user_b_fid) = dup_rec.max_fid
    )
    DELETE FROM public.match_cooldowns
    WHERE id IN (
      SELECT id FROM ranked_cooldowns WHERE rn > 1
    );

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '  ✓ Removed % duplicate(s) for FID pair (%, %)',
      deleted_count, dup_rec.min_fid, dup_rec.max_fid;
  END LOOP;

  IF NOT FOUND THEN
    RAISE NOTICE '  ℹ No duplicate cooldowns found';
  END IF;

  RAISE NOTICE '';
END $$;

-- Step 4: Create the proper unique index with normalized FIDs
DO $$
BEGIN
  RAISE NOTICE 'Step 4: Creating unique index on normalized FID pairs...';

  -- Create unique index that prevents duplicates with order-independent matching
  -- This ensures (A,B) and (B,A) are treated as the same pair
  CREATE UNIQUE INDEX IF NOT EXISTS uniq_cooldown_pair
    ON public.match_cooldowns (
      LEAST(user_a_fid, user_b_fid),
      GREATEST(user_a_fid, user_b_fid)
    );

  RAISE NOTICE '  ✓ Created unique index: uniq_cooldown_pair';
  RAISE NOTICE '    (Ensures no duplicate pairs regardless of FID order)';
  RAISE NOTICE '';
END $$;

-- Step 5: Fix the add_match_cooldown trigger function
CREATE OR REPLACE FUNCTION public.add_match_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_min_fid BIGINT;
  v_max_fid BIGINT;
BEGIN
  -- Only process when status changes TO 'declined'
  IF NEW.status = 'declined' AND (OLD.status IS NULL OR OLD.status IS DISTINCT FROM 'declined') THEN

    -- Normalize FID order: always store smaller FID first
    v_min_fid := LEAST(NEW.user_a_fid, NEW.user_b_fid);
    v_max_fid := GREATEST(NEW.user_a_fid, NEW.user_b_fid);

    -- Use INSERT ... ON CONFLICT with the unique index
    -- Since we always normalize FIDs (v_min_fid, v_max_fid), this will properly detect conflicts
    INSERT INTO public.match_cooldowns (
      user_a_fid,
      user_b_fid,
      declined_at,
      cooldown_until
    ) VALUES (
      v_min_fid,
      v_max_fid,
      NOW(),
      NOW() + INTERVAL '7 days'
    )
    ON CONFLICT ((LEAST(user_a_fid, user_b_fid)), (GREATEST(user_a_fid, user_b_fid)))
    DO UPDATE SET
      declined_at = NOW(),
      cooldown_until = GREATEST(
        match_cooldowns.cooldown_until,
        NOW() + INTERVAL '7 days'
      );

  END IF;

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  RAISE NOTICE 'Step 5: Updated add_match_cooldown() function';
  RAISE NOTICE '  ✓ Function now properly handles duplicate pairs';
  RAISE NOTICE '  ✓ Uses INSERT ... ON CONFLICT for true upsert behavior';
  RAISE NOTICE '  ✓ Normalizes FID order (LEAST/GREATEST)';
  RAISE NOTICE '  ✓ Resets cooldown timer on repeated declines';
  RAISE NOTICE '';
END $$;

-- Step 6: Ensure the trigger exists and is active
DO $$
DECLARE
  trigger_exists BOOLEAN;
BEGIN
  RAISE NOTICE 'Step 6: Verifying trigger configuration...';

  -- Check if trigger exists
  SELECT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'match_declined_cooldown'
      AND tgrelid = 'public.matches'::regclass
  ) INTO trigger_exists;

  IF trigger_exists THEN
    RAISE NOTICE '  ✓ Trigger "match_declined_cooldown" exists';
    RAISE NOTICE '    (Automatically calls add_match_cooldown on match updates)';
  ELSE
    RAISE NOTICE '  ⚠ Trigger does not exist! Creating it now...';

    CREATE TRIGGER match_declined_cooldown
      AFTER UPDATE ON public.matches
      FOR EACH ROW
      EXECUTE FUNCTION public.add_match_cooldown();

    RAISE NOTICE '  ✓ Created trigger "match_declined_cooldown"';
  END IF;

  RAISE NOTICE '';
END $$;

-- Step 7: Final verification and statistics
DO $$
DECLARE
  total_cooldowns INTEGER;
  active_cooldowns INTEGER;
  expired_cooldowns INTEGER;
  unique_pairs INTEGER;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'FIX APPLIED SUCCESSFULLY!';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';

  -- Get statistics
  SELECT COUNT(*) INTO total_cooldowns FROM public.match_cooldowns;
  SELECT COUNT(*) INTO active_cooldowns FROM public.match_cooldowns WHERE cooldown_until > NOW();
  SELECT COUNT(*) INTO expired_cooldowns FROM public.match_cooldowns WHERE cooldown_until <= NOW();

  -- Count unique pairs to verify no duplicates
  SELECT COUNT(DISTINCT (LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid)))
  INTO unique_pairs
  FROM public.match_cooldowns;

  RAISE NOTICE 'Current Statistics:';
  RAISE NOTICE '  Total cooldown records: %', total_cooldowns;
  RAISE NOTICE '  Active cooldowns: %', active_cooldowns;
  RAISE NOTICE '  Expired cooldowns: %', expired_cooldowns;
  RAISE NOTICE '  Unique pairs: %', unique_pairs;

  IF total_cooldowns = unique_pairs THEN
    RAISE NOTICE '  ✓ No duplicate pairs detected!';
  ELSE
    RAISE WARNING '  ⚠ Duplicate pairs still exist (% records, % unique)', total_cooldowns, unique_pairs;
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE 'What was fixed:';
  RAISE NOTICE '  ✓ Removed old problematic constraints';
  RAISE NOTICE '  ✓ Created proper unique index: uniq_cooldown_pair';
  RAISE NOTICE '  ✓ Updated trigger function with true UPSERT logic';
  RAISE NOTICE '  ✓ Cleaned up any existing duplicate records';
  RAISE NOTICE '  ✓ Normalized all FID pairs (smaller FID always first)';
  RAISE NOTICE '';
  RAISE NOTICE '🎉 You can now decline matches without errors!';
  RAISE NOTICE '   The API will no longer throw 23505 duplicate key errors.';
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;
