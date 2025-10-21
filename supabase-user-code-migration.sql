-- ============================================================================
-- USER CODE SYSTEM - Complete Database Migration
-- ============================================================================
-- This creates a unique 10-digit numeric user code for each user
-- Automatically generated on first insert via database trigger
-- ============================================================================

-- Step 1: Add the user_code column
-- ============================================================================
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS user_code CHAR(10);

-- Step 2: Add format constraint (exactly 10 digits)
-- ============================================================================
ALTER TABLE users
  ADD CONSTRAINT user_code_format_chk
  CHECK (user_code ~ '^[0-9]{10}$' OR user_code IS NULL);

-- Step 3: Add unique index
-- ============================================================================
CREATE UNIQUE INDEX IF NOT EXISTS users_user_code_key
  ON users (user_code);

-- Step 4: Create function to generate unique 10-digit code
-- ============================================================================
CREATE OR REPLACE FUNCTION gen_unique_user_code()
RETURNS CHAR(10)
LANGUAGE plpgsql
AS $$
DECLARE
  candidate CHAR(10);
BEGIN
  LOOP
    -- Generate random 10-digit number with leading zeros
    candidate := LPAD(FLOOR(RANDOM() * 10000000000)::BIGINT::TEXT, 10, '0');

    -- Exit loop if this code doesn't exist yet
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM users WHERE user_code = candidate
    );
  END LOOP;

  RETURN candidate;
END;
$$;

-- Step 5: Create trigger function to auto-set user_code on insert
-- ============================================================================
CREATE OR REPLACE FUNCTION set_user_code_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only set if user_code is null
  IF NEW.user_code IS NULL THEN
    NEW.user_code := gen_unique_user_code();
  END IF;
  RETURN NEW;
END;
$$;

-- Step 6: Drop existing trigger if it exists and create new one
-- ============================================================================
DROP TRIGGER IF EXISTS trg_set_user_code ON users;

CREATE TRIGGER trg_set_user_code
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION set_user_code_before_insert();

-- Step 7: Backfill existing users with user codes
-- ============================================================================
-- This generates codes for any existing users who don't have one
UPDATE users
SET user_code = gen_unique_user_code()
WHERE user_code IS NULL;

-- Step 8: Add comment for documentation
-- ============================================================================
COMMENT ON COLUMN users.user_code IS 'Unique 10-digit numeric identifier for each user, automatically generated on insert';

-- ============================================================================
-- Verification Queries (Optional - run to verify)
-- ============================================================================

-- Check all users have codes:
-- SELECT COUNT(*) as total_users,
--        COUNT(user_code) as users_with_codes
-- FROM users;

-- Check for any duplicates (should return 0):
-- SELECT user_code, COUNT(*)
-- FROM users
-- WHERE user_code IS NOT NULL
-- GROUP BY user_code
-- HAVING COUNT(*) > 1;

-- View sample codes:
-- SELECT fid, username, user_code
-- FROM users
-- LIMIT 10;
