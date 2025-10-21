-- =====================================================================
-- FIX: "Failed to respond to match" API Endpoint Issue
-- =====================================================================
-- Purpose: Ensures all required columns and views exist for the respond endpoint
-- Issue: Frontend calls /api/matches/:id/respond but fails
-- Root Cause: Missing columns in matches table and incomplete match_details view
-- Run this in: Supabase Dashboard → SQL Editor
-- =====================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================
-- STEP 1: Add Missing Columns to matches Table
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'STEP 1: Adding missing columns to matches table...';
  RAISE NOTICE '=============================================================';
END $$;

-- Add columns that might be missing
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS created_by    TEXT    DEFAULT 'system',
  ADD COLUMN IF NOT EXISTS rationale     JSONB,
  ADD COLUMN IF NOT EXISTS meeting_link  TEXT,
  ADD COLUMN IF NOT EXISTS scheduled_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS completed_at  TIMESTAMPTZ;

-- =====================================================================
-- STEP 2: Update Status Constraint (Support All Statuses)
-- =====================================================================

DO $$
DECLARE
  chk_name text;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'STEP 2: Updating status constraint...';
  RAISE NOTICE '=============================================================';

  -- Find existing status constraint
  SELECT conname
  INTO chk_name
  FROM pg_constraint
  WHERE conrelid = 'public.matches'::regclass
    AND contype = 'c'
    AND conname LIKE '%status%';

  -- Drop old constraint if exists
  IF chk_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.matches DROP CONSTRAINT %I;', chk_name);
    RAISE NOTICE '✓ Dropped old constraint: %', chk_name;
  END IF;

  -- Add new constraint with all status values
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

  RAISE NOTICE '✓ Added new status constraint with all valid values';
END $$;

-- =====================================================================
-- STEP 3: Update match_details View (Add Missing Fields)
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'STEP 3: Recreating match_details view...';
  RAISE NOTICE '=============================================================';
END $$;

-- Drop and recreate the view
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

COMMENT ON VIEW public.match_details IS 'Enriched match data with user information and traits';

-- =====================================================================
-- STEP 4: Create Indexes for Performance
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'STEP 4: Creating indexes...';
  RAISE NOTICE '=============================================================';
END $$;

CREATE INDEX IF NOT EXISTS idx_matches_rationale    ON public.matches USING GIN (rationale);
CREATE INDEX IF NOT EXISTS idx_matches_scheduled_at ON public.matches(scheduled_at) WHERE scheduled_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_matches_created_by   ON public.matches(created_by);

-- =====================================================================
-- STEP 5: Verify Schema
-- =====================================================================

DO $$
DECLARE
  col_count INTEGER;
  view_count INTEGER;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'STEP 5: Verifying schema...';
  RAISE NOTICE '=============================================================';

  -- Check matches table columns
  SELECT COUNT(*)
  INTO col_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'matches'
    AND column_name IN ('created_by', 'rationale', 'meeting_link', 'scheduled_at', 'completed_at');

  IF col_count = 5 THEN
    RAISE NOTICE '✓ All required columns exist in matches table';
  ELSE
    RAISE WARNING '⚠ Missing columns in matches table! Found % of 5', col_count;
  END IF;

  -- Check match_details view columns
  SELECT COUNT(*)
  INTO view_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'match_details'
    AND column_name IN ('user_a_traits', 'user_b_traits', 'created_by', 'rationale', 'meeting_link');

  IF view_count = 5 THEN
    RAISE NOTICE '✓ All required columns exist in match_details view';
  ELSE
    RAISE WARNING '⚠ Missing columns in match_details view! Found % of 5', view_count;
  END IF;
END $$;

-- =====================================================================
-- STEP 6: Display Current Matches
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'STEP 6: Current matches in system';
  RAISE NOTICE '=============================================================';
END $$;

-- Show all matches with their statuses
SELECT
  id,
  user_a_fid,
  user_b_fid,
  created_by_fid,
  created_by,
  status,
  a_accepted,
  b_accepted,
  meeting_link IS NOT NULL as has_meeting_link,
  rationale IS NOT NULL as has_rationale,
  created_at
FROM public.matches
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================================
-- STEP 7: Test Query for Emir ↔ Aysu16 Match
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'STEP 7: Looking for Emir (543581) ↔ Aysu16 (1394398) match...';
  RAISE NOTICE '=============================================================';
END $$;

-- Find the specific match
SELECT
  m.id as match_id,
  m.user_a_fid,
  ua.username as user_a_username,
  m.user_b_fid,
  ub.username as user_b_username,
  m.status,
  m.a_accepted,
  m.b_accepted,
  m.meeting_link,
  m.created_by,
  m.created_at
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 543581 AND m.user_b_fid = 1394398)
   OR (m.user_a_fid = 1394398 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 5;

-- =====================================================================
-- SUCCESS MESSAGE
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '✅ RESPOND ENDPOINT FIX COMPLETE!';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'What was fixed:';
  RAISE NOTICE '  1. Added missing columns to matches table:';
  RAISE NOTICE '     • created_by (TEXT)';
  RAISE NOTICE '     • rationale (JSONB)';
  RAISE NOTICE '     • meeting_link (TEXT)';
  RAISE NOTICE '     • scheduled_at (TIMESTAMPTZ)';
  RAISE NOTICE '     • completed_at (TIMESTAMPTZ)';
  RAISE NOTICE '';
  RAISE NOTICE '  2. Updated status constraint to include all valid statuses';
  RAISE NOTICE '';
  RAISE NOTICE '  3. Recreated match_details view with all required fields';
  RAISE NOTICE '';
  RAISE NOTICE '  4. Created indexes for better performance';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '  1. Test the respond endpoint with Emir accepting the match';
  RAISE NOTICE '  2. Verify that status updates correctly';
  RAISE NOTICE '  3. Check that meeting link is generated when both accept';
  RAISE NOTICE '';
  RAISE NOTICE 'Test command:';
  RAISE NOTICE '  • Visit: http://localhost:3000/mini/inbox';
  RAISE NOTICE '  • Login as Emir (FID 543581)';
  RAISE NOTICE '  • Click "Accept" on the match from Aysu16';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
