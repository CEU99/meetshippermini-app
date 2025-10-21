-- Create chat_rooms table
CREATE TABLE IF NOT EXISTS chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  first_join_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  ttl_seconds INTEGER NOT NULL DEFAULT 7200, -- 2 hours
  is_closed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create chat_participants table
CREATE TABLE IF NOT EXISTS chat_participants (
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (room_id, fid)
);

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_chat_rooms_match_id ON chat_rooms(match_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_is_closed ON chat_rooms(is_closed);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_first_join_at ON chat_rooms(first_join_at);
CREATE INDEX IF NOT EXISTS idx_chat_participants_fid ON chat_participants(fid);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(room_id, created_at DESC);

-- Add updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_chat_rooms_updated_at
  BEFORE UPDATE ON chat_rooms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_participants_updated_at
  BEFORE UPDATE ON chat_participants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chat_rooms
-- Users can only select rooms they are participants of
CREATE POLICY "Users can view their chat rooms"
  ON chat_rooms
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_participants
      WHERE chat_participants.room_id = chat_rooms.id
        AND chat_participants.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
  );

-- Service role can do anything (no policy needed, bypasses RLS)
-- But for explicit operations, we can add:
CREATE POLICY "Service role can manage chat rooms"
  ON chat_rooms
  FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role')
  WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

-- RLS Policies for chat_participants
-- Users can view participants in rooms they're part of
CREATE POLICY "Users can view participants in their rooms"
  ON chat_participants
  FOR SELECT
  USING (
    fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR EXISTS (
      SELECT 1 FROM chat_participants cp
      WHERE cp.room_id = chat_participants.room_id
        AND cp.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
  );

-- Service role can manage participants
CREATE POLICY "Service role can manage participants"
  ON chat_participants
  FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role')
  WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

-- RLS Policies for chat_messages
-- Users can view messages in rooms they're participants of
CREATE POLICY "Users can view messages in their rooms"
  ON chat_messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_participants
      WHERE chat_participants.room_id = chat_messages.room_id
        AND chat_participants.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
  );

-- Users can insert messages only if:
-- 1. They are participants of the room
-- 2. The room is not closed
-- 3. TTL has not expired (if first_join_at is set)
CREATE POLICY "Users can send messages in open rooms"
  ON chat_messages
  FOR INSERT
  WITH CHECK (
    sender_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    AND EXISTS (
      SELECT 1 FROM chat_participants
      WHERE chat_participants.room_id = chat_messages.room_id
        AND chat_participants.fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
    AND EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE chat_rooms.id = chat_messages.room_id
        AND chat_rooms.is_closed = false
        AND (
          chat_rooms.first_join_at IS NULL
          OR now() <= (chat_rooms.first_join_at + (chat_rooms.ttl_seconds || ' seconds')::interval)
        )
    )
  );

-- Service role can manage messages
CREATE POLICY "Service role can manage messages"
  ON chat_messages
  FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role')
  WITH CHECK (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

-- Enable realtime for chat_messages
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- Function to check if room is expired (for use in triggers/cron)
CREATE OR REPLACE FUNCTION is_room_expired(room_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  room_record RECORD;
BEGIN
  SELECT first_join_at, ttl_seconds, is_closed
  INTO room_record
  FROM chat_rooms
  WHERE id = room_id;

  IF NOT FOUND OR room_record.is_closed THEN
    RETURN true;
  END IF;

  IF room_record.first_join_at IS NULL THEN
    RETURN false;
  END IF;

  RETURN now() > (room_record.first_join_at + (room_record.ttl_seconds || ' seconds')::interval);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to auto-close expired rooms (to be called by pg_cron)
CREATE OR REPLACE FUNCTION close_expired_chat_rooms()
RETURNS INTEGER AS $$
DECLARE
  closed_count INTEGER;
BEGIN
  WITH updated_rooms AS (
    UPDATE chat_rooms
    SET is_closed = true,
        closed_at = now()
    WHERE is_closed = false
      AND first_join_at IS NOT NULL
      AND now() > (first_join_at + (ttl_seconds || ' seconds')::interval)
    RETURNING id, match_id
  ),
  updated_matches AS (
    UPDATE matches
    SET status = 'completed',
        completed_at = now()
    WHERE id IN (SELECT match_id FROM updated_rooms)
      AND status != 'completed'
    RETURNING id
  )
  SELECT COUNT(*) INTO closed_count FROM updated_rooms;

  RETURN closed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON chat_rooms TO service_role;
GRANT ALL ON chat_participants TO service_role;
GRANT ALL ON chat_messages TO service_role;
GRANT SELECT ON chat_rooms TO authenticated;
GRANT SELECT ON chat_participants TO authenticated;
GRANT SELECT, INSERT ON chat_messages TO authenticated;
