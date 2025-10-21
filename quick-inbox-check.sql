-- =====================================================================
-- Quick Inbox Match Check
-- =====================================================================
-- Find a user and check what they should see in their inbox
-- =====================================================================

-- Step 1: Find aysu16's FID
SELECT
  fid,
  username,
  display_name,
  '🔍 Finding user...' as step
FROM users
WHERE username ILIKE '%aysu%'
   OR username ILIKE '%16%'
   OR display_name ILIKE '%aysu%'
ORDER BY created_at DESC
LIMIT 5;

-- Step 2: Check matches involving aysu16 and Emir
-- Replace AYSU_FID with actual FID from step 1
\set aysu_fid 'REPLACE_WITH_ACTUAL_FID'

SELECT
  m.id as match_id,
  m.user_a_fid,
  ua.username as user_a_name,
  m.user_b_fid,
  ub.username as user_b_name,
  m.status,
  m.a_accepted,
  m.b_accepted,
  m.created_at,
  CASE
    WHEN m.user_a_fid = :aysu_fid THEN '👉 aysu is user_a'
    WHEN m.user_b_fid = :aysu_fid THEN '👉 aysu is user_b'
    ELSE 'other match'
  END as aysu_role,
  '🔍 All aysu matches' as step
FROM matches m
LEFT JOIN users ua ON m.user_a_fid = ua.fid
LEFT JOIN users ub ON m.user_b_fid = ub.fid
WHERE m.user_a_fid = :aysu_fid
   OR m.user_b_fid = :aysu_fid
ORDER BY m.created_at DESC;

-- Step 3: Check if match appears with FIXED pending logic
SELECT
  m.id,
  m.status,
  m.a_accepted,
  m.b_accepted,
  CASE
    WHEN m.user_a_fid = :aysu_fid THEN
      CASE WHEN m.a_accepted = false THEN '✅ Should show in pending' ELSE '❌ Already accepted' END
    WHEN m.user_b_fid = :aysu_fid THEN
      CASE WHEN m.b_accepted = false THEN '✅ Should show in pending' ELSE '❌ Already accepted' END
    ELSE '⚠️  aysu not in match'
  END as pending_check,
  '🔍 Pending filter test' as step
FROM match_details m
WHERE (m.user_a_fid = :aysu_fid OR m.user_b_fid = :aysu_fid)
  AND (
    (m.user_a_fid = :aysu_fid AND m.a_accepted = false)
    OR
    (m.user_b_fid = :aysu_fid AND m.b_accepted = false)
  )
  AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b');

-- Step 4: Check match_details view has the match
SELECT EXISTS(
  SELECT 1 FROM match_details
  WHERE (user_a_fid = :aysu_fid OR user_b_fid = :aysu_fid)
    AND (user_a_fid = 543581 OR user_b_fid = 543581)
) as match_in_view,
'🔍 View check' as step;

-- =====================================================================
-- Quick Summary
-- =====================================================================

DO $$
DECLARE
  aysu_fid BIGINT := :aysu_fid;
  match_count INT;
  pending_count INT;
BEGIN
  -- Count all matches
  SELECT COUNT(*)
  INTO match_count
  FROM matches
  WHERE user_a_fid = aysu_fid OR user_b_fid = aysu_fid;

  -- Count pending matches (with fix)
  SELECT COUNT(*)
  INTO pending_count
  FROM match_details m
  WHERE (m.user_a_fid = aysu_fid OR m.user_b_fid = aysu_fid)
    AND (
      (m.user_a_fid = aysu_fid AND m.a_accepted = false)
      OR
      (m.user_b_fid = aysu_fid AND m.b_accepted = false)
    )
    AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b');

  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '📊 INBOX CHECK SUMMARY';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'User FID: %', aysu_fid;
  RAISE NOTICE 'Total matches: %', match_count;
  RAISE NOTICE 'Pending matches (should show): %', pending_count;
  RAISE NOTICE '';
  IF pending_count > 0 THEN
    RAISE NOTICE '✅ Match should appear in inbox after fix';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Restart dev server (npm run dev)';
    RAISE NOTICE '  2. Clear browser cache';
    RAISE NOTICE '  3. Login as aysu16';
    RAISE NOTICE '  4. Go to /mini/inbox';
    RAISE NOTICE '  5. Check Pending tab';
  ELSE
    RAISE NOTICE '⚠️  No pending matches found';
    RAISE NOTICE '';
    RAISE NOTICE 'Possible reasons:';
    RAISE NOTICE '  - Match already accepted';
    RAISE NOTICE '  - Match declined';
    RAISE NOTICE '  - User not participant in any matches';
  END IF;
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
