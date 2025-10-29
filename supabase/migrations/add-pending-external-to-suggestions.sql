-- Migration: Add 'pending_external' status to match_suggestions table
-- Date: 2025-10-29
-- Purpose: Support external Farcaster user suggestions

-- Add rationale column if it doesn't exist (for storing metadata)
ALTER TABLE public.match_suggestions
ADD COLUMN IF NOT EXISTS rationale jsonb;

-- Drop the existing status check constraint
ALTER TABLE public.match_suggestions
DROP CONSTRAINT IF EXISTS match_suggestions_status_check;

-- Add the updated constraint with pending_external
ALTER TABLE public.match_suggestions
ADD CONSTRAINT match_suggestions_status_check
CHECK (status IN (
    'proposed',          -- Suggestion to internal MeetShipper users
    'pending_external',  -- Suggestion to external Farcaster users
    'accepted_by_a',     -- User A accepted
    'accepted_by_b',     -- User B accepted
    'accepted',          -- Both accepted
    'declined',          -- Declined by one party
    'cancelled'          -- Suggestion cancelled
));

-- Add comment for documentation
COMMENT ON CONSTRAINT match_suggestions_status_check ON public.match_suggestions IS
'Allowed suggestion statuses: proposed (internal), pending_external (external Farcaster), accepted_by_a, accepted_by_b, accepted, declined, cancelled';

-- Verify the constraint was added
SELECT
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conname = 'match_suggestions_status_check'
  AND conrelid = 'public.match_suggestions'::regclass;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Successfully added pending_external status to match_suggestions';
    RAISE NOTICE 'Allowed statuses: proposed, pending_external, accepted_by_a, accepted_by_b, accepted, declined, cancelled';
END $$;
