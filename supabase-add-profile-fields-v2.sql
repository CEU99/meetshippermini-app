-- =====================================================
-- PROFILE FEATURES MIGRATION V2 (fixed)
-- =====================================================
-- Adds bio and traits columns to users table
-- Safe to run multiple times (idempotent)
-- Run in: Supabase Dashboard → SQL Editor
-- =====================================================

BEGIN;

-- =====================================================
-- STEP 1: Add bio column (if not exists)
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'bio'
    ) THEN
        ALTER TABLE public.users ADD COLUMN bio TEXT;
        RAISE NOTICE '✅ Added bio column';
    ELSE
        RAISE NOTICE 'ℹ️  bio column already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 2: Add traits column (if not exists)
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'traits'
    ) THEN
        ALTER TABLE public.users ADD COLUMN traits JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE '✅ Added traits column';
    ELSE
        RAISE NOTICE 'ℹ️  traits column already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 3: Ensure traits defaults to empty array
-- =====================================================
UPDATE public.users
SET traits = '[]'::jsonb
WHERE traits IS NULL;

DO $$
BEGIN
  RAISE NOTICE '✅ Set default values for existing rows';
END $$;

-- =====================================================
-- STEP 4: Add constraint - traits must be a JSON array
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'traits_is_array_chk'
          AND conrelid = 'public.users'::regclass
    ) THEN
        ALTER TABLE public.users
        ADD CONSTRAINT traits_is_array_chk
        CHECK (jsonb_typeof(traits) = 'array');
        RAISE NOTICE '✅ Added traits array type constraint';
    ELSE
        RAISE NOTICE 'ℹ️  traits_is_array_chk constraint already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 5: Add constraint - traits must have 0-10 items
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'traits_length_chk'
          AND conrelid = 'public.users'::regclass
    ) THEN
        ALTER TABLE public.users
        ADD CONSTRAINT traits_length_chk
        CHECK (
            jsonb_array_length(traits) >= 0 AND
            jsonb_array_length(traits) <= 10
        );
        RAISE NOTICE '✅ Added traits length constraint (0-10 items)';
    ELSE
        RAISE NOTICE 'ℹ️  traits_length_chk constraint already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 6: Add GIN index on traits for fast querying
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND tablename = 'users'
          AND indexname = 'idx_users_traits'
    ) THEN
        CREATE INDEX idx_users_traits ON public.users USING GIN (traits);
        RAISE NOTICE '✅ Added GIN index on traits column';
    ELSE
        RAISE NOTICE 'ℹ️  idx_users_traits index already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 7: Add column comments for documentation
-- =====================================================
COMMENT ON COLUMN public.users.bio IS 'User biography/description (max 500 characters)';
COMMENT ON COLUMN public.users.traits IS 'User personality traits/tags as JSONB array (5-10 items from predefined list)';

DO $$
BEGIN
  RAISE NOTICE '✅ Added column comments';
END $$;

-- =====================================================
-- STEP 8: Reload PostgREST schema cache
-- =====================================================
-- This helps avoid PGRST204 errors after schema changes
NOTIFY pgrst, 'reload schema';

DO $$
BEGIN
  RAISE NOTICE '✅ Notified PostgREST to reload schema cache';
END $$;

COMMIT;

-- =====================================================
-- VERIFICATION QUERIES (optional)
-- =====================================================

-- Columns
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
  AND column_name IN ('bio', 'traits')
ORDER BY column_name;

-- Constraints
SELECT
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.users'::regclass
  AND conname LIKE '%traits%';

-- Indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'users'
  AND indexname LIKE '%traits%';

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '✅ MIGRATION COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Verify the output above shows bio and traits columns';
    RAISE NOTICE '2. Refresh your application';
    RAISE NOTICE '3. Visit /profile/edit to test the feature';
    RAISE NOTICE '';
END $$;
