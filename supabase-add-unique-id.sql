-- Add unique 10-digit ID column to users table
-- Run this in your Supabase SQL Editor

-- Add the column
ALTER TABLE users ADD COLUMN IF NOT EXISTS unique_id TEXT UNIQUE;

-- Create an index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_unique_id ON users(unique_id);

-- Add a comment to document the column
COMMENT ON COLUMN users.unique_id IS 'Unique 10-digit identifier for each user, generated on first login';
