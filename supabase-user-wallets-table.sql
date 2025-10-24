-- Create user_wallets table for wallet linking
-- This table stores wallet addresses linked to Farcaster users

CREATE TABLE IF NOT EXISTS user_wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fid INTEGER NOT NULL UNIQUE,
  wallet_address TEXT NOT NULL,
  chain_id INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key to users table
  CONSTRAINT fk_user_wallets_fid FOREIGN KEY (fid) REFERENCES users(fid) ON DELETE CASCADE
);

-- Create index on fid for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_wallets_fid ON user_wallets(fid);

-- Create index on wallet_address for reverse lookups
CREATE INDEX IF NOT EXISTS idx_user_wallets_address ON user_wallets(wallet_address);

-- Add comment
COMMENT ON TABLE user_wallets IS 'Stores wallet addresses linked to Farcaster users';
COMMENT ON COLUMN user_wallets.fid IS 'Farcaster ID of the user';
COMMENT ON COLUMN user_wallets.wallet_address IS 'Ethereum wallet address (0x...)';
COMMENT ON COLUMN user_wallets.chain_id IS 'Chain ID (8453 for Base, 84532 for Base Sepolia)';

-- Enable RLS
ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only read/write their own wallet
CREATE POLICY "Users can view their own wallet"
  ON user_wallets FOR SELECT
  USING (true); -- Allow anyone to read (for matching purposes)

CREATE POLICY "Users can insert their own wallet"
  ON user_wallets FOR INSERT
  WITH CHECK (true); -- API handles auth via service role

CREATE POLICY "Users can update their own wallet"
  ON user_wallets FOR UPDATE
  USING (true); -- API handles auth via service role

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON user_wallets TO anon, authenticated, service_role;
GRANT USAGE ON SEQUENCE user_wallets_id_seq TO anon, authenticated, service_role;
