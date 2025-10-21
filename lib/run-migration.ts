/**
 * Migration runner using Supabase REST API
 * This can execute SQL directly using the service role key
 */

export async function runUserCodeMigration(): Promise<{
  success: boolean;
  error?: string;
}> {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !serviceKey) {
    return {
      success: false,
      error: 'Missing Supabase credentials',
    };
  }

  console.log('🔄 Running user_code migration via SQL API...');

  const migrationSQL = `
-- Add user_code column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'user_code'
    ) THEN
        ALTER TABLE users ADD COLUMN user_code CHAR(10);
    END IF;
END $$;

-- Add format constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'user_code_format_chk'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT user_code_format_chk
        CHECK (user_code ~ '^[0-9]{10}$' OR user_code IS NULL);
    END IF;
END $$;

-- Add unique index
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE indexname = 'users_user_code_key'
    ) THEN
        CREATE UNIQUE INDEX users_user_code_key ON users (user_code);
    END IF;
END $$;

-- Create generator function
CREATE OR REPLACE FUNCTION gen_unique_user_code()
RETURNS CHAR(10) LANGUAGE plpgsql AS $$
DECLARE
  candidate CHAR(10);
  attempts INT := 0;
BEGIN
  LOOP
    candidate := LPAD(FLOOR(RANDOM() * 10000000000)::BIGINT::TEXT, 10, '0');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM users WHERE user_code = candidate);
    attempts := attempts + 1;
    IF attempts >= 100 THEN
      RAISE EXCEPTION 'Failed to generate unique code';
    END IF;
  END LOOP;
  RETURN candidate;
END $$;

-- Create trigger function
CREATE OR REPLACE FUNCTION set_user_code_before_insert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.user_code IS NULL THEN
    NEW.user_code := gen_unique_user_code();
  END IF;
  RETURN NEW;
END $$;

-- Create trigger
DROP TRIGGER IF EXISTS trg_set_user_code ON users;
CREATE TRIGGER trg_set_user_code
  BEFORE INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION set_user_code_before_insert();

-- Backfill existing users
DO $$
DECLARE
  user_rec RECORD;
  new_code CHAR(10);
BEGIN
  FOR user_rec IN SELECT fid FROM users WHERE user_code IS NULL LOOP
    new_code := gen_unique_user_code();
    UPDATE users SET user_code = new_code WHERE fid = user_rec.fid;
  END LOOP;
END $$;
`;

  try {
    // Use Supabase's SQL endpoint
    const response = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
      },
      body: JSON.stringify({ query: migrationSQL }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('❌ Migration failed:', error);
      return { success: false, error };
    }

    console.log('✅ Migration completed successfully');
    return { success: true };
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : 'Unknown error';
    console.error('❌ Migration error:', errorMsg);
    return { success: false, error: errorMsg };
  }
}

/**
 * Check if user_code column exists
 */
export async function checkUserCodeExists(): Promise<boolean> {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !serviceKey) {
    return false;
  }

  try {
    const response = await fetch(
      `${supabaseUrl}/rest/v1/users?select=user_code&limit=1`,
      {
        headers: {
          apikey: serviceKey,
          Authorization: `Bearer ${serviceKey}`,
        },
      }
    );

    // If we get a 42703 error in the response, column doesn't exist
    if (!response.ok) {
      const error = await response.json();
      if (error.code === '42703') {
        return false;
      }
    }

    return response.ok;
  } catch (err) {
    console.error('Error checking user_code column:', err);
    return false;
  }
}
