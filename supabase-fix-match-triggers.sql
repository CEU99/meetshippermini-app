-- =====================================================================
-- FIX: Match Status Override & Cooldown Trigger Issue
-- =====================================================================
-- This migration fixes the issue where:
-- 1. update_match_status() overrides manual status changes to 'declined'/'cancelled'
-- 2. Cooldown triggers don't fire because status gets reset to 'accepted'
-- =====================================================================

-- =====================================================================
-- PART 1: Fix update_match_status() to respect manual status changes
-- =====================================================================

CREATE OR REPLACE FUNCTION public.update_match_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- CRITICAL FIX: Do NOT override if status is being explicitly set to declined/cancelled
  -- This allows manual updates to these statuses to persist
  IF NEW.status IN ('declined', 'cancelled') THEN
    -- Let the manual status change go through without modification
    RETURN NEW;
  END IF;

  -- Otherwise, apply automatic status logic based on acceptance flags

  -- When user A accepts
  IF NEW.a_accepted IS TRUE AND COALESCE(OLD.a_accepted, FALSE) IS FALSE THEN
    IF COALESCE(NEW.b_accepted, FALSE) IS TRUE THEN
      NEW.status := 'accepted';
    ELSE
      NEW.status := 'accepted_by_a';
    END IF;
  END IF;

  -- When user B accepts
  IF NEW.b_accepted IS TRUE AND COALESCE(OLD.b_accepted, FALSE) IS FALSE THEN
    IF COALESCE(NEW.a_accepted, FALSE) IS TRUE THEN
      NEW.status := 'accepted';
    ELSE
      NEW.status := 'accepted_by_b';
    END IF;
  END IF;

  -- When both have accepted (double-check to ensure consistency)
  IF COALESCE(NEW.a_accepted, FALSE) IS TRUE
     AND COALESCE(NEW.b_accepted, FALSE) IS TRUE
     AND NEW.status NOT IN ('declined', 'cancelled') THEN
    NEW.status := 'accepted';
  END IF;

  RETURN NEW;
END;
$$;

-- =====================================================================
-- PART 2: Unified cooldown function for both declined and cancelled
-- =====================================================================

CREATE OR REPLACE FUNCTION public.handle_match_decline()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Insert cooldown when match transitions TO 'declined' or 'cancelled'
  -- AND it wasn't already declined/cancelled
  IF NEW.status IN ('declined', 'cancelled')
     AND (OLD.status IS NULL OR OLD.status NOT IN ('declined', 'cancelled')) THEN

    -- Use INSERT ... ON CONFLICT to handle race conditions
    INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
    VALUES (
      NEW.user_a_fid,
      NEW.user_b_fid,
      NOW(),
      NOW() + INTERVAL '7 days'
    )
    ON CONFLICT (user_a_fid, user_b_fid)
    DO UPDATE SET
      declined_at = NOW(),
      cooldown_until = NOW() + INTERVAL '7 days';

  END IF;

  RETURN NEW;
END;
$$;

-- =====================================================================
-- PART 3: Separate function for cancel-specific logic (if needed)
-- =====================================================================

CREATE OR REPLACE FUNCTION public.add_cooldown_on_cancel()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Handle cancelled status specifically
  IF NEW.status = 'cancelled'
     AND (OLD.status IS NULL OR OLD.status <> 'cancelled') THEN

    -- Use INSERT ... ON CONFLICT to be idempotent
    INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
    VALUES (
      NEW.user_a_fid,
      NEW.user_b_fid,
      NOW(),
      NOW() + INTERVAL '7 days'
    )
    ON CONFLICT (user_a_fid, user_b_fid)
    DO UPDATE SET
      declined_at = NOW(),
      cooldown_until = NOW() + INTERVAL '7 days';

  END IF;

  RETURN NEW;
END;
$$;

-- =====================================================================
-- PART 4: Ensure match_cooldowns has proper unique constraint
-- =====================================================================

-- Add unique constraint if it doesn't exist (needed for ON CONFLICT)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'match_cooldowns_users_unique'
      AND conrelid = 'public.match_cooldowns'::regclass
  ) THEN
    -- Create unique constraint on both orderings
    ALTER TABLE public.match_cooldowns
      ADD CONSTRAINT match_cooldowns_users_unique
      UNIQUE (user_a_fid, user_b_fid);
  END IF;
END $$;

-- =====================================================================
-- PART 5: Drop and recreate triggers in correct order
-- =====================================================================

-- Drop all existing triggers on matches table related to status/cooldowns
DROP TRIGGER IF EXISTS check_match_acceptance ON public.matches;
DROP TRIGGER IF EXISTS match_declined_cooldown ON public.matches;
DROP TRIGGER IF EXISTS trg_match_decline ON public.matches;
DROP TRIGGER IF EXISTS trg_match_cancel ON public.matches;

-- BEFORE UPDATE: Handle automatic status transitions based on acceptance flags
-- This runs FIRST and will skip if status is being set to declined/cancelled
CREATE TRIGGER check_match_acceptance
  BEFORE UPDATE ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.update_match_status();

-- AFTER UPDATE: Handle cooldown creation for declined matches
-- This runs AFTER the row is updated, so NEW.status will be the final value
CREATE TRIGGER trg_match_decline
  AFTER UPDATE ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_match_decline();

-- AFTER UPDATE: Handle cooldown creation for cancelled matches
-- This ensures cancelled matches also trigger cooldowns
CREATE TRIGGER trg_match_cancel
  AFTER UPDATE ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.add_cooldown_on_cancel();

-- =====================================================================
-- PART 6: Verification & Testing Helpers
-- =====================================================================

-- Function to check if fix is working
CREATE OR REPLACE FUNCTION public.verify_trigger_fix()
RETURNS TABLE (
  trigger_name TEXT,
  trigger_timing TEXT,
  trigger_event TEXT,
  function_name TEXT
)
LANGUAGE sql
AS $$
  SELECT
    tgname::TEXT,
    CASE
      WHEN tgtype::INTEGER & 2 = 2 THEN 'BEFORE'
      WHEN tgtype::INTEGER & 1 = 1 THEN 'AFTER'
      ELSE 'UNKNOWN'
    END::TEXT,
    CASE
      WHEN tgtype::INTEGER & 16 = 16 THEN 'UPDATE'
      WHEN tgtype::INTEGER & 8 = 8 THEN 'INSERT'
      WHEN tgtype::INTEGER & 4 = 4 THEN 'DELETE'
      ELSE 'OTHER'
    END::TEXT,
    tgfoid::regprocedure::TEXT
  FROM pg_trigger
  WHERE tgrelid = 'public.matches'::regclass
    AND tgname NOT LIKE 'RI_%'  -- Exclude foreign key triggers
  ORDER BY
    CASE
      WHEN tgtype::INTEGER & 2 = 2 THEN 1  -- BEFORE triggers first
      ELSE 2  -- AFTER triggers second
    END,
    tgname;
$$;

-- =====================================================================
-- PART 7: Run verification
-- =====================================================================

-- Show the current trigger configuration
SELECT * FROM public.verify_trigger_fix();

COMMENT ON FUNCTION public.verify_trigger_fix() IS
  'Helper function to verify trigger order and configuration after applying the fix';

-- =====================================================================
-- Migration Complete
-- =====================================================================
-- To verify this fix works:
-- 1. Run: SELECT * FROM public.verify_trigger_fix();
-- 2. Test declining a match (see test script: test-match-trigger-fix.sql)
-- 3. Verify cooldown rows are created correctly
-- =====================================================================
