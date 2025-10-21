-- =====================================================================
-- Fix match_details View - Add Missing Fields
-- =====================================================================
-- This adds missing fields needed by the inbox API
-- Run this in Supabase SQL Editor
-- =====================================================================

-- Drop and recreate the view with all necessary fields
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

-- Grant access to the view
GRANT SELECT ON public.match_details TO anon, authenticated;

-- Add comment
COMMENT ON VIEW public.match_details IS 'Enriched match data with user information and traits';

-- =====================================================================
-- Verify the view
-- =====================================================================

-- Check that all columns exist
SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'match_details'
ORDER BY ordinal_position;

-- Test query
SELECT
  id,
  user_a_username,
  user_b_username,
  status,
  created_by,
  rationale IS NOT NULL as has_rationale,
  meeting_link IS NOT NULL as has_meeting_link
FROM public.match_details
ORDER BY created_at DESC
LIMIT 5;

-- =====================================================================
-- Success message
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '✅ match_details VIEW UPDATED SUCCESSFULLY!';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Added fields:';
  RAISE NOTICE '  • user_a_traits (JSONB array)';
  RAISE NOTICE '  • user_b_traits (JSONB array)';
  RAISE NOTICE '  • created_by (system/user tracking)';
  RAISE NOTICE '  • rationale (match reasoning)';
  RAISE NOTICE '  • meeting_link (meeting URL)';
  RAISE NOTICE '  • scheduled_at (meeting schedule)';
  RAISE NOTICE '  • completed_at (completion timestamp)';
  RAISE NOTICE '';
  RAISE NOTICE 'The inbox API can now fetch all required match data.';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
