-- =====================================================================
-- Diagnose Missing Match in Inbox
-- =====================================================================
-- Use this to troubleshoot why @aysu16 doesn't see their match
-- =====================================================================

-- Replace these with actual values:
\set new_user_fid 'REPLACE_WITH_AYSU_FID'
\set emir_fid 543581

-- =====================================================================
-- STEP 1: Find the match in question
-- =====================================================================

SELECT
  id,
  user_a_fid,
  user_b_fid,
  status,
  a_accepted,
  b_accepted,
  created_by,
  message,
  created_at,
  '🔍 Match Record' as check
FROM matches
WHERE (user_a_fid = :emir_fid OR user_b_fid = :emir_fid)
  AND (user_a_fid = :new_user_fid OR user_b_fid = :new_user_fid)
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 2: Check which user is user_a and which is user_b
-- =====================================================================

SELECT
  id,
  CASE
    WHEN user_a_fid = :new_user_fid THEN 'aysu16 is user_a'
    WHEN user_b_fid = :new_user_fid THEN 'aysu16 is user_b'
    ELSE 'aysu16 not found in match!'
  END as aysu_role,
  CASE
    WHEN user_a_fid = :emir_fid THEN 'Emir is user_a'
    WHEN user_b_fid = :emir_fid THEN 'Emir is user_b'
    ELSE 'Emir not found in match!'
  END as emir_role,
  status,
  a_accepted,
  b_accepted,
  '🎭 User Roles' as check
FROM matches
WHERE (user_a_fid = :emir_fid OR user_b_fid = :emir_fid)
  AND (user_a_fid = :new_user_fid OR user_b_fid = :new_user_fid)
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 3: Test the API query for aysu16 (pending scope)
-- =====================================================================

-- This simulates what the API does for scope=pending
SELECT
  m.*,
  '📥 Would aysu16 see this (pending)?' as check
FROM match_details m
WHERE (
  -- User is participant
  user_a_fid = :new_user_fid OR user_b_fid = :new_user_fid OR created_by_fid = :new_user_fid
)
AND (
  -- Pending logic: waiting for my response
  (user_a_fid = :new_user_fid AND a_accepted = false AND status IN ('proposed', 'pending'))
  OR
  (user_b_fid = :new_user_fid AND b_accepted = false AND status IN ('proposed', 'pending'))
)
ORDER BY created_at DESC;

-- =====================================================================
-- STEP 4: Test the API query for Emir (pending scope)
-- =====================================================================

SELECT
  m.*,
  '📥 Would Emir see this (pending)?' as check
FROM match_details m
WHERE (
  -- User is participant
  user_a_fid = :emir_fid OR user_b_fid = :emir_fid OR created_by_fid = :emir_fid
)
AND (
  -- Pending logic: waiting for my response
  (user_a_fid = :emir_fid AND a_accepted = false AND status IN ('proposed', 'pending'))
  OR
  (user_b_fid = :emir_fid AND b_accepted = false AND status IN ('proposed', 'pending'))
)
ORDER BY created_at DESC;

-- =====================================================================
-- STEP 5: Check match_details view exists and has data
-- =====================================================================

SELECT
  id,
  user_a_fid,
  user_a_username,
  user_b_fid,
  user_b_username,
  status,
  a_accepted,
  b_accepted,
  created_by,
  '🔍 match_details view' as check
FROM match_details
WHERE (user_a_fid = :emir_fid OR user_b_fid = :emir_fid)
  AND (user_a_fid = :new_user_fid OR user_b_fid = :new_user_fid)
ORDER BY created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 6: Check if users exist in users table
-- =====================================================================

SELECT
  fid,
  username,
  display_name,
  bio IS NOT NULL as has_bio,
  jsonb_array_length(COALESCE(traits, '[]'::jsonb)) as trait_count,
  CASE
    WHEN fid = :new_user_fid THEN '👤 aysu16'
    WHEN fid = :emir_fid THEN '👤 Emir'
    ELSE '👤 Other'
  END as who
FROM users
WHERE fid IN (:new_user_fid, :emir_fid)
ORDER BY fid;

-- =====================================================================
-- STEP 7: Test all scope queries for aysu16
-- =====================================================================

-- Inbox (all relevant)
SELECT 'inbox' as scope, COUNT(*) as match_count
FROM match_details m
WHERE (user_a_fid = :new_user_fid OR user_b_fid = :new_user_fid OR created_by_fid = :new_user_fid)
  AND status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b', 'accepted', 'declined')

UNION ALL

-- Pending (needs my response)
SELECT 'pending' as scope, COUNT(*) as match_count
FROM match_details m
WHERE (user_a_fid = :new_user_fid OR user_b_fid = :new_user_fid OR created_by_fid = :new_user_fid)
  AND (
    (user_a_fid = :new_user_fid AND a_accepted = false AND status IN ('proposed', 'pending'))
    OR
    (user_b_fid = :new_user_fid AND b_accepted = false AND status IN ('proposed', 'pending'))
  )

UNION ALL

-- Awaiting (I accepted, waiting for them)
SELECT 'awaiting' as scope, COUNT(*) as match_count
FROM match_details m
WHERE (user_a_fid = :new_user_fid OR user_b_fid = :new_user_fid OR created_by_fid = :new_user_fid)
  AND (
    (user_a_fid = :new_user_fid AND a_accepted = true AND status IN ('accepted_by_a', 'proposed', 'pending'))
    OR
    (user_b_fid = :new_user_fid AND b_accepted = true AND status IN ('accepted_by_b', 'proposed', 'pending'))
  )

UNION ALL

-- Accepted (both accepted)
SELECT 'accepted' as scope, COUNT(*) as match_count
FROM match_details m
WHERE (user_a_fid = :new_user_fid OR user_b_fid = :new_user_fid OR created_by_fid = :new_user_fid)
  AND status = 'accepted'

UNION ALL

-- Declined
SELECT 'declined' as scope, COUNT(*) as match_count
FROM match_details m
WHERE (user_a_fid = :new_user_fid OR user_b_fid = :new_user_fid OR created_by_fid = :new_user_fid)
  AND status = 'declined';

-- =====================================================================
-- STEP 8: Check for duplicate user entries (potential issue)
-- =====================================================================

SELECT
  fid,
  COUNT(*) as entry_count,
  array_agg(username) as usernames,
  CASE
    WHEN COUNT(*) > 1 THEN '⚠️  DUPLICATE FID!'
    ELSE '✅ OK'
  END as status
FROM users
WHERE fid IN (:new_user_fid, :emir_fid)
GROUP BY fid;

-- =====================================================================
-- STEP 9: Raw OR query test (what API actually does)
-- =====================================================================

-- This exactly matches the API query on line 40-42
SELECT
  id,
  user_a_fid,
  user_b_fid,
  status,
  a_accepted,
  b_accepted,
  '🔍 Raw API pending query for aysu16' as test
FROM match_details
WHERE (user_a_fid = :new_user_fid OR user_b_fid = :new_user_fid OR created_by_fid = :new_user_fid)
  AND (
    (user_a_fid = :new_user_fid AND a_accepted = false AND status IN ('proposed', 'pending'))
    OR
    (user_b_fid = :new_user_fid AND b_accepted = false AND status IN ('proposed', 'pending'))
  );

-- =====================================================================
-- SUMMARY & RECOMMENDATIONS
-- =====================================================================

DO $$
DECLARE
  match_exists BOOLEAN;
  aysu_fid BIGINT := :new_user_fid;
  aysu_is_a BOOLEAN;
  aysu_is_b BOOLEAN;
  match_status TEXT;
BEGIN
  -- Check if match exists
  SELECT EXISTS(
    SELECT 1 FROM matches
    WHERE (user_a_fid = :emir_fid OR user_b_fid = :emir_fid)
      AND (user_a_fid = aysu_fid OR user_b_fid = aysu_fid)
  ) INTO match_exists;

  IF NOT match_exists THEN
    RAISE NOTICE '❌ ISSUE: No match found between aysu16 (%) and Emir (%)', aysu_fid, :emir_fid;
    RAISE NOTICE 'The match may have been deleted or never created.';
    RETURN;
  END IF;

  -- Check user roles
  SELECT
    user_a_fid = aysu_fid,
    user_b_fid = aysu_fid,
    status
  INTO aysu_is_a, aysu_is_b, match_status
  FROM matches
  WHERE (user_a_fid = :emir_fid OR user_b_fid = :emir_fid)
    AND (user_a_fid = aysu_fid OR user_b_fid = aysu_fid)
  LIMIT 1;

  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '📊 DIAGNOSTIC RESULTS';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Match found: ✅';
  RAISE NOTICE 'Match status: %', match_status;
  RAISE NOTICE 'aysu16 role: %', CASE WHEN aysu_is_a THEN 'user_a' ELSE 'user_b' END;
  RAISE NOTICE 'Emir role: %', CASE WHEN aysu_is_a THEN 'user_b' ELSE 'user_a' END;
  RAISE NOTICE '';
  RAISE NOTICE 'Check STEP 7 results above to see which scope shows the match.';
  RAISE NOTICE 'If pending shows 0, but inbox shows 1, the query filter is wrong.';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
