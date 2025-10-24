-- Create user_wallets table for wallet linking (v2 - Fixed)
-- This table stores wallet addresses linked to Farcaster users

DO $$
BEGIN
  RAISE NOTICE 'Creating user_wallets table...';
END $$;

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop table if exists (for clean reinstall)
DROP TABLE IF EXISTS user_wallets CASCADE;

-- Create user_wallets table
CREATE TABLE user_wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fid INTEGER NOT NULL UNIQUE,
  wallet_address TEXT NOT NULL,
  chain_id INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key to users table
  CONSTRAINT fk_user_wallets_fid
    FOREIGN KEY (fid)
    REFERENCES users(fid)
    ON DELETE CASCADE
);

DO $$
BEGIN
  RAISE NOTICE '✓ Table created';
END $$;

-- Create indexes
CREATE INDEX idx_user_wallets_fid ON user_wallets(fid);
CREATE INDEX idx_user_wallets_address ON user_wallets(wallet_address);

DO $$
BEGIN
  RAISE NOTICE '✓ Indexes created';
END $$;

-- Add comments
COMMENT ON TABLE user_wallets IS 'Stores wallet addresses linked to Farcaster users';
COMMENT ON COLUMN user_wallets.fid IS 'Farcaster ID of the user';
COMMENT ON COLUMN user_wallets.wallet_address IS 'Ethereum wallet address (0x...)';
COMMENT ON COLUMN user_wallets.chain_id IS 'Chain ID (8453 for Base, 84532 for Base Sepolia)';

DO $$
BEGIN
  RAISE NOTICE '✓ Comments added';
END $$;

-- Enable RLS
ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  RAISE NOTICE '✓ RLS enabled';
END $$;

-- Create RLS policies
CREATE POLICY "Users can view wallets"
  ON user_wallets
  FOR SELECT
  USING (true);

CREATE POLICY "Service can insert wallets"
  ON user_wallets
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Service can update wallets"
  ON user_wallets
  FOR UPDATE
  USING (true);

DO $$
BEGIN
  RAISE NOTICE '✓ RLS policies created';
END $$;

-- Grant permissions (no sequence needed for UUID)
GRANT SELECT, INSERT, UPDATE, DELETE ON user_wallets TO anon, authenticated, service_role;

DO $$
BEGIN
  RAISE NOTICE '✓ Permissions granted';
END $$;

-- Verification query
DO $$
DECLARE
  col_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO col_count
  FROM information_schema.columns
  WHERE table_name = 'user_wallets';

  RAISE NOTICE '';
  RAISE NOTICE '=== Verification ===';
  RAISE NOTICE 'Columns in user_wallets table: %', col_count;

  IF col_count = 6 THEN
    RAISE NOTICE '✓ All columns created successfully';
  ELSE
    RAISE NOTICE '✗ Expected 6 columns, found %', col_count;
  END IF;
END $$;

-- Show table structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_wallets'
ORDER BY ordinal_position;
