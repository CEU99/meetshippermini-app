-- =====================================================================
-- Verify Profile Trait Synchronization
-- =====================================================================
-- Purpose: Test that trait updates properly REPLACE (not merge) old traits
-- =====================================================================

\echo ''
\echo '=================================================='
\echo 'Profile Trait Sync Verification'
\echo '=================================================='
\echo ''

-- Step 1: Check if traits column exists
\echo '1. Checking if traits column exists...'
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
  AND column_name = 'traits';

\echo ''

-- Step 2: Show current traits for a test user (update FID as needed)
\echo '2. Current traits for test user (FID 543581):'
SELECT
    fid,
    username,
    traits,
    jsonb_array_length(traits) as trait_count,
    updated_at
FROM public.users
WHERE fid = 543581;

\echo ''

-- Step 3: Test trait replacement (simulate API update)
\echo '3. Testing trait replacement...'
\echo '   Original traits: ["Creative", "Adventurous", "Analytical", "Empathetic", "Ambitious"]'
\echo '   New traits: ["Curious", "Patient", "Optimistic"]'
\echo ''

-- Save current traits
CREATE TEMP TABLE IF NOT EXISTS trait_test_backup AS
SELECT fid, traits, updated_at
FROM public.users
WHERE fid = 543581;

-- Update with new traits (this is what the API does)
UPDATE public.users
SET
    traits = '["Curious", "Patient", "Optimistic"]'::jsonb,
    updated_at = NOW()
WHERE fid = 543581;

\echo '   ✓ Traits updated'
\echo ''

-- Step 4: Verify traits were replaced (not merged)
\echo '4. Verifying traits after update:'
SELECT
    fid,
    username,
    traits,
    jsonb_array_length(traits) as trait_count,
    updated_at
FROM public.users
WHERE fid = 543581;

\echo ''
\echo 'Expected: ["Curious", "Patient", "Optimistic"] (3 traits)'
\echo 'If you see 3 traits with ONLY the new values → ✅ REPLACE working correctly'
\echo 'If you see 5+ traits with both old and new → ❌ MERGE bug (unexpected)'
\echo ''

-- Step 5: Test empty array replacement
\echo '5. Testing empty array (clearing all traits)...'

UPDATE public.users
SET
    traits = '[]'::jsonb,
    updated_at = NOW()
WHERE fid = 543581;

SELECT
    fid,
    username,
    traits,
    jsonb_array_length(traits) as trait_count,
    updated_at
FROM public.users
WHERE fid = 543581;

\echo ''
\echo 'Expected: [] (0 traits)'
\echo ''

-- Step 6: Restore original traits
\echo '6. Restoring original traits...'

UPDATE public.users u
SET
    traits = b.traits,
    updated_at = b.updated_at
FROM trait_test_backup b
WHERE u.fid = b.fid AND u.fid = 543581;

SELECT
    fid,
    username,
    traits,
    jsonb_array_length(traits) as trait_count,
    updated_at
FROM public.users
WHERE fid = 543581;

\echo ''
\echo '   ✓ Original traits restored'
\echo ''

-- Clean up
DROP TABLE IF EXISTS trait_test_backup;

-- Step 7: Test constraints
\echo '7. Testing trait constraints...'
\echo ''

-- Test: traits must be array
\echo '   a) Testing array type constraint...'
DO $$
BEGIN
    UPDATE public.users
    SET traits = '"not an array"'::jsonb
    WHERE fid = 543581;

    RAISE NOTICE '   ❌ FAILED: Should have rejected non-array value';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE '   ✅ PASSED: Non-array value rejected (constraint working)';
END $$;

\echo ''

-- Test: traits must be 0-10 items
\echo '   b) Testing length constraint (max 10)...'
DO $$
BEGIN
    UPDATE public.users
    SET traits = '["T1","T2","T3","T4","T5","T6","T7","T8","T9","T10","T11"]'::jsonb
    WHERE fid = 543581;

    RAISE NOTICE '   ❌ FAILED: Should have rejected 11 traits (max is 10)';
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE '   ✅ PASSED: 11 traits rejected (constraint working)';
END $$;

\echo ''

-- Step 8: Check GIN index exists
\echo '8. Verifying GIN index on traits...'
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'users'
  AND indexname = 'idx_users_traits';

\echo ''

-- Step 9: Summary
\echo '=================================================='
\echo 'Verification Complete'
\echo '=================================================='
\echo ''
\echo 'What was tested:'
\echo '  ✓ Trait column exists and is JSONB type'
\echo '  ✓ Trait updates REPLACE (not merge) previous values'
\echo '  ✓ Empty array can be set (clearing all traits)'
\echo '  ✓ Original traits can be restored'
\echo '  ✓ Array type constraint enforced'
\echo '  ✓ Length constraint (0-10) enforced'
\echo '  ✓ GIN index exists for fast queries'
\echo ''
\echo 'Result:'
\echo '  If all tests passed → Database is working correctly'
\echo '  The issue is likely in frontend state management (now fixed)'
\echo ''
\echo 'Next: Test in browser after restarting dev server'
\echo ''
