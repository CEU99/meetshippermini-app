-- ============================================================================
-- MeetShipper Conversation Messages
-- ============================================================================
-- Real-time chat messages for MeetShipper Conversation Rooms
-- Enables in-room messaging between matched users
-- ============================================================================

DO $$ BEGIN RAISE NOTICE '🚀 Creating meetshipper_messages table...'; END $$;

-- ====================
-- STEP 1: Create meetshipper_messages Table
-- ====================

CREATE TABLE IF NOT EXISTS meetshipper_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES meetshipper_rooms(id) ON DELETE CASCADE,
  sender_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Ensure content is not empty
  CONSTRAINT content_not_empty CHECK (length(trim(content)) > 0)
);

DO $$ BEGIN RAISE NOTICE '  ✅ meetshipper_messages table created'; END $$;

-- ====================
-- STEP 2: Create Indexes
-- ====================

CREATE INDEX IF NOT EXISTS idx_meetshipper_messages_room_id ON meetshipper_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_meetshipper_messages_sender_fid ON meetshipper_messages(sender_fid);
CREATE INDEX IF NOT EXISTS idx_meetshipper_messages_created_at ON meetshipper_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_meetshipper_messages_room_created ON meetshipper_messages(room_id, created_at);

DO $$ BEGIN RAISE NOTICE '  ✅ Indexes created'; END $$;

-- ====================
-- STEP 3: Enable RLS
-- ====================

ALTER TABLE meetshipper_messages ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN RAISE NOTICE '  ✅ RLS enabled'; END $$;

-- ====================
-- STEP 4: Create RLS Policies
-- ====================

-- Policy 1: Users can view messages in rooms they participate in
CREATE POLICY "Users can view messages in their rooms"
  ON meetshipper_messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM meetshipper_rooms
      WHERE meetshipper_rooms.id = meetshipper_messages.room_id
      AND (
        meetshipper_rooms.user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
        OR meetshipper_rooms.user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
      )
    )
  );

-- Policy 2: Users can send messages in rooms they participate in
CREATE POLICY "Users can send messages in their rooms"
  ON meetshipper_messages
  FOR INSERT
  WITH CHECK (
    sender_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    AND EXISTS (
      SELECT 1 FROM meetshipper_rooms
      WHERE meetshipper_rooms.id = meetshipper_messages.room_id
      AND (
        meetshipper_rooms.user_a_fid = sender_fid
        OR meetshipper_rooms.user_b_fid = sender_fid
      )
      AND meetshipper_rooms.is_closed = false
    )
  );

-- Policy 3: Service role has full access
CREATE POLICY "Service role has full access to messages"
  ON meetshipper_messages
  FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role')
  WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

DO $$ BEGIN RAISE NOTICE '  ✅ RLS policies created'; END $$;

-- ====================
-- STEP 5: Enable Realtime
-- ====================

ALTER TABLE meetshipper_messages REPLICA IDENTITY FULL;

DO $$
BEGIN
  -- Check if table is already in publication
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'meetshipper_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE meetshipper_messages;
    RAISE NOTICE '  ✅ Realtime enabled';
  ELSE
    RAISE NOTICE '  ✅ Realtime already enabled';
  END IF;
END $$;

-- ====================
-- STEP 6: Create Helper Functions
-- ====================

-- Function to get message count for a room
CREATE OR REPLACE FUNCTION get_room_message_count(p_room_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  message_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO message_count
  FROM meetshipper_messages
  WHERE room_id = p_room_id;

  RETURN message_count;
END;
$$;

DO $$ BEGIN RAISE NOTICE '  ✅ Helper functions created'; END $$;

-- ====================
-- STEP 7: Create View for Message Details
-- ====================

CREATE OR REPLACE VIEW meetshipper_message_details AS
SELECT
  m.id,
  m.room_id,
  m.sender_fid,
  m.content,
  m.created_at,
  u.username as sender_username,
  u.display_name as sender_display_name,
  u.avatar_url as sender_avatar_url
FROM meetshipper_messages m
LEFT JOIN users u ON m.sender_fid = u.fid
ORDER BY m.created_at ASC;

DO $$ BEGIN RAISE NOTICE '  ✅ Message details view created'; END $$;

-- ====================
-- STEP 8: Grant Permissions
-- ====================

GRANT SELECT ON meetshipper_message_details TO authenticated;
GRANT SELECT ON meetshipper_message_details TO service_role;

DO $$ BEGIN RAISE NOTICE '  ✅ Permissions granted'; END $$;

-- ====================
-- Final Notice
-- ====================

DO $$ BEGIN RAISE NOTICE '🎉 Ready for MeetShipper Real-Time Chat!'; END $$;
