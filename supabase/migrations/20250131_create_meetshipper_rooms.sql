-- ============================================================================
-- MeetShipper Conversation Rooms
-- ============================================================================
-- New conversation room system that replaces the auto-chat system
-- Users can manually enter/exit rooms
-- Rooms can be permanently closed by either participant
-- ============================================================================

DO $$ BEGIN RAISE NOTICE '🚀 Creating meetshipper_rooms table...'; END $$;

-- ====================
-- STEP 1: Create meetshipper_rooms Table
-- ====================

CREATE TABLE IF NOT EXISTS meetshipper_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  user_a_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  user_b_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  is_closed BOOLEAN NOT NULL DEFAULT false,
  closed_by_fid BIGINT REFERENCES users(fid),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  closed_at TIMESTAMPTZ,

  -- Ensure user_a and user_b are different
  CONSTRAINT different_users_meetshipper CHECK (user_a_fid != user_b_fid)
);

DO $$ BEGIN RAISE NOTICE '  ✅ meetshipper_rooms table created'; END $$;

-- ====================
-- STEP 2: Create Indexes
-- ====================

CREATE INDEX IF NOT EXISTS idx_meetshipper_rooms_match_id ON meetshipper_rooms(match_id);
CREATE INDEX IF NOT EXISTS idx_meetshipper_rooms_user_a ON meetshipper_rooms(user_a_fid);
CREATE INDEX IF NOT EXISTS idx_meetshipper_rooms_user_b ON meetshipper_rooms(user_b_fid);
CREATE INDEX IF NOT EXISTS idx_meetshipper_rooms_is_closed ON meetshipper_rooms(is_closed);

DO $$ BEGIN RAISE NOTICE '  ✅ Indexes created'; END $$;

-- ====================
-- STEP 3: Enable RLS
-- ====================

ALTER TABLE meetshipper_rooms ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN RAISE NOTICE '  ✅ RLS enabled'; END $$;

-- ====================
-- STEP 4: Create RLS Policies
-- ====================

-- Policy: Users can view rooms for matches they're part of
CREATE POLICY "Users can view rooms for their matches"
ON meetshipper_rooms
FOR SELECT
TO authenticated
USING (
  user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
);

DO $$ BEGIN RAISE NOTICE '  ✅ SELECT policy created'; END $$;

-- Policy: Rooms can only be created via service role (API endpoints)
CREATE POLICY "Service role can create rooms"
ON meetshipper_rooms
FOR INSERT
TO service_role
WITH CHECK (true);

DO $$ BEGIN RAISE NOTICE '  ✅ INSERT policy created'; END $$;

-- Policy: Users can close rooms for their matches
CREATE POLICY "Users can close their rooms"
ON meetshipper_rooms
FOR UPDATE
TO authenticated
USING (
  user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
)
WITH CHECK (
  user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
);

DO $$ BEGIN RAISE NOTICE '  ✅ UPDATE policy created'; END $$;

-- Policy: Service role full access
CREATE POLICY "Service role full access to meetshipper_rooms"
ON meetshipper_rooms
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

DO $$ BEGIN RAISE NOTICE '  ✅ Service role policy created'; END $$;

-- ====================
-- STEP 5: Enable Realtime
-- ====================

ALTER TABLE meetshipper_rooms REPLICA IDENTITY FULL;

-- Add to realtime publication
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'meetshipper_rooms'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE meetshipper_rooms;
        RAISE NOTICE '  ✅ Added to realtime publication';
    ELSE
        RAISE NOTICE '  ℹ️  Already in realtime publication';
    END IF;
END $$;

-- ====================
-- STEP 6: Grant Permissions
-- ====================

GRANT SELECT, UPDATE ON meetshipper_rooms TO authenticated;
GRANT ALL ON meetshipper_rooms TO service_role;

DO $$ BEGIN RAISE NOTICE '  ✅ Permissions granted'; END $$;

-- ====================
-- STEP 7: Create Helper Functions
-- ====================

-- Function to ensure a conversation room exists for a match
CREATE OR REPLACE FUNCTION ensure_meetshipper_room(
  p_match_id UUID,
  p_user_a_fid BIGINT,
  p_user_b_fid BIGINT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_room_id UUID;
BEGIN
  -- Check if room already exists
  SELECT id INTO v_room_id
  FROM meetshipper_rooms
  WHERE match_id = p_match_id;

  -- If exists, return it
  IF FOUND THEN
    RETURN v_room_id;
  END IF;

  -- Create new room
  INSERT INTO meetshipper_rooms (match_id, user_a_fid, user_b_fid)
  VALUES (p_match_id, p_user_a_fid, p_user_b_fid)
  RETURNING id INTO v_room_id;

  RETURN v_room_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '  ✅ Helper functions created'; END $$;

-- ====================
-- COMPLETION
-- ====================

DO $$ BEGIN RAISE NOTICE '✅ meetshipper_rooms table setup complete!'; END $$;
DO $$ BEGIN RAISE NOTICE '📊 Summary:'; END $$;
DO $$ BEGIN RAISE NOTICE '   - Table: meetshipper_rooms'; END $$;
DO $$ BEGIN RAISE NOTICE '   - Indexes: 4'; END $$;
DO $$ BEGIN RAISE NOTICE '   - RLS Policies: 4'; END $$;
DO $$ BEGIN RAISE NOTICE '   - Realtime: Enabled'; END $$;
DO $$ BEGIN RAISE NOTICE '🎉 Ready for MeetShipper Conversation Rooms!'; END $$;
