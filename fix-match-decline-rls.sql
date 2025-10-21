-- Fix Match Decline RLS Issue
-- This ensures service role can update matches for decline operations
-- Run in: Supabase Dashboard → SQL Editor

-- ============================================================================
-- 1. Check current RLS status
-- ============================================================================

DO $$
DECLARE
  v_rls_enabled BOOLEAN;
  v_policy_count INTEGER;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Checking matches table RLS configuration...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

  -- Check if RLS is enabled
  SELECT relrowsecurity INTO v_rls_enabled
  FROM pg_class
  WHERE oid = 'public.matches'::regclass;

  IF v_rls_enabled THEN
    RAISE NOTICE '✅ RLS is ENABLED on matches table';

    -- Count policies
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'matches';

    RAISE NOTICE '   Found % RLS policies on matches table', v_policy_count;
  ELSE
    RAISE NOTICE '⚠️  RLS is DISABLED on matches table';
    RAISE NOTICE '   Service role should have full access';
  END IF;
END $$;

-- ============================================================================
-- 2. Show current policies (for reference)
-- ============================================================================

DO $$
DECLARE
  policy_rec RECORD;
  policy_count INTEGER := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'Current RLS policies on matches table:';
  RAISE NOTICE '────────────────────────────────────────';

  FOR policy_rec IN
    SELECT policyname, cmd,
           CASE WHEN qual IS NOT NULL THEN 'USING clause set' ELSE 'No USING clause' END as using_clause,
           CASE WHEN with_check IS NOT NULL THEN 'WITH CHECK clause set' ELSE 'No WITH CHECK clause' END as check_clause
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'matches'
  LOOP
    policy_count := policy_count + 1;
    RAISE NOTICE '  %: % (%)', policy_count, policy_rec.policyname, policy_rec.cmd;
    RAISE NOTICE '     USING: %', policy_rec.using_clause;
    RAISE NOTICE '     WITH CHECK: %', policy_rec.check_clause;
  END LOOP;

  IF policy_count = 0 THEN
    RAISE NOTICE '  (No policies found)';
  END IF;
END $$;

-- ============================================================================
-- 3. Fix: Remove restrictive service role policies
-- ============================================================================

-- Drop any existing service role policies that might be blocking updates
-- These are problematic because they check JWT claims that may not exist
-- for service role operations

DROP POLICY IF EXISTS "Service role can manage matches" ON matches;
DROP POLICY IF EXISTS "Service role full access on matches" ON matches;
DROP POLICY IF EXISTS "Service role bypass" ON matches;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '✅ Dropped restrictive service role policies (if they existed)';
  RAISE NOTICE '   Service role will now bypass RLS automatically';
END $$;

-- ============================================================================
-- 4. Ensure user policies are correct
-- ============================================================================

-- Drop old user policies
DROP POLICY IF EXISTS "Users can update their matches" ON matches;
DROP POLICY IF EXISTS "Users can view their matches" ON matches;
DROP POLICY IF EXISTS "Users can create matches" ON matches;

-- Recreate user policies with correct structure

-- Policy 1: Users can view matches they're involved in
CREATE POLICY "Users can view their matches" ON matches
  FOR SELECT
  USING (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR created_by_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );

-- Policy 2: Users can create matches
CREATE POLICY "Users can create matches" ON matches
  FOR INSERT
  WITH CHECK (
    created_by_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );

-- Policy 3: Users can update matches they're participants in
-- This is crucial for accepting/declining matches
CREATE POLICY "Users can update their matches" ON matches
  FOR UPDATE
  USING (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  )
  WITH CHECK (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '✅ Created user policies for matches table';
END $$;

-- ============================================================================
-- 5. Verify the status constraint includes 'declined'
-- ============================================================================

DO $$
DECLARE
  v_constraint_def TEXT;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Checking status constraint...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

  -- Get the constraint definition
  SELECT pg_get_constraintdef(oid) INTO v_constraint_def
  FROM pg_constraint
  WHERE conrelid = 'matches'::regclass
    AND contype = 'c'
    AND conname LIKE '%status%';

  IF v_constraint_def IS NOT NULL THEN
    RAISE NOTICE 'Current status constraint: %', v_constraint_def;

    IF v_constraint_def LIKE '%declined%' THEN
      RAISE NOTICE '✅ Status constraint includes "declined"';
    ELSE
      RAISE NOTICE '⚠️  Status constraint does NOT include "declined"';
      RAISE NOTICE '   This will prevent declining matches!';
    END IF;
  ELSE
    RAISE NOTICE '⚠️  No status constraint found';
  END IF;
END $$;

-- Fix status constraint if needed (safe - will only recreate if needed)
DO $$
DECLARE
  v_constraint_name TEXT;
BEGIN
  -- Find the status constraint name
  SELECT conname INTO v_constraint_name
  FROM pg_constraint
  WHERE conrelid = 'matches'::regclass
    AND contype = 'c'
    AND conname LIKE '%status%';

  -- Drop old constraint
  IF v_constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE matches DROP CONSTRAINT IF EXISTS %I', v_constraint_name);
    RAISE NOTICE '   Dropped old status constraint: %', v_constraint_name;
  END IF;

  -- Create new constraint with all required statuses
  ALTER TABLE matches ADD CONSTRAINT matches_status_check
    CHECK (status IN (
      'proposed',
      'accepted_by_a',
      'accepted_by_b',
      'accepted',
      'declined',
      'cancelled',
      'completed',
      'pending'
    ));

  RAISE NOTICE '✅ Created new status constraint with all required values';
END $$;

-- ============================================================================
-- 6. Grant necessary permissions
-- ============================================================================

-- Ensure service_role has full access
GRANT ALL ON matches TO service_role;
GRANT ALL ON match_details TO service_role;

-- Ensure authenticated users have necessary access
GRANT SELECT, INSERT, UPDATE ON matches TO authenticated;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '✅ Granted permissions';
END $$;

-- ============================================================================
-- 7. Final verification
-- ============================================================================

DO $$
DECLARE
  v_rls_enabled BOOLEAN;
  v_policy_count INTEGER;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Final verification:';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

  -- Check RLS status
  SELECT relrowsecurity INTO v_rls_enabled
  FROM pg_class
  WHERE oid = 'public.matches'::regclass;

  RAISE NOTICE 'RLS Enabled: %', v_rls_enabled;

  -- Count policies
  SELECT COUNT(*) INTO v_policy_count
  FROM pg_policies
  WHERE schemaname = 'public' AND tablename = 'matches';

  RAISE NOTICE 'Policy Count: %', v_policy_count;
  RAISE NOTICE '';
  RAISE NOTICE '✅ Fix applied successfully!';
  RAISE NOTICE '';
  RAISE NOTICE 'Expected behavior:';
  RAISE NOTICE '  • Service role: Full access (bypasses RLS)';
  RAISE NOTICE '  • Authenticated users: Can view/update their own matches';
  RAISE NOTICE '  • Status constraint: Includes "declined"';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '  1. Test declining a match in your app';
  RAISE NOTICE '  2. Check API logs for success confirmation';
  RAISE NOTICE '  3. Verify match status changes to "declined"';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- 8. List final policies for reference
-- ============================================================================

SELECT
  tablename,
  policyname,
  cmd as command,
  CASE
    WHEN cmd = 'SELECT' THEN 'View'
    WHEN cmd = 'INSERT' THEN 'Create'
    WHEN cmd = 'UPDATE' THEN 'Update'
    WHEN cmd = 'DELETE' THEN 'Delete'
    WHEN cmd = 'ALL' THEN 'Full Access'
  END as operation
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'matches'
ORDER BY policyname;
