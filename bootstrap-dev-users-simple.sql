-- =====================================================================
-- Bootstrap Dev Test Users - Simple Version
-- =====================================================================
-- Purpose: Update ONLY bio and traits for existing users
-- Use this if user_code conflicts occur
-- =====================================================================

-- =====================================================================
-- Alice (Test User - FID 1111)
-- =====================================================================

UPDATE public.users
SET
  bio = 'Test user for manual matching. Interested in web3, startups, and meeting new people.',
  traits = '["Founder", "Web3", "Builder", "Open Source", "Community", "Design", "Product"]'::jsonb,
  updated_at = NOW()
WHERE fid = 1111;

-- If Alice doesn't exist, create her (without user_code - will be set by dev login)
INSERT INTO public.users (
  fid,
  username,
  display_name,
  avatar_url,
  bio,
  traits,
  created_at,
  updated_at
)
SELECT
  1111,
  'alice',
  'Alice',
  'https://avatar.vercel.sh/alice',
  'Test user for manual matching. Interested in web3, startups, and meeting new people.',
  '["Founder", "Web3", "Builder", "Open Source", "Community", "Design", "Product"]'::jsonb,
  NOW(),
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE fid = 1111);

-- =====================================================================
-- Emir (Real User - FID 543581)
-- =====================================================================

UPDATE public.users
SET
  bio = 'Builder and entrepreneur. Building cool stuff in web3.',
  traits = '["Founder", "Builder", "Web3", "Startups", "Product", "Tech", "Innovation"]'::jsonb,
  updated_at = NOW()
WHERE fid = 543581;

-- If Emir doesn't exist, create him (without user_code - will be set by dev login)
INSERT INTO public.users (
  fid,
  username,
  display_name,
  avatar_url,
  bio,
  traits,
  created_at,
  updated_at
)
SELECT
  543581,
  'cengizhaneu',
  'Emir Cengizhan Ulu',
  'https://avatar.vercel.sh/cengizhaneu',
  'Builder and entrepreneur. Building cool stuff in web3.',
  '["Founder", "Builder", "Web3", "Startups", "Product", "Tech", "Innovation"]'::jsonb,
  NOW(),
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.users WHERE fid = 543581);

-- =====================================================================
-- Verify Users Updated
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
  RAISE NOTICE '✅ DEV USERS BOOTSTRAPPED (BIO & TRAITS ONLY)';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Users updated:';
  RAISE NOTICE '  • Alice (FID 1111) - Bio and traits set';
  RAISE NOTICE '  • Emir (FID 543581) - Bio and traits set';
  RAISE NOTICE '';
  RAISE NOTICE 'Both users now have:';
  RAISE NOTICE '  ✅ Bio text';
  RAISE NOTICE '  ✅ 7 traits (minimum 5 required)';
  RAISE NOTICE '  ℹ️  user_code kept as-is (not modified)';
  RAISE NOTICE '';
  RAISE NOTICE 'You can now:';
  RAISE NOTICE '  1. Login via /api/dev/login?fid=1111&username=alice...';
  RAISE NOTICE '  2. Access /mini/inbox without redirect';
  RAISE NOTICE '  3. Create and accept matches';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
