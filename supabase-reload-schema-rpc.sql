-- =====================================================
-- SCHEMA CACHE RELOAD RPC
-- =====================================================
-- Creates a function to reload PostgREST schema cache
-- This fixes PGRST204 errors after schema changes
--
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- https://supabase.com/dashboard
-- =====================================================

BEGIN;

-- Create function to reload PostgREST schema cache
CREATE OR REPLACE FUNCTION reload_pgrst_schema()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT pg_notify('pgrst', 'reload schema');
$$;

-- Grant execute permission to anon and authenticated roles
GRANT EXECUTE ON FUNCTION reload_pgrst_schema() TO anon, authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION reload_pgrst_schema() IS
  'Reloads PostgREST schema cache. Call this after DDL changes (ALTER TABLE, etc.) to ensure the API layer sees the latest schema.';

COMMIT;

-- =====================================================
-- VERIFICATION
-- =====================================================
-- Verify the function was created
SELECT
    proname AS function_name,
    pg_get_functiondef(oid) AS definition
FROM pg_proc
WHERE proname = 'reload_pgrst_schema';

-- =====================================================
-- TEST THE FUNCTION
-- =====================================================
-- Test that the function works (should return nothing on success)
SELECT reload_pgrst_schema();

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '✅ Schema reload RPC created successfully!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Function: reload_pgrst_schema()';
    RAISE NOTICE 'Usage: SELECT reload_pgrst_schema();';
    RAISE NOTICE '';
    RAISE NOTICE 'The API will now auto-recover from schema cache errors.';
    RAISE NOTICE '';
END $$;
