-- Create attestations table to store EAS attestation records
CREATE TABLE IF NOT EXISTS public.attestations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT NOT NULL,
  wallet_address TEXT NOT NULL,
  tx_hash TEXT NOT NULL,
  attestation_uid TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on wallet_address for faster lookups
CREATE INDEX IF NOT EXISTS idx_attestations_wallet_address ON public.attestations(wallet_address);

-- Create index on username for faster lookups
CREATE INDEX IF NOT EXISTS idx_attestations_username ON public.attestations(username);

-- Create index on attestation_uid for faster lookups
CREATE INDEX IF NOT EXISTS idx_attestations_uid ON public.attestations(attestation_uid);

-- Create index on created_at for ordering
CREATE INDEX IF NOT EXISTS idx_attestations_created_at ON public.attestations(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.attestations ENABLE ROW LEVEL SECURITY;

-- Policy: Allow anyone to read attestations
CREATE POLICY "Anyone can read attestations"
  ON public.attestations
  FOR SELECT
  USING (true);

-- Policy: Allow anyone to insert attestations (can be restricted later)
CREATE POLICY "Anyone can create attestations"
  ON public.attestations
  FOR INSERT
  WITH CHECK (true);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_attestations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_attestations_updated_at
  BEFORE UPDATE ON public.attestations
  FOR EACH ROW
  EXECUTE FUNCTION update_attestations_updated_at();

-- Add comment to the table
COMMENT ON TABLE public.attestations IS 'Stores Ethereum Attestation Service (EAS) attestation records linking usernames to wallet addresses';
