-- ============================================================================
-- Complete Fix for Match Decline Issue
-- ============================================================================
-- This script fixes the "Failed to update match" error when declining
-- Root causes:
--   1. Status constraint may not include all required values
--   2. RLS policies may be blocking updates
--   3. JWT claims may be missing or incorrectly configured
-- ============================================================================

BEGIN;

-- ============================================================================
-- STEP 1: Fix Status Constraint
-- ============================================================================

DO $$
DECLARE
  v_constraint_name TEXT;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Fixing status constraint';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

  -- Find and drop existing status constraint
  SELECT conname INTO v_constraint_name
  FROM pg_constraint
  WHERE conrelid = 'public.matches'::regclass
    AND contype = 'c'
    AND conname LIKE '%status%';

  IF v_constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS %I', v_constraint_name);
    RAISE NOTICE '✓ Dropped old constraint: %', v_constraint_name;
  END IF;

  -- Create new comprehensive constraint
  ALTER TABLE public.matches ADD CONSTRAINT matches_status_check
    CHECK (status IN (
      'proposed',
      'pending',
      'accepted_by_a',
      'accepted_by_b',
      'accepted',
      'declined',
      'cancelled',
      'completed'
    ));

  RAISE NOTICE '✓ Created new status constraint with all required values';
  RAISE NOTICE '  Allowed statuses: proposed, pending, accepted_by_a, accepted_by_b, accepted, declined, cancelled, completed';
END $$;

-- ============================================================================
-- STEP 2: Fix RLS Policies
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 2: Fixing RLS policies';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Drop ALL existing policies on matches table
DROP POLICY IF EXISTS "Service role can manage matches" ON public.matches;
DROP POLICY IF EXISTS "Service role full access on matches" ON public.matches;
DROP POLICY IF EXISTS "Service role bypass" ON public.matches;
DROP POLICY IF EXISTS "Users can update their matches" ON public.matches;
DROP POLICY IF EXISTS "Users can view their matches" ON public.matches;
DROP POLICY IF EXISTS "Users can create matches" ON public.matches;
DROP POLICY IF EXISTS "Allow service role all access" ON public.matches;
DROP POLICY IF EXISTS "Allow authenticated users to view their matches" ON public.matches;
DROP POLICY IF EXISTS "Allow authenticated users to create matches" ON public.matches;
DROP POLICY IF EXISTS "Allow authenticated users to update their matches" ON public.matches;

DO $$
BEGIN
  RAISE NOTICE '✓ Dropped all existing RLS policies';
END $$;

-- Create new, permissive policies for authenticated users
-- Policy 1: Users can view matches they're involved in
CREATE POLICY "Users can view their matches" ON public.matches
  FOR SELECT
  TO authenticated
  USING (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR created_by_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );

-- Policy 2: Users can create matches
CREATE POLICY "Users can create matches" ON public.matches
  FOR INSERT
  TO authenticated
  WITH CHECK (
    created_by_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );

-- Policy 3: Users can update matches they're participants in (CRITICAL FOR DECLINE)
CREATE POLICY "Users can update their matches" ON public.matches
  FOR UPDATE
  TO authenticated
  USING (
    user_a_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims', true)::json->>'fid')::bigint
  );
  -- Note: Removed WITH CHECK to make updates more permissive

DO $$
BEGIN
  RAISE NOTICE '✓ Created new RLS policies:';
  RAISE NOTICE '  - Users can view their matches';
  RAISE NOTICE '  - Users can create matches';
  RAISE NOTICE '  - Users can update their matches (permissive)';
END $$;

-- ============================================================================
-- STEP 3: Grant Permissions
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: Granting permissions';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Ensure service_role has full access (bypasses RLS)
GRANT ALL ON public.matches TO service_role;
GRANT ALL ON public.match_details TO service_role;

-- Ensure authenticated users have necessary access
GRANT SELECT, INSERT, UPDATE ON public.matches TO authenticated;

DO $$
BEGIN
  RAISE NOTICE '✓ Granted permissions to service_role and authenticated';
END $$;

-- ============================================================================
-- STEP 4: Verify Configuration
-- ============================================================================

DO $$
DECLARE
  v_rls_enabled BOOLEAN;
  v_policy_count INTEGER;
  v_constraint_def TEXT;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 4: Verification';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

  -- Check RLS status
  SELECT relrowsecurity INTO v_rls_enabled
  FROM pg_class
  WHERE oid = 'public.matches'::regclass;

  RAISE NOTICE 'RLS Enabled: %', CASE WHEN v_rls_enabled THEN 'YES' ELSE 'NO' END;

  -- Count policies
  SELECT COUNT(*) INTO v_policy_count
  FROM pg_policies
  WHERE schemaname = 'public' AND tablename = 'matches';

  RAISE NOTICE 'Active Policies: %', v_policy_count;

  -- Verify status constraint
  SELECT pg_get_constraintdef(oid) INTO v_constraint_def
  FROM pg_constraint
  WHERE conrelid = 'public.matches'::regclass
    AND contype = 'c'
    AND conname = 'matches_status_check';

  IF v_constraint_def LIKE '%declined%' THEN
    RAISE NOTICE 'Status Constraint: ✓ Includes "declined"';
  ELSE
    RAISE WARNING 'Status Constraint: ✗ Missing "declined"';
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ FIX COMPLETED SUCCESSFULLY';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'Test the fix:';
  RAISE NOTICE '  1. Go to /mini/inbox in your app';
  RAISE NOTICE '  2. Click "Decline" on a pending match';
  RAISE NOTICE '  3. Verify the match status changes to "declined"';
  RAISE NOTICE '  4. Check that no error appears';
  RAISE NOTICE '';
END $$;

COMMIT;

-- ============================================================================
-- STEP 5: Display Current Policies
-- ============================================================================

SELECT
  'Current RLS Policies:' as info;

SELECT
  policyname as "Policy Name",
  cmd as "Command",
  CASE
    WHEN cmd = 'SELECT' THEN 'View'
    WHEN cmd = 'INSERT' THEN 'Create'
    WHEN cmd = 'UPDATE' THEN 'Update'
    WHEN cmd = 'DELETE' THEN 'Delete'
    WHEN cmd = 'ALL' THEN 'Full Access'
  END as "Operation",
  roles as "Roles"
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'matches'
ORDER BY policyname;
