-- Migration: Add hasJoinedMeetShipper column to users table
-- Date: 2025-10-29
-- Purpose: Differentiate users who have actually logged into MeetShipper from external Farcaster users

-- Add the hasJoinedMeetShipper column with default true
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS has_joined_meetshipper BOOLEAN NOT NULL DEFAULT true;

-- Set existing users to true (they've all joined already)
UPDATE public.users
SET has_joined_meetshipper = true
WHERE has_joined_meetshipper IS NULL;

-- Add index for efficient filtering
CREATE INDEX IF NOT EXISTS idx_users_has_joined ON public.users(has_joined_meetshipper);

-- Add comment for documentation
COMMENT ON COLUMN public.users.has_joined_meetshipper IS
'True if user has logged into MeetShipper, false if they are only known from Farcaster (external user)';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Successfully added has_joined_meetshipper column';
    RAISE NOTICE 'Default: true for authenticated users';
    RAISE NOTICE 'Set to false for external-only Farcaster users';
END $$;
