-- =====================================================================
-- RLS Policy for Users Table - Read Access
-- =====================================================================
-- Purpose: Enable authenticated users to read all user profiles
-- Run this in Supabase SQL Editor
-- =====================================================================

-- Step 1: Enable RLS on users table (if not already enabled)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policy if it exists (to avoid conflicts)
DROP POLICY IF EXISTS "Users can read all profiles" ON public.users;

-- Step 3: Create policy to allow all authenticated users to read user profiles
CREATE POLICY "Users can read all profiles"
ON public.users
FOR SELECT
USING (true);  -- Allow all authenticated users to read

-- Step 4: Verify the policy was created
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'users';

-- =====================================================================
-- Expected Output:
-- =====================================================================
-- You should see a policy named "Users can read all profiles" with:
-- - cmd: SELECT
-- - qual: true (or similar - allows all reads)
-- =====================================================================

-- =====================================================================
-- Notes:
-- =====================================================================
-- 1. This policy allows ANY authenticated user to read ALL user profiles
-- 2. RLS is bypassed when using the service_role key (used in API routes)
-- 3. This is appropriate for a social/matching app where profiles are public
-- 4. For more restrictive access, modify the USING clause
-- =====================================================================

-- =====================================================================
-- Optional: Create policy for users to update their own profile
-- =====================================================================
-- Uncomment if you want users to be able to update their own profiles

-- DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
--
-- CREATE POLICY "Users can update own profile"
-- ON public.users
-- FOR UPDATE
-- USING (fid = current_setting('app.current_user_fid', true)::bigint)
-- WITH CHECK (fid = current_setting('app.current_user_fid', true)::bigint);

-- =====================================================================
-- Testing the Policy
-- =====================================================================
-- After running this script, test the API endpoints:
-- 1. GET /api/users - Should return list of users
-- 2. GET /api/users/[fid] - Should return specific user profile
-- 3. Check browser console for any RLS-related errors
-- =====================================================================
