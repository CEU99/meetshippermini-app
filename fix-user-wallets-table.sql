-- Fix user_wallets table
-- This script will drop and recreate the table with correct structure

-- Drop existing table if it exists (including all dependencies)
DROP TABLE IF EXISTS user_wallets CASCADE;

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user_wallets table with correct column names
CREATE TABLE user_wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fid INTEGER NOT NULL UNIQUE,
  wallet_address TEXT NOT NULL,
  chain_id INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key constraint
  CONSTRAINT fk_user_wallets_fid
    FOREIGN KEY (fid)
    REFERENCES users(fid)
    ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX idx_user_wallets_fid ON user_wallets(fid);
CREATE INDEX idx_user_wallets_address ON user_wallets(wallet_address);

-- Add comments
COMMENT ON TABLE user_wallets IS 'Stores wallet addresses linked to Farcaster users';
COMMENT ON COLUMN user_wallets.fid IS 'Farcaster ID of the user';
COMMENT ON COLUMN user_wallets.wallet_address IS 'Ethereum wallet address (0x...)';
COMMENT ON COLUMN user_wallets.chain_id IS 'Chain ID (8453 for Base, 84532 for Base Sepolia)';

-- Enable RLS
ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own wallet" ON user_wallets;
DROP POLICY IF EXISTS "Users can insert their own wallet" ON user_wallets;
DROP POLICY IF EXISTS "Users can update their own wallet" ON user_wallets;

-- Create RLS policies
CREATE POLICY "Users can view their own wallet"
  ON user_wallets
  FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own wallet"
  ON user_wallets
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update their own wallet"
  ON user_wallets
  FOR UPDATE
  USING (true);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON user_wallets TO anon, authenticated, service_role;

-- Verify table structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_wallets'
ORDER BY ordinal_position;
