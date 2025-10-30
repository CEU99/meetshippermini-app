-- Quick syntax test for the publication logic
-- This tests the corrected syntax without modifying anything

DO $$
BEGIN
    -- Test: Check if a table is in publication
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'matches'
    ) THEN
        RAISE NOTICE 'matches is NOT in publication (this is just a test check)';
    ELSE
        RAISE NOTICE 'matches is already in publication (this is just a test check)';
    END IF;
END $$;
