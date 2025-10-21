-- ============================================================================
-- USER CODE SYSTEM - Complete Idempotent Migration
-- ============================================================================
-- Run this ENTIRE file in Supabase SQL Editor
-- Safe to run multiple times (idempotent)
-- ============================================================================

-- Step 1: Add user_code column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'user_code'
    ) THEN
        ALTER TABLE users ADD COLUMN user_code CHAR(10);
        RAISE NOTICE 'Added user_code column';
    ELSE
        RAISE NOTICE 'user_code column already exists';
    END IF;
END $$;

-- Step 2: Add format constraint (exactly 10 digits)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'user_code_format_chk'
    ) THEN
        ALTER TABLE users
        ADD CONSTRAINT user_code_format_chk
        CHECK (user_code ~ '^[0-9]{10}$' OR user_code IS NULL);
        RAISE NOTICE 'Added format constraint';
    ELSE
        RAISE NOTICE 'Format constraint already exists';
    END IF;
END $$;

-- Step 3: Add unique index
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'users_user_code_key'
    ) THEN
        CREATE UNIQUE INDEX users_user_code_key ON users (user_code);
        RAISE NOTICE 'Added unique index';
    ELSE
        RAISE NOTICE 'Unique index already exists';
    END IF;
END $$;

-- Step 4: Create function to generate unique 10-digit code
CREATE OR REPLACE FUNCTION gen_unique_user_code()
RETURNS CHAR(10)
LANGUAGE plpgsql
AS $$
DECLARE
  candidate CHAR(10);
  attempts INT := 0;
  max_attempts INT := 100;
BEGIN
  LOOP
    -- Generate random 10-digit number with leading zeros
    candidate := LPAD(FLOOR(RANDOM() * 10000000000)::BIGINT::TEXT, 10, '0');

    -- Exit loop if this code doesn't exist yet
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM users WHERE user_code = candidate
    );

    -- Safety: prevent infinite loop
    attempts := attempts + 1;
    IF attempts >= max_attempts THEN
      RAISE EXCEPTION 'Failed to generate unique user_code after % attempts', max_attempts;
    END IF;
  END LOOP;

  RETURN candidate;
END;
$$;

-- Step 5: Create trigger function to auto-set user_code on insert
CREATE OR REPLACE FUNCTION set_user_code_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only set if user_code is null
  IF NEW.user_code IS NULL THEN
    NEW.user_code := gen_unique_user_code();
    RAISE NOTICE 'Generated user_code: % for fid: %', NEW.user_code, NEW.fid;
  END IF;
  RETURN NEW;
END;
$$;

-- Step 6: Create trigger (drop and recreate to ensure it's correct)
DROP TRIGGER IF EXISTS trg_set_user_code ON users;

CREATE TRIGGER trg_set_user_code
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION set_user_code_before_insert();

-- Step 7: Backfill existing users with user codes (one at a time to avoid duplicates)
DO $$
DECLARE
  user_record RECORD;
  new_code CHAR(10);
BEGIN
  FOR user_record IN
    SELECT fid FROM users WHERE user_code IS NULL
  LOOP
    new_code := gen_unique_user_code();
    UPDATE users
    SET user_code = new_code
    WHERE fid = user_record.fid;
    RAISE NOTICE 'Assigned code % to fid %', new_code, user_record.fid;
  END LOOP;
END $$;

-- Step 8: Add column comment
COMMENT ON COLUMN users.user_code IS 'Unique 10-digit numeric identifier, automatically generated on insert';

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Check column exists
SELECT
  column_name,
  data_type,
  character_maximum_length,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'user_code';

-- Check constraint exists
SELECT conname, pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conname = 'user_code_format_chk';

-- Check index exists
SELECT indexname, indexdef
FROM pg_indexes
WHERE indexname = 'users_user_code_key';

-- Check trigger exists
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trg_set_user_code';

-- Count users with codes
SELECT
  COUNT(*) as total_users,
  COUNT(user_code) as users_with_codes,
  COUNT(*) - COUNT(user_code) as users_without_codes
FROM users;

-- Show sample codes
SELECT fid, username, user_code
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- ============================================================================
-- SUCCESS!
-- All users should now have unique 10-digit codes
-- ============================================================================
