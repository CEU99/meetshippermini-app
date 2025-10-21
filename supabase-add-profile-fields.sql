-- ============================================================================
-- PROFILE ENHANCEMENTS - Bio and Traits Migration
-- ============================================================================
-- Adds bio and traits fields to the users table
-- Safe to run multiple times (idempotent)
-- ============================================================================

-- Step 1: Ensure bio column exists (it should already exist from initial schema)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'bio'
    ) THEN
        ALTER TABLE users ADD COLUMN bio TEXT;
        RAISE NOTICE 'Added bio column';
    ELSE
        RAISE NOTICE 'bio column already exists';
    END IF;
END $$;

-- Step 2: Add traits column (JSON array to store selected trait tags)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'traits'
    ) THEN
        ALTER TABLE users ADD COLUMN traits JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added traits column';
    ELSE
        RAISE NOTICE 'traits column already exists';
    END IF;
END $$;

-- Step 3: Add constraint to ensure traits is always a JSON array
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'traits_is_array_chk'
    ) THEN
        ALTER TABLE users
        ADD CONSTRAINT traits_is_array_chk
        CHECK (jsonb_typeof(traits) = 'array');
        RAISE NOTICE 'Added traits array constraint';
    ELSE
        RAISE NOTICE 'Traits array constraint already exists';
    END IF;
END $$;

-- Step 4: Add constraint to limit traits array length (5-10 items)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'traits_length_chk'
    ) THEN
        ALTER TABLE users
        ADD CONSTRAINT traits_length_chk
        CHECK (
            jsonb_array_length(traits) >= 0 AND
            jsonb_array_length(traits) <= 10
        );
        RAISE NOTICE 'Added traits length constraint (0-10 items)';
    ELSE
        RAISE NOTICE 'Traits length constraint already exists';
    END IF;
END $$;

-- Step 5: Add comments for documentation
COMMENT ON COLUMN users.bio IS 'User bio/description text, editable by user';
COMMENT ON COLUMN users.traits IS 'User personal traits (5-10 tags from predefined list), stored as JSON array';

-- Step 6: Create index on traits for faster queries (optional, for future features)
CREATE INDEX IF NOT EXISTS idx_users_traits ON users USING GIN (traits);

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Check columns exist
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'users' AND column_name IN ('bio', 'traits');

-- Check constraints
SELECT conname, pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conname LIKE 'traits%';

-- Check index exists
SELECT indexname, indexdef
FROM pg_indexes
WHERE indexname = 'idx_users_traits';

-- Show sample data
SELECT fid, username, bio, traits
FROM users
ORDER BY created_at DESC
LIMIT 5;

-- ============================================================================
-- SUCCESS!
-- Users can now have bio and traits fields
-- ============================================================================
