-- ============================================================================
-- CORRECTED FINAL FIX: Chat Room RLS Policies
-- ============================================================================
-- SCHEMA REALITY:
-- - users table has: fid BIGINT PRIMARY KEY (NO id column)
-- - JWT claims contain: {"fid": 12345} (Farcaster ID)
-- - No Supabase auth.uid() - using custom session system
--
-- ROOT CAUSE:
-- Original RLS policies checked chat_participants which creates circular dependency
-- and fails for client-side queries before participants can be verified
--
-- SOLUTION:
-- Check MATCHES table directly using JWT fid claim
-- This is simpler, more reliable, and avoids circular dependencies
-- ============================================================================

DO $$ BEGIN RAISE NOTICE '🔧 Starting CORRECTED chat_rooms RLS fix...'; END $$;

-- ====================
-- STEP 1: Drop Incompatible Policies
-- ====================

DO $$ BEGIN RAISE NOTICE '🗑️  Step 1: Removing old RLS policies...'; END $$;

-- Drop all existing chat_rooms policies
DROP POLICY IF EXISTS "Users can view their chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Service role can manage chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Both participants can view chat room" ON chat_rooms;
DROP POLICY IF EXISTS "Both participants can update chat room" ON chat_rooms;
DROP POLICY IF EXISTS "System can create chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can view chat rooms for their matches" ON chat_rooms;
DROP POLICY IF EXISTS "Service role full access to chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can update chat rooms for their matches" ON chat_rooms;

DO $$ BEGIN RAISE NOTICE '  ✅ Dropped old chat_rooms policies'; END $$;

-- ====================
-- STEP 2: Create Match-Based RLS Policies (Using FID)
-- ====================

DO $$ BEGIN RAISE NOTICE '🔒 Step 2: Creating match-based RLS policies...'; END $$;

-- Policy: Users can view chat rooms for matches they're part of
-- Uses JWT fid claim to check matches table directly
CREATE POLICY "Users can view chat rooms for their matches"
ON chat_rooms
FOR SELECT
TO authenticated
USING (
  match_id IN (
    SELECT id FROM matches
    WHERE user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
       OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  )
);

DO $$ BEGIN RAISE NOTICE '  ✅ Created SELECT policy for chat_rooms'; END $$;

-- Policy: Service role can do everything (bypasses RLS anyway)
CREATE POLICY "Service role full access to chat rooms"
ON chat_rooms
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

DO $$ BEGIN RAISE NOTICE '  ✅ Created service_role policy for chat_rooms'; END $$;

-- Policy: Users can update chat rooms for their matches
CREATE POLICY "Users can update chat rooms for their matches"
ON chat_rooms
FOR UPDATE
TO authenticated
USING (
  match_id IN (
    SELECT id FROM matches
    WHERE user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
       OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  )
)
WITH CHECK (
  match_id IN (
    SELECT id FROM matches
    WHERE user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
       OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  )
);

DO $$ BEGIN RAISE NOTICE '  ✅ Created UPDATE policy for chat_rooms'; END $$;

-- ====================
-- STEP 3: Fix chat_participants Policies
-- ====================

DO $$ BEGIN RAISE NOTICE '🔒 Step 3: Updating chat_participants policies...'; END $$;

-- Drop old policies
DROP POLICY IF EXISTS "Users can view participants in their rooms" ON chat_participants;
DROP POLICY IF EXISTS "Service role can manage participants" ON chat_participants;
DROP POLICY IF EXISTS "Users can view participants for their matches" ON chat_participants;
DROP POLICY IF EXISTS "Service role full access to chat_participants" ON chat_participants;

-- Policy: View participants via matches
CREATE POLICY "Users can view participants for their matches"
ON chat_participants
FOR SELECT
TO authenticated
USING (
  room_id IN (
    SELECT id FROM chat_rooms
    WHERE match_id IN (
      SELECT id FROM matches
      WHERE user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
         OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
  )
);

DO $$ BEGIN RAISE NOTICE '  ✅ Created SELECT policy for chat_participants'; END $$;

-- Service role full access
CREATE POLICY "Service role full access to chat_participants"
ON chat_participants
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

DO $$ BEGIN RAISE NOTICE '  ✅ Created service_role policy for chat_participants'; END $$;

-- ====================
-- STEP 4: Fix chat_messages Policies (RENAMED TABLE!)
-- ====================

DO $$ BEGIN RAISE NOTICE '🔒 Step 4: Updating chat_messages policies...'; END $$;

-- Drop old policies on chat_messages
DROP POLICY IF EXISTS "Users can view messages in their rooms" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages in open rooms" ON chat_messages;
DROP POLICY IF EXISTS "Service role can manage messages" ON chat_messages;
DROP POLICY IF EXISTS "Both participants can view messages" ON chat_messages;
DROP POLICY IF EXISTS "Both participants can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update messages in their rooms" ON chat_messages;
DROP POLICY IF EXISTS "Users can view messages for their matches" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages in their match rooms" ON chat_messages;
DROP POLICY IF EXISTS "Service role full access to chat_messages" ON chat_messages;

-- View messages via matches
CREATE POLICY "Users can view messages for their matches"
ON chat_messages
FOR SELECT
TO authenticated
USING (
  room_id IN (
    SELECT id FROM chat_rooms
    WHERE match_id IN (
      SELECT id FROM matches
      WHERE user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
         OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
  )
);

DO $$ BEGIN RAISE NOTICE '  ✅ Created SELECT policy for chat_messages'; END $$;

-- Send messages (with room open check)
CREATE POLICY "Users can send messages in their match rooms"
ON chat_messages
FOR INSERT
TO authenticated
WITH CHECK (
  -- Must be in a chat room for a match they're part of
  room_id IN (
    SELECT cr.id FROM chat_rooms cr
    WHERE cr.match_id IN (
      SELECT m.id FROM matches m
      WHERE m.user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
         OR m.user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    )
    AND cr.is_closed = false
  )
  -- Sender FID must match JWT fid
  AND sender_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
);

DO $$ BEGIN RAISE NOTICE '  ✅ Created INSERT policy for chat_messages'; END $$;

-- Service role full access
CREATE POLICY "Service role full access to chat_messages"
ON chat_messages
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

DO $$ BEGIN RAISE NOTICE '  ✅ Created service_role policy for chat_messages'; END $$;

-- ====================
-- COMPLETION
-- ====================

DO $$ BEGIN RAISE NOTICE '✅ CORRECTED FIX COMPLETE!'; END $$;
DO $$ BEGIN RAISE NOTICE '📊 Summary:'; END $$;
DO $$ BEGIN RAISE NOTICE '   - chat_rooms: 3 policies (fid-based)'; END $$;
DO $$ BEGIN RAISE NOTICE '   - chat_participants: 2 policies (fid-based)'; END $$;
DO $$ BEGIN RAISE NOTICE '   - chat_messages: 3 policies (fid-based)'; END $$;
DO $$ BEGIN RAISE NOTICE '   - Uses JWT fid claim: current_setting(''request.jwt.claims'', true)::json->>''fid'''; END $$;
DO $$ BEGIN RAISE NOTICE '🎉 Both users can now see "Open Chat" button!'; END $$;

-- ====================
-- VERIFICATION QUERIES
-- ====================

-- Run these to verify the fix worked:

-- 1. Check policies exist
-- SELECT tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('chat_rooms', 'chat_participants', 'chat_messages')
-- ORDER BY tablename, cmd;

-- 2. Test JWT fid extraction (should return your Farcaster ID)
-- SELECT (current_setting('request.jwt.claims', true)::json->>'fid')::bigint;

-- 3. Test chat room access (should show rooms for your matches)
-- SELECT cr.id, cr.match_id, m.user_a_fid, m.user_b_fid
-- FROM chat_rooms cr
-- JOIN matches m ON m.id = cr.match_id
-- WHERE m.user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
--    OR m.user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint;
