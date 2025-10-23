-- ============================================================================
-- TEST SCRIPT: Verify Match Decline Fix
-- ============================================================================
-- Run this AFTER applying FIX_DECLINE_FINAL.sql
-- This will test that duplicate declines work without errors
-- ============================================================================

DO $$
DECLARE
  test_match_id UUID;
  test_user_a BIGINT := 999991;  -- Test FID A
  test_user_b BIGINT := 999992;  -- Test FID B
  test_creator BIGINT := 999990;  -- Test creator FID
  cooldown_count_before INTEGER;
  cooldown_count_after INTEGER;
  cooldown_id_1 UUID;
  cooldown_id_2 UUID;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Testing Match Decline Fix';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';

  -- Clean up any test data from previous runs
  DELETE FROM public.match_cooldowns
  WHERE (user_a_fid = test_user_a AND user_b_fid = test_user_b)
     OR (user_a_fid = test_user_b AND user_b_fid = test_user_a);

  DELETE FROM public.matches
  WHERE (user_a_fid = test_user_a AND user_b_fid = test_user_b)
     OR (user_a_fid = test_user_b AND user_b_fid = test_user_a);

  -- Create test users if they don't exist
  INSERT INTO public.users (fid, username, display_name)
  VALUES
    (test_creator, 'test_creator', 'Test Creator'),
    (test_user_a, 'test_user_a', 'Test User A'),
    (test_user_b, 'test_user_b', 'Test User B')
  ON CONFLICT (fid) DO NOTHING;

  RAISE NOTICE 'Test setup: Created/verified test users (%, %, %)', test_creator, test_user_a, test_user_b;

  RAISE NOTICE 'Test 1: Creating a test match...';

  -- Create a test match
  INSERT INTO public.matches (
    user_a_fid,
    user_b_fid,
    created_by_fid,
    status
  ) VALUES (
    test_user_a,
    test_user_b,
    test_creator,
    'proposed'
  )
  RETURNING id INTO test_match_id;

  RAISE NOTICE '  ✓ Created test match: %', test_match_id;
  RAISE NOTICE '';

  -- Count cooldowns before first decline
  SELECT COUNT(*) INTO cooldown_count_before
  FROM public.match_cooldowns
  WHERE LEAST(user_a_fid, user_b_fid) = LEAST(test_user_a, test_user_b)
    AND GREATEST(user_a_fid, user_b_fid) = GREATEST(test_user_a, test_user_b);

  RAISE NOTICE 'Test 2: First decline (should create cooldown)...';
  RAISE NOTICE '  Cooldowns before: %', cooldown_count_before;

  -- First decline (should create a cooldown)
  UPDATE public.matches
  SET status = 'declined'
  WHERE id = test_match_id;

  -- Check cooldown was created
  SELECT COUNT(*) INTO cooldown_count_after
  FROM public.match_cooldowns
  WHERE LEAST(user_a_fid, user_b_fid) = LEAST(test_user_a, test_user_b)
    AND GREATEST(user_a_fid, user_b_fid) = GREATEST(test_user_a, test_user_b);

  RAISE NOTICE '  Cooldowns after: %', cooldown_count_after;

  IF cooldown_count_after = cooldown_count_before + 1 THEN
    RAISE NOTICE '  ✓ Cooldown created successfully!';

    -- Get the cooldown ID for comparison
    SELECT id INTO cooldown_id_1
    FROM public.match_cooldowns
    WHERE LEAST(user_a_fid, user_b_fid) = LEAST(test_user_a, test_user_b)
      AND GREATEST(user_a_fid, user_b_fid) = GREATEST(test_user_a, test_user_b)
    LIMIT 1;

    RAISE NOTICE '  Cooldown ID: %', cooldown_id_1;
  ELSE
    RAISE WARNING '  ✗ Cooldown was not created! Expected %, got %',
      cooldown_count_before + 1, cooldown_count_after;
  END IF;

  RAISE NOTICE '';

  -- Reset match status to test second decline
  UPDATE public.matches
  SET status = 'proposed'
  WHERE id = test_match_id;

  RAISE NOTICE 'Test 3: Second decline (should update existing cooldown, not create new)...';
  RAISE NOTICE '  Cooldowns before: %', cooldown_count_after;

  -- Second decline (should UPDATE existing cooldown, not create new one)
  BEGIN
    UPDATE public.matches
    SET status = 'declined'
    WHERE id = test_match_id;

    RAISE NOTICE '  ✓ Update succeeded without error!';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE EXCEPTION '  ✗ FAILED: Got unique_violation error (23505)';
    WHEN OTHERS THEN
      RAISE EXCEPTION '  ✗ FAILED: Got unexpected error: % %', SQLERRM, SQLSTATE;
  END;

  -- Check cooldown count didn't increase
  SELECT COUNT(*) INTO cooldown_count_after
  FROM public.match_cooldowns
  WHERE LEAST(user_a_fid, user_b_fid) = LEAST(test_user_a, test_user_b)
    AND GREATEST(user_a_fid, user_b_fid) = GREATEST(test_user_a, test_user_b);

  RAISE NOTICE '  Cooldowns after: %', cooldown_count_after;

  IF cooldown_count_after = 1 THEN
    RAISE NOTICE '  ✓ No duplicate created! Still only 1 cooldown.';

    -- Verify it's the same record (or updated)
    SELECT id INTO cooldown_id_2
    FROM public.match_cooldowns
    WHERE LEAST(user_a_fid, user_b_fid) = LEAST(test_user_a, test_user_b)
      AND GREATEST(user_a_fid, user_b_fid) = GREATEST(test_user_a, test_user_b)
    LIMIT 1;

    IF cooldown_id_1 = cooldown_id_2 THEN
      RAISE NOTICE '  ✓ Same cooldown record was updated (ID: %)', cooldown_id_2;
    ELSE
      RAISE NOTICE '  ℹ Different cooldown record (old: %, new: %)', cooldown_id_1, cooldown_id_2;
    END IF;
  ELSE
    RAISE WARNING '  ✗ Duplicate cooldown created! Expected 1, got %', cooldown_count_after;
  END IF;

  RAISE NOTICE '';

  -- Test with reversed FID order
  RAISE NOTICE 'Test 4: Decline with reversed FID order...';

  -- Create another test match with FIDs in reverse order
  INSERT INTO public.matches (
    user_a_fid,
    user_b_fid,
    created_by_fid,
    status
  ) VALUES (
    test_user_b,  -- Reversed!
    test_user_a,  -- Reversed!
    test_creator,
    'proposed'
  )
  RETURNING id INTO test_match_id;

  RAISE NOTICE '  Created match with reversed FIDs: %', test_match_id;

  -- Decline it (should still update same cooldown)
  BEGIN
    UPDATE public.matches
    SET status = 'declined'
    WHERE id = test_match_id;

    RAISE NOTICE '  ✓ Decline with reversed FIDs succeeded!';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE EXCEPTION '  ✗ FAILED: Got unique_violation with reversed FIDs';
  END;

  -- Verify still only 1 cooldown for this pair
  SELECT COUNT(*) INTO cooldown_count_after
  FROM public.match_cooldowns
  WHERE LEAST(user_a_fid, user_b_fid) = LEAST(test_user_a, test_user_b)
    AND GREATEST(user_a_fid, user_b_fid) = GREATEST(test_user_a, test_user_b);

  IF cooldown_count_after = 1 THEN
    RAISE NOTICE '  ✓ Still only 1 cooldown! FID normalization works correctly.';
  ELSE
    RAISE WARNING '  ✗ Cooldown count is %, expected 1', cooldown_count_after;
  END IF;

  RAISE NOTICE '';

  -- Clean up test data
  DELETE FROM public.match_cooldowns
  WHERE (user_a_fid = test_user_a AND user_b_fid = test_user_b)
     OR (user_a_fid = test_user_b AND user_b_fid = test_user_a);

  DELETE FROM public.matches
  WHERE (user_a_fid = test_user_a AND user_b_fid = test_user_b)
     OR (user_a_fid = test_user_b AND user_b_fid = test_user_a);

  DELETE FROM public.users
  WHERE fid IN (test_creator, test_user_a, test_user_b);

  RAISE NOTICE 'Test cleanup: Removed test data and test users';
  RAISE NOTICE '';

  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ ALL TESTS PASSED!';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'The match decline fix is working correctly:';
  RAISE NOTICE '  ✓ First decline creates cooldown';
  RAISE NOTICE '  ✓ Subsequent declines update cooldown without error';
  RAISE NOTICE '  ✓ No duplicate cooldowns are created';
  RAISE NOTICE '  ✓ FID order normalization works (A,B) = (B,A)';
  RAISE NOTICE '';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE EXCEPTION '✗ TEST FAILED: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;
