-- =====================================================================
-- Attestations User Isolation Migration
-- =====================================================================
-- This migration adds user isolation to the attestations table
-- Run this SQL in your Supabase SQL Editor
-- =====================================================================

-- Step 1: Add fid column to attestations table
-- This links each attestation to a specific Farcaster user
ALTER TABLE public.attestations
ADD COLUMN IF NOT EXISTS fid BIGINT;

-- Step 2: Add foreign key constraint to users table
-- This ensures referential integrity
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'attestations_fid_fkey'
          AND conrelid = 'public.attestations'::regclass
    ) THEN
        ALTER TABLE public.attestations
        ADD CONSTRAINT attestations_fid_fkey
        FOREIGN KEY (fid) REFERENCES public.users(fid) ON DELETE CASCADE;
    END IF;
END $$;

-- Step 3: Create index on fid for faster lookups
CREATE INDEX IF NOT EXISTS idx_attestations_fid ON public.attestations(fid);

-- Step 4: Backfill existing attestations with fid based on username
-- This attempts to match existing attestations to users by username
UPDATE public.attestations a
SET fid = u.fid
FROM public.users u
WHERE a.fid IS NULL
  AND LOWER(a.username) = LOWER(u.username);

-- Step 5: Drop old RLS policies
DROP POLICY IF EXISTS "Anyone can read attestations" ON public.attestations;
DROP POLICY IF EXISTS "Anyone can create attestations" ON public.attestations;

-- Step 6: Create new RLS policies for user isolation
-- Policy: Users can only read their own attestations
CREATE POLICY "Users can read own attestations"
  ON public.attestations
  FOR SELECT
  USING (
    fid IN (
      SELECT fid FROM public.users
      WHERE fid = (current_setting('app.current_user_fid', true))::bigint
    )
  );

-- Policy: Users can only insert their own attestations
CREATE POLICY "Users can create own attestations"
  ON public.attestations
  FOR INSERT
  WITH CHECK (
    fid IN (
      SELECT fid FROM public.users
      WHERE fid = (current_setting('app.current_user_fid', true))::bigint
    )
  );

-- Policy: Users can only update their own attestations
CREATE POLICY "Users can update own attestations"
  ON public.attestations
  FOR UPDATE
  USING (
    fid IN (
      SELECT fid FROM public.users
      WHERE fid = (current_setting('app.current_user_fid', true))::bigint
    )
  );

-- Policy: Users can only delete their own attestations
CREATE POLICY "Users can delete own attestations"
  ON public.attestations
  FOR DELETE
  USING (
    fid IN (
      SELECT fid FROM public.users
      WHERE fid = (current_setting('app.current_user_fid', true))::bigint
    )
  );

-- Step 7: Add comment to the fid column
COMMENT ON COLUMN public.attestations.fid IS 'Farcaster ID of the user who owns this attestation';

-- =====================================================================
-- Verification Query
-- =====================================================================
-- Run this to verify the migration:
-- SELECT
--   a.id,
--   a.username,
--   a.fid,
--   u.username as user_username
-- FROM public.attestations a
-- LEFT JOIN public.users u ON a.fid = u.fid;
-- =====================================================================
