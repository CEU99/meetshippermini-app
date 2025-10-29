-- Migration: Add function to get cooldown expiry timestamp
-- Date: 2025-10-29
-- Purpose: Get the cooldown_until timestamp for user-facing cooldown feedback

-- Create function to get cooldown expiry timestamp
CREATE OR REPLACE FUNCTION public.get_match_cooldown_expiry(fid_a bigint, fid_b bigint)
RETURNS timestamptz
LANGUAGE plpgsql
AS $function$
DECLARE
    expiry_time timestamptz;
BEGIN
    SELECT mc.cooldown_until
    INTO expiry_time
    FROM public.match_cooldowns mc
    WHERE ((mc.user_a_fid = fid_a AND mc.user_b_fid = fid_b)
        OR (mc.user_a_fid = fid_b AND mc.user_b_fid = fid_a))
      AND mc.cooldown_until > NOW()
    ORDER BY mc.cooldown_until DESC
    LIMIT 1;

    RETURN expiry_time;
END;
$function$;

-- Add comment for documentation
COMMENT ON FUNCTION public.get_match_cooldown_expiry(bigint, bigint) IS
'Returns the cooldown_until timestamp for a user pair if they are currently in cooldown, NULL otherwise';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Successfully added get_match_cooldown_expiry function';
END $$;
