/**
 * Auto-migration system for user_code column
 * This checks if the column exists and creates it automatically if missing
 */

import { getServerSupabase } from './supabase';

/**
 * Check if user_code column exists in the database
 */
async function checkUserCodeColumnExists(): Promise<boolean> {
  const supabase = getServerSupabase();

  try {
    // Try to select user_code from users table
    const { error } = await supabase
      .from('users')
      .select('user_code')
      .limit(1);

    // If error code is 42703, column doesn't exist
    if (error && error.code === '42703') {
      return false;
    }

    // No error or different error means column exists
    return true;
  } catch (err) {
    console.error('Error checking user_code column:', err);
    return false;
  }
}

/**
 * Run the complete migration to create user_code column and related objects
 */
async function runUserCodeMigration(): Promise<{ success: boolean; error?: string }> {
  const supabase = getServerSupabase();

  console.log('🔄 Starting automatic user_code migration...');

  const migrationSQL = `
-- Step 1: Add user_code column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'user_code'
    ) THEN
        ALTER TABLE users ADD COLUMN user_code CHAR(10);
        RAISE NOTICE 'Added user_code column';
    END IF;
END $$;

-- Step 2: Add format constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'user_code_format_chk'
    ) THEN
        ALTER TABLE users
        ADD CONSTRAINT user_code_format_chk
        CHECK (user_code ~ '^[0-9]{10}$' OR user_code IS NULL);
        RAISE NOTICE 'Added format constraint';
    END IF;
END $$;

-- Step 3: Add unique index
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE indexname = 'users_user_code_key'
    ) THEN
        CREATE UNIQUE INDEX users_user_code_key ON users (user_code);
        RAISE NOTICE 'Added unique index';
    END IF;
END $$;

-- Step 4: Create generator function
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
    candidate := LPAD(FLOOR(RANDOM() * 10000000000)::BIGINT::TEXT, 10, '0');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM users WHERE user_code = candidate);
    attempts := attempts + 1;
    IF attempts >= max_attempts THEN
      RAISE EXCEPTION 'Failed to generate unique user_code';
    END IF;
  END LOOP;
  RETURN candidate;
END;
$$;

-- Step 5: Create trigger function
CREATE OR REPLACE FUNCTION set_user_code_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.user_code IS NULL THEN
    NEW.user_code := gen_unique_user_code();
  END IF;
  RETURN NEW;
END;
$$;

-- Step 6: Create trigger
DROP TRIGGER IF EXISTS trg_set_user_code ON users;
CREATE TRIGGER trg_set_user_code
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION set_user_code_before_insert();

-- Step 7: Backfill existing users
DO $$
DECLARE
  user_record RECORD;
  new_code CHAR(10);
BEGIN
  FOR user_record IN
    SELECT fid FROM users WHERE user_code IS NULL
  LOOP
    new_code := gen_unique_user_code();
    UPDATE users SET user_code = new_code WHERE fid = user_record.fid;
  END LOOP;
END $$;
`;

  try {
    // Execute the migration SQL using rpc call
    const { error } = await supabase.rpc('exec_sql', { sql: migrationSQL });

    if (error) {
      console.error('❌ Migration failed:', error);
      return { success: false, error: error.message };
    }

    console.log('✅ User_code migration completed successfully');
    return { success: true };
  } catch (err) {
    console.error('❌ Migration error:', err);
    return {
      success: false,
      error: err instanceof Error ? err.message : 'Unknown error',
    };
  }
}

/**
 * Main function to ensure user_code column exists
 * Checks if column exists, and creates it if missing
 */
export async function ensureUserCodeColumn(): Promise<{
  exists: boolean;
  migrated: boolean;
  error?: string;
}> {
  const exists = await checkUserCodeColumnExists();

  if (exists) {
    console.log('✅ user_code column already exists');
    return { exists: true, migrated: false };
  }

  console.log('⚠️  user_code column missing, attempting auto-migration...');

  const result = await runUserCodeMigration();

  if (result.success) {
    return { exists: true, migrated: true };
  } else {
    return { exists: false, migrated: false, error: result.error };
  }
}

/**
 * Simple check without auto-migration
 */
export async function checkUserCodeSetup(): Promise<boolean> {
  return await checkUserCodeColumnExists();
}
