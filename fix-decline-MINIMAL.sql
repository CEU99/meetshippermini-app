-- MINIMAL FIX for Match Decline Issue
-- This is the essential fix without any testing or verification code
-- Safe to run - only updates the trigger function

-- Update the cooldown trigger function to handle duplicates
CREATE OR REPLACE FUNCTION public.add_match_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_min_fid BIGINT;
  v_max_fid BIGINT;
  v_existing_id UUID;
BEGIN
  -- Only add cooldown when status changes TO 'declined'
  IF NEW.status = 'declined' AND (OLD.status IS NULL OR OLD.status IS DISTINCT FROM 'declined') THEN

    -- Normalize the FID order to ensure consistency
    v_min_fid := LEAST(NEW.user_a_fid, NEW.user_b_fid);
    v_max_fid := GREATEST(NEW.user_a_fid, NEW.user_b_fid);

    -- Check if cooldown already exists for this pair
    SELECT id INTO v_existing_id
    FROM public.match_cooldowns
    WHERE LEAST(user_a_fid, user_b_fid) = v_min_fid
      AND GREATEST(user_a_fid, user_b_fid) = v_max_fid;

    IF v_existing_id IS NOT NULL THEN
      -- Cooldown already exists, update it instead (reset timer)
      UPDATE public.match_cooldowns
      SET
        declined_at = NOW(),
        cooldown_until = NOW() + INTERVAL '7 days'
      WHERE id = v_existing_id;
    ELSE
      -- No existing cooldown, insert new one
      INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
      VALUES (v_min_fid, v_max_fid, NOW(), NOW() + INTERVAL '7 days');
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- That's it! The fix is now applied.
-- Go ahead and test declining a match - it should work now.
