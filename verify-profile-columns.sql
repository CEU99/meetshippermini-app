-- =====================================================
-- VERIFICATION SCRIPT: Check if bio and traits columns exist
-- =====================================================
-- Run this in Supabase SQL Editor to verify the columns
-- Location: https://supabase.com/dashboard -> SQL Editor

-- 1. Check if bio and traits columns exist
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
  AND column_name IN ('bio', 'traits')
ORDER BY column_name;

-- Expected output:
-- bio     | text  | YES | null
-- traits  | jsonb | YES | '[]'::jsonb

-- =====================================================
-- 2. Check table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
ORDER BY ordinal_position;

-- This shows ALL columns in the users table

-- =====================================================
-- 3. Check constraints on traits column (if it exists)
SELECT
    con.conname AS constraint_name,
    con.contype AS constraint_type,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
WHERE nsp.nspname = 'public'
  AND rel.relname = 'users'
  AND pg_get_constraintdef(con.oid) LIKE '%traits%';

-- =====================================================
-- 4. Check indexes on traits column (if it exists)
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'users'
  AND indexdef LIKE '%traits%';
