-- Fix Match Suggestions RLS Policy
-- Problem: The service role policy is preventing the service role from bypassing RLS
-- Solution: Drop the service role policy so that service role key bypasses RLS automatically
--
-- IMPORTANT: Run this AFTER running the main migration (20250122_create_match_suggestions.sql)

-- Drop the problematic service role policy
DROP POLICY IF EXISTS "Service role can manage suggestions" ON match_suggestions;

-- Drop the service role policy on cooldowns too
DROP POLICY IF EXISTS "Service role can manage cooldowns" ON match_suggestion_cooldowns;

-- Note: By NOT having a service role policy, the service role key will automatically
-- bypass ALL RLS policies on these tables. This is the correct Supabase behavior.

-- Verify the policies were dropped
DO $$
DECLARE
  v_policy_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO v_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'match_suggestions'
    AND policyname = 'Service role can manage suggestions';

  IF v_policy_count = 0 THEN
    RAISE NOTICE '✅ Service role policy removed from match_suggestions';
  ELSE
    RAISE EXCEPTION '❌ Failed to remove service role policy from match_suggestions';
  END IF;

  SELECT COUNT(*)
  INTO v_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'match_suggestion_cooldowns'
    AND policyname = 'Service role can manage cooldowns';

  IF v_policy_count = 0 THEN
    RAISE NOTICE '✅ Service role policy removed from match_suggestion_cooldowns';
  ELSE
    RAISE EXCEPTION '❌ Failed to remove service role policy from match_suggestion_cooldowns';
  END IF;
END $$;

-- List remaining policies for verification
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('match_suggestions', 'match_suggestion_cooldowns')
ORDER BY tablename, policyname;
