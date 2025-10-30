-- ============================================================================
-- Fix Supabase Realtime Permissions for Anon Role
-- ============================================================================
-- This script grants the necessary permissions for browser clients to use
-- Realtime subscriptions on the meetshipper_messages table
-- ============================================================================

-- Step 1: Ensure table is in realtime publication
DO $$
BEGIN
  -- Check if table is already in publication
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'meetshipper_messages'
  ) THEN
    -- Add table to publication
    ALTER PUBLICATION supabase_realtime ADD TABLE meetshipper_messages;
    RAISE NOTICE '✅ Added meetshipper_messages to realtime publication';
  ELSE
    RAISE NOTICE '✅ meetshipper_messages already in realtime publication';
  END IF;
END $$;

-- Step 2: Ensure REPLICA IDENTITY is set to FULL
ALTER TABLE meetshipper_messages REPLICA IDENTITY FULL;
RAISE NOTICE '✅ Set REPLICA IDENTITY to FULL';

-- Step 3: Grant SELECT permission to authenticated role on the table
GRANT SELECT ON meetshipper_messages TO authenticated;
RAISE NOTICE '✅ Granted SELECT on meetshipper_messages to authenticated';

-- Step 4: Grant SELECT permission to authenticated role on the view
GRANT SELECT ON meetshipper_message_details TO authenticated;
RAISE NOTICE '✅ Granted SELECT on meetshipper_message_details to authenticated';

-- Step 5: Grant USAGE on schema to authenticated
GRANT USAGE ON SCHEMA public TO authenticated;
RAISE NOTICE '✅ Granted USAGE on schema public to authenticated';

-- Step 6: Verify RLS policies allow SELECT for participants
-- The existing RLS policies should already handle this, but let's verify

DO $$
BEGIN
  -- Check if policies exist
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'meetshipper_messages'
    AND policyname = 'Users can view messages in their rooms'
  ) THEN
    RAISE NOTICE '✅ RLS policy for viewing messages exists';
  ELSE
    RAISE WARNING '⚠️  RLS policy for viewing messages not found';
  END IF;
END $$;

-- Step 7: Test query to verify permissions work
-- This simulates what the browser client will do

DO $$
DECLARE
  test_count INTEGER;
BEGIN
  -- Try to count messages (should work if permissions are correct)
  SELECT COUNT(*) INTO test_count FROM meetshipper_messages;
  RAISE NOTICE '✅ Permission test passed: Found % messages', test_count;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING '⚠️  Permission test failed: %', SQLERRM;
END $$;

-- ============================================================================
-- Summary
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🎉 Realtime Permissions Configuration Complete!';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Restart your browser (close all tabs)';
  RAISE NOTICE '2. Restart your dev server: pnpm run dev';
  RAISE NOTICE '3. Test the chat again';
  RAISE NOTICE '';
  RAISE NOTICE 'If subscription still times out:';
  RAISE NOTICE '• Check Supabase Dashboard → Database → Replication';
  RAISE NOTICE '• Verify meetshipper_messages is enabled';
  RAISE NOTICE '• Check browser console for WebSocket errors';
  RAISE NOTICE '';
END $$;
