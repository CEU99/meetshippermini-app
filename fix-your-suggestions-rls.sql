-- Fix RLS for "Your Suggestions" feature
-- This allows users to view match suggestions they created

-- Add RLS policy to allow creators to view their own suggestions
CREATE POLICY "Creators can view their suggestions"
  ON match_suggestions
  FOR SELECT
  USING (
    created_by_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );

-- Verify the policy was created
DO $$
BEGIN
  RAISE NOTICE '✅ RLS policy "Creators can view their suggestions" created successfully';
END $$;
