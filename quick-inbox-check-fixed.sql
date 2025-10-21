-- =====================================================================
-- Quick Inbox Match Check - Supabase Compatible
-- =====================================================================
-- Find a user and check what they should see in their inbox
-- =====================================================================

-- Step 1: Find aysu16's FID and recent users
SELECT
  fid,
  username,
  display_name,
  '🔍 Step 1: Finding user...' as step
FROM users
WHERE username ILIKE '%aysu%'
   OR username ILIKE '%16%'
   OR display_name ILIKE '%aysu%'
ORDER BY created_at DESC
LIMIT 5;

-- =====================================================================
-- ⚙️ CONFIGURATION: Copy the FID from Step 1 above
-- Replace AYSU_FID_HERE with the actual FID number in all queries below
-- =====================================================================

-- =====================================================================
-- Step 2: Check matches involving aysu16 and Emir
-- =====================================================================
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
    WHEN m.user_a_fid = AYSU_FID_HERE THEN '👉 aysu is user_a'
    WHEN m.user_b_fid = AYSU_FID_HERE THEN '👉 aysu is user_b'
    ELSE 'other match'
  END as aysu_role,
  '🔍 Step 2: All aysu matches' as step
FROM matches m
LEFT JOIN users ua ON m.user_a_fid = ua.fid
LEFT JOIN users ub ON m.user_b_fid = ub.fid
WHERE m.user_a_fid = AYSU_FID_HERE
   OR m.user_b_fid = AYSU_FID_HERE
ORDER BY m.created_at DESC;

-- =====================================================================
-- Step 3: Check if match appears with FIXED pending logic
-- =====================================================================
SELECT
  m.id,
  m.status,
  m.a_accepted,
  m.b_accepted,
  m.user_a_username,
  m.user_b_username,
  CASE
    WHEN m.user_a_fid = AYSU_FID_HERE THEN
      CASE WHEN m.a_accepted = false THEN '✅ Should show in pending' ELSE '❌ Already accepted' END
    WHEN m.user_b_fid = AYSU_FID_HERE THEN
      CASE WHEN m.b_accepted = false THEN '✅ Should show in pending' ELSE '❌ Already accepted' END
    ELSE '⚠️  aysu not in match'
  END as pending_check,
  '🔍 Step 3: Pending filter test (FIXED)' as step
FROM match_details m
WHERE (m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE)
  AND (
    (m.user_a_fid = AYSU_FID_HERE AND m.a_accepted = false)
    OR
    (m.user_b_fid = AYSU_FID_HERE AND m.b_accepted = false)
  )
  AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b');

-- =====================================================================
-- Step 4: Check match_details view has the match
-- =====================================================================
SELECT
  EXISTS(
    SELECT 1 FROM match_details m
    WHERE (m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE)
      AND (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
  ) as match_in_view,
  '🔍 Step 4: View check' as step;

-- =====================================================================
-- Step 5: Quick Summary
-- =====================================================================
SELECT
  '=============================================================' as divider1,
  '📊 INBOX CHECK SUMMARY' as title,
  '=============================================================' as divider2,
  '' as blank1,
  'User FID: ' || COALESCE(AYSU_FID_HERE::TEXT, 'NOT FOUND') as user_fid,
  'Total matches: ' || (
    SELECT COUNT(*)::TEXT FROM matches m
    WHERE m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE
  ) as total,
  'Pending matches (should show): ' || (
    SELECT COUNT(*)::TEXT FROM match_details m
    WHERE (m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE)
      AND (
        (m.user_a_fid = AYSU_FID_HERE AND m.a_accepted = false)
        OR
        (m.user_b_fid = AYSU_FID_HERE AND m.b_accepted = false)
      )
      AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
  ) as pending,
  '' as blank2,
  CASE
    WHEN (
      SELECT COUNT(*) FROM match_details m
      WHERE (m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE)
        AND (
          (m.user_a_fid = AYSU_FID_HERE AND m.a_accepted = false)
          OR
          (m.user_b_fid = AYSU_FID_HERE AND m.b_accepted = false)
        )
        AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
    ) > 0 THEN '✅ Match should appear in inbox after fix'
    ELSE '⚠️  No pending matches found'
  END as status,
  '' as blank3,
  CASE
    WHEN (
      SELECT COUNT(*) FROM match_details m
      WHERE (m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE)
        AND (
          (m.user_a_fid = AYSU_FID_HERE AND m.a_accepted = false)
          OR
          (m.user_b_fid = AYSU_FID_HERE AND m.b_accepted = false)
        )
        AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
    ) > 0 THEN 'Next steps:'
    ELSE 'Possible reasons:'
  END as next_label,
  CASE
    WHEN (
      SELECT COUNT(*) FROM match_details m
      WHERE (m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE)
        AND (
          (m.user_a_fid = AYSU_FID_HERE AND m.a_accepted = false)
          OR
          (m.user_b_fid = AYSU_FID_HERE AND m.b_accepted = false)
        )
        AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
    ) > 0 THEN '  1. Restart dev server (npm run dev)'
    ELSE '  - Match already accepted'
  END as step_1,
  CASE
    WHEN (
      SELECT COUNT(*) FROM match_details m
      WHERE (m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE)
        AND (
          (m.user_a_fid = AYSU_FID_HERE AND m.a_accepted = false)
          OR
          (m.user_b_fid = AYSU_FID_HERE AND m.b_accepted = false)
        )
        AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
    ) > 0 THEN '  2. Clear browser cache'
    ELSE '  - Match declined'
  END as step_2,
  CASE
    WHEN (
      SELECT COUNT(*) FROM match_details m
      WHERE (m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE)
        AND (
          (m.user_a_fid = AYSU_FID_HERE AND m.a_accepted = false)
          OR
          (m.user_b_fid = AYSU_FID_HERE AND m.b_accepted = false)
        )
        AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
    ) > 0 THEN '  3. Login as aysu16'
    ELSE '  - User not participant in any matches'
  END as step_3,
  CASE
    WHEN (
      SELECT COUNT(*) FROM match_details m
      WHERE (m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE)
        AND (
          (m.user_a_fid = AYSU_FID_HERE AND m.a_accepted = false)
          OR
          (m.user_b_fid = AYSU_FID_HERE AND m.b_accepted = false)
        )
        AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
    ) > 0 THEN '  4. Go to /mini/inbox'
    ELSE ''
  END as step_4,
  CASE
    WHEN (
      SELECT COUNT(*) FROM match_details m
      WHERE (m.user_a_fid = AYSU_FID_HERE OR m.user_b_fid = AYSU_FID_HERE)
        AND (
          (m.user_a_fid = AYSU_FID_HERE AND m.a_accepted = false)
          OR
          (m.user_b_fid = AYSU_FID_HERE AND m.b_accepted = false)
        )
        AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
    ) > 0 THEN '  5. Check Pending tab'
    ELSE ''
  END as step_5,
  '' as blank4,
  '=============================================================' as divider3,
  '🔍 Step 5: Summary' as step;
