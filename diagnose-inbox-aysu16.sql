-- =====================================================================
-- Diagnose Missing Match in Inbox - Ready for aysu16
-- =====================================================================
-- User: @aysu16
-- FID: 1394398
-- Emir FID: 543581
-- =====================================================================

-- STEP 1: Verify user details
-- =====================================================================
SELECT
  fid,
  username,
  display_name,
  user_code,
  '🔍 Step 1: User verified' as check
FROM users
WHERE fid = 1394398;

-- =====================================================================
-- STEP 2: Find the match in question
-- =====================================================================
SELECT
  m.id,
  m.user_a_fid,
  m.user_b_fid,
  m.status,
  m.a_accepted,
  m.b_accepted,
  m.created_by,
  m.message,
  m.created_at,
  '🔍 Step 2: Match Record' as check
FROM matches m
WHERE (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
  AND (m.user_a_fid = 1394398 OR m.user_b_fid = 1394398)
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 3: Check which user is user_a and which is user_b
-- =====================================================================
SELECT
  m.id,
  CASE
    WHEN m.user_a_fid = 1394398 THEN '👤 aysu16 is user_a'
    WHEN m.user_b_fid = 1394398 THEN '👤 aysu16 is user_b'
    ELSE '⚠️  aysu16 not found in match!'
  END as aysu_role,
  CASE
    WHEN m.user_a_fid = 543581 THEN '👤 Emir is user_a'
    WHEN m.user_b_fid = 543581 THEN '👤 Emir is user_b'
    ELSE '⚠️  Emir not found in match!'
  END as emir_role,
  m.status,
  m.a_accepted,
  m.b_accepted,
  '🎭 Step 3: User Roles' as check
FROM matches m
WHERE (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
  AND (m.user_a_fid = 1394398 OR m.user_b_fid = 1394398)
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 4: Test FIXED API query for aysu16 (pending scope)
-- =====================================================================
-- This simulates what the FIXED API does for scope=pending
SELECT
  m.id,
  m.user_a_fid,
  m.user_a_username,
  m.user_b_fid,
  m.user_b_username,
  m.status,
  m.a_accepted,
  m.b_accepted,
  CASE
    WHEN m.user_a_fid = 1394398 AND m.a_accepted = false THEN '✅ Would show (user_a, not accepted)'
    WHEN m.user_b_fid = 1394398 AND m.b_accepted = false THEN '✅ Would show (user_b, not accepted)'
    ELSE '❌ Would NOT show'
  END as result,
  '📥 Step 4: Pending Query Test (aysu16)' as check
FROM match_details m
WHERE (
  -- User is participant
  m.user_a_fid = 1394398 OR m.user_b_fid = 1394398
)
AND (
  -- FIXED pending logic: waiting for my response
  (m.user_a_fid = 1394398 AND m.a_accepted = false)
  OR
  (m.user_b_fid = 1394398 AND m.b_accepted = false)
)
AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
ORDER BY m.created_at DESC;

-- =====================================================================
-- STEP 5: Test FIXED API query for Emir (pending scope)
-- =====================================================================
SELECT
  m.id,
  m.user_a_fid,
  m.user_a_username,
  m.user_b_fid,
  m.user_b_username,
  m.status,
  m.a_accepted,
  m.b_accepted,
  CASE
    WHEN m.user_a_fid = 543581 AND m.a_accepted = false THEN '✅ Would show (user_a, not accepted)'
    WHEN m.user_b_fid = 543581 AND m.b_accepted = false THEN '✅ Would show (user_b, not accepted)'
    ELSE '❌ Would NOT show'
  END as result,
  '📥 Step 5: Pending Query Test (Emir)' as check
FROM match_details m
WHERE (
  -- User is participant
  m.user_a_fid = 543581 OR m.user_b_fid = 543581
)
AND (
  -- FIXED pending logic: waiting for my response
  (m.user_a_fid = 543581 AND m.a_accepted = false)
  OR
  (m.user_b_fid = 543581 AND m.b_accepted = false)
)
AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
ORDER BY m.created_at DESC;

-- =====================================================================
-- STEP 6: Check match_details view exists and has data
-- =====================================================================
SELECT
  m.id,
  m.user_a_fid,
  m.user_a_username,
  m.user_b_fid,
  m.user_b_username,
  m.status,
  m.a_accepted,
  m.b_accepted,
  m.created_by,
  '🔍 Step 6: match_details View' as check
FROM match_details m
WHERE (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
  AND (m.user_a_fid = 1394398 OR m.user_b_fid = 1394398)
ORDER BY m.created_at DESC
LIMIT 1;

-- =====================================================================
-- STEP 7: Check if users exist in users table
-- =====================================================================
SELECT
  u.fid,
  u.username,
  u.display_name,
  u.user_code,
  u.bio IS NOT NULL as has_bio,
  jsonb_array_length(COALESCE(u.traits, '[]'::jsonb)) as trait_count,
  CASE
    WHEN u.fid = 1394398 THEN '👤 aysu16'
    WHEN u.fid = 543581 THEN '👤 Emir'
    ELSE '👤 Other'
  END as who,
  '🔍 Step 7: User Records' as check
FROM users u
WHERE u.fid IN (1394398, 543581)
ORDER BY u.fid;

-- =====================================================================
-- STEP 8: Test all scope queries for aysu16
-- =====================================================================

-- Inbox (all relevant)
SELECT 'inbox' as scope, COUNT(*) as match_count, '📊 Step 8: Scope Summary' as check
FROM match_details m
WHERE (m.user_a_fid = 1394398 OR m.user_b_fid = 1394398)
  AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b', 'accepted', 'declined')

UNION ALL

-- Pending (needs my response) - FIXED QUERY
SELECT 'pending' as scope, COUNT(*) as match_count, '📊 Step 8: Scope Summary' as check
FROM match_details m
WHERE (m.user_a_fid = 1394398 OR m.user_b_fid = 1394398)
  AND (
    (m.user_a_fid = 1394398 AND m.a_accepted = false)
    OR
    (m.user_b_fid = 1394398 AND m.b_accepted = false)
  )
  AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')

UNION ALL

-- Awaiting (I accepted, waiting for them) - FIXED QUERY
SELECT 'awaiting' as scope, COUNT(*) as match_count, '📊 Step 8: Scope Summary' as check
FROM match_details m
WHERE (m.user_a_fid = 1394398 OR m.user_b_fid = 1394398)
  AND (
    (m.user_a_fid = 1394398 AND m.a_accepted = true AND m.b_accepted = false)
    OR
    (m.user_b_fid = 1394398 AND m.b_accepted = true AND m.a_accepted = false)
  )
  AND m.status IN ('accepted_by_a', 'accepted_by_b', 'proposed', 'pending')

UNION ALL

-- Accepted (both accepted)
SELECT 'accepted' as scope, COUNT(*) as match_count, '📊 Step 8: Scope Summary' as check
FROM match_details m
WHERE (m.user_a_fid = 1394398 OR m.user_b_fid = 1394398)
  AND m.status = 'accepted'

UNION ALL

-- Declined
SELECT 'declined' as scope, COUNT(*) as match_count, '📊 Step 8: Scope Summary' as check
FROM match_details m
WHERE (m.user_a_fid = 1394398 OR m.user_b_fid = 1394398)
  AND m.status = 'declined'

ORDER BY
  CASE scope
    WHEN 'inbox' THEN 1
    WHEN 'pending' THEN 2
    WHEN 'awaiting' THEN 3
    WHEN 'accepted' THEN 4
    WHEN 'declined' THEN 5
  END;

-- =====================================================================
-- STEP 9: Check for duplicate user entries (potential issue)
-- =====================================================================
SELECT
  u.fid,
  COUNT(*) as entry_count,
  array_agg(u.username) as usernames,
  CASE
    WHEN COUNT(*) > 1 THEN '⚠️  DUPLICATE FID!'
    ELSE '✅ OK'
  END as status,
  '🔍 Step 9: Duplicate Check' as check
FROM users u
WHERE u.fid IN (1394398, 543581)
GROUP BY u.fid;

-- =====================================================================
-- SUMMARY
-- =====================================================================
SELECT
  '📊 DIAGNOSTIC COMPLETE' as summary,
  'Review the results above:' as instructions,
  '1. Step 2: Does the match exist?' as check_1,
  '2. Step 3: Are roles correct?' as check_2,
  '3. Step 4: Does FIXED query show match for aysu16?' as check_3,
  '4. Step 5: Does FIXED query show match for Emir?' as check_4,
  '5. Step 8: Which scopes show matches?' as check_5,
  'If pending shows 0 but inbox shows 1, query filter is wrong.' as tip_1,
  'If both Steps 4 & 5 show ✅, the fix will work!' as tip_2;
