-- ============================================================================
-- MEET SHIPPER - MASTER DATABASE SETUP
-- ============================================================================
-- Complete one-shot setup for a fresh Supabase database
-- Run this in: Supabase Dashboard → SQL Editor
-- Safe to run multiple times (idempotent)
-- ============================================================================

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo 'MEET SHIPPER - MASTER DATABASE SETUP'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo ''

-- ============================================================================
-- STEP 1: EXTENSIONS
-- ============================================================================

\echo 'Step 1: Enabling extensions...'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search
\echo '✅ Extensions enabled'
\echo ''

-- ============================================================================
-- STEP 2: CORE TABLES
-- ============================================================================

\echo 'Step 2: Creating core tables...'

-- Users Table
CREATE TABLE IF NOT EXISTS public.users (
    fid BIGINT PRIMARY KEY,
    username TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    traits JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_traits ON public.users USING GIN (traits);
CREATE INDEX IF NOT EXISTS idx_users_bio ON public.users USING GIN (to_tsvector('english', bio)) WHERE bio IS NOT NULL;

-- Matches Table
CREATE TABLE IF NOT EXISTS public.matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_a_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
    user_b_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
    created_by_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
    created_by TEXT DEFAULT 'system',
    status TEXT NOT NULL DEFAULT 'pending',
    message TEXT,
    rationale JSONB,
    a_accepted BOOLEAN DEFAULT FALSE,
    b_accepted BOOLEAN DEFAULT FALSE,
    a_completed BOOLEAN DEFAULT FALSE,
    b_completed BOOLEAN DEFAULT FALSE,
    meeting_link TEXT,
    scheduled_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT different_users CHECK (user_a_fid != user_b_fid)
);

-- Update status constraint
DO $$
BEGIN
    ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS matches_status_check;
    ALTER TABLE public.matches
        ADD CONSTRAINT matches_status_check
        CHECK (status IN (
            'proposed', 'pending',
            'accepted_by_a', 'accepted_by_b', 'accepted',
            'declined', 'cancelled', 'completed'
        ));
EXCEPTION WHEN OTHERS THEN
    NULL; -- Constraint may already exist
END $$;

CREATE INDEX IF NOT EXISTS idx_matches_user_a ON public.matches(user_a_fid);
CREATE INDEX IF NOT EXISTS idx_matches_user_b ON public.matches(user_b_fid);
CREATE INDEX IF NOT EXISTS idx_matches_creator ON public.matches(created_by_fid);
CREATE INDEX IF NOT EXISTS idx_matches_status ON public.matches(status);
CREATE INDEX IF NOT EXISTS idx_matches_created_at ON public.matches(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_matches_created_by ON public.matches(created_by);
CREATE INDEX IF NOT EXISTS idx_matches_rationale ON public.matches USING GIN (rationale);
CREATE INDEX IF NOT EXISTS idx_matches_scheduled_at ON public.matches(scheduled_at) WHERE scheduled_at IS NOT NULL;

-- Messages Table (legacy, for backward compatibility)
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    sender_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_system_message BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_match_id ON public.messages(match_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_fid);

-- User Friends Cache
CREATE TABLE IF NOT EXISTS public.user_friends (
    user_fid BIGINT NOT NULL REFERENCES public.users(fid) ON DELETE CASCADE,
    friend_fid BIGINT NOT NULL,
    friend_username TEXT NOT NULL,
    friend_display_name TEXT,
    friend_avatar_url TEXT,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_fid, friend_fid)
);

CREATE INDEX IF NOT EXISTS idx_user_friends_user ON public.user_friends(user_fid);
CREATE INDEX IF NOT EXISTS idx_user_friends_cached_at ON public.user_friends(cached_at);

\echo '✅ Core tables created'
\echo ''

-- ============================================================================
-- STEP 3: MATCHMAKING SYSTEM
-- ============================================================================

\echo 'Step 3: Creating matchmaking system...'

-- Match Cooldowns Table
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

-- Auto Match Runs Table
CREATE TABLE IF NOT EXISTS public.auto_match_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    users_processed INT DEFAULT 0,
    matches_created INT DEFAULT 0,
    status TEXT DEFAULT 'running' CHECK (status IN ('running','completed','failed')),
    error_message TEXT
);

\echo '✅ Matchmaking tables created'
\echo ''

-- ============================================================================
-- STEP 4: CHAT SYSTEM
-- ============================================================================

\echo 'Step 4: Creating chat system...'

-- Chat Rooms Table
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

CREATE INDEX IF NOT EXISTS idx_chat_rooms_match_id ON chat_rooms(match_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_is_closed ON chat_rooms(is_closed);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_first_join_at ON chat_rooms(first_join_at);

-- Chat Participants Table
CREATE TABLE IF NOT EXISTS chat_participants (
    room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (room_id, fid)
);

CREATE INDEX IF NOT EXISTS idx_chat_participants_fid ON chat_participants(fid);

-- Chat Messages Table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(room_id, created_at DESC);

\echo '✅ Chat tables created'
\echo ''

-- ============================================================================
-- STEP 5: MATCH SUGGESTIONS
-- ============================================================================

\echo 'Step 5: Creating match suggestions system...'

-- Match Suggestions Table
CREATE TABLE IF NOT EXISTS match_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
    user_a_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
    user_b_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'proposed' CHECK (
        status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'accepted', 'declined', 'cancelled')
    ),
    a_accepted BOOLEAN NOT NULL DEFAULT false,
    b_accepted BOOLEAN NOT NULL DEFAULT false,
    chat_room_id UUID REFERENCES chat_rooms(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT different_users CHECK (user_a_fid != user_b_fid),
    CONSTRAINT different_from_creator CHECK (
        created_by_fid != user_a_fid AND created_by_fid != user_b_fid
    )
);

CREATE INDEX IF NOT EXISTS idx_match_suggestions_user_a ON match_suggestions(user_a_fid);
CREATE INDEX IF NOT EXISTS idx_match_suggestions_user_b ON match_suggestions(user_b_fid);
CREATE INDEX IF NOT EXISTS idx_match_suggestions_creator ON match_suggestions(created_by_fid);
CREATE INDEX IF NOT EXISTS idx_match_suggestions_status ON match_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_match_suggestions_created_at ON match_suggestions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_match_suggestions_chat_room ON match_suggestions(chat_room_id);

CREATE INDEX IF NOT EXISTS idx_match_suggestions_pair_status ON match_suggestions(
    LEAST(user_a_fid, user_b_fid),
    GREATEST(user_a_fid, user_b_fid),
    status
) WHERE status NOT IN ('declined', 'cancelled');

CREATE UNIQUE INDEX IF NOT EXISTS idx_match_suggestions_unique_pending_pair ON match_suggestions(
    LEAST(user_a_fid, user_b_fid),
    GREATEST(user_a_fid, user_b_fid)
) WHERE status IN ('proposed', 'accepted_by_a', 'accepted_by_b');

-- Match Suggestion Cooldowns Table
CREATE TABLE IF NOT EXISTS match_suggestion_cooldowns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
    user_b_fid BIGINT NOT NULL REFERENCES users(fid) ON DELETE CASCADE,
    cooldown_until TIMESTAMPTZ NOT NULL,
    declined_suggestion_id UUID REFERENCES match_suggestions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT cooldown_different_users CHECK (user_a_fid != user_b_fid)
);

CREATE INDEX IF NOT EXISTS idx_match_cooldowns_pair ON match_suggestion_cooldowns(
    LEAST(user_a_fid, user_b_fid),
    GREATEST(user_a_fid, user_b_fid),
    cooldown_until
);

\echo '✅ Match suggestions tables created'
\echo ''

-- ============================================================================
-- STEP 6: CORE FUNCTIONS
-- ============================================================================

\echo 'Step 6: Creating core functions...'

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update match status on accepts
CREATE OR REPLACE FUNCTION public.update_match_status()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

-- Add cooldown after decline (FIXED VERSION)
CREATE OR REPLACE FUNCTION public.add_match_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_min_fid BIGINT;
    v_max_fid BIGINT;
BEGIN
    -- Only process when status changes TO 'declined'
    IF NEW.status = 'declined' AND (OLD.status IS NULL OR OLD.status IS DISTINCT FROM 'declined') THEN

        -- Normalize FID order: always store smaller FID first
        v_min_fid := LEAST(NEW.user_a_fid, NEW.user_b_fid);
        v_max_fid := GREATEST(NEW.user_a_fid, NEW.user_b_fid);

        -- Use INSERT ... ON CONFLICT with the unique index
        INSERT INTO public.match_cooldowns (
            user_a_fid,
            user_b_fid,
            declined_at,
            cooldown_until
        ) VALUES (
            v_min_fid,
            v_max_fid,
            NOW(),
            NOW() + INTERVAL '7 days'
        )
        ON CONFLICT ((LEAST(user_a_fid, user_b_fid)), (GREATEST(user_a_fid, user_b_fid)))
        DO UPDATE SET
            declined_at = NOW(),
            cooldown_until = GREATEST(
                match_cooldowns.cooldown_until,
                NOW() + INTERVAL '7 days'
            );

    END IF;

    RETURN NEW;
END;
$$;

-- Check if cooldown exists
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

-- Cleanup expired cooldowns
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

-- Get matchable users (bio + >=5 traits)
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

-- Count pending matches
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

-- Calculate trait similarity (Jaccard)
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

-- Chat: Check if room is expired
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

-- Chat: Auto-close expired rooms
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

-- Suggestions: Check cooldown
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
    v_min_fid := LEAST(p_user_a_fid, p_user_b_fid);
    v_max_fid := GREATEST(p_user_a_fid, p_user_b_fid);

    SELECT COUNT(*)
    INTO v_cooldown_count
    FROM match_suggestion_cooldowns
    WHERE LEAST(user_a_fid, user_b_fid) = v_min_fid
      AND GREATEST(user_a_fid, user_b_fid) = v_max_fid
      AND cooldown_until > now();

    RETURN v_cooldown_count = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Suggestions: Create cooldown after decline
CREATE OR REPLACE FUNCTION create_suggestion_cooldown()
RETURNS TRIGGER AS $$
BEGIN
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

-- Suggestions: Update status based on acceptance
CREATE OR REPLACE FUNCTION update_suggestion_status()
RETURNS TRIGGER AS $$
BEGIN
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

\echo '✅ Core functions created'
\echo ''

-- ============================================================================
-- STEP 7: TRIGGERS
-- ============================================================================

\echo 'Step 7: Creating triggers...'

-- Drop existing triggers to avoid conflicts
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_matches_updated_at ON public.matches;
DROP TRIGGER IF EXISTS check_match_acceptance ON public.matches;
DROP TRIGGER IF EXISTS match_declined_cooldown ON public.matches;
DROP TRIGGER IF EXISTS update_chat_rooms_updated_at ON chat_rooms;
DROP TRIGGER IF EXISTS update_chat_participants_updated_at ON chat_participants;
DROP TRIGGER IF EXISTS update_match_suggestions_updated_at ON match_suggestions;
DROP TRIGGER IF EXISTS trigger_create_suggestion_cooldown ON match_suggestions;
DROP TRIGGER IF EXISTS trigger_update_suggestion_status ON match_suggestions;

-- Users: updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Matches: updated_at
CREATE TRIGGER update_matches_updated_at
    BEFORE UPDATE ON public.matches
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Matches: status update on acceptance
CREATE TRIGGER check_match_acceptance
    BEFORE UPDATE ON public.matches
    FOR EACH ROW
    EXECUTE FUNCTION public.update_match_status();

-- Matches: cooldown on decline
CREATE TRIGGER match_declined_cooldown
    AFTER UPDATE ON public.matches
    FOR EACH ROW
    EXECUTE FUNCTION public.add_match_cooldown();

-- Chat rooms: updated_at
CREATE TRIGGER update_chat_rooms_updated_at
    BEFORE UPDATE ON chat_rooms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Chat participants: updated_at
CREATE TRIGGER update_chat_participants_updated_at
    BEFORE UPDATE ON chat_participants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Match suggestions: updated_at
CREATE TRIGGER update_match_suggestions_updated_at
    BEFORE UPDATE ON match_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Match suggestions: cooldown on decline
CREATE TRIGGER trigger_create_suggestion_cooldown
    AFTER UPDATE ON match_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION create_suggestion_cooldown();

-- Match suggestions: status update
CREATE TRIGGER trigger_update_suggestion_status
    BEFORE UPDATE ON match_suggestions
    FOR EACH ROW
    WHEN (OLD.a_accepted IS DISTINCT FROM NEW.a_accepted OR OLD.b_accepted IS DISTINCT FROM NEW.b_accepted)
    EXECUTE FUNCTION update_suggestion_status();

\echo '✅ Triggers created'
\echo ''

-- ============================================================================
-- STEP 8: FIX DECLINE 500 ERROR (CRITICAL)
-- ============================================================================

\echo 'Step 8: Applying decline 500 error fix...'

-- Clean up old constraints/indexes
DO $$
BEGIN
    ALTER TABLE public.match_cooldowns DROP CONSTRAINT IF EXISTS uniq_cooldown_pair CASCADE;
    DROP INDEX IF EXISTS public.uniq_cooldown_pair CASCADE;
    DROP INDEX IF EXISTS public.match_cooldowns_pair_unique CASCADE;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

-- Remove duplicate cooldowns
WITH ranked_cooldowns AS (
    SELECT id,
        ROW_NUMBER() OVER (
            PARTITION BY
                LEAST(user_a_fid, user_b_fid),
                GREATEST(user_a_fid, user_b_fid)
            ORDER BY declined_at DESC NULLS LAST, cooldown_until DESC
        ) as rn
    FROM public.match_cooldowns
)
DELETE FROM public.match_cooldowns
WHERE id IN (SELECT id FROM ranked_cooldowns WHERE rn > 1);

-- Create proper unique index with normalized FID order
CREATE UNIQUE INDEX IF NOT EXISTS uniq_cooldown_pair
    ON public.match_cooldowns (
        LEAST(user_a_fid, user_b_fid),
        GREATEST(user_a_fid, user_b_fid)
    );

\echo '✅ Decline 500 error fix applied'
\echo ''

-- ============================================================================
-- STEP 9: VIEWS
-- ============================================================================

\echo 'Step 9: Creating views...'

-- Match details view
DROP VIEW IF EXISTS public.match_details CASCADE;
CREATE VIEW public.match_details AS
SELECT
    m.id,
    m.user_a_fid,
    ua.username as user_a_username,
    ua.display_name as user_a_display_name,
    ua.avatar_url as user_a_avatar_url,
    ua.traits as user_a_traits,
    m.user_b_fid,
    ub.username as user_b_username,
    ub.display_name as user_b_display_name,
    ub.avatar_url as user_b_avatar_url,
    ub.traits as user_b_traits,
    m.created_by_fid,
    m.created_by,
    uc.username as creator_username,
    uc.display_name as creator_display_name,
    uc.avatar_url as creator_avatar_url,
    m.status,
    m.message,
    m.rationale,
    m.a_accepted,
    m.b_accepted,
    m.a_completed,
    m.b_completed,
    m.meeting_link,
    m.scheduled_at,
    m.completed_at,
    m.created_at,
    m.updated_at
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
LEFT JOIN public.users uc ON m.created_by_fid = uc.fid;

-- Message details view
DROP VIEW IF EXISTS public.message_details CASCADE;
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

-- Match suggestions with details view
DROP VIEW IF EXISTS match_suggestions_with_details CASCADE;
CREATE VIEW match_suggestions_with_details AS
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
    ua.username AS user_a_username,
    ua.display_name AS user_a_display_name,
    ua.avatar_url AS user_a_avatar_url,
    ub.username AS user_b_username,
    ub.display_name AS user_b_display_name,
    ub.avatar_url AS user_b_avatar_url
FROM match_suggestions ms
LEFT JOIN users ua ON ms.user_a_fid = ua.fid
LEFT JOIN users ub ON ms.user_b_fid = ub.fid;

\echo '✅ Views created'
\echo ''

-- ============================================================================
-- STEP 10: GRANTS & PERMISSIONS
-- ============================================================================

\echo 'Step 10: Setting up permissions...'

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- Core tables
GRANT ALL ON public.users TO service_role;
GRANT ALL ON public.matches TO service_role;
GRANT ALL ON public.messages TO service_role;
GRANT ALL ON public.user_friends TO service_role;
GRANT ALL ON public.match_cooldowns TO service_role;
GRANT ALL ON public.auto_match_runs TO service_role;

-- Chat tables
GRANT ALL ON chat_rooms TO service_role;
GRANT ALL ON chat_participants TO service_role;
GRANT ALL ON chat_messages TO service_role;

-- Suggestions tables
GRANT ALL ON match_suggestions TO service_role;
GRANT ALL ON match_suggestion_cooldowns TO service_role;

-- Views
GRANT SELECT ON public.match_details TO anon, authenticated, service_role;
GRANT SELECT ON public.message_details TO anon, authenticated, service_role;
GRANT SELECT ON match_suggestions_with_details TO authenticated, service_role;

-- Authenticated users
GRANT SELECT ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.matches TO authenticated;
GRANT SELECT, INSERT ON public.messages TO authenticated;
GRANT SELECT ON public.match_cooldowns TO authenticated;
GRANT SELECT ON chat_rooms TO authenticated;
GRANT SELECT ON chat_participants TO authenticated;
GRANT SELECT, INSERT ON chat_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE ON match_suggestions TO authenticated;
GRANT SELECT ON match_suggestion_cooldowns TO authenticated;

\echo '✅ Permissions configured'
\echo ''

-- ============================================================================
-- STEP 11: ENABLE REALTIME (Optional)
-- ============================================================================

\echo 'Step 11: Enabling realtime...'

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
EXCEPTION WHEN OTHERS THEN
    NULL; -- Publication may not exist or table already added
END $$;

\echo '✅ Realtime enabled (if available)'
\echo ''

-- ============================================================================
-- VERIFICATION & SUMMARY
-- ============================================================================

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '✅ MASTER SETUP COMPLETE!'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo ''

-- Show created tables
\echo 'Created tables:'
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'users', 'matches', 'messages', 'user_friends',
    'match_cooldowns', 'auto_match_runs',
    'chat_rooms', 'chat_participants', 'chat_messages',
    'match_suggestions', 'match_suggestion_cooldowns'
  )
ORDER BY tablename;

-- Show created views
\echo ''
\echo 'Created views:'
SELECT viewname
FROM pg_views
WHERE schemaname = 'public'
  AND viewname IN (
    'match_details', 'message_details',
    'match_suggestions_with_details'
  )
ORDER BY viewname;

-- Show critical indexes
\echo ''
\echo 'Critical indexes:'
SELECT indexname
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'uniq_cooldown_pair',
    'idx_matches_status',
    'idx_chat_messages_room_id',
    'idx_match_suggestions_unique_pending_pair'
  )
ORDER BY indexname;

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo ''
\echo 'What was set up:'
\echo '  ✅ Core schema (users, matches, messages)'
\echo '  ✅ Matchmaking system (cooldowns, auto-match)'
\echo '  ✅ Chat system (rooms, participants, messages)'
\echo '  ✅ Match suggestions (user-suggested matches)'
\echo '  ✅ All triggers and functions'
\echo '  ✅ DECLINE 500 ERROR FIX (critical!)'
\echo '  ✅ Views for easier querying'
\echo '  ✅ Permissions and grants'
\echo ''
\echo 'Next steps:'
\echo '  1. Run test_decline_fix.sql to verify decline fix works'
\echo '  2. Configure RLS policies if needed (see supabase-users-rls-policy.sql)'
\echo '  3. Set up pg_cron for auto-close rooms (see supabase/migrations/20250121_setup_pg_cron.sql)'
\echo '  4. Start your application: pnpm run dev'
\echo ''
\echo '🎉 Your database is ready to use!'
\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
