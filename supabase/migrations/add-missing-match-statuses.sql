-- Migration: Add missing status values to matches table constraint
-- Date: 2025-10-29
-- Purpose: Fix constraint violation - add 'accepted_by_a', 'accepted_by_b', 'completed', 'expired'

-- Drop the existing status check constraint
ALTER TABLE public.matches
DROP CONSTRAINT IF EXISTS matches_status_check;

-- Add the updated constraint with ALL status values
ALTER TABLE public.matches
ADD CONSTRAINT matches_status_check
CHECK (status IN (
    'pending',           -- Legacy status
    'proposed',          -- Match proposed to internal MeetShipper user
    'pending_external',  -- Match proposed to external Farcaster user
    'accepted_by_a',     -- User A accepted, waiting for User B
    'accepted_by_b',     -- User B accepted, waiting for User A
    'accepted',          -- Match accepted by both parties
    'declined',          -- Match declined by one party
    'cancelled',         -- Match cancelled
    'completed',         -- Meeting completed by both parties
    'expired'            -- Match expired
));

-- Add comment for documentation
COMMENT ON CONSTRAINT matches_status_check ON public.matches IS
'Allowed match statuses: pending (legacy), proposed (internal), pending_external (external Farcaster), accepted_by_a, accepted_by_b, accepted, declined, cancelled, completed, expired';

-- Verify the constraint was added
SELECT
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conname = 'matches_status_check'
  AND conrelid = 'public.matches'::regclass;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Successfully added all missing status values';
    RAISE NOTICE 'Allowed statuses: pending, proposed, pending_external, accepted_by_a, accepted_by_b, accepted, declined, cancelled, completed, expired';
END $$;
