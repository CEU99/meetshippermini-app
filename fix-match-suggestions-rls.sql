-- Fix Match Suggestions RLS Policy
-- The issue: Service role should bypass RLS, but the INSERT policy is checking JWT claims
-- Solution: Update the service role policy to be more permissive

-- Drop the existing overly restrictive service role policy
DROP POLICY IF EXISTS "Service role can manage suggestions" ON match_suggestions;

-- Create a better service role policy that properly bypasses RLS
-- Service role should have full access without JWT claim checks
CREATE POLICY "Service role full access"
  ON match_suggestions
  FOR ALL
  USING (
    -- Service role key bypasses RLS automatically when auth.uid() returns null
    -- But we add this explicit check for clarity
    auth.role() = 'service_role' OR
    current_setting('request.jwt.claims', true)::json->>'role' = 'service_role'
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    current_setting('request.jwt.claims', true)::json->>'role' = 'service_role'
  );

-- Verify the policy was created
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'match_suggestions'
    AND policyname = 'Service role full access'
  ) THEN
    RAISE NOTICE '✅ Service role policy updated successfully';
  ELSE
    RAISE EXCEPTION '❌ Failed to update service role policy';
  END IF;
END $$;
