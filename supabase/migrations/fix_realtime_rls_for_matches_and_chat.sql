-- ============================================================================
-- MeetShipper: Fix Realtime + RLS for Matches and Chat Rooms
-- ============================================================================
-- This migration ensures both users (user_a and user_b) can:
--   1. See matches and chat rooms via RLS policies
--   2. Receive realtime events when matches are accepted
--   3. See the "Open Chat" button simultaneously
-- ============================================================================

DO $$ BEGIN RAISE NOTICE '🚀 Starting Realtime + RLS migration...'; END $$;

-- ====================
-- STEP 1: Enable Realtime on Tables
-- ====================

DO $$ BEGIN RAISE NOTICE '📡 Step 1: Enabling realtime on tables...'; END $$;

-- Enable realtime for matches table
ALTER TABLE matches REPLICA IDENTITY FULL;

-- Enable realtime for chat_rooms table
ALTER TABLE chat_rooms REPLICA IDENTITY FULL;


-- ====================
-- STEP 2: Add Tables to Realtime Publication
-- ====================

DO $$ BEGIN RAISE NOTICE '📢 Step 2: Adding tables to realtime publication...'; END $$;

-- Add tables to the realtime publication
-- Note: Supabase uses 'supabase_realtime' as the default publication name
DO $$
BEGIN
    -- Add matches table to publication (if not already added)
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'matches'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE matches;
        RAISE NOTICE 'Added matches to supabase_realtime publication';
    ELSE
        RAISE NOTICE 'matches already in supabase_realtime publication';
    END IF;

    -- Add chat_rooms table to publication (if not already added)
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'chat_rooms'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;
        RAISE NOTICE 'Added chat_rooms to supabase_realtime publication';
    ELSE
        RAISE NOTICE 'chat_rooms already in supabase_realtime publication';
    END IF;
END $$;


-- ====================
-- STEP 3: RLS Policies for Matches Table
-- ====================

DO $$ BEGIN RAISE NOTICE '🔒 Step 3: Creating RLS policies for matches table...'; END $$;

-- Enable RLS on matches table (if not already enabled)
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own matches" ON matches;
DROP POLICY IF EXISTS "Users can view matches they are part of" ON matches;
DROP POLICY IF EXISTS "Allow users to see their matches" ON matches;
DROP POLICY IF EXISTS "Both participants can view match" ON matches;
DROP POLICY IF EXISTS "Users can update their match response" ON matches;
DROP POLICY IF EXISTS "Users can create matches" ON matches;

-- Policy: Both user_a and user_b can SELECT their matches
CREATE POLICY "Both participants can view match"
ON matches
FOR SELECT
TO authenticated
USING (
    -- Allow if the authenticated user is either user_a or user_b
    (auth.uid() IN (
        SELECT id FROM users WHERE fid = matches.user_a_fid
    ))
    OR
    (auth.uid() IN (
        SELECT id FROM users WHERE fid = matches.user_b_fid
    ))
    OR
    -- Also allow the creator to see the match
    (auth.uid() IN (
        SELECT id FROM users WHERE fid = matches.created_by_fid
    ))
);

-- Policy: Users can update their own acceptance status
CREATE POLICY "Users can update their match response"
ON matches
FOR UPDATE
TO authenticated
USING (
    (auth.uid() IN (
        SELECT id FROM users WHERE fid = matches.user_a_fid
    ))
    OR
    (auth.uid() IN (
        SELECT id FROM users WHERE fid = matches.user_b_fid
    ))
)
WITH CHECK (
    (auth.uid() IN (
        SELECT id FROM users WHERE fid = matches.user_a_fid
    ))
    OR
    (auth.uid() IN (
        SELECT id FROM users WHERE fid = matches.user_b_fid
    ))
);

-- Policy: Allow creators to INSERT matches
CREATE POLICY "Users can create matches"
ON matches
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM users WHERE fid = matches.created_by_fid
    )
);


-- ====================
-- STEP 4: RLS Policies for Chat Rooms Table
-- ====================

DO $$ BEGIN RAISE NOTICE '🔒 Step 4: Creating RLS policies for chat_rooms table...'; END $$;

-- Enable RLS on chat_rooms table (if not already enabled)
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Allow users to see their chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Both participants can view chat room" ON chat_rooms;
DROP POLICY IF EXISTS "Both participants can update chat room" ON chat_rooms;
DROP POLICY IF EXISTS "System can create chat rooms" ON chat_rooms;

-- Policy: Both participants can SELECT their chat room
CREATE POLICY "Both participants can view chat room"
ON chat_rooms
FOR SELECT
TO authenticated
USING (
    -- Allow if the authenticated user is part of the match
    match_id IN (
        SELECT id FROM matches
        WHERE
            (user_a_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
            OR
            (user_b_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
    )
);

-- Policy: Both participants can UPDATE their chat room (e.g., mark as read, update state)
CREATE POLICY "Both participants can update chat room"
ON chat_rooms
FOR UPDATE
TO authenticated
USING (
    match_id IN (
        SELECT id FROM matches
        WHERE
            (user_a_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
            OR
            (user_b_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
    )
)
WITH CHECK (
    match_id IN (
        SELECT id FROM matches
        WHERE
            (user_a_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
            OR
            (user_b_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
    )
);

-- Policy: System can INSERT chat rooms (usually done via backend/trigger)
CREATE POLICY "System can create chat rooms"
ON chat_rooms
FOR INSERT
TO authenticated
WITH CHECK (true);  -- Adjust as needed for your use case


-- ====================
-- STEP 5: RLS Policies for Messages Table
-- ====================

DO $$ BEGIN RAISE NOTICE '🔒 Step 5: Creating RLS policies for messages table...'; END $$;

-- Enable RLS on messages table (if not already enabled)
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view messages in their rooms" ON messages;
DROP POLICY IF EXISTS "Users can insert messages in their rooms" ON messages;
DROP POLICY IF EXISTS "Both participants can view messages" ON messages;
DROP POLICY IF EXISTS "Both participants can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update messages in their rooms" ON messages;

-- Policy: Both participants can SELECT messages from their chat rooms
CREATE POLICY "Both participants can view messages"
ON messages
FOR SELECT
TO authenticated
USING (
    room_id IN (
        SELECT id FROM chat_rooms
        WHERE match_id IN (
            SELECT id FROM matches
            WHERE
                (user_a_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
                OR
                (user_b_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
        )
    )
);

-- Policy: Both participants can INSERT messages into their chat rooms
CREATE POLICY "Both participants can send messages"
ON messages
FOR INSERT
TO authenticated
WITH CHECK (
    room_id IN (
        SELECT id FROM chat_rooms
        WHERE match_id IN (
            SELECT id FROM matches
            WHERE
                (user_a_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
                OR
                (user_b_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
        )
    )
);

-- Policy: Users can UPDATE their own messages (e.g., mark as read)
CREATE POLICY "Users can update messages in their rooms"
ON messages
FOR UPDATE
TO authenticated
USING (
    room_id IN (
        SELECT id FROM chat_rooms
        WHERE match_id IN (
            SELECT id FROM matches
            WHERE
                (user_a_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
                OR
                (user_b_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
        )
    )
)
WITH CHECK (
    room_id IN (
        SELECT id FROM chat_rooms
        WHERE match_id IN (
            SELECT id FROM matches
            WHERE
                (user_a_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
                OR
                (user_b_fid IN (SELECT fid FROM users WHERE id = auth.uid()))
        )
    )
);


-- ====================
-- STEP 6: Add Messages to Realtime Publication
-- ====================

DO $$ BEGIN RAISE NOTICE '📢 Step 6: Adding messages table to realtime publication...'; END $$;

-- Enable realtime for messages table
ALTER TABLE messages REPLICA IDENTITY FULL;

-- Add messages to realtime publication
DO $$
BEGIN
    -- Add messages table to publication (if not already added)
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE messages;
        RAISE NOTICE 'Added messages to supabase_realtime publication';
    ELSE
        RAISE NOTICE 'messages already in supabase_realtime publication';
    END IF;
END $$;


-- ====================
-- STEP 7: Grant Permissions
-- ====================

DO $$ BEGIN RAISE NOTICE '🔑 Step 7: Granting permissions...'; END $$;

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE ON matches TO authenticated;
GRANT SELECT, INSERT, UPDATE ON chat_rooms TO authenticated;
GRANT SELECT, INSERT, UPDATE ON messages TO authenticated;

-- Grant usage on sequences (if applicable)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ====================
-- MIGRATION COMPLETE!
-- ====================

DO $$ BEGIN RAISE NOTICE '✅ Migration completed successfully!'; END $$;
DO $$ BEGIN RAISE NOTICE '📊 Summary:'; END $$;
DO $$ BEGIN RAISE NOTICE '   - 3 tables enabled for realtime (matches, chat_rooms, messages)'; END $$;
DO $$ BEGIN RAISE NOTICE '   - 9 RLS policies created (3 per table)'; END $$;
DO $$ BEGIN RAISE NOTICE '   - All tables added to supabase_realtime publication'; END $$;
DO $$ BEGIN RAISE NOTICE '🎉 Both users should now see "Open Chat" button simultaneously!'; END $$;


-- ====================
-- STEP 8: Verify Configuration (Optional)
-- ====================

-- Run these queries to verify the configuration:

-- Check if realtime is enabled on tables
-- SELECT schemaname, tablename
-- FROM pg_tables
-- WHERE tablename IN ('matches', 'chat_rooms', 'messages');

-- Check publication contents
-- SELECT * FROM pg_publication_tables
-- WHERE pubname = 'supabase_realtime';

-- Check RLS policies
-- SELECT tablename, policyname, cmd, qual
-- FROM pg_policies
-- WHERE tablename IN ('matches', 'chat_rooms', 'messages');


-- ====================
-- NOTES
-- ====================

/*
IMPORTANT NOTES:

1. REPLICA IDENTITY FULL:
   - This ensures that realtime events include all column values
   - This is crucial for RLS to work properly with realtime subscriptions

2. RLS Policy Logic:
   - The policies use auth.uid() to check if the current user is part of the match
   - Both user_a and user_b can access their shared match and chat room
   - This ensures both participants receive realtime events

3. Realtime Publication:
   - Tables must be added to 'supabase_realtime' publication
   - Supabase uses this publication for broadcasting changes

4. Testing:
   - After running this migration, test by creating a match
   - Both users should see realtime updates when match status changes to 'accepted'
   - Both users should see the "Open Chat" button simultaneously

5. Frontend Requirements:
   - The frontend realtime listener should NOT filter by user_a_fid or user_b_fid
   - Instead, always call fetchMatches() when receiving an 'accepted' status update
   - Let RLS handle the filtering on the backend

6. If you encounter issues:
   - Check Supabase Dashboard > Database > Replication
   - Ensure the publication includes your tables
   - Check Supabase Dashboard > Authentication > Policies
   - Verify all RLS policies are active
*/
