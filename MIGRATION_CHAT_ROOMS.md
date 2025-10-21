# Chat Room Migration Guide

## Overview
This guide covers the migration from video meeting links (Whereby/Huddle01) to in-app chat rooms with a 2-hour TTL.

**Status**: App is already deployed to Vercel (production)
**Goal**: Zero-downtime migration
**Timeline**: Follow steps sequentially

---

## Pre-Migration Checklist

- [ ] Backup database (create snapshot in Supabase dashboard)
- [ ] Review current active matches with `status = 'accepted'`
- [ ] Notify users about upcoming changes (optional)
- [ ] Ensure you have access to:
  - Vercel dashboard
  - Supabase dashboard
  - Git repository

---

## Step 1: Database Migration (15 minutes)

### 1.1 Apply Chat Tables Migration

**Via Supabase Dashboard:**
1. Navigate to: Supabase Dashboard > SQL Editor
2. Click "New Query"
3. Copy and paste contents of: `supabase/migrations/20250121_create_chat_tables.sql`
4. Click "Run" and verify success
5. Expected tables created:
   - `chat_rooms`
   - `chat_participants`
   - `chat_messages`

**Via Supabase CLI (Alternative):**
```bash
# If you have Supabase CLI installed
supabase db push
```

### 1.2 Verify Tables & RLS

Run this verification query:
```sql
-- Check tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('chat_rooms', 'chat_participants', 'chat_messages');

-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('chat_rooms', 'chat_participants', 'chat_messages');

-- Should return: rowsecurity = true for all three tables
```

### 1.3 Enable Realtime for Chat Messages

```sql
-- Enable realtime for chat_messages table
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
```

Verify in: Supabase Dashboard > Database > Replication
- Ensure `chat_messages` appears in the publication

---

## Step 2: Setup pg_cron for Auto-Closure (10 minutes)

### 2.1 Enable pg_cron Extension

**Important**: This requires superuser privileges. In Supabase:

1. Navigate to: Supabase Dashboard > SQL Editor
2. Run:
```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

3. If you get permission error, contact Supabase support or enable via:
   - Supabase Dashboard > Database > Extensions
   - Search for "pg_cron" and click "Enable"

### 2.2 Schedule the Cron Job

Run the contents of `supabase/migrations/20250121_setup_pg_cron.sql`:

```sql
SELECT cron.schedule(
  'close-expired-chat-rooms',
  '*/10 * * * *',
  $$SELECT close_expired_chat_rooms()$$
);
```

### 2.3 Verify Cron Job

```sql
-- View scheduled jobs
SELECT * FROM cron.job;

-- Should show: close-expired-chat-rooms running every 10 minutes
```

### 2.4 Test the Function Manually

```sql
-- This should return 0 (no expired rooms yet)
SELECT close_expired_chat_rooms();
```

---

## Step 3: Deploy Code Changes (20 minutes)

### 3.1 Commit and Push Changes

```bash
cd /Users/Cengizhan/Desktop/meetshippermini-app

# Check git status
git status

# Stage all changes
git add .

# Commit
git commit -m "Replace video rooms with in-app chat (2h TTL)

- Add chat_rooms, chat_participants, chat_messages tables
- Implement chat API endpoints
- Create /chat/[roomId] page with realtime messaging
- Update inbox UI to show 'Open Chat' instead of meeting link
- Add pg_cron job for auto-closing expired rooms
- Remove dependency on Whereby/Huddle01 APIs"

# Push to main (triggers Vercel deployment)
git push origin main
```

### 3.2 Monitor Vercel Deployment

1. Go to: https://vercel.com/dashboard
2. Watch deployment logs
3. Wait for "Deployment Ready" status
4. Expected build time: ~2-3 minutes

### 3.3 Verify Deployment

Visit your production URL and check:
- [ ] Inbox page loads without errors
- [ ] No meeting link visible on accepted matches
- [ ] "Open Chat" button appears for accepted matches
- [ ] Console shows no JavaScript errors

---

## Step 4: Remove Video API Keys (5 minutes)

### 4.1 Remove from Vercel Environment Variables

1. Navigate to: Vercel Dashboard > Project > Settings > Environment Variables
2. Delete these variables (if they exist):
   - `WHEREBY_API_KEY`
   - `HUDDLE01_API_KEY`

3. Click "Save" and redeploy (Vercel will auto-redeploy)

### 4.2 Clean Up Code (Optional)

After confirming everything works, you can optionally remove:
- `lib/services/meeting-service.ts` (old video meeting code)

---

## Step 5: Backfill Existing Matches (10 minutes)

Create chat rooms for any existing accepted matches without a chat room:

```sql
-- Run this in Supabase SQL Editor
DO $$
DECLARE
  match_record RECORD;
  new_room_id UUID;
BEGIN
  -- Find all accepted matches without a chat room
  FOR match_record IN
    SELECT m.id, m.user_a_fid, m.user_b_fid
    FROM matches m
    LEFT JOIN chat_rooms cr ON cr.match_id = m.id
    WHERE m.status = 'accepted'
      AND cr.id IS NULL
  LOOP
    -- Create chat room
    INSERT INTO chat_rooms (match_id, opened_at)
    VALUES (match_record.id, now())
    RETURNING id INTO new_room_id;

    -- Create participants
    INSERT INTO chat_participants (room_id, fid)
    VALUES
      (new_room_id, match_record.user_a_fid),
      (new_room_id, match_record.user_b_fid);

    RAISE NOTICE 'Created chat room % for match %', new_room_id, match_record.id;
  END LOOP;
END $$;
```

Verify:
```sql
-- Check how many chat rooms were created
SELECT COUNT(*) FROM chat_rooms;

-- Check matches vs chat rooms
SELECT
  (SELECT COUNT(*) FROM matches WHERE status = 'accepted') as accepted_matches,
  (SELECT COUNT(*) FROM chat_rooms) as chat_rooms;
```

---

## Step 6: Testing & Validation (15 minutes)

### 6.1 Test New Match Flow

1. **Create a test match** (use two test accounts)
2. **Both accept** the match
3. Verify: "Open Chat" button appears
4. Click "Open Chat"
5. Verify: Chat room loads with:
   - [ ] Empty message list
   - [ ] Input field enabled
   - [ ] "Mark Meeting Completed" button visible
   - [ ] Status badge shows "Open (No timer yet)"

### 6.2 Test Messaging

1. Send a message from User A
2. Verify: Message appears in chat
3. Verify: Status badge updates to "Open · 2:00:00"
4. Open chat from User B's account
5. Verify: User B sees User A's message (realtime)
6. Send message from User B
7. Verify: User A sees it in realtime

### 6.3 Test Completion Flow

1. User A clicks "Mark Meeting Completed"
2. Verify: Button changes to "Marked as Completed"
3. User B clicks "Mark Meeting Completed"
4. Verify: Room closes immediately
5. Verify: Input field disabled
6. Verify: Status badge shows "Read-only (Closed)"
7. Verify: Match status changes to "completed" in inbox

### 6.4 Test TTL Expiration (Manual)

**Option 1: Modify TTL for testing**
```sql
-- Create a test room with 1-minute TTL
INSERT INTO chat_rooms (match_id, opened_at, first_join_at, ttl_seconds)
VALUES (
  'some-test-match-id',
  now(),
  now() - interval '61 seconds', -- Started 61 seconds ago
  60 -- 1 minute TTL
);
```

Then run:
```sql
SELECT close_expired_chat_rooms();
-- Should return 1 (closed the test room)
```

**Option 2: Wait for natural expiration**
- Wait 2 hours after first message
- Verify room auto-closes

---

## Step 7: Monitor & Rollback Plan (Ongoing)

### 7.1 Monitoring Checklist

**First 24 hours:**
- [ ] Check Vercel logs for errors
- [ ] Check Supabase logs for failed queries
- [ ] Monitor pg_cron job runs: `SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;`
- [ ] Verify no users report issues
- [ ] Check chat message delivery rate (should be instant)

**First week:**
- [ ] Verify auto-closure is working (check closed rooms)
- [ ] Monitor database size (messages table growth)
- [ ] Check for any stuck rooms (open > 3 hours)

### 7.2 Rollback Plan (If Needed)

**If critical issues arise:**

1. **Revert Vercel Deployment**
   ```bash
   # In Vercel dashboard, click "Deployments"
   # Find the previous working deployment
   # Click "..." > "Promote to Production"
   ```

2. **Restore Database (if needed)**
   - Supabase Dashboard > Database > Backups
   - Select snapshot from before migration
   - Click "Restore"

3. **Re-add Video API Keys**
   - Add `WHEREBY_API_KEY` back to Vercel env vars
   - Redeploy

4. **Keep Chat Tables** (don't drop them)
   - They won't interfere with old system
   - Can retry migration later

---

## Step 8: Post-Migration Cleanup (Optional, after 1 week)

### 8.1 Remove Old Meeting Columns (Optional)

**After confirming everything works for 1 week:**

```sql
-- WARNING: This is irreversible. Only run if you're 100% sure.
-- Consider keeping these columns for historical data.

-- If you really want to remove them:
ALTER TABLE matches DROP COLUMN IF EXISTS meeting_link;
ALTER TABLE matches DROP COLUMN IF EXISTS meeting_state;
ALTER TABLE matches DROP COLUMN IF EXISTS meeting_started_at;
ALTER TABLE matches DROP COLUMN IF EXISTS meeting_expires_at;
ALTER TABLE matches DROP COLUMN IF EXISTS meeting_closed_at;
```

**Recommendation**: Keep these columns for historical data. They won't affect new matches.

### 8.2 Remove Old Code Files

```bash
# Only if you removed meeting columns above
rm lib/services/meeting-service.ts
```

Update any TypeScript interfaces to remove meeting-related fields.

---

## Troubleshooting

### Issue: Chat room not appearing in inbox

**Solution:**
```sql
-- Check if room exists for the match
SELECT * FROM chat_rooms WHERE match_id = 'your-match-id';

-- If not, create it manually:
-- (See Step 5: Backfill query)
```

### Issue: Messages not appearing in realtime

**Solution:**
1. Check Supabase Dashboard > Database > Replication
2. Verify `chat_messages` is in the publication
3. Check browser console for WebSocket errors
4. Verify user is authenticated (check session cookie)

### Issue: pg_cron not running

**Solution:**
```sql
-- Check cron job status
SELECT * FROM cron.job;

-- Check recent runs
SELECT * FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'close-expired-chat-rooms')
ORDER BY start_time DESC
LIMIT 5;

-- If status = 'failed', check return_message column
```

### Issue: Room won't close after 2 hours

**Solution:**
```sql
-- Manually close a specific room
UPDATE chat_rooms
SET is_closed = true, closed_at = now()
WHERE id = 'room-id';

-- Update associated match
UPDATE matches
SET status = 'completed', completed_at = now()
WHERE id = (SELECT match_id FROM chat_rooms WHERE id = 'room-id');
```

### Issue: Users can't send messages (403/400 errors)

**Solution:**
1. Check RLS policies are correct
2. Verify user is a participant:
   ```sql
   SELECT * FROM chat_participants WHERE room_id = 'room-id' AND fid = user_fid;
   ```
3. Check room status:
   ```sql
   SELECT is_closed, first_join_at, ttl_seconds FROM chat_rooms WHERE id = 'room-id';
   ```

---

## Success Criteria

Migration is successful when:

✅ All new accepted matches create chat rooms automatically
✅ Users can send and receive messages in realtime
✅ Chat rooms auto-close after 2 hours from first entry
✅ Completion by both users closes room immediately
✅ No JavaScript errors in browser console
✅ No SQL errors in Supabase logs
✅ pg_cron job runs successfully every 10 minutes
✅ Old meeting link references removed from UI
✅ Zero user complaints about broken functionality

---

## Contact & Support

**Questions or Issues?**
- Check Vercel deployment logs: https://vercel.com/dashboard
- Check Supabase logs: Supabase Dashboard > Logs
- Review this migration guide
- Contact: [Your support contact]

---

## Appendix: SQL Queries for Monitoring

```sql
-- Count active chat rooms
SELECT COUNT(*) FROM chat_rooms WHERE is_closed = false;

-- Count closed chat rooms
SELECT COUNT(*) FROM chat_rooms WHERE is_closed = true;

-- Find rooms approaching expiration
SELECT
  id,
  match_id,
  first_join_at,
  (first_join_at + (ttl_seconds || ' seconds')::interval) as expires_at,
  EXTRACT(EPOCH FROM (first_join_at + (ttl_seconds || ' seconds')::interval - now())) / 60 as minutes_remaining
FROM chat_rooms
WHERE is_closed = false
  AND first_join_at IS NOT NULL
ORDER BY minutes_remaining ASC
LIMIT 10;

-- Count messages sent today
SELECT COUNT(*) FROM chat_messages WHERE created_at > CURRENT_DATE;

-- Average messages per room
SELECT AVG(message_count) FROM (
  SELECT COUNT(*) as message_count
  FROM chat_messages
  GROUP BY room_id
) as counts;

-- Find stuck rooms (open > 3 hours)
SELECT
  cr.*,
  EXTRACT(EPOCH FROM (now() - cr.first_join_at)) / 3600 as hours_open
FROM chat_rooms cr
WHERE cr.is_closed = false
  AND cr.first_join_at IS NOT NULL
  AND now() > (cr.first_join_at + interval '3 hours');
```

---

**END OF MIGRATION GUIDE**
