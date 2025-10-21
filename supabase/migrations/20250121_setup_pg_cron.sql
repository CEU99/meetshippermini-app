-- Enable pg_cron extension (requires superuser or rds_superuser role)
-- This may need to be run manually in Supabase dashboard SQL editor
-- Navigate to: Supabase Dashboard > SQL Editor > New Query
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule the close_expired_chat_rooms function to run every 10 minutes
-- This ensures chat rooms are automatically closed when they exceed the 2-hour TTL
SELECT cron.schedule(
  'close-expired-chat-rooms',           -- job name
  '*/10 * * * *',                       -- every 10 minutes
  $$SELECT close_expired_chat_rooms()$$ -- SQL to execute
);

-- To view scheduled jobs:
-- SELECT * FROM cron.job;

-- To unschedule (if needed for testing/debugging):
-- SELECT cron.unschedule('close-expired-chat-rooms');

-- To manually run the function for testing:
-- SELECT close_expired_chat_rooms();

-- Expected output: Returns the number of rooms that were closed
