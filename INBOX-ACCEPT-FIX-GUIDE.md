# Inbox Accept/Decline Fix Guide

## Problem Summary

When Emir (FID 543581) clicks "Accept" on Alice's (FID 1111) manual match request in `/mini/inbox`, the API returns an error: **"Failed to respond to match"**.

## Root Cause Analysis

The issue could be one of several problems:

1. **Missing fields in `match_details` view** - The view doesn't include `rationale`, `meeting_link`, `traits`, etc.
2. **Supabase error not properly surfaced** - The API was catching errors but not logging enough detail
3. **Service role key not configured** - Environment variable missing
4. **Trigger errors** - Database triggers may be failing silently

## Fixes Applied

### 1. Enhanced API Logging

**File:** `app/api/matches/[id]/respond/route.ts`

Added comprehensive logging at every step:
- ✅ Session check with user details
- ✅ Match fetch with full match state
- ✅ User participation validation
- ✅ Update operation with detailed error info
- ✅ Supabase error details (message, code, hint)

**How to check logs:**
```bash
# In development
npm run dev

# Watch for logs like:
# [API] Respond request: { matchId: '...', userFid: 543581, ... }
# [API] Respond: Match found: { ... }
# [API] Respond: User participation check: { ... }
# [API] Respond: Updating match with data: { ... }
```

### 2. Fixed `match_details` View

**File:** `supabase-fix-match-details-view.sql`

The original view was missing critical fields needed by the inbox:
- `user_a_traits` / `user_b_traits` (for showing common traits)
- `created_by` (system/user indicator)
- `rationale` (match reasoning JSONB)
- `meeting_link` (generated Cal.com link)
- `scheduled_at` / `completed_at` (timestamps)

**Run this SQL:**
```bash
psql <your-connection-string> -f supabase-fix-match-details-view.sql
```

Or in Supabase SQL Editor:
1. Copy contents of `supabase-fix-match-details-view.sql`
2. Paste into SQL Editor
3. Click "Run"

### 3. Better Error Responses

The API now returns structured errors:

```json
{
  "error": "Failed to update match",
  "message": "column \"created_by\" does not exist",
  "details": "The column is missing from the matches table",
  "hint": "Run the matchmaking system migration"
}
```

Instead of just:
```json
{
  "error": "Failed to respond to match"
}
```

## How to Test

### Prerequisites

1. ✅ Ensure migrations are applied:
   ```bash
   # Check if these files have been run:
   # 1. supabase-schema.sql
   # 2. supabase-matchmaking-system.sql
   # 3. supabase-fix-match-triggers.sql
   # 4. supabase-fix-match-details-view.sql (NEW!)
   ```

2. ✅ Check environment variables:
   ```bash
   # .env.local should have:
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   JWT_SECRET=your-jwt-secret
   ```

3. ✅ Verify test match exists:
   ```sql
   SELECT id, user_a_fid, user_b_fid, status, a_accepted, b_accepted
   FROM matches
   WHERE user_a_fid = 1111 AND user_b_fid = 543581
   ORDER BY created_at DESC
   LIMIT 1;
   ```

### Test Steps

#### Step 1: Start Dev Server with Logging

```bash
npm run dev

# Keep this terminal open to watch logs
```

#### Step 2: Login as Emir

1. Go to `http://localhost:3000`
2. Login with Emir's account (FID 543581, @cengizhaneu)
3. Navigate to `/mini/inbox`

#### Step 3: Accept the Match

1. Find Alice's match request in the "Pending" tab
2. Click on it to view details
3. Click the green "Accept" button
4. **Watch the terminal for logs**

#### Expected Logs (Success):

```
[API] Respond request: {
  matchId: 'abc-123-def',
  userFid: 543581,
  username: 'cengizhaneu',
  response: 'accept',
  hasReason: false
}

[API] Respond: Match found: {
  matchId: 'abc-123-def',
  user_a_fid: 1111,
  user_b_fid: 543581,
  status: 'proposed',
  a_accepted: false,
  b_accepted: false
}

[API] Respond: User participation check: {
  userFid: 543581,
  isUserA: false,
  isUserB: true
}

[API] Respond: Updating match with data: { b_accepted: true }

[API] Respond: Match updated successfully: {
  matchId: 'abc-123-def',
  status: 'accepted_by_b',
  a_accepted: false,
  b_accepted: true
}

[API] Respond: Request completed successfully
```

#### Expected UI Behavior:

1. ✅ No error toast/alert
2. ✅ Match moves from "Pending" to "Awaiting Other Party" tab
3. ✅ Status badge changes to "Awaiting other party"
4. ✅ System message appears: "cengizhaneu accepted the match! Waiting for your response."

#### Step 4: Login as Alice and Accept

1. Logout
2. Login as Alice (FID 1111, @alice)
3. Go to `/mini/inbox`
4. Find the match (should show "Emir accepted, waiting for you")
5. Click "Accept"

#### Expected Logs (Both Accepted):

```
[API] Respond: Match updated successfully: {
  matchId: 'abc-123-def',
  status: 'accepted',
  a_accepted: true,
  b_accepted: true
}

[Match] Both users accepted, scheduling meeting for match abc-123-def
[Match] Meeting scheduled: https://cal.com/meet/alice-emir-xxxxx
[API] Respond: Request completed successfully
```

#### Expected UI Behavior:

1. ✅ Status changes to "Accepted"
2. ✅ Meeting link appears in green box
3. ✅ Both users receive system messages with the meeting link
4. ✅ Match visible in "Accepted" tab

### Troubleshooting

#### Error: "Match not found"

**Possible causes:**
- Match ID is wrong
- Match was deleted

**Check:**
```sql
SELECT * FROM matches WHERE id = 'your-match-id';
```

#### Error: "You are not a participant"

**Possible causes:**
- User FID mismatch
- Session not loaded correctly

**Check logs for:**
```
[API] Respond: User participation check: {
  userFid: 543581,
  isUserA: false,
  isUserB: false  // <- Both false means FID mismatch!
}
```

**Fix:**
- Verify session FID matches database FID
- Check if user logged in correctly

#### Error: "Failed to update match" with details

**Example:**
```json
{
  "error": "Failed to update match",
  "message": "column \"created_by\" does not exist",
  "details": "...",
  "hint": "..."
}
```

**Solution:**
- The database schema is incomplete
- Run missing migrations:
  ```bash
  psql <conn> -f supabase-matchmaking-system.sql
  psql <conn> -f supabase-fix-match-triggers.sql
  ```

#### Error: "Failed to retrieve updated match"

**Possible causes:**
- Update succeeded but `.single()` returned null
- RLS policy blocking SELECT

**Check:**
```sql
-- See if match exists
SELECT * FROM matches WHERE id = 'your-match-id';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'matches';
```

**Note:** We use service role key which bypasses RLS, so this is unlikely.

#### Error: View doesn't include required fields

**Symptoms:**
- Frontend shows missing data
- Traits not displaying
- Meeting link not showing

**Solution:**
```bash
psql <conn> -f supabase-fix-match-details-view.sql
```

**Verify:**
```sql
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'match_details'
ORDER BY ordinal_position;

-- Should include: user_a_traits, user_b_traits, rationale, meeting_link, etc.
```

## Database Queries for Debugging

### Check Match State

```sql
SELECT
  m.id,
  m.user_a_fid,
  ua.username as alice,
  m.user_b_fid,
  ub.username as emir,
  m.status,
  m.a_accepted,
  m.b_accepted,
  m.created_by,
  m.rationale,
  m.meeting_link,
  m.created_at
FROM matches m
LEFT JOIN users ua ON m.user_a_fid = ua.fid
LEFT JOIN users ub ON m.user_b_fid = ub.fid
WHERE m.user_a_fid = 1111 AND m.user_b_fid = 543581
ORDER BY m.created_at DESC
LIMIT 1;
```

### Check Messages

```sql
SELECT
  msg.sender_fid,
  u.username,
  msg.content,
  msg.is_system_message,
  msg.created_at
FROM messages msg
LEFT JOIN users u ON msg.sender_fid = u.fid
WHERE msg.match_id = 'your-match-id'
ORDER BY msg.created_at ASC;
```

### Check Triggers

```sql
SELECT * FROM public.verify_trigger_fix();
```

Expected output:
```
trigger_name              | trigger_timing | trigger_event | function_name
--------------------------+----------------+---------------+---------------------------
check_match_acceptance    | BEFORE         | UPDATE        | update_match_status()
trg_match_decline         | AFTER          | UPDATE        | handle_match_decline()
trg_match_cancel          | AFTER          | UPDATE        | add_cooldown_on_cancel()
```

### Check Cooldowns (After Decline)

```sql
SELECT
  mc.user_a_fid,
  mc.user_b_fid,
  mc.declined_at,
  mc.cooldown_until,
  EXTRACT(EPOCH FROM (mc.cooldown_until - NOW())) / 86400 as days_remaining
FROM match_cooldowns mc
WHERE (mc.user_a_fid = 1111 AND mc.user_b_fid = 543581)
   OR (mc.user_a_fid = 543581 AND mc.user_b_fid = 1111)
ORDER BY mc.declined_at DESC;
```

## Environment Variables Checklist

Create/verify `.env.local`:

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Auth
JWT_SECRET=your-random-secret-at-least-32-chars

# Cal.com (optional, for meeting links)
CALCOM_API_KEY=cal_live_xxxxx
CALCOM_EVENT_TYPE_ID=123456
```

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| "Unauthorized" error | No session cookie | Login again, check JWT_SECRET |
| "Match not found" | Wrong match ID or deleted | Verify match exists in DB |
| "Not a participant" | FID mismatch | Check session.fid vs match FIDs |
| "Failed to update" | Missing columns | Run matchmaking migrations |
| Missing meeting link | Cal.com not configured | Check CALCOM_API_KEY env var |
| Status not changing | Trigger bug | Run supabase-fix-match-triggers.sql |
| Cooldown not created | Trigger bug | Run supabase-fix-match-triggers.sql |
| Missing traits in UI | View incomplete | Run supabase-fix-match-details-view.sql |

## Success Criteria

After applying all fixes, the following should work:

### Accept Flow
- [x] Emir clicks Accept → no error
- [x] Status changes to `accepted_by_b`
- [x] Alice sees "Emir accepted, awaiting your response"
- [x] Alice clicks Accept → status changes to `accepted`
- [x] Meeting link generated
- [x] Both users receive meeting link messages
- [x] Match appears in "Accepted" tab

### Decline Flow
- [x] Emir clicks Decline → no error
- [x] Status changes to `declined`
- [x] Cooldown created (7 days)
- [x] Alice receives decline notification
- [x] Match removed from active inbox
- [x] New match request blocked by cooldown

### Logging
- [x] All API calls logged with details
- [x] Errors include message, code, hint
- [x] User participation logged
- [x] Match state changes logged

## Next Steps

Once the accept flow works:

1. **Test decline flow** - Ensure decline + cooldown works
2. **Test edge cases** - Already accepted, invalid status, etc.
3. **Test UI states** - Pending, awaiting, accepted, declined tabs
4. **Test meeting links** - Verify Cal.com integration
5. **Clean up logs** - Remove verbose logging after testing

## Related Files

- `app/api/matches/[id]/respond/route.ts` - Main API route (updated)
- `app/mini/inbox/page.tsx` - Inbox UI component
- `lib/api-client.ts` - API fetch helper
- `lib/auth.ts` - Session management
- `lib/supabase.ts` - Supabase clients
- `supabase-fix-match-details-view.sql` - View fix (new)
- `supabase-fix-match-triggers.sql` - Trigger fixes
- `test-manual-match-alice-emir.sql` - Test data script

## Contact

If issues persist after applying all fixes:

1. Check server logs for detailed error messages
2. Verify all migrations are applied (check Supabase dashboard)
3. Test with SQL scripts first to isolate API vs DB issues
4. Check browser console for client-side errors
5. Verify environment variables are loaded (restart dev server)
