-- =====================================================================
-- DIAGNOSTIC: Respond Endpoint Issue (Emir ↔ Aysu16)
-- =====================================================================
-- Purpose: Diagnose why /api/matches/:id/respond is failing
-- Run this in: Supabase Dashboard → SQL Editor
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'DIAGNOSTIC SCRIPT: Respond Endpoint Failure';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Testing match between:';
  RAISE NOTICE '  • Emir (@cengizhaneu) - FID: 543581';
  RAISE NOTICE '  • Aysu16 (@aysu16) - FID: 1394398';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;

-- =====================================================================
-- CHECK 1: Verify Users Exist
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 1: User Records';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  fid,
  username,
  display_name,
  user_code,
  traits IS NOT NULL as has_traits,
  avatar_url IS NOT NULL as has_avatar,
  created_at
FROM public.users
WHERE fid IN (543581, 1394398)
ORDER BY fid;

-- =====================================================================
-- CHECK 2: Verify Match Record Exists
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 2: Match Record';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  m.id,
  m.user_a_fid,
  ua.username as user_a_username,
  m.user_b_fid,
  ub.username as user_b_username,
  m.created_by_fid,
  uc.username as creator_username,
  m.status,
  m.a_accepted,
  m.b_accepted,
  m.created_by,
  m.rationale IS NOT NULL as has_rationale,
  m.meeting_link,
  m.message,
  m.created_at
FROM public.matches m
LEFT JOIN public.users ua ON m.user_a_fid = ua.fid
LEFT JOIN public.users ub ON m.user_b_fid = ub.fid
LEFT JOIN public.users uc ON m.created_by_fid = uc.fid
WHERE (m.user_a_fid = 543581 AND m.user_b_fid = 1394398)
   OR (m.user_a_fid = 1394398 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 5;

-- =====================================================================
-- CHECK 3: Verify matches Table Schema
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 3: matches Table Columns';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'matches'
ORDER BY ordinal_position;

-- =====================================================================
-- CHECK 4: Verify match_details View Schema
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 4: match_details View Columns';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'match_details'
ORDER BY ordinal_position;

-- =====================================================================
-- CHECK 5: Check for Missing Required Columns
-- =====================================================================

DO $$
DECLARE
  missing_cols TEXT[];
  required_cols TEXT[] := ARRAY['created_by', 'rationale', 'meeting_link', 'scheduled_at'];
  col_name TEXT;
  col_exists BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 5: Missing Required Columns';
  RAISE NOTICE '-------------------------------------------------------------';

  FOREACH col_name IN ARRAY required_cols
  LOOP
    SELECT EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'matches'
        AND column_name = col_name
    ) INTO col_exists;

    IF NOT col_exists THEN
      missing_cols := array_append(missing_cols, col_name);
      RAISE NOTICE '❌ MISSING: %', col_name;
    ELSE
      RAISE NOTICE '✓ EXISTS: %', col_name;
    END IF;
  END LOOP;

  IF array_length(missing_cols, 1) > 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  WARNING: Missing columns detected!';
    RAISE NOTICE 'Run fix-respond-endpoint-complete.sql to add them.';
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE '✅ All required columns exist';
  END IF;
END $$;

-- =====================================================================
-- CHECK 6: Verify Status Constraint
-- =====================================================================

DO $$
DECLARE
  constraint_def TEXT;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 6: Status Constraint';
  RAISE NOTICE '-------------------------------------------------------------';

  SELECT pg_get_constraintdef(oid)
  INTO constraint_def
  FROM pg_constraint
  WHERE conrelid = 'public.matches'::regclass
    AND contype = 'c'
    AND conname LIKE '%status%';

  IF constraint_def IS NOT NULL THEN
    RAISE NOTICE 'Constraint: %', constraint_def;
  ELSE
    RAISE NOTICE '⚠️  No status constraint found';
  END IF;
END $$;

-- =====================================================================
-- CHECK 7: Check Triggers on matches Table
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 7: Triggers on matches Table';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'matches'
ORDER BY trigger_name;

-- =====================================================================
-- CHECK 8: Test match_details View Query
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 8: Test match_details View Query';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

-- Try to query the view for the specific match
SELECT
  id,
  user_a_fid,
  user_a_username,
  user_a_traits IS NOT NULL as has_user_a_traits,
  user_b_fid,
  user_b_username,
  user_b_traits IS NOT NULL as has_user_b_traits,
  created_by_fid,
  created_by,
  creator_username,
  status,
  a_accepted,
  b_accepted,
  rationale IS NOT NULL as has_rationale,
  meeting_link,
  created_at
FROM public.match_details
WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
   OR (user_a_fid = 1394398 AND user_b_fid = 543581)
ORDER BY created_at DESC
LIMIT 5;

-- =====================================================================
-- CHECK 9: Simulate Accept Action
-- =====================================================================

DO $$
DECLARE
  v_match_id UUID;
  v_user_a_fid BIGINT;
  v_user_b_fid BIGINT;
  v_emir_is_a BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 9: Simulate Accept Action';
  RAISE NOTICE '-------------------------------------------------------------';

  -- Get the match
  SELECT id, user_a_fid, user_b_fid
  INTO v_match_id, v_user_a_fid, v_user_b_fid
  FROM public.matches
  WHERE (user_a_fid = 543581 AND user_b_fid = 1394398)
     OR (user_a_fid = 1394398 AND user_b_fid = 543581)
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_match_id IS NULL THEN
    RAISE NOTICE '❌ No match found between Emir and Aysu16';
    RETURN;
  END IF;

  RAISE NOTICE 'Match ID: %', v_match_id;
  RAISE NOTICE 'User A (FID %): %', v_user_a_fid, (SELECT username FROM users WHERE fid = v_user_a_fid);
  RAISE NOTICE 'User B (FID %): %', v_user_b_fid, (SELECT username FROM users WHERE fid = v_user_b_fid);

  -- Determine if Emir is user_a or user_b
  v_emir_is_a := (v_user_a_fid = 543581);

  IF v_emir_is_a THEN
    RAISE NOTICE '';
    RAISE NOTICE 'Emir is User A - would update a_accepted = true';
    RAISE NOTICE 'SQL: UPDATE matches SET a_accepted = true WHERE id = ''%''', v_match_id;
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE 'Emir is User B - would update b_accepted = true';
    RAISE NOTICE 'SQL: UPDATE matches SET b_accepted = true WHERE id = ''%''', v_match_id;
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE 'NOTE: This is a simulation - no actual update performed';
END $$;

-- =====================================================================
-- CHECK 10: Check RLS Policies (if enabled)
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'CHECK 10: Row Level Security';
  RAISE NOTICE '-------------------------------------------------------------';
END $$;

SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'matches';

-- Show policies if RLS is enabled
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'matches';

-- =====================================================================
-- SUMMARY
-- =====================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE 'DIAGNOSTIC COMPLETE';
  RAISE NOTICE '=============================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Review the output above to identify issues:';
  RAISE NOTICE '';
  RAISE NOTICE '1. Both users should exist (CHECK 1)';
  RAISE NOTICE '2. A match record should exist (CHECK 2)';
  RAISE NOTICE '3. All required columns should exist (CHECK 5)';
  RAISE NOTICE '4. match_details view should be complete (CHECK 4)';
  RAISE NOTICE '5. Status constraint should include all statuses (CHECK 6)';
  RAISE NOTICE '6. RLS should be disabled or have proper policies (CHECK 10)';
  RAISE NOTICE '';
  RAISE NOTICE 'If issues found, run: fix-respond-endpoint-complete.sql';
  RAISE NOTICE '';
  RAISE NOTICE '=============================================================';
END $$;
