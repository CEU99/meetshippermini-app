-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these to verify your database setup
-- =====================================================

-- 1. Check if bio and traits columns exist
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN ('bio', 'traits')
ORDER BY column_name;

-- Expected output:
-- bio     | text  | YES | null
-- traits  | jsonb | YES | '[]'::jsonb

-- =====================================================
-- 2. Check all columns in users table
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- =====================================================
-- 3. Check RLS (Row Level Security) status
SELECT
    schemaname,
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE tablename = 'users';

-- =====================================================
-- 4. Check RLS policies (if RLS is enabled)
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'users';

-- =====================================================
-- 5. Check if reload_pgrst_schema function exists
SELECT
    proname AS function_name,
    proargnames AS argument_names,
    prosrc AS source_code
FROM pg_proc
WHERE proname = 'reload_pgrst_schema';

-- =====================================================
-- 6. Test a sample user query (replace FID with yours)
-- SELECT fid, username, bio, traits
-- FROM users
-- WHERE fid = 543581;

-- =====================================================
-- NOTES
-- =====================================================
-- If RLS is enabled on the users table:
--   - The service role key bypasses RLS (used by API)
--   - No additional policies needed for API routes
--
-- If you want to enable RLS for additional security:
--   ALTER TABLE users ENABLE ROW LEVEL SECURITY;
--
--   CREATE POLICY "Users can view own profile"
--     ON users FOR SELECT
--     TO authenticated
--     USING (fid = (current_setting('request.jwt.claims', true)::json->>'fid')::integer);
--
--   CREATE POLICY "Users can update own profile"
--     ON users FOR UPDATE
--     TO authenticated
--     USING (fid = (current_setting('request.jwt.claims', true)::json->>'fid')::integer)
--     WITH CHECK (fid = (current_setting('request.jwt.claims', true)::json->>'fid')::integer);
