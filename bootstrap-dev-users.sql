-- =====================================================================
-- Bootstrap Dev Test Users with Bio and Traits
-- =====================================================================
-- Purpose: Ensure test users (Alice, Emir) have profile data
-- Requirement: Some parts of the app check bio and >= 5 traits
-- Run this after using dev login to ensure users are match-eligible
-- =====================================================================

-- Ensure extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================
-- Alice (Test User - FID 1111)
-- =====================================================================

-- First, check if Alice already exists with a different user_code
DO $$
DECLARE
  existing_code TEXT;
BEGIN
  SELECT user_code INTO existing_code
  FROM public.users
  WHERE fid = 1111;

  IF existing_code IS NOT NULL AND existing_code != '6287777951' THEN
    RAISE NOTICE 'Alice (FID 1111) already has user_code: %, keeping it', existing_code;
  END IF;
END $$;

INSERT INTO public.users (
  fid,
  username,
  display_name,
  avatar_url,
  bio,
  traits,
  user_code,
  created_at,
  updated_at
)
VALUES (
  1111,
  'alice',
  'Alice',
  'https://avatar.vercel.sh/alice',
  'Test user for manual matching. Interested in web3, startups, and meeting new people.',
  '["Founder", "Web3", "Builder", "Open Source", "Community", "Design", "Product"]'::jsonb,
  '6287777951',
  NOW(),
  NOW()
)
ON CONFLICT (fid) DO UPDATE SET
  username = EXCLUDED.username,
  display_name = EXCLUDED.display_name,
  avatar_url = EXCLUDED.avatar_url,
  bio = EXCLUDED.bio,
  traits = EXCLUDED.traits,
  -- Only update user_code if it's NULL or if this doesn't conflict
  user_code = CASE
    WHEN users.user_code IS NULL THEN EXCLUDED.user_code
    ELSE users.user_code
  END,
  updated_at = NOW();

-- =====================================================================
-- Emir (Real User - FID 543581)
-- =====================================================================

-- First, check if Emir already exists with a different user_code
DO $$
DECLARE
  existing_code TEXT;
BEGIN
  SELECT user_code INTO existing_code
  FROM public.users
  WHERE fid = 543581;

  IF existing_code IS NOT NULL AND existing_code != '7189696562' THEN
    RAISE NOTICE 'Emir (FID 543581) already has user_code: %, keeping it', existing_code;
  END IF;
END $$;

INSERT INTO public.users (
  fid,
  username,
  display_name,
  avatar_url,
  bio,
  traits,
  user_code,
  created_at,
  updated_at
)
VALUES (
  543581,
  'cengizhaneu',
  'Emir Cengizhan Ulu',
  'https://avatar.vercel.sh/cengizhaneu',
  'Builder and entrepreneur. Building cool stuff in web3.',
  '["Founder", "Builder", "Web3", "Startups", "Product", "Tech", "Innovation"]'::jsonb,
  '7189696562',
  NOW(),
  NOW()
)
ON CONFLICT (fid) DO UPDATE SET
  username = EXCLUDED.username,
  display_name = EXCLUDED.display_name,
  avatar_url = EXCLUDED.avatar_url,
  bio = EXCLUDED.bio,
  traits = EXCLUDED.traits,
  -- Only update user_code if it's NULL or if this doesn't conflict
  user_code = CASE
    WHEN users.user_code IS NULL THEN EXCLUDED.user_code
    ELSE users.user_code
  END,
  updated_at = NOW();

-- =====================================================================
-- Verify Users Created
-- =====================================================================

SELECT
  fid,
  username,
  display_name,
  bio,
  jsonb_array_length(traits) as trait_count,
  user_code,
  '✅ Ready for matching' as status
FROM public.users
WHERE fid IN (1111, 543581)
ORDER BY fid;

-- =====================================================================
-- Check Match Eligibility
-- =====================================================================

-- Users must have bio and >= 5 traits to be matchable
SELECT
  fid,
  username,
  bio IS NOT NULL AND bio != '' as has_bio,
  jsonb_array_length(COALESCE(traits, '[]'::jsonb)) as trait_count,
  CASE
    WHEN bio IS NOT NULL AND bio != ''
         AND jsonb_array_length(COALESCE(traits, '[]'::jsonb)) >= 5
    THEN '✅ Matchable'
    ELSE '❌ Not matchable'
  END as eligibility
FROM public.users
WHERE fid IN (1111, 543581)
ORDER BY fid;

-- =====================================================================
-- Success Message
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '✅ DEV USERS BOOTSTRAPPED SUCCESSFULLY!';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Users created/updated:';
  RAISE NOTICE '  • Alice (FID 1111) - Test user';
  RAISE NOTICE '  • Emir (FID 543581) - Real user';
  RAISE NOTICE '';
  RAISE NOTICE 'Both users now have:';
  RAISE NOTICE '  ✅ Bio text';
  RAISE NOTICE '  ✅ 7 traits (minimum 5 required)';
  RAISE NOTICE '  ✅ User codes';
  RAISE NOTICE '';
  RAISE NOTICE 'You can now:';
  RAISE NOTICE '  1. Login via /api/dev/login?fid=1111&username=alice...';
  RAISE NOTICE '  2. Access /mini/inbox without redirect';
  RAISE NOTICE '  3. Create and accept matches';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
