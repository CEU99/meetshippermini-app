-- ============================================================================
-- Test Script: Verify Match Decline Permissions
-- ============================================================================
-- This script checks if the decline issue has been fixed
-- Run this in Supabase SQL Editor BEFORE and AFTER applying the fix
-- ============================================================================

-- Test 1: Check if status constraint includes 'declined'
SELECT
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator,
  'TEST 1: Status Constraint Check' as test_name;

SELECT
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition,
  CASE
    WHEN pg_get_constraintdef(oid) LIKE '%declined%' THEN '✅ PASS: Includes declined'
    ELSE '❌ FAIL: Missing declined'
  END as result
FROM pg_constraint
WHERE conrelid = 'public.matches'::regclass
  AND contype = 'c'
  AND conname LIKE '%status%';

-- Test 2: Check RLS status
SELECT
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator,
  'TEST 2: RLS Configuration' as test_name;

SELECT
  relname as table_name,
  relrowsecurity as rls_enabled,
  CASE
    WHEN relrowsecurity THEN '✅ RLS Enabled (as expected)'
    ELSE '⚠️  RLS Disabled'
  END as status
FROM pg_class
WHERE oid = 'public.matches'::regclass;

-- Test 3: Check RLS policies
SELECT
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator,
  'TEST 3: RLS Policies' as test_name;

SELECT
  policyname as policy_name,
  cmd as command,
  roles as roles,
  CASE
    WHEN policyname LIKE '%update%' AND roles::text LIKE '%authenticated%'
    THEN '✅ Update policy exists for authenticated users'
    ELSE 'ℹ️  ' || policyname
  END as status
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'matches'
ORDER BY cmd, policyname;

-- Test 4: Check policy count
SELECT
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator,
  'TEST 4: Policy Count' as test_name;

SELECT
  COUNT(*) as total_policies,
  CASE
    WHEN COUNT(*) >= 3 THEN '✅ PASS: Expected minimum policies found'
    WHEN COUNT(*) = 0 THEN '⚠️  WARNING: No policies (service role may have full access)'
    ELSE '❌ FAIL: Insufficient policies'
  END as result
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'matches'
  AND roles::text LIKE '%authenticated%';

-- Test 5: Check permissions
SELECT
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator,
  'TEST 5: Table Permissions' as test_name;

SELECT
  grantee,
  string_agg(privilege_type, ', ' ORDER BY privilege_type) as privileges,
  CASE
    WHEN grantee = 'authenticated' AND string_agg(privilege_type, ', ') LIKE '%UPDATE%'
    THEN '✅ PASS: Authenticated has UPDATE'
    WHEN grantee = 'service_role' AND string_agg(privilege_type, ', ') LIKE '%ALL%'
    THEN '✅ PASS: Service role has ALL'
    ELSE 'ℹ️  ' || grantee
  END as status
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name = 'matches'
  AND grantee IN ('authenticated', 'service_role', 'anon')
GROUP BY grantee
ORDER BY grantee;

-- Test 6: Sample recent matches
SELECT
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator,
  'TEST 6: Recent Match Statuses' as test_name;

SELECT
  status,
  COUNT(*) as count,
  CASE
    WHEN status = 'declined' THEN '✅ Found declined matches'
    ELSE 'ℹ️  ' || status
  END as info
FROM public.matches
GROUP BY status
ORDER BY count DESC;

-- Test 7: Check for matches that could be declined
SELECT
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator,
  'TEST 7: Declinable Matches' as test_name;

SELECT
  COUNT(*) as pending_matches,
  CASE
    WHEN COUNT(*) > 0 THEN '✅ Found matches that can be tested'
    ELSE '⚠️  No pending matches to test with'
  END as result
FROM public.matches
WHERE status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b');

-- Final summary
SELECT
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator,
  'SUMMARY' as section;

DO $$
DECLARE
  v_has_constraint BOOLEAN;
  v_has_update_policy BOOLEAN;
  v_has_permissions BOOLEAN;
  v_ready TEXT;
BEGIN
  -- Check constraint
  SELECT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.matches'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) LIKE '%declined%'
  ) INTO v_has_constraint;

  -- Check update policy
  SELECT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'matches'
      AND cmd = 'UPDATE'
      AND roles::text LIKE '%authenticated%'
  ) INTO v_has_update_policy;

  -- Check permissions
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.role_table_grants
    WHERE table_schema = 'public'
      AND table_name = 'matches'
      AND grantee = 'authenticated'
      AND privilege_type = 'UPDATE'
  ) INTO v_has_permissions;

  -- Determine readiness
  IF v_has_constraint AND v_has_update_policy AND v_has_permissions THEN
    v_ready := '✅ READY: All checks passed - decline should work';
  ELSIF v_has_constraint AND v_has_update_policy THEN
    v_ready := '⚠️  ALMOST: Constraint and policy OK, check permissions';
  ELSIF v_has_constraint THEN
    v_ready := '❌ NOT READY: Missing update policy';
  ELSE
    v_ready := '❌ NOT READY: Missing status constraint with declined';
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE '%', v_ready;
  RAISE NOTICE '';
  RAISE NOTICE 'Checklist:';
  RAISE NOTICE '  [%] Status constraint includes "declined"', CASE WHEN v_has_constraint THEN '✓' ELSE ' ' END;
  RAISE NOTICE '  [%] Update policy exists for authenticated', CASE WHEN v_has_update_policy THEN '✓' ELSE ' ' END;
  RAISE NOTICE '  [%] UPDATE permission granted to authenticated', CASE WHEN v_has_permissions THEN '✓' ELSE ' ' END;
  RAISE NOTICE '';

  IF v_has_constraint AND v_has_update_policy AND v_has_permissions THEN
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Start dev server: pnpm run dev';
    RAISE NOTICE '  2. Go to /mini/inbox';
    RAISE NOTICE '  3. Click Decline on a pending match';
    RAISE NOTICE '  4. Verify no error appears';
  ELSE
    RAISE NOTICE 'Action required:';
    RAISE NOTICE '  Run fix-decline-issue-complete.sql to apply the fix';
  END IF;
  RAISE NOTICE '';
END $$;

SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;
