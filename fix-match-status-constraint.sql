-- Quick Fix: Add 'pending_external', 'proposed', and 'completed' to match status constraint
-- Copy and paste this into Supabase SQL Editor

-- Drop the existing constraint
ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS matches_status_check;

-- Add the updated constraint with ALL status values
ALTER TABLE public.matches
ADD CONSTRAINT matches_status_check
CHECK (status IN (
    'pending',           -- Legacy pending status
    'proposed',          -- Match proposed to internal user
    'pending_external',  -- Match proposed to external Farcaster user
    'accepted',          -- Match accepted by both parties
    'completed',         -- Meeting completed
    'declined',          -- Match declined by one party
    'cancelled'          -- Match cancelled
));

-- Verify it worked
SELECT 'SUCCESS: Constraint updated with all status values!' as result;
