-- =====================================================================
-- FEATURE: Meeting Completed Button & Completed Meetings Section
-- =====================================================================
-- Purpose: Add completion tracking for accepted matches
-- Features:
--   1. a_completed & b_completed flags
--   2. 'completed' status
--   3. Auto-transition when both users mark completed
--   4. Trigger to handle completion logic
-- Run this in: Supabase Dashboard → SQL Editor
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'FEATURE: Meeting Completed Implementation';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'This adds:';
  RAISE NOTICE '  • a_completed & b_completed columns';
  RAISE NOTICE '  • completed status support';
  RAISE NOTICE '  • Auto-transition trigger';
  RAISE NOTICE '  • Updated match_details view';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;

-- =====================================================================
-- STEP 1: Add Completion Columns to matches Table
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 1: Adding completion columns...';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

-- Add completion tracking columns
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS a_completed BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS b_completed BOOLEAN DEFAULT FALSE;

-- Add comment for documentation
COMMENT ON COLUMN public.matches.a_completed IS 'User A has marked the meeting as completed';
COMMENT ON COLUMN public.matches.b_completed IS 'User B has marked the meeting as completed';

-- =====================================================================
-- STEP 2: Update Status Constraint (Add 'completed')
-- =====================================================================

DO $$
DECLARE
  chk_name text;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 2: Updating status constraint...';
  RAISE NOTICE '-------------------------------------------------------------';

  -- Find and drop existing status constraint
  SELECT conname
  INTO chk_name
  FROM pg_constraint
  WHERE conrelid = 'public.matches'::regclass
    AND contype = 'c'
    AND conname LIKE '%status%';

  IF chk_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.matches DROP CONSTRAINT %I;', chk_name);
    RAISE NOTICE '✓ Dropped old constraint: %', chk_name;
  END IF;

  -- Add new constraint with 'completed' status
  ALTER TABLE public.matches
    ADD CONSTRAINT matches_status_check
    CHECK (status IN (
      'proposed',
      'accepted_by_a',
      'accepted_by_b',
      'accepted',
      'declined',
      'cancelled',
      'completed',
      'pending'
    ));

  RAISE NOTICE '✓ Added new status constraint with completed';
END $$;

-- =====================================================================
-- STEP 3: Create Trigger Function for Auto-Completion
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 3: Creating completion trigger function...';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

-- Function to automatically update status to 'completed' when both users complete
CREATE OR REPLACE FUNCTION public.update_match_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- If both users marked as completed, update status
  IF NEW.a_completed = TRUE AND NEW.b_completed = TRUE AND NEW.status = 'accepted' THEN
    NEW.status = 'completed';
    NEW.completed_at = NOW();

    RAISE NOTICE '[Trigger] Match % marked as completed by both users', NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS check_match_completion ON public.matches;

-- Create trigger to run before UPDATE
CREATE TRIGGER check_match_completion
  BEFORE UPDATE ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.update_match_completion();

COMMENT ON FUNCTION public.update_match_completion() IS 'Automatically sets status to completed when both users mark meeting as complete';

-- =====================================================================
-- STEP 4: Update match_details View
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 4: Updating match_details view...';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

-- Drop and recreate view with completion fields
DROP VIEW IF EXISTS public.match_details CASCADE;

CREATE VIEW public.match_details AS
SELECT
    m.id,
    m.user_a_fid,
    ua.username as user_a_username,
    ua.display_name as user_a_display_name,
    ua.avatar_url as user_a_avatar_url,
    COALESCE(ua.traits, '[]'::jsonb) as user_a_traits,
    m.user_b_fid,
    ub.username as user_b_username,
    ub.display_name as user_b_display_name,
    ub.avatar_url as user_b_avatar_url,
    COALESCE(ub.traits, '[]'::jsonb) as user_b_traits,
    m.created_by_fid,
    m.created_by,
    uc.username as creator_username,
    uc.display_name as creator_display_name,
    uc.avatar_url as creator_avatar_url,
    m.status,
    m.message,
    m.rationale,
    m.a_accepted,
    m.b_accepted,
    m.a_completed,
    m.b_completed,
    m.meeting_link,
    m.scheduled_at,
    m.completed_at,
    m.created_at,
    m.updated_at
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
LEFT JOIN public.users uc ON m.created_by_fid = uc.fid;

-- Grant access
GRANT SELECT ON public.match_details TO anon, authenticated;

COMMENT ON VIEW public.match_details IS 'Enriched match data with user information, traits, and completion status';

-- =====================================================================
-- STEP 5: Create Index for Completed Matches
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 5: Creating indexes...';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

-- Index for querying completed matches
CREATE INDEX IF NOT EXISTS idx_matches_completed ON public.matches(status) WHERE status = 'completed';

-- Index for completion flags
CREATE INDEX IF NOT EXISTS idx_matches_a_completed ON public.matches(a_completed);
CREATE INDEX IF NOT EXISTS idx_matches_b_completed ON public.matches(b_completed);

-- =====================================================================
-- STEP 6: Verify Installation
-- =====================================================================

DO $$
DECLARE
  col_count INTEGER;
  has_trigger BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 6: Verifying installation...';
  RAISE NOTICE '-------------------------------------------------------------';

  -- Check columns exist
  SELECT COUNT(*)
  INTO col_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'matches'
    AND column_name IN ('a_completed', 'b_completed');

  IF col_count = 2 THEN
    RAISE NOTICE '✓ Completion columns added';
  ELSE
    RAISE WARNING '⚠ Missing completion columns! Found % of 2', col_count;
  END IF;

  -- Check trigger exists
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.triggers
    WHERE event_object_table = 'matches'
      AND trigger_name = 'check_match_completion'
  ) INTO has_trigger;

  IF has_trigger THEN
    RAISE NOTICE '✓ Completion trigger installed';
  ELSE
    RAISE WARNING '⚠ Completion trigger missing!';
  END IF;

  -- Check view has completion columns
  SELECT COUNT(*)
  INTO col_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'match_details'
    AND column_name IN ('a_completed', 'b_completed');

  IF col_count = 2 THEN
    RAISE NOTICE '✓ View includes completion fields';
  ELSE
    RAISE WARNING '⚠ View missing completion fields! Found % of 2', col_count;
  END IF;

END $$;

-- =====================================================================
-- STEP 7: Show Current Schema
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 7: Current matches table schema';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'matches'
  AND column_name IN ('status', 'a_accepted', 'b_accepted', 'a_completed', 'b_completed', 'completed_at')
ORDER BY ordinal_position;

-- =====================================================================
-- SUCCESS MESSAGE
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '✅ MEETING COMPLETED FEATURE INSTALLED SUCCESSFULLY!';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Database changes:';
  RAISE NOTICE '  ✓ Added a_completed column (BOOLEAN)';
  RAISE NOTICE '  ✓ Added b_completed column (BOOLEAN)';
  RAISE NOTICE '  ✓ Updated status constraint to include completed';
  RAISE NOTICE '  ✓ Created update_match_completion() trigger function';
  RAISE NOTICE '  ✓ Created check_match_completion trigger';
  RAISE NOTICE '  ✓ Updated match_details view';
  RAISE NOTICE '  ✓ Created performance indexes';
  RAISE NOTICE '';
  RAISE NOTICE 'How it works:';
  RAISE NOTICE '  1. User A clicks "Meeting Completed" → a_completed = true';
  RAISE NOTICE '  2. User B clicks "Meeting Completed" → b_completed = true';
  RAISE NOTICE '  3. Trigger detects both true → status = completed';
  RAISE NOTICE '  4. completed_at timestamp set automatically';
  RAISE NOTICE '  5. Match moves from Accepted to Completed tab';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '  1. Update API: Add /api/matches/:id/complete endpoint';
  RAISE NOTICE '  2. Update frontend: Add Completed tab';
  RAISE NOTICE '  3. Update frontend: Add Meeting Completed button';
  RAISE NOTICE '  4. Test with Emir ↔ Aysu16 match';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
