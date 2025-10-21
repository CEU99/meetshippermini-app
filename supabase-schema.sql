-- =====================================================================
-- Meet Shipper Database Schema for Supabase (Idempotent)
-- =====================================================================
-- Run this SQL in your Supabase SQL Editor
-- Safe to run multiple times - checks for existing objects
-- =====================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================
-- TABLES
-- =====================================================================

-- Users Table
-- Stores Farcaster user information
CREATE TABLE IF NOT EXISTS public.users (
    fid BIGINT PRIMARY KEY,
    username TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on username for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);

-- Matches Table
-- Stores match/introduction records
CREATE TABLE IF NOT EXISTS public.matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
    user_b_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
    created_by_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending',
    message TEXT,
    a_accepted BOOLEAN DEFAULT FALSE,
    b_accepted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Ensure user_a and user_b are different
    CONSTRAINT different_users CHECK (user_a_fid != user_b_fid)
);

-- Add status constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'matches_status_check'
          AND conrelid = 'public.matches'::regclass
    ) THEN
        ALTER TABLE public.matches
        ADD CONSTRAINT matches_status_check
        CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled'));
    END IF;
END $$;

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_matches_user_a ON public.matches(user_a_fid);
CREATE INDEX IF NOT EXISTS idx_matches_user_b ON public.matches(user_b_fid);
CREATE INDEX IF NOT EXISTS idx_matches_creator ON public.matches(created_by_fid);
CREATE INDEX IF NOT EXISTS idx_matches_status ON public.matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_created_at ON public.matches(created_at DESC);

-- Messages Table
-- Stores chat messages between matched users
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    sender_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_system_message BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for faster message retrieval
CREATE INDEX IF NOT EXISTS idx_messages_match_id ON public.messages(match_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_fid);

-- User Friends Cache (Optional)
-- Cache Farcaster follow relationships to reduce API calls
CREATE TABLE IF NOT EXISTS public.user_friends (
    user_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
    friend_fid BIGINT NOT NULL,
    friend_username TEXT NOT NULL,
    friend_display_name TEXT,
    friend_avatar_url TEXT,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_fid, friend_fid)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_friends_user ON public.user_friends(user_fid);
CREATE INDEX IF NOT EXISTS idx_user_friends_cached_at ON public.user_friends(cached_at);

-- =====================================================================
-- FUNCTIONS
-- =====================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to automatically update match status when both users accept
CREATE OR REPLACE FUNCTION public.update_match_status()
RETURNS TRIGGER AS $$
BEGIN
    -- If both users have accepted, update status to 'accepted'
    IF NEW.a_accepted = TRUE AND NEW.b_accepted = TRUE THEN
        NEW.status = 'accepted';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to insert initial system message when a match is created
CREATE OR REPLACE FUNCTION public.create_initial_match_message()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.messages (match_id, sender_fid, content, is_system_message)
    VALUES (
        NEW.id,
        NEW.created_by_fid,
        CONCAT('Match created! ',
               (SELECT username FROM public.users WHERE fid = NEW.created_by_fid),
               ' has introduced you both.',
               CASE WHEN NEW.message IS NOT NULL AND NEW.message != ''
                    THEN CONCAT(' Message: ', NEW.message)
                    ELSE ''
               END),
        TRUE
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- TRIGGERS
-- =====================================================================

-- Trigger for users table (updated_at)
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger for matches table (updated_at)
DROP TRIGGER IF EXISTS update_matches_updated_at ON public.matches;
CREATE TRIGGER update_matches_updated_at
    BEFORE UPDATE ON public.matches
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger to update match status
DROP TRIGGER IF EXISTS check_match_acceptance ON public.matches;
CREATE TRIGGER check_match_acceptance
    BEFORE UPDATE ON public.matches
    FOR EACH ROW
    EXECUTE FUNCTION public.update_match_status();

-- Trigger to create initial message
DROP TRIGGER IF EXISTS create_match_notification ON public.matches;
CREATE TRIGGER create_match_notification
    AFTER INSERT ON public.matches
    FOR EACH ROW
    EXECUTE FUNCTION public.create_initial_match_message();

-- =====================================================================
-- VIEWS (Drop and Recreate to avoid column conflicts)
-- =====================================================================

-- View to get match details with user information
DROP VIEW IF EXISTS public.match_details;
CREATE VIEW public.match_details AS
SELECT
    m.id,
    m.user_a_fid,
    ua.username as user_a_username,
    ua.display_name as user_a_display_name,
    ua.avatar_url as user_a_avatar_url,
    m.user_b_fid,
    ub.username as user_b_username,
    ub.display_name as user_b_display_name,
    ub.avatar_url as user_b_avatar_url,
    m.created_by_fid,
    uc.username as creator_username,
    uc.display_name as creator_display_name,
    uc.avatar_url as creator_avatar_url,
    m.status,
    m.message,
    m.a_accepted,
    m.b_accepted,
    m.created_at,
    m.updated_at
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
LEFT JOIN public.users uc ON m.created_by_fid = uc.fid;

-- View to get message details with sender information
DROP VIEW IF EXISTS public.message_details;
CREATE VIEW public.message_details AS
SELECT
    msg.id,
    msg.match_id,
    msg.sender_fid,
    u.username as sender_username,
    u.display_name as sender_display_name,
    u.avatar_url as sender_avatar_url,
    msg.content,
    msg.is_system_message,
    msg.created_at
FROM public.messages msg
LEFT JOIN public.users u ON msg.sender_fid = u.fid;

-- =====================================================================
-- COMMENTS
-- =====================================================================

COMMENT ON TABLE public.users IS 'Stores Farcaster user information';
COMMENT ON TABLE public.matches IS 'Stores match/introduction records between users';
COMMENT ON TABLE public.messages IS 'Stores chat messages between matched users';
COMMENT ON TABLE public.user_friends IS 'Caches Farcaster follow relationships';

-- =====================================================================
-- ROW LEVEL SECURITY (Optional - Commented Out)
-- =====================================================================
-- Note: These are optional since we're handling auth via Farcaster
-- Uncomment if you want to use Supabase RLS

-- ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.user_friends ENABLE ROW LEVEL SECURITY;

-- Example RLS Policies (if using Supabase Auth with Farcaster JWT)
-- Users can read all user profiles
-- CREATE POLICY "Users can read all profiles" ON public.users FOR SELECT USING (true);

-- Users can only update their own profile
-- CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE
--   USING (auth.uid()::text = fid::text);

-- Users can view matches they're involved in
-- CREATE POLICY "Users can view their matches" ON public.matches FOR SELECT
--   USING (user_a_fid = auth.uid()::bigint OR user_b_fid = auth.uid()::bigint
--          OR created_by_fid = auth.uid()::bigint);

-- Users can create matches
-- CREATE POLICY "Users can create matches" ON public.matches FOR INSERT
--   WITH CHECK (created_by_fid = auth.uid()::bigint);

-- Users can update matches they're part of
-- CREATE POLICY "Users can update their matches" ON public.matches FOR UPDATE
--   USING (user_a_fid = auth.uid()::bigint OR user_b_fid = auth.uid()::bigint);

-- =====================================================================
-- GRANTS (Optional - Adjust as needed)
-- =====================================================================
-- Uncomment if you need to grant permissions

-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO anon, authenticated;
-- GRANT SELECT ON ALL VIEWS IN SCHEMA public TO anon, authenticated;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- =====================================================================
-- VERIFICATION
-- =====================================================================

-- Show all tables
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('users', 'matches', 'messages', 'user_friends')
ORDER BY tablename;

-- Show all views
SELECT
    schemaname,
    viewname,
    viewowner
FROM pg_views
WHERE schemaname = 'public'
  AND viewname IN ('match_details', 'message_details')
ORDER BY viewname;

-- Show all functions
SELECT
    n.nspname as schema,
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN ('update_updated_at_column', 'update_match_status', 'create_initial_match_message')
ORDER BY p.proname;

-- =====================================================================
-- SUCCESS MESSAGE
-- =====================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=============================================================';
    RAISE NOTICE '✅ BASE SCHEMA CREATED SUCCESSFULLY!';
    RAISE NOTICE '=============================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables created:';
    RAISE NOTICE '  • users (Farcaster user information)';
    RAISE NOTICE '  • matches (match/introduction records)';
    RAISE NOTICE '  • messages (chat messages)';
    RAISE NOTICE '  • user_friends (follow relationships cache)';
    RAISE NOTICE '';
    RAISE NOTICE 'Views created:';
    RAISE NOTICE '  • match_details (enriched match data)';
    RAISE NOTICE '  • message_details (enriched message data)';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Run supabase-user-code-complete.sql';
    RAISE NOTICE '  2. Run supabase-add-profile-fields-v2.sql';
    RAISE NOTICE '  3. Run supabase-matchmaking-system.sql';
    RAISE NOTICE '  4. Run supabase-fix-match-triggers.sql';
    RAISE NOTICE '';
    RAISE NOTICE '=============================================================';
END $$;
