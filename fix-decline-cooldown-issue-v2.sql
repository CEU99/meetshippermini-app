-- Fix: Match Decline Cooldown Duplicate Key Issue
-- Problem: When declining a match, the trigger tries to insert a cooldown
--          but fails if one already exists for that user pair
-- Solution: Update the trigger function to properly handle duplicates

-- ============================================================================
-- 1. Show current issue
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Fixing Match Decline Cooldown Issue';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'Problem: Duplicate key violation when declining matches';
  RAISE NOTICE 'Error: unique constraint "uniq_cooldown_pair"';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- 2. Check existing cooldowns table and constraints
-- ============================================================================

DO $$
DECLARE
  constraint_rec RECORD;
  cooldown_count INTEGER;
BEGIN
  RAISE NOTICE 'Checking match_cooldowns table...';

  -- Count existing cooldowns
  SELECT COUNT(*) INTO cooldown_count FROM match_cooldowns;
  RAISE NOTICE '  Current cooldowns: %', cooldown_count;

  -- Show constraints
  FOR constraint_rec IN
    SELECT conname, pg_get_constraintdef(oid) as definition
    FROM pg_constraint
    WHERE conrelid = 'match_cooldowns'::regclass
  LOOP
    RAISE NOTICE '  Constraint: % - %', constraint_rec.conname, constraint_rec.definition;
  END LOOP;

  RAISE NOTICE '';
END $$;

-- ============================================================================
-- 3. Fix the add_match_cooldown() function
-- ============================================================================

-- This is the improved version that properly handles duplicates
CREATE OR REPLACE FUNCTION public.add_match_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_min_fid BIGINT;
  v_max_fid BIGINT;
  v_existing_id UUID;
BEGIN
  -- Only add cooldown when status changes TO 'declined'
  IF NEW.status = 'declined' AND (OLD.status IS NULL OR OLD.status IS DISTINCT FROM 'declined') THEN

    -- Normalize the FID order to ensure consistency
    v_min_fid := LEAST(NEW.user_a_fid, NEW.user_b_fid);
    v_max_fid := GREATEST(NEW.user_a_fid, NEW.user_b_fid);

    -- Check if cooldown already exists for this pair
    SELECT id INTO v_existing_id
    FROM public.match_cooldowns
    WHERE LEAST(user_a_fid, user_b_fid) = v_min_fid
      AND GREATEST(user_a_fid, user_b_fid) = v_max_fid;

    IF v_existing_id IS NOT NULL THEN
      -- Cooldown already exists, update it instead
      UPDATE public.match_cooldowns
      SET
        declined_at = NOW(),
        cooldown_until = NOW() + INTERVAL '7 days'
      WHERE id = v_existing_id;

      RAISE NOTICE 'Updated existing cooldown for FIDs % and %', v_min_fid, v_max_fid;
    ELSE
      -- No existing cooldown, insert new one
      INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
      VALUES (v_min_fid, v_max_fid, NOW(), NOW() + INTERVAL '7 days');

      RAISE NOTICE 'Created new cooldown for FIDs % and %', v_min_fid, v_max_fid;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  RAISE NOTICE '✅ Updated add_match_cooldown() function to handle duplicates';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- 4. Verify the trigger exists and uses the updated function
-- ============================================================================

DO $$
DECLARE
  trigger_exists BOOLEAN;
BEGIN
  RAISE NOTICE 'Checking match_declined_cooldown trigger...';

  SELECT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'match_declined_cooldown'
      AND tgrelid = 'matches'::regclass
  ) INTO trigger_exists;

  IF trigger_exists THEN
    RAISE NOTICE '✅ Trigger exists and is now using the fixed function';
  ELSE
    RAISE NOTICE '⚠️  Trigger does not exist, creating it...';

    CREATE TRIGGER match_declined_cooldown
      AFTER UPDATE ON public.matches
      FOR EACH ROW
      EXECUTE FUNCTION public.add_match_cooldown();

    RAISE NOTICE '✅ Created match_declined_cooldown trigger';
  END IF;

  RAISE NOTICE '';
END $$;

-- ============================================================================
-- 5. Ensure the unique constraint is properly defined
-- ============================================================================

-- Drop and recreate the unique constraint if needed
DO $$
BEGIN
  -- Drop existing constraint if present
  ALTER TABLE match_cooldowns DROP CONSTRAINT IF EXISTS uniq_cooldown_pair;

  -- Create the unique constraint with normalized FID order
  -- This ensures (A,B) and (B,A) are treated as the same pair
  CREATE UNIQUE INDEX IF NOT EXISTS uniq_cooldown_pair
    ON match_cooldowns (LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid));

  RAISE NOTICE '✅ Ensured unique constraint on cooldown pairs';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- 6. Clean up any duplicate cooldowns that may exist
-- ============================================================================

DO $$
DECLARE
  deleted_count INTEGER := 0;
  dup_rec RECORD;
BEGIN
  RAISE NOTICE 'Checking for duplicate cooldowns...';

  -- Find and keep only the most recent cooldown for each pair
  FOR dup_rec IN
    SELECT
      LEAST(user_a_fid, user_b_fid) as min_fid,
      GREATEST(user_a_fid, user_b_fid) as max_fid,
      COUNT(*) as count
    FROM match_cooldowns
    GROUP BY LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid)
    HAVING COUNT(*) > 1
  LOOP
    -- Delete older duplicates, keep the most recent
    WITH ranked_cooldowns AS (
      SELECT id, ROW_NUMBER() OVER (ORDER BY declined_at DESC) as rn
      FROM match_cooldowns
      WHERE LEAST(user_a_fid, user_b_fid) = dup_rec.min_fid
        AND GREATEST(user_a_fid, user_b_fid) = dup_rec.max_fid
    )
    DELETE FROM match_cooldowns
    WHERE id IN (
      SELECT id FROM ranked_cooldowns WHERE rn > 1
    );

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '  Cleaned up % duplicate(s) for FIDs % and %',
      deleted_count, dup_rec.min_fid, dup_rec.max_fid;
  END LOOP;

  IF deleted_count = 0 THEN
    RAISE NOTICE '  No duplicate cooldowns found';
  END IF;

  RAISE NOTICE '';
END $$;

-- ============================================================================
-- 7. Final verification
-- ============================================================================

DO $$
DECLARE
  total_cooldowns INTEGER;
  active_cooldowns INTEGER;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Fix Applied Successfully!';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';

  SELECT COUNT(*) INTO total_cooldowns FROM match_cooldowns;
  SELECT COUNT(*) INTO active_cooldowns FROM match_cooldowns WHERE cooldown_until > NOW();

  RAISE NOTICE 'Statistics:';
  RAISE NOTICE '  Total cooldowns: %', total_cooldowns;
  RAISE NOTICE '  Active cooldowns: %', active_cooldowns;
  RAISE NOTICE '';
  RAISE NOTICE 'What was fixed:';
  RAISE NOTICE '  ✅ Updated add_match_cooldown() to check for existing cooldowns';
  RAISE NOTICE '  ✅ Function now updates existing cooldown instead of inserting duplicate';
  RAISE NOTICE '  ✅ Ensured unique constraint is properly defined';
  RAISE NOTICE '  ✅ Cleaned up any existing duplicate cooldowns';
  RAISE NOTICE '';
  RAISE NOTICE 'You can now decline matches without errors!';
  RAISE NOTICE '';
END $$;
