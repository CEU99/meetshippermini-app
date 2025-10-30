-- ============================================================================
-- FINAL FIX: Chat Room RLS Policies
-- ============================================================================
-- ROOT CAUSE ANALYSIS:
-- The chat_rooms RLS policy checks chat_participants and uses JWT claims:
--   current_setting('request.jwt.claims', true)::json->>'fid'
--
-- This FAILS for client-side queries because:
-- 1. JWT structure might not have 'fid' claim
-- 2. Client auth might use different claim structure
-- 3. The check happens BEFORE participants can be queried
--
-- SOLUTION:
-- Check the MATCHES table instead, since:
-- 1. Users must be part of a match to see its chat room
-- 2. Matches table has proper RLS already
-- 3. Simpler, more reliable check
-- ============================================================================

DO $$ BEGIN RAISE NOTICE '🔧 Starting FINAL chat_rooms RLS fix...'; END $$;

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

-- ====================
-- STEP 2: Create Match-Based RLS Policies
-- ====================

DO $$ BEGIN RAISE NOTICE '🔒 Step 2: Creating match-based RLS policies...'; END $$;

-- Policy: Users can view chat rooms for matches they're part of
CREATE POLICY "Users can view chat rooms for their matches"
ON chat_rooms
FOR SELECT
TO authenticated
USING (
  match_id IN (
    SELECT id FROM matches
    WHERE EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
        AND (users.fid = matches.user_a_fid OR users.fid = matches.user_b_fid)
    )
  )
);

DO $$ BEGIN RAISE NOTICE '  ✅ Created SELECT policy for chat_rooms'; END $$;

-- Policy: Service role can do everything (bypasses RLS anyway, but explicit is good)
CREATE POLICY "Service role full access to chat rooms"
ON chat_rooms
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

DO $$ BEGIN RAISE NOTICE '  ✅ Created service_role policy for chat_rooms'; END $$;

-- Policy: Authenticated users can update chat rooms for their matches
CREATE POLICY "Users can update chat rooms for their matches"
ON chat_rooms
FOR UPDATE
TO authenticated
USING (
  match_id IN (
    SELECT id FROM matches
    WHERE EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
        AND (users.fid = matches.user_a_fid OR users.fid = matches.user_b_fid)
    )
  )
)
WITH CHECK (
  match_id IN (
    SELECT id FROM matches
    WHERE EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
        AND (users.fid = matches.user_a_fid OR users.fid = matches.user_b_fid)
    )
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

-- New policy: View participants via matches
CREATE POLICY "Users can view participants for their matches"
ON chat_participants
FOR SELECT
TO authenticated
USING (
  room_id IN (
    SELECT id FROM chat_rooms
    WHERE match_id IN (
      SELECT id FROM matches
      WHERE EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
          AND (users.fid = matches.user_a_fid OR users.fid = matches.user_b_fid)
      )
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
-- STEP 4: Fix chat_messages Policies
-- ====================

DO $$ BEGIN RAISE NOTICE '🔒 Step 4: Updating chat_messages policies...'; END $$;

-- Drop old policies
DROP POLICY IF EXISTS "Users can view messages in their rooms" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages in open rooms" ON chat_messages;
DROP POLICY IF EXISTS "Service role can manage messages" ON chat_messages;
DROP POLICY IF EXISTS "Both participants can view messages" ON chat_messages;
DROP POLICY IF EXISTS "Both participants can send messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update messages in their rooms" ON chat_messages;

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
      WHERE EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
          AND (users.fid = matches.user_a_fid OR users.fid = matches.user_b_fid)
      )
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
      WHERE EXISTS (
        SELECT 1 FROM users u
        WHERE u.id = auth.uid()
          AND (u.fid = m.user_a_fid OR u.fid = m.user_b_fid)
      )
    )
    AND cr.is_closed = false
  )
  -- Sender FID must match authenticated user
  AND sender_fid IN (
    SELECT fid FROM users WHERE id = auth.uid()
  )
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

DO $$ BEGIN RAISE NOTICE '✅ FINAL FIX COMPLETE!'; END $$;
DO $$ BEGIN RAISE NOTICE '📊 Summary:'; END $$;
DO $$ BEGIN RAISE NOTICE '   - chat_rooms: 3 policies (match-based)'; END $$;
DO $$ BEGIN RAISE NOTICE '   - chat_participants: 2 policies (match-based)'; END $$;
DO $$ BEGIN RAISE NOTICE '   - chat_messages: 3 policies (match-based)'; END $$;
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

-- 2. Test as authenticated user (replace with actual user ID)
-- SET ROLE authenticated;
-- SET request.jwt.claims = '{"sub": "YOUR_USER_UUID"}';
-- SELECT * FROM chat_rooms LIMIT 1;
-- RESET ROLE;
