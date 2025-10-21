-- ================================================
-- MEETING ROOM AUTO-CLOSE SYSTEM
-- ================================================
-- Date: 2025-10-20
-- Purpose: Implement 2-hour auto-close for Whereby meeting rooms
--
-- Rules:
-- 1. 2-hour countdown starts on first participant join
-- 2. Room auto-closes after 2 hours
-- 3. "Mark as Completed" closes room immediately
-- 4. Retroactive cleanup for old rooms

-- ================================================
-- 1. ADD NEW COLUMNS TO MATCHES TABLE
-- ================================================

-- Add meeting room state tracking columns
ALTER TABLE matches
ADD COLUMN IF NOT EXISTS meeting_started_at TIMESTAMPTZ NULL,
ADD COLUMN IF NOT EXISTS meeting_expires_at TIMESTAMPTZ NULL,
ADD COLUMN IF NOT EXISTS meeting_closed_at TIMESTAMPTZ NULL,
ADD COLUMN IF NOT EXISTS meeting_state TEXT DEFAULT 'scheduled'
  CHECK (meeting_state IN ('scheduled', 'in_progress', 'closed'));

-- Add comment for documentation
COMMENT ON COLUMN matches.meeting_started_at IS 'When first participant joined the meeting room';
COMMENT ON COLUMN matches.meeting_expires_at IS 'When the room should auto-close (started_at + 2 hours)';
COMMENT ON COLUMN matches.meeting_closed_at IS 'When the room was actually closed';
COMMENT ON COLUMN matches.meeting_state IS 'Room state: scheduled (not started), in_progress (started, not expired), closed (ended or expired)';

-- Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_matches_meeting_state ON matches(meeting_state);
CREATE INDEX IF NOT EXISTS idx_matches_meeting_expires_at ON matches(meeting_expires_at) WHERE meeting_state != 'closed';
CREATE INDEX IF NOT EXISTS idx_matches_auto_close_check ON matches(meeting_state, meeting_expires_at)
  WHERE meeting_state IN ('scheduled', 'in_progress') AND meeting_expires_at IS NOT NULL;

-- ================================================
-- 2. HELPER FUNCTION: START MEETING TIMER
-- ================================================
-- Called when first participant joins the room

CREATE OR REPLACE FUNCTION start_meeting_timer(
  p_match_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_match RECORD;
BEGIN
  -- Get match details
  SELECT * INTO v_match
  FROM matches
  WHERE id = p_match_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Match not found');
  END IF;

  -- Only start timer if not already started
  IF v_match.meeting_started_at IS NOT NULL THEN
    RETURN jsonb_build_object(
      'already_started', true,
      'started_at', v_match.meeting_started_at,
      'expires_at', v_match.meeting_expires_at
    );
  END IF;

  -- Set meeting as started, calculate expiry (2 hours)
  UPDATE matches
  SET
    meeting_started_at = NOW(),
    meeting_expires_at = NOW() + INTERVAL '2 hours',
    meeting_state = 'in_progress'
  WHERE id = p_match_id;

  RETURN jsonb_build_object(
    'started', true,
    'started_at', NOW(),
    'expires_at', NOW() + INTERVAL '2 hours'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 3. HELPER FUNCTION: CLOSE MEETING ROOM
-- ================================================
-- Called when room should be closed (manual or auto)

CREATE OR REPLACE FUNCTION close_meeting_room(
  p_match_id UUID,
  p_reason TEXT DEFAULT 'manual'
)
RETURNS JSONB AS $$
DECLARE
  v_match RECORD;
  v_both_completed BOOLEAN;
BEGIN
  -- Get match details
  SELECT * INTO v_match
  FROM matches
  WHERE id = p_match_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Match not found');
  END IF;

  -- Check if already closed
  IF v_match.meeting_state = 'closed' THEN
    RETURN jsonb_build_object(
      'already_closed', true,
      'closed_at', v_match.meeting_closed_at
    );
  END IF;

  -- Update meeting state to closed
  UPDATE matches
  SET
    meeting_closed_at = NOW(),
    meeting_state = 'closed'
  WHERE id = p_match_id;

  -- Check if both users marked as completed
  v_both_completed := v_match.a_completed AND v_match.b_completed;

  -- If both completed, update match status to completed
  IF v_both_completed AND v_match.status != 'completed' THEN
    UPDATE matches
    SET status = 'completed'
    WHERE id = p_match_id;
  END IF;

  RETURN jsonb_build_object(
    'closed', true,
    'closed_at', NOW(),
    'reason', p_reason,
    'match_status_updated', v_both_completed
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 4. HELPER FUNCTION: GET EXPIRED ROOMS
-- ================================================
-- Returns list of rooms that should be auto-closed

CREATE OR REPLACE FUNCTION get_expired_meeting_rooms()
RETURNS TABLE (
  match_id UUID,
  meeting_link TEXT,
  meeting_started_at TIMESTAMPTZ,
  meeting_expires_at TIMESTAMPTZ,
  minutes_overdue INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.id as match_id,
    m.meeting_link,
    m.meeting_started_at,
    m.meeting_expires_at,
    EXTRACT(EPOCH FROM (NOW() - m.meeting_expires_at))::INTEGER / 60 as minutes_overdue
  FROM matches m
  WHERE m.meeting_state IN ('scheduled', 'in_progress')
    AND m.meeting_expires_at IS NOT NULL
    AND m.meeting_expires_at < NOW()
    AND m.meeting_link IS NOT NULL
  ORDER BY m.meeting_expires_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 5. HELPER FUNCTION: AUTO-CLOSE EXPIRED ROOMS
-- ================================================
-- Bulk close all expired rooms (called by cron)

CREATE OR REPLACE FUNCTION auto_close_expired_rooms()
RETURNS JSONB AS $$
DECLARE
  v_expired_count INTEGER;
  v_closed_count INTEGER := 0;
  v_room RECORD;
BEGIN
  -- Get count of expired rooms
  SELECT COUNT(*) INTO v_expired_count
  FROM matches
  WHERE meeting_state IN ('scheduled', 'in_progress')
    AND meeting_expires_at IS NOT NULL
    AND meeting_expires_at < NOW()
    AND meeting_link IS NOT NULL;

  IF v_expired_count = 0 THEN
    RETURN jsonb_build_object(
      'expired_count', 0,
      'closed_count', 0,
      'message', 'No expired rooms to close'
    );
  END IF;

  -- Close each expired room
  FOR v_room IN
    SELECT id FROM matches
    WHERE meeting_state IN ('scheduled', 'in_progress')
      AND meeting_expires_at IS NOT NULL
      AND meeting_expires_at < NOW()
      AND meeting_link IS NOT NULL
  LOOP
    PERFORM close_meeting_room(v_room.id, 'auto_expired');
    v_closed_count := v_closed_count + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'expired_count', v_expired_count,
    'closed_count', v_closed_count,
    'message', format('Auto-closed %s expired room(s)', v_closed_count)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 6. RETROACTIVE CLEANUP
-- ================================================
-- Close old rooms that should already be closed

-- Set default state for existing matches
UPDATE matches
SET meeting_state = 'scheduled'
WHERE meeting_state IS NULL
  AND status IN ('accepted', 'pending', 'proposed');

-- Close rooms where both users accepted and >2h passed (no start time tracked)
UPDATE matches
SET
  meeting_state = 'closed',
  meeting_closed_at = NOW()
WHERE status = 'accepted'
  AND meeting_link IS NOT NULL
  AND meeting_started_at IS NULL
  AND scheduled_at IS NOT NULL
  AND scheduled_at < NOW() - INTERVAL '2 hours'
  AND (meeting_state IS NULL OR meeting_state != 'closed');

-- Close rooms where meeting started and expired
UPDATE matches
SET
  meeting_state = 'closed',
  meeting_closed_at = NOW()
WHERE meeting_started_at IS NOT NULL
  AND meeting_expires_at < NOW()
  AND (meeting_state IS NULL OR meeting_state IN ('scheduled', 'in_progress'));

-- Close rooms for completed matches
UPDATE matches
SET
  meeting_state = 'closed',
  meeting_closed_at = COALESCE(meeting_closed_at, NOW())
WHERE status = 'completed'
  AND meeting_link IS NOT NULL
  AND (meeting_state IS NULL OR meeting_state != 'closed');

-- ================================================
-- 7. GRANT PERMISSIONS
-- ================================================

GRANT EXECUTE ON FUNCTION start_meeting_timer(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION close_meeting_room(UUID, TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_expired_meeting_rooms() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION auto_close_expired_rooms() TO authenticated, service_role;

-- ================================================
-- 8. VERIFICATION QUERIES
-- ================================================

-- Check columns were added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'matches'
  AND column_name IN ('meeting_started_at', 'meeting_expires_at', 'meeting_closed_at', 'meeting_state');

-- Check functions exist
SELECT routine_name
FROM information_schema.routines
WHERE routine_name IN (
  'start_meeting_timer',
  'close_meeting_room',
  'get_expired_meeting_rooms',
  'auto_close_expired_rooms'
);

-- Check indexes exist
SELECT indexname
FROM pg_indexes
WHERE tablename = 'matches'
  AND indexname LIKE '%meeting%';

-- View retroactive cleanup results
SELECT
  status,
  meeting_state,
  COUNT(*) as count
FROM matches
WHERE meeting_link IS NOT NULL
GROUP BY status, meeting_state
ORDER BY status, meeting_state;

-- View expired rooms that need attention
SELECT * FROM get_expired_meeting_rooms();

-- ================================================
-- SETUP COMPLETE
-- ================================================
-- Next steps:
-- 1. Run this SQL in Supabase SQL Editor
-- 2. Update meeting-service.ts to call these functions
-- 3. Create cron endpoint at /api/cron/close-expired-rooms
-- 4. Update respond API to close rooms on completion
-- 5. Update Inbox UI to show timer and room status
