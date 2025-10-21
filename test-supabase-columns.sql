-- === Profile fields: bio + traits (idempotent & safe) ==================

-- 1) bio sütunu
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users' AND column_name='bio'
  ) THEN
    ALTER TABLE public.users ADD COLUMN bio TEXT;
    RAISE NOTICE 'Added bio column';
  ELSE
    RAISE NOTICE 'bio column already exists';
  END IF;
END $$;

-- 2) traits sütunu (JSONB dizi)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users' AND column_name='traits'
  ) THEN
    ALTER TABLE public.users ADD COLUMN traits JSONB DEFAULT '[]'::jsonb;
    RAISE NOTICE 'Added traits column';
  ELSE
    RAISE NOTICE 'traits column already exists';
  END IF;
END $$;

-- 3) traits JSONB array ve uzunluk (0–10) kısıtları
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='traits_is_array_chk'
  ) THEN
    ALTER TABLE public.users
      ADD CONSTRAINT traits_is_array_chk
      CHECK (jsonb_typeof(traits) = 'array');
    RAISE NOTICE 'Added traits_is_array_chk';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='traits_length_chk'
  ) THEN
    ALTER TABLE public.users
      ADD CONSTRAINT traits_length_chk
      CHECK (jsonb_array_length(traits) BETWEEN 0 AND 10);
    RAISE NOTICE 'Added traits_length_chk';
  END IF;
END $$;

-- 4) (İsteğe bağlı) hızlı sorgular için GIN index
CREATE INDEX IF NOT EXISTS idx_users_traits_gin ON public.users USING GIN (traits);

-- 5) Varsayılanları boş bırakmak isteyenler için NULL->[] düzeltmesi
UPDATE public.users SET traits='[]'::jsonb WHERE traits IS NULL;

-- 6) Şema cache yenileme RPC’si (yoksa oluştur, sonra çalıştır)
CREATE OR REPLACE FUNCTION public.reload_pgrst_schema()
RETURNS void
LANGUAGE sql
AS $$
  NOTIFY pgrst, 'reload schema';
$$;

-- PostgREST şema cache’ini yenile
SELECT public.reload_pgrst_schema();
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema='public' AND table_name='users' AND column_name IN ('bio','traits');