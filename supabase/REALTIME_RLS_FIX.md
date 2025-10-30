# MeetShipper: Realtime + RLS Fix for Chat Room Access

## Problem Statement

When a match is created and both parties mark it as "accepted," only one user (typically the initiator) can see the "Open Chat" button. The other user remains stuck on "Loading chat room..."

### Root Causes

1. **RLS Filtering on Realtime Events**: Supabase Realtime payloads may not include all columns (like `user_a_fid`, `user_b_fid`) due to Row Level Security filtering
2. **Missing Realtime Configuration**: Tables not properly configured for realtime subscriptions
3. **Incomplete RLS Policies**: Policies that don't allow both participants to see and receive updates

## Solution Overview

This fix includes:

1. ✅ **Proper RLS policies** for `matches`, `chat_rooms`, and `messages` tables
2. ✅ **Realtime publication configuration** to broadcast changes to both users
3. ✅ **REPLICA IDENTITY FULL** to ensure all column values are included in realtime events
4. ✅ **Frontend code update** to handle realtime events without relying on filtered fields

---

## Installation Steps

### Option 1: Run in Supabase Dashboard SQL Editor (Recommended)

1. **Open Supabase Dashboard**
   - Go to your project at https://supabase.com/dashboard
   - Navigate to **SQL Editor**

2. **Copy and Run the Migration**
   - Open the file: `supabase/migrations/fix_realtime_rls_for_matches_and_chat.sql`
   - Copy the entire contents
   - Paste into the SQL Editor
   - Click **"Run"**

3. **Verify Success**
   - Check for success messages in the SQL Editor
   - No errors should appear

### Option 2: Run via Supabase CLI

```bash
# Make sure you're in the project root
cd /path/to/meetshippermini-app

# Run the migration
supabase migration up --file supabase/migrations/fix_realtime_rls_for_matches_and_chat.sql

# Or if you have the CLI linked to remote:
supabase db push
```

---

## What This Migration Does

### 1. Enables Realtime on Tables

```sql
ALTER TABLE matches REPLICA IDENTITY FULL;
ALTER TABLE chat_rooms REPLICA IDENTITY FULL;
ALTER TABLE messages REPLICA IDENTITY FULL;
```

- **REPLICA IDENTITY FULL**: Ensures all column values are included in realtime payloads
- This is crucial for RLS to work correctly with realtime subscriptions

### 2. Adds Tables to Realtime Publication

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE matches;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
```

- Supabase uses the `supabase_realtime` publication to broadcast changes
- Both users will receive events when these tables are updated

### 3. Creates RLS Policies for Both Participants

#### Matches Table
- ✅ Both `user_a` and `user_b` can **SELECT** their matches
- ✅ Both can **UPDATE** their acceptance status (`a_accepted`, `b_accepted`)
- ✅ Creators can **INSERT** new matches

#### Chat Rooms Table
- ✅ Both participants can **SELECT** their chat rooms
- ✅ Both can **UPDATE** room state (e.g., mark as read)
- ✅ System can **INSERT** new chat rooms (via backend/trigger)

#### Messages Table
- ✅ Both participants can **SELECT** messages from their rooms
- ✅ Both can **INSERT** new messages
- ✅ Both can **UPDATE** messages (e.g., mark as read)

### 4. Grants Necessary Permissions

```sql
GRANT SELECT, INSERT, UPDATE ON matches TO authenticated;
GRANT SELECT, INSERT, UPDATE ON chat_rooms TO authenticated;
GRANT SELECT, INSERT, UPDATE ON messages TO authenticated;
```

---

## Frontend Changes (Already Applied)

The frontend code in `app/mini/inbox/page.tsx` has been updated to:

### Before (❌ Broken)
```typescript
if (updatedMatch.user_a_fid === user.fid || updatedMatch.user_b_fid === user.fid) {
  // Only one user gets here due to RLS filtering
  await fetchMatches();
}
```

### After (✅ Fixed)
```typescript
// Always refetch matches when ANY match becomes accepted
// This ensures both participants get the update regardless of RLS filtering
await fetchMatches();
console.log('[Inbox] Force refreshed matches after accepted update');
```

**Key Change**: We no longer check `user_a_fid` or `user_b_fid` in the realtime payload. Instead, we always call `fetchMatches()`, which uses RLS-protected API endpoints that correctly filter for each user.

---

## Verification Steps

After running the migration, verify everything works:

### 1. Check Realtime Publication
```sql
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime';
```

Expected output should include:
- `matches`
- `chat_rooms`
- `messages`

### 2. Check RLS Policies
```sql
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('matches', 'chat_rooms', 'messages')
ORDER BY tablename, cmd;
```

Expected output:
- Multiple policies for each table
- Policies for SELECT, INSERT, UPDATE operations

### 3. Check Replica Identity
```sql
SELECT schemaname, tablename,
       CASE relreplident
           WHEN 'd' THEN 'default'
           WHEN 'n' THEN 'nothing'
           WHEN 'f' THEN 'full'
           WHEN 'i' THEN 'index'
       END as replica_identity
FROM pg_class
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE tablename IN ('matches', 'chat_rooms', 'messages')
  AND schemaname = 'public';
```

Expected: All tables should show **'full'** for `replica_identity`

---

## Testing the Fix

### Test Scenario: Match Acceptance Flow

1. **User A** (FID: 12345) creates a match with **User B** (FID: 67890)
2. **User A** accepts the match → `a_accepted = true`, `status = 'accepted_by_a'`
3. **User B** accepts the match → `b_accepted = true`, `status = 'accepted'`
4. **Expected Result**:
   - ✅ Both User A and User B receive a realtime event
   - ✅ Both users' inbox pages call `fetchMatches()`
   - ✅ Both users see the match status update to 'accepted'
   - ✅ Both users see the "Open Chat" button **simultaneously**

### Manual Testing Steps

1. **Open two browser windows**:
   - Window 1: User A logged in
   - Window 2: User B logged in

2. **Create a match**:
   - User A creates a match with User B

3. **Both users accept**:
   - User A clicks "Accept" → should see "Awaiting other party"
   - User B clicks "Accept" → **both should immediately see "Open Chat" button**

4. **Open the chat**:
   - Both users click "Open Chat"
   - Both should enter the same chat room
   - Messages sent by either user should appear in real-time for both

---

## Troubleshooting

### Issue: Still Only One User Sees the Button

**Check 1: Verify Realtime is Enabled**
```sql
-- In Supabase SQL Editor
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND schemaname = 'public'
  AND tablename IN ('matches', 'chat_rooms');
```

If tables are missing, run:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE matches;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;
```

**Check 2: Verify RLS Policies**
```sql
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'matches';
```

If no policies exist, re-run the migration.

**Check 3: Check Frontend Console Logs**

Open browser DevTools → Console → Look for:
```
[Inbox] Match status updated to accepted: {payload}
[Inbox] Force refreshed matches after accepted update
```

Both users should see these logs when the match is accepted.

### Issue: Realtime Events Not Firing

**Solution 1: Restart Supabase Realtime**

In Supabase Dashboard:
1. Go to **Database** → **Replication**
2. Disable and re-enable realtime for the tables
3. Wait 30 seconds for changes to propagate

**Solution 2: Check Replica Identity**
```sql
ALTER TABLE matches REPLICA IDENTITY FULL;
ALTER TABLE chat_rooms REPLICA IDENTITY FULL;
ALTER TABLE messages REPLICA IDENTITY FULL;
```

### Issue: RLS Denies Access

**Verify User Authentication**:
```sql
SELECT auth.uid(); -- Should return the user's UUID
```

**Check User's FID Mapping**:
```sql
SELECT id, fid, username FROM users WHERE id = auth.uid();
```

If the mapping is incorrect, the RLS policies won't work.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Supabase Realtime                        │
│                                                               │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │   Matches    │         │  Chat Rooms  │                  │
│  │  REPLICA ID  │────────▶│  REPLICA ID  │                  │
│  │     FULL     │         │     FULL     │                  │
│  └──────────────┘         └──────────────┘                  │
│         │                         │                          │
│         └────────────┬────────────┘                          │
│                      │                                       │
│              ┌───────▼────────┐                              │
│              │  supabase_     │                              │
│              │   realtime     │                              │
│              │  publication   │                              │
│              └───────┬────────┘                              │
└──────────────────────┼──────────────────────────────────────┘
                       │
           ┌───────────┴───────────┐
           │                       │
    ┌──────▼──────┐         ┌──────▼──────┐
    │   User A    │         │   User B    │
    │  (Inbox)    │         │  (Inbox)    │
    │             │         │             │
    │ RLS Policy: │         │ RLS Policy: │
    │ user_a_fid  │         │ user_b_fid  │
    │ = auth.uid()│         │ = auth.uid()│
    └─────────────┘         └─────────────┘
           │                       │
           └───────────┬───────────┘
                       │
                ┌──────▼──────┐
                │ Both Users  │
                │ See "Open   │
                │ Chat" Button│
                └─────────────┘
```

---

## Additional Resources

- **Supabase Realtime Docs**: https://supabase.com/docs/guides/realtime
- **RLS Policies Guide**: https://supabase.com/docs/guides/auth/row-level-security
- **REPLICA IDENTITY**: https://www.postgresql.org/docs/current/sql-altertable.html#SQL-CREATETABLE-REPLICA-IDENTITY

---

## Summary

✅ **What was fixed**:
1. Enabled realtime on `matches`, `chat_rooms`, and `messages` tables
2. Added tables to the `supabase_realtime` publication
3. Set `REPLICA IDENTITY FULL` to include all columns in realtime events
4. Created comprehensive RLS policies for both participants
5. Updated frontend to not rely on RLS-filtered fields in realtime payloads

✅ **Expected behavior after fix**:
- Both users receive realtime events when matches are accepted
- Both users see the "Open Chat" button simultaneously
- Both users can access the chat room at the same time
- Real-time messaging works correctly for both participants

🚀 **Ready to deploy!**
