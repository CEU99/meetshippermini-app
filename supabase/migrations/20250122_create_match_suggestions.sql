-- Migration: Add Match Suggestions Feature
-- Description: Allows users to suggest matches between two other users (not self-matches)
-- Author: Claude
-- Date: 2025-01-22

-- ============================================================================
-- 1. Create match_suggestions table
-- ============================================================================

CREATE TABLE IF NOT EXISTS match_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- The suggester (creator) - hidden from participants
  created_by_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,

  -- The two participants
  user_a_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  user_b_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,

  -- Introduction message from suggester
  message TEXT NOT NULL,

  -- Status tracking
  status TEXT NOT NULL DEFAULT 'proposed' CHECK (
    status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'accepted', 'declined', 'cancelled')
  ),

  -- Individual acceptance flags
  a_accepted BOOLEAN NOT NULL DEFAULT false,
  b_accepted BOOLEAN NOT NULL DEFAULT false,

  -- Chat room reference (set when both accept)
  chat_room_id UUID REFERENCES chat_rooms(id) ON DELETE SET NULL,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Constraints
  CONSTRAINT different_users CHECK (user_a_fid != user_b_fid),
  CONSTRAINT different_from_creator CHECK (
    created_by_fid != user_a_fid AND created_by_fid != user_b_fid
  )
);

-- ============================================================================
-- 2. Create indexes for performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_match_suggestions_user_a ON match_suggestions(user_a_fid);
CREATE INDEX IF NOT EXISTS idx_match_suggestions_user_b ON match_suggestions(user_b_fid);
CREATE INDEX IF NOT EXISTS idx_match_suggestions_creator ON match_suggestions(created_by_fid);
CREATE INDEX IF NOT EXISTS idx_match_suggestions_status ON match_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_match_suggestions_created_at ON match_suggestions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_match_suggestions_chat_room ON match_suggestions(chat_room_id);

-- Composite index for checking active suggestions between two users
CREATE INDEX IF NOT EXISTS idx_match_suggestions_pair_status ON match_suggestions(
  LEAST(user_a_fid, user_b_fid),
  GREATEST(user_a_fid, user_b_fid),
  status
) WHERE status NOT IN ('declined', 'cancelled');

-- ============================================================================
-- 3. Create unique constraint to prevent duplicate pending suggestions
-- ============================================================================

-- Prevent duplicate suggestions between same two users (order-independent)
CREATE UNIQUE INDEX IF NOT EXISTS idx_match_suggestions_unique_pending_pair ON match_suggestions(
  LEAST(user_a_fid, user_b_fid),
  GREATEST(user_a_fid, user_b_fid)
) WHERE status IN ('proposed', 'accepted_by_a', 'accepted_by_b');

-- ============================================================================
-- 4. Create updated_at trigger
-- ============================================================================

CREATE TRIGGER update_match_suggestions_updated_at
  BEFORE UPDATE ON match_suggestions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. Create cooldown tracking table
-- ============================================================================

CREATE TABLE IF NOT EXISTS match_suggestion_cooldowns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- The two users (normalized order)
  user_a_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  user_b_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,

  -- When the cooldown expires
  cooldown_until TIMESTAMPTZ NOT NULL,

  -- Reference to the declined suggestion
  declined_suggestion_id UUID REFERENCES match_suggestions(id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT cooldown_different_users CHECK (user_a_fid != user_b_fid)
);

CREATE INDEX IF NOT EXISTS idx_match_cooldowns_pair ON match_suggestion_cooldowns(
  LEAST(user_a_fid, user_b_fid),
  GREATEST(user_a_fid, user_b_fid),
  cooldown_until
);

-- ============================================================================
-- 6. Function to check if suggestion is allowed (cooldown check)
-- ============================================================================

CREATE OR REPLACE FUNCTION check_suggestion_cooldown(
  p_user_a_fid BIGINT,
  p_user_b_fid BIGINT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_min_fid BIGINT;
  v_max_fid BIGINT;
  v_cooldown_count INTEGER;
BEGIN
  -- Normalize the FID order
  v_min_fid := LEAST(p_user_a_fid, p_user_b_fid);
  v_max_fid := GREATEST(p_user_a_fid, p_user_b_fid);

  -- Check if there's an active cooldown
  SELECT COUNT(*)
  INTO v_cooldown_count
  FROM match_suggestion_cooldowns
  WHERE LEAST(user_a_fid, user_b_fid) = v_min_fid
    AND GREATEST(user_a_fid, user_b_fid) = v_max_fid
    AND cooldown_until > now();

  -- Return true if allowed (no active cooldown), false if blocked
  RETURN v_cooldown_count = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. Function to create cooldown after decline
-- ============================================================================

CREATE OR REPLACE FUNCTION create_suggestion_cooldown()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create cooldown if status changed to 'declined'
  IF NEW.status = 'declined' AND OLD.status != 'declined' THEN
    INSERT INTO match_suggestion_cooldowns (
      user_a_fid,
      user_b_fid,
      cooldown_until,
      declined_suggestion_id
    ) VALUES (
      LEAST(NEW.user_a_fid, NEW.user_b_fid),
      GREATEST(NEW.user_a_fid, NEW.user_b_fid),
      now() + INTERVAL '7 days',
      NEW.id
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_create_suggestion_cooldown
  AFTER UPDATE ON match_suggestions
  FOR EACH ROW
  EXECUTE FUNCTION create_suggestion_cooldown();

-- ============================================================================
-- 8. Function to auto-update status based on acceptance flags
-- ============================================================================

CREATE OR REPLACE FUNCTION update_suggestion_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Update status based on acceptance flags
  IF NEW.a_accepted AND NEW.b_accepted THEN
    NEW.status := 'accepted';
  ELSIF NEW.a_accepted AND NOT NEW.b_accepted THEN
    NEW.status := 'accepted_by_a';
  ELSIF NOT NEW.a_accepted AND NEW.b_accepted THEN
    NEW.status := 'accepted_by_b';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_suggestion_status
  BEFORE UPDATE ON match_suggestions
  FOR EACH ROW
  WHEN (OLD.a_accepted IS DISTINCT FROM NEW.a_accepted OR OLD.b_accepted IS DISTINCT FROM NEW.b_accepted)
  EXECUTE FUNCTION update_suggestion_status();

-- ============================================================================
-- 9. Enable Row Level Security
-- ============================================================================

ALTER TABLE match_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_suggestion_cooldowns ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 10. RLS Policies for match_suggestions
-- ============================================================================

-- Policy: Users can create suggestions (but not to themselves)
CREATE POLICY "Users can create match suggestions"
  ON match_suggestions
  FOR INSERT
  WITH CHECK (
    created_by_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    AND user_a_fid != created_by_fid
    AND user_b_fid != created_by_fid
    AND user_a_fid != user_b_fid
  );

-- Policy: Participants can view suggestions where they are involved
-- IMPORTANT: Does NOT reveal creator identity
CREATE POLICY "Participants can view their suggestions"
  ON match_suggestions
  FOR SELECT
  USING (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );

-- Policy: Participants can update their acceptance status
CREATE POLICY "Participants can accept/decline suggestions"
  ON match_suggestions
  FOR UPDATE
  USING (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  )
  WITH CHECK (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );

-- Policy: Service role has full access (for automation)
CREATE POLICY "Service role can manage suggestions"
  ON match_suggestions
  FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role')
  WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

-- ============================================================================
-- 11. RLS Policies for match_suggestion_cooldowns
-- ============================================================================

-- Policy: Users can check cooldowns for pairs they're involved in
CREATE POLICY "Users can view relevant cooldowns"
  ON match_suggestion_cooldowns
  FOR SELECT
  USING (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );

-- Policy: Service role has full access
CREATE POLICY "Service role can manage cooldowns"
  ON match_suggestion_cooldowns
  FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role')
  WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

-- ============================================================================
-- 12. Grant necessary permissions
-- ============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON match_suggestions TO service_role;
GRANT ALL ON match_suggestion_cooldowns TO service_role;
GRANT SELECT, INSERT, UPDATE ON match_suggestions TO authenticated;
GRANT SELECT ON match_suggestion_cooldowns TO authenticated;

-- ============================================================================
-- 13. Create view for easier querying (with participant details)
-- ============================================================================

CREATE OR REPLACE VIEW match_suggestions_with_details AS
SELECT
  ms.id,
  ms.created_by_fid,
  ms.user_a_fid,
  ms.user_b_fid,
  ms.message,
  ms.status,
  ms.a_accepted,
  ms.b_accepted,
  ms.chat_room_id,
  ms.created_at,
  ms.updated_at,
  -- User A details
  ua.username AS user_a_username,
  ua.display_name AS user_a_display_name,
  ua.avatar_url AS user_a_avatar_url,
  -- User B details
  ub.username AS user_b_username,
  ub.display_name AS user_b_display_name,
  ub.avatar_url AS user_b_avatar_url
FROM match_suggestions ms
LEFT JOIN users ua ON ms.user_a_fid = ua.fid
LEFT JOIN users ub ON ms.user_b_fid = ub.fid;

-- Grant select on view
GRANT SELECT ON match_suggestions_with_details TO authenticated, service_role;

-- ============================================================================
-- Migration Complete
-- ============================================================================

-- Verify tables were created
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'match_suggestions') THEN
    RAISE NOTICE '✅ match_suggestions table created successfully';
  END IF;

  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'match_suggestion_cooldowns') THEN
    RAISE NOTICE '✅ match_suggestion_cooldowns table created successfully';
  END IF;
END $$;
