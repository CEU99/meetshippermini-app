-- ================================================
-- LEVEL & ACHIEVEMENT SYSTEM - COMPLETE SCHEMA
-- ================================================
-- Date: 2025-10-20
-- Purpose: Implement level progression (0-20) and achievement tracking
-- Points per level: 100
-- Max level: 20 (2000 total points)

-- ================================================
-- 1. USER LEVELS TABLE
-- ================================================
-- Stores user level progression and total points

CREATE TABLE IF NOT EXISTS user_levels (
  user_fid BIGINT PRIMARY KEY REFERENCES users(fid) ON DELETE CASCADE,
  points_total INT NOT NULL DEFAULT 0 CHECK (points_total >= 0),
  level INT GENERATED ALWAYS AS (LEAST(FLOOR(points_total / 100), 20)) STORED,
  level_progress INT GENERATED ALWAYS AS (
    CASE
      WHEN points_total >= 2000 THEN 100
      ELSE points_total % 100
    END
  ) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for efficient lookups
CREATE INDEX IF NOT EXISTS idx_user_levels_fid ON user_levels(user_fid);
CREATE INDEX IF NOT EXISTS idx_user_levels_points ON user_levels(points_total DESC);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_user_levels_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_levels_timestamp
  BEFORE UPDATE ON user_levels
  FOR EACH ROW
  EXECUTE FUNCTION update_user_levels_timestamp();

-- ================================================
-- 2. USER ACHIEVEMENTS TABLE
-- ================================================
-- Stores earned achievements (idempotent - each awarded once)

CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  code TEXT NOT NULL CHECK (code != ''),
  points INT NOT NULL CHECK (points > 0),
  awarded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Ensure each achievement is awarded once per user
  UNIQUE(user_fid, code)
);

-- Indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_user_achievements_fid ON user_achievements(user_fid);
CREATE INDEX IF NOT EXISTS idx_user_achievements_code ON user_achievements(code);
CREATE INDEX IF NOT EXISTS idx_user_achievements_awarded ON user_achievements(awarded_at DESC);

-- ================================================
-- 3. ACHIEVEMENT DEFINITIONS (Reference)
-- ================================================
-- These are the available achievements in the system

COMMENT ON TABLE user_achievements IS 'Achievement codes:
- bio_done: Fill bio (+50 points)
- traits_done: Fill personal traits (+50 points)
- sent_5: Send match requests to 5 unique users (+100 points)
- sent_10: Send match requests to 10 unique users (+100 points)
- sent_20: Send match requests to 20 unique users (+100 points)
- sent_30: Send match requests to 30 unique users (+100 points)
- joined_1: Join 1 completed meeting (+400 points)
- joined_5: Join 5 completed meetings (+400 points)
- joined_10: Join 10 completed meetings (+400 points)
- joined_40: Join 40 completed meetings (+400 points)

Wave 1: bio_done, traits_done, sent_5 (200 points = Level 2)
Wave 2: sent_10, sent_20, sent_30 (300 points = Level 5)
Wave 3: joined_1, joined_5, joined_10 (1200 points = Level 17)
Wave 4: joined_40 (400 points = Level 20 - MAX)';

-- ================================================
-- 4. RLS POLICIES
-- ================================================
-- Enable Row Level Security

ALTER TABLE user_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Users can view their own level data
CREATE POLICY user_levels_select_own ON user_levels
  FOR SELECT
  USING (user_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint);

-- Users can view their own achievements
CREATE POLICY user_achievements_select_own ON user_achievements
  FOR SELECT
  USING (user_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint);

-- Service role can insert/update (for backend triggers)
CREATE POLICY user_levels_service_all ON user_levels
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY user_achievements_service_all ON user_achievements
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- ================================================
-- 5. HELPER FUNCTION: AWARD ACHIEVEMENT
-- ================================================
-- Idempotent function to award achievements and update points

CREATE OR REPLACE FUNCTION award_achievement(
  p_user_fid BIGINT,
  p_code TEXT,
  p_points INT
)
RETURNS JSONB AS $$
DECLARE
  v_already_awarded BOOLEAN;
  v_new_total INT;
  v_new_level INT;
  v_new_progress INT;
BEGIN
  -- Check if achievement already awarded
  SELECT EXISTS(
    SELECT 1 FROM user_achievements
    WHERE user_fid = p_user_fid AND code = p_code
  ) INTO v_already_awarded;

  IF v_already_awarded THEN
    -- Already awarded, return current state
    SELECT points_total, level, level_progress
    INTO v_new_total, v_new_level, v_new_progress
    FROM user_levels
    WHERE user_fid = p_user_fid;

    RETURN jsonb_build_object(
      'awarded', false,
      'already_exists', true,
      'points_total', COALESCE(v_new_total, 0),
      'level', COALESCE(v_new_level, 0),
      'level_progress', COALESCE(v_new_progress, 0)
    );
  END IF;

  -- Insert achievement
  INSERT INTO user_achievements (user_fid, code, points)
  VALUES (p_user_fid, p_code, p_points);

  -- Initialize user_levels if not exists
  INSERT INTO user_levels (user_fid, points_total)
  VALUES (p_user_fid, 0)
  ON CONFLICT (user_fid) DO NOTHING;

  -- Update points_total
  UPDATE user_levels
  SET points_total = LEAST(points_total + p_points, 2000)
  WHERE user_fid = p_user_fid;

  -- Get updated values
  SELECT points_total, level, level_progress
  INTO v_new_total, v_new_level, v_new_progress
  FROM user_levels
  WHERE user_fid = p_user_fid;

  RETURN jsonb_build_object(
    'awarded', true,
    'already_exists', false,
    'code', p_code,
    'points', p_points,
    'points_total', v_new_total,
    'level', v_new_level,
    'level_progress', v_new_progress
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 6. HELPER FUNCTION: GET USER LEVEL INFO
-- ================================================

CREATE OR REPLACE FUNCTION get_user_level(p_user_fid BIGINT)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Initialize if not exists
  INSERT INTO user_levels (user_fid, points_total)
  VALUES (p_user_fid, 0)
  ON CONFLICT (user_fid) DO NOTHING;

  -- Get level info
  SELECT jsonb_build_object(
    'user_fid', user_fid,
    'points_total', points_total,
    'level', level,
    'level_progress', level_progress,
    'updated_at', updated_at
  )
  INTO v_result
  FROM user_levels
  WHERE user_fid = p_user_fid;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 7. HELPER FUNCTION: GET USER ACHIEVEMENTS
-- ================================================

CREATE OR REPLACE FUNCTION get_user_achievements(p_user_fid BIGINT)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'code', code,
      'points', points,
      'awarded_at', awarded_at
    )
    ORDER BY awarded_at ASC
  ), '[]'::jsonb)
  INTO v_result
  FROM user_achievements
  WHERE user_fid = p_user_fid;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 8. HELPER FUNCTION: CHECK AND AWARD PROFILE ACHIEVEMENTS
-- ================================================
-- Checks bio and traits, awards if criteria met

CREATE OR REPLACE FUNCTION check_profile_achievements(p_user_fid BIGINT)
RETURNS JSONB AS $$
DECLARE
  v_bio TEXT;
  v_traits JSONB;
  v_bio_result JSONB;
  v_traits_result JSONB;
BEGIN
  -- Get user profile data
  SELECT bio, traits
  INTO v_bio, v_traits
  FROM users
  WHERE fid = p_user_fid;

  -- Initialize result
  v_bio_result := jsonb_build_object('awarded', false);
  v_traits_result := jsonb_build_object('awarded', false);

  -- Check bio achievement
  IF v_bio IS NOT NULL AND LENGTH(TRIM(v_bio)) > 0 THEN
    v_bio_result := award_achievement(p_user_fid, 'bio_done', 50);
  END IF;

  -- Check traits achievement (need at least 5)
  IF v_traits IS NOT NULL AND jsonb_array_length(v_traits) >= 5 THEN
    v_traits_result := award_achievement(p_user_fid, 'traits_done', 50);
  END IF;

  RETURN jsonb_build_object(
    'bio', v_bio_result,
    'traits', v_traits_result
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 9. HELPER FUNCTION: CHECK AND AWARD MATCH REQUEST ACHIEVEMENTS
-- ================================================
-- Checks unique match requests sent count

CREATE OR REPLACE FUNCTION check_match_request_achievements(p_user_fid BIGINT)
RETURNS JSONB AS $$
DECLARE
  v_unique_count INT;
  v_results JSONB := '[]'::jsonb;
  v_result JSONB;
BEGIN
  -- Count unique recipients this user has sent matches to
  SELECT COUNT(DISTINCT
    CASE
      WHEN created_by_fid = p_user_fid THEN
        CASE
          WHEN user_a_fid = p_user_fid THEN user_b_fid
          ELSE user_a_fid
        END
      ELSE NULL
    END
  )
  INTO v_unique_count
  FROM matches
  WHERE created_by_fid = p_user_fid;

  -- Check thresholds and award
  IF v_unique_count >= 30 THEN
    v_result := award_achievement(p_user_fid, 'sent_30', 100);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_unique_count >= 20 THEN
    v_result := award_achievement(p_user_fid, 'sent_20', 100);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_unique_count >= 10 THEN
    v_result := award_achievement(p_user_fid, 'sent_10', 100);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_unique_count >= 5 THEN
    v_result := award_achievement(p_user_fid, 'sent_5', 100);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  RETURN jsonb_build_object(
    'unique_count', v_unique_count,
    'awards', v_results
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 10. HELPER FUNCTION: CHECK AND AWARD MEETING ACHIEVEMENTS
-- ================================================
-- Checks completed meetings count

CREATE OR REPLACE FUNCTION check_meeting_achievements(p_user_fid BIGINT)
RETURNS JSONB AS $$
DECLARE
  v_meeting_count INT;
  v_results JSONB := '[]'::jsonb;
  v_result JSONB;
BEGIN
  -- Count completed meetings for this user
  SELECT COUNT(*)
  INTO v_meeting_count
  FROM matches
  WHERE (user_a_fid = p_user_fid OR user_b_fid = p_user_fid)
    AND status = 'completed';

  -- Check thresholds and award
  IF v_meeting_count >= 40 THEN
    v_result := award_achievement(p_user_fid, 'joined_40', 400);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_meeting_count >= 10 THEN
    v_result := award_achievement(p_user_fid, 'joined_10', 400);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_meeting_count >= 5 THEN
    v_result := award_achievement(p_user_fid, 'joined_5', 400);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  IF v_meeting_count >= 1 THEN
    v_result := award_achievement(p_user_fid, 'joined_1', 400);
    v_results := v_results || jsonb_build_array(v_result);
  END IF;

  RETURN jsonb_build_object(
    'meeting_count', v_meeting_count,
    'awards', v_results
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 11. GRANT PERMISSIONS
-- ================================================

-- Grant execute on functions to authenticated users
GRANT EXECUTE ON FUNCTION get_user_level(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_achievements(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_profile_achievements(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_match_request_achievements(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION check_meeting_achievements(BIGINT) TO authenticated;

-- Grant execute on award_achievement to service role only
GRANT EXECUTE ON FUNCTION award_achievement(BIGINT, TEXT, INT) TO service_role;

-- ================================================
-- 12. VERIFICATION QUERIES
-- ================================================

-- Check tables exist
SELECT table_name FROM information_schema.tables
WHERE table_name IN ('user_levels', 'user_achievements');

-- Check functions exist
SELECT routine_name FROM information_schema.routines
WHERE routine_name IN (
  'award_achievement',
  'get_user_level',
  'get_user_achievements',
  'check_profile_achievements',
  'check_match_request_achievements',
  'check_meeting_achievements'
);

-- ================================================
-- SETUP COMPLETE
-- ================================================
-- Next steps:
-- 1. Run this SQL in Supabase SQL Editor
-- 2. Implement API endpoints in Next.js
-- 3. Add achievement triggers to profile/match/meeting endpoints
-- 4. Create UI components for level progress and achievement cards
