-- Migration: Add 'pending_external' and 'proposed' status values to matches table
-- Date: 2025-10-29
-- Purpose: Fix constraint violation when creating matches with external Farcaster users

-- Drop the existing status check constraint
ALTER TABLE public.matches
DROP CONSTRAINT IF EXISTS matches_status_check;

-- Add the updated constraint with new status values
ALTER TABLE public.matches
ADD CONSTRAINT matches_status_check
CHECK (status IN (
    'pending',           -- Legacy status
    'proposed',          -- Match proposed to internal MeetShipper user
    'pending_external',  -- Match proposed to external Farcaster user
    'accepted',          -- Match accepted by both parties
    'declined',          -- Match declined by one party
    'cancelled'          -- Match cancelled
));

-- Add comment for documentation
COMMENT ON CONSTRAINT matches_status_check ON public.matches IS
'Allowed match statuses: pending (legacy), proposed (internal user), pending_external (external Farcaster user), accepted, declined, cancelled';

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
    RAISE NOTICE '✅ Successfully added pending_external and proposed status values';
    RAISE NOTICE 'Allowed statuses: pending, proposed, pending_external, accepted, declined, cancelled';
END $$;
