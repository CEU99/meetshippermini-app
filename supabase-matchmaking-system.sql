-- =====================================================================
-- Enhanced Matchmaking System Schema (Idempotent & Fixed)
-- =====================================================================
-- Safe to run multiple times
-- Run this in: Supabase Dashboard → SQL Editor
-- =====================================================================

-- 0) Extensions (UUID)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================
-- PART 1: Extend matches table with new columns
-- =====================================================================

-- Add new columns to matches (if missing)
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS created_by  TEXT    DEFAULT 'system',
  ADD COLUMN IF NOT EXISTS rationale   JSONB,
  ADD COLUMN IF NOT EXISTS meeting_link TEXT,
  ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- =====================================================================
-- PART 2: Update status constraint to include new statuses
-- =====================================================================

DO $$
DECLARE
  chk_name text;
BEGIN
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
    RAISE NOTICE 'Dropped old constraint: %', chk_name;
  END IF;

  -- Add new constraint with expanded status values
  EXECUTE $sql$
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
  $sql$;

  RAISE NOTICE '✅ Added new status constraint with expanded values';
END $$;

-- =====================================================================
-- PART 3: Create cooldown & auto_match_runs tables
-- =====================================================================

-- Cooldown table to prevent re-matching declined pairs
CREATE TABLE IF NOT EXISTS public.match_cooldowns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_a_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
  user_b_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
  declined_at TIMESTAMPTZ DEFAULT NOW(),
  cooldown_until TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  CONSTRAINT different_users_cooldown CHECK (user_a_fid <> user_b_fid)
);

CREATE INDEX IF NOT EXISTS idx_cooldowns_users ON public.match_cooldowns(user_a_fid, user_b_fid);
CREATE INDEX IF NOT EXISTS idx_cooldowns_until ON public.match_cooldowns(cooldown_until);

-- Auto-match runs logging table
CREATE TABLE IF NOT EXISTS public.auto_match_runs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  users_processed INT DEFAULT 0,
  matches_created INT DEFAULT 0,
  status TEXT DEFAULT 'running' CHECK (status IN ('running','completed','failed')),
  error_message TEXT
);

-- =====================================================================
-- PART 4: Create helper functions
-- =====================================================================

-- 4.1) Check if cooldown exists between two users
CREATE OR REPLACE FUNCTION public.check_match_cooldown(fid_a BIGINT, fid_b BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  cooldown_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.match_cooldowns mc
    WHERE ((mc.user_a_fid = fid_a AND mc.user_b_fid = fid_b)
        OR (mc.user_a_fid = fid_b AND mc.user_b_fid = fid_a))
      AND mc.cooldown_until > NOW()
  )
  INTO cooldown_exists;

  RETURN cooldown_exists;
END;
$$;

-- 4.2) Add cooldown after decline (trigger target)
CREATE OR REPLACE FUNCTION public.add_match_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'declined' AND (OLD.status IS DISTINCT FROM 'declined') THEN
    INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid)
    VALUES (NEW.user_a_fid, NEW.user_b_fid)
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

-- 4.3) Update match status on accepts (trigger target)
-- NOTE: This will be replaced by supabase-fix-match-triggers.sql
CREATE OR REPLACE FUNCTION public.update_match_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- User A accepts
  IF NEW.a_accepted IS TRUE AND COALESCE(OLD.a_accepted, FALSE) IS FALSE THEN
    IF COALESCE(NEW.b_accepted, FALSE) IS TRUE THEN
      NEW.status := 'accepted';
    ELSE
      NEW.status := 'accepted_by_a';
    END IF;
  END IF;

  -- User B accepts
  IF NEW.b_accepted IS TRUE AND COALESCE(OLD.b_accepted, FALSE) IS FALSE THEN
    IF COALESCE(NEW.a_accepted, FALSE) IS TRUE THEN
      NEW.status := 'accepted';
    ELSE
      NEW.status := 'accepted_by_b';
    END IF;
  END IF;

  -- Both accepted (double-check)
  IF COALESCE(NEW.a_accepted, FALSE) IS TRUE
     AND COALESCE(NEW.b_accepted, FALSE) IS TRUE THEN
    NEW.status := 'accepted';
  END IF;

  RETURN NEW;
END;
$$;

-- 4.4) Get users eligible for matching (bio + >=5 traits)
CREATE OR REPLACE FUNCTION public.get_matchable_users()
RETURNS TABLE (
  fid BIGINT,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  traits JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.fid,
    u.username,
    u.display_name,
    u.avatar_url,
    u.bio,
    COALESCE(u.traits, '[]'::jsonb) AS traits
  FROM public.users u
  WHERE u.bio IS NOT NULL
    AND u.bio <> ''
    AND jsonb_array_length(COALESCE(u.traits, '[]'::jsonb)) >= 5
  ORDER BY u.updated_at DESC NULLS LAST;
END;
$$;

-- 4.5) Count pending matches for a user (last 24h)
CREATE OR REPLACE FUNCTION public.count_pending_matches(user_fid BIGINT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  match_count INT;
BEGIN
  SELECT COUNT(*)::INT
  INTO match_count
  FROM public.matches m
  WHERE (m.user_a_fid = user_fid OR m.user_b_fid = user_fid)
    AND m.status IN ('proposed','accepted_by_a','accepted_by_b')
    AND m.created_at > NOW() - INTERVAL '24 hours';

  RETURN match_count;
END;
$$;

-- 4.6) Calculate Jaccard similarity for traits
CREATE OR REPLACE FUNCTION public.calculate_trait_similarity(traits_a JSONB, traits_b JSONB)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
  common_count INT;
  total_unique_count INT;
  similarity NUMERIC;
BEGIN
  WITH common AS (
    SELECT COUNT(*) AS cnt
    FROM (
      SELECT jsonb_array_elements_text(traits_a) INTERSECT
      SELECT jsonb_array_elements_text(traits_b)
    ) t
  ),
  total_unique AS (
    SELECT COUNT(*) AS cnt
    FROM (
      SELECT jsonb_array_elements_text(traits_a) UNION
      SELECT jsonb_array_elements_text(traits_b)
    ) t
  )
  SELECT c.cnt, u.cnt
  INTO common_count, total_unique_count
  FROM common c, total_unique u;

  IF total_unique_count = 0 THEN
    RETURN 0;
  END IF;

  similarity := common_count::NUMERIC / total_unique_count::NUMERIC;
  RETURN ROUND(similarity, 3);
END;
$$;

-- 4.7) Cleanup expired cooldowns (manual/cron)
CREATE OR REPLACE FUNCTION public.cleanup_expired_cooldowns()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM public.match_cooldowns
  WHERE cooldown_until < NOW();

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- =====================================================================
-- PART 5: Create/recreate triggers
-- =====================================================================

-- Drop existing triggers to avoid conflicts
DROP TRIGGER IF EXISTS match_declined_cooldown ON public.matches;
DROP TRIGGER IF EXISTS check_match_acceptance ON public.matches;

-- Create cooldown trigger
CREATE TRIGGER match_declined_cooldown
AFTER UPDATE ON public.matches
FOR EACH ROW
EXECUTE FUNCTION public.add_match_cooldown();

-- Create acceptance trigger
CREATE TRIGGER check_match_acceptance
BEFORE UPDATE ON public.matches
FOR EACH ROW
EXECUTE FUNCTION public.update_match_status();

-- =====================================================================
-- PART 6: Create indexes for performance
-- =====================================================================

CREATE INDEX IF NOT EXISTS idx_matches_created_by   ON public.matches(created_by);
CREATE INDEX IF NOT EXISTS idx_matches_rationale    ON public.matches USING GIN (rationale);
CREATE INDEX IF NOT EXISTS idx_matches_scheduled_at ON public.matches(scheduled_at) WHERE scheduled_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_traits         ON public.users USING GIN (traits);
CREATE INDEX IF NOT EXISTS idx_users_bio            ON public.users USING GIN (to_tsvector('english', bio)) WHERE bio IS NOT NULL;

-- =====================================================================
-- PART 7: Grants & comments
-- =====================================================================

GRANT SELECT ON public.match_cooldowns TO anon, authenticated;
GRANT SELECT ON public.auto_match_runs TO anon, authenticated;

COMMENT ON TABLE  public.match_cooldowns IS 'Tracks cooldown periods between users after declined matches';
COMMENT ON TABLE  public.auto_match_runs  IS 'Logs of automatic matching system runs';
COMMENT ON COLUMN public.matches.created_by   IS 'Either "system" or "admin:<fid>" to track match origin';
COMMENT ON COLUMN public.matches.rationale    IS 'JSON object with trait overlap, bio keywords, and match score';
COMMENT ON COLUMN public.matches.meeting_link IS 'Generated meeting URL after both users accept';
COMMENT ON COLUMN public.matches.scheduled_at IS 'When the meeting is scheduled to occur';

-- =====================================================================
-- PART 8: PostgREST schema cache reload RPC
-- =====================================================================

-- Create or replace the schema reload function
CREATE OR REPLACE FUNCTION public.reload_pgrst_schema()
RETURNS void
LANGUAGE sql
AS $$
  NOTIFY pgrst, 'reload schema';
$$;

-- Reload PostgREST schema cache (wrapped in DO block to handle result)
DO $$
BEGIN
  PERFORM public.reload_pgrst_schema();
  RAISE NOTICE '✅ PostgREST schema cache reloaded';
END $$;

-- =====================================================================
-- VERIFICATION QUERIES
-- =====================================================================

-- Check matches table columns
SELECT
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'matches'
  AND column_name IN ('created_by', 'rationale', 'meeting_link', 'scheduled_at', 'completed_at')
ORDER BY ordinal_position;

-- Check cooldown tables exist
SELECT
  tablename,
  tableowner
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('match_cooldowns', 'auto_match_runs');

-- Check functions exist
SELECT
  proname AS function_name,
  pg_get_function_arguments(oid) AS arguments
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN (
    'check_match_cooldown',
    'add_match_cooldown',
    'update_match_status',
    'get_matchable_users',
    'count_pending_matches',
    'calculate_trait_similarity',
    'cleanup_expired_cooldowns',
    'reload_pgrst_schema'
  )
ORDER BY proname;

-- Check triggers
SELECT
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'matches'
  AND trigger_name IN ('match_declined_cooldown', 'check_match_acceptance')
ORDER BY trigger_name;

-- =====================================================================
-- SUCCESS MESSAGE
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '✅ MATCHMAKING SYSTEM INSTALLED SUCCESSFULLY!';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'New columns added to matches:';
  RAISE NOTICE '  • created_by (system/admin tracking)';
  RAISE NOTICE '  • rationale (match reasoning)';
  RAISE NOTICE '  • meeting_link (generated meeting URL)';
  RAISE NOTICE '  • scheduled_at (meeting schedule)';
  RAISE NOTICE '  • completed_at (completion timestamp)';
  RAISE NOTICE '';
  RAISE NOTICE 'New tables created:';
  RAISE NOTICE '  • match_cooldowns (7-day cooldown tracking)';
  RAISE NOTICE '  • auto_match_runs (matchmaking run logs)';
  RAISE NOTICE '';
  RAISE NOTICE 'New functions created:';
  RAISE NOTICE '  • check_match_cooldown(fid_a, fid_b)';
  RAISE NOTICE '  • get_matchable_users()';
  RAISE NOTICE '  • count_pending_matches(user_fid)';
  RAISE NOTICE '  • calculate_trait_similarity(traits_a, traits_b)';
  RAISE NOTICE '  • cleanup_expired_cooldowns()';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️  IMPORTANT: Next step required!';
  RAISE NOTICE '   Run supabase-fix-match-triggers.sql to fix the trigger bug';
  RAISE NOTICE '   that prevents declined/cancelled statuses from persisting.';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
