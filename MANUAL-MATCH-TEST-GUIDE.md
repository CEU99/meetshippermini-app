# Manual Match Testing Guide: Alice → Emir

Complete end-to-end testing guide for the manual match system using specific test users.

## Test Scenario

**User A (Sender - Alice):**
- Name: Alice
- Username: @alice
- User ID (FID): 1111
- User Code: 6287777951

**User B (Target - Emir):**
- Name: Emir Cengizhan Ulu
- Username: @cengizhaneu
- User ID (FID): 543581
- User Code: 7189696562

**Introduction Message:**
```
Sizinle tanışmak istiyorum proje hakkında konuşmak istiyorum zaman ayırırsanız bugün görüşelim
```

---

## Testing Overview

This guide provides three SQL test scripts to validate the manual match system:

1. **test-manual-match-alice-emir.sql** - Creates the match request
2. **test-manual-match-accept.sql** - Tests the acceptance flow
3. **test-manual-match-decline.sql** - Tests the decline flow

---

## Prerequisites

Before running tests, ensure:

1. ✅ Supabase database is accessible
2. ✅ Schema migrations are applied:
   - `supabase-schema.sql`
   - `supabase-matchmaking-system.sql`
   - `supabase-fix-match-triggers.sql`
3. ✅ Test users exist (Alice & Emir)
4. ✅ Trigger functions are working correctly

### Verify Prerequisites

```sql
-- Check if required tables exist
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('users', 'matches', 'messages', 'match_cooldowns')
ORDER BY tablename;

-- Check if required functions exist
SELECT proname
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN ('check_match_cooldown', 'update_match_status', 'handle_match_decline')
ORDER BY proname;

-- Check if triggers are set up
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE event_object_table = 'matches'
  AND trigger_schema = 'public'
ORDER BY trigger_name;
```

---

## Test Flow Option 1: Accept Path

### Step 1: Create Match Request

Run the first script to create Alice's match request to Emir:

```bash
# In Supabase SQL Editor or via psql
psql <your-connection-string> -f test-manual-match-alice-emir.sql
```

**Expected Results:**
- ✅ Match created with status `proposed`
- ✅ Alice is `user_a_fid` (sender)
- ✅ Emir is `user_b_fid` (target)
- ✅ Initial system message created with introduction
- ✅ `a_accepted = false`, `b_accepted = false`

**Verification Checklist:**
- [ ] Match exists in database
- [ ] Status is `proposed`
- [ ] Message contains introduction text
- [ ] System message visible in messages table
- [ ] Emir sees request in his inbox
- [ ] Alice sees pending request in her inbox

### Step 2: Test Acceptance Flow

Run the acceptance script:

```bash
psql <your-connection-string> -f test-manual-match-accept.sql
```

**Expected Results:**

**Phase A: Emir Accepts (First)**
- ✅ `b_accepted` set to `true`
- ✅ Status changes to `accepted_by_b`
- ✅ System message created: "cengizhaneu accepted the match!"
- ✅ Alice sees notification that Emir accepted

**Phase B: Alice Accepts (Both Accept)**
- ✅ `a_accepted` set to `true`
- ✅ Status changes to `accepted`
- ✅ Meeting link generated
- ✅ Both users receive meeting link messages
- ✅ `scheduled_at` timestamp set

**Verification Checklist:**
- [ ] Status transitions: `proposed` → `accepted_by_b` → `accepted`
- [ ] Meeting link generated and stored
- [ ] Both users receive meeting link messages
- [ ] Messages visible in both inboxes
- [ ] No cooldown created (only happens on decline)

---

## Test Flow Option 2: Decline Path

### Step 1: Create Match Request

Same as above - run `test-manual-match-alice-emir.sql`

### Step 2: Test Decline Flow

Run the decline script:

```bash
psql <your-connection-string> -f test-manual-match-decline.sql
```

**Expected Results:**
- ✅ Status changes to `declined`
- ✅ Cooldown entry created in `match_cooldowns` table
- ✅ Cooldown duration: 7 days
- ✅ Alice receives decline notification
- ✅ Emir sees decline confirmation
- ✅ Match removed from active inbox queries
- ✅ New match attempts blocked by cooldown check

**Verification Checklist:**
- [ ] Status is `declined` (NOT overridden by trigger)
- [ ] Cooldown exists: `check_match_cooldown(1111, 543581)` returns `true`
- [ ] Cooldown expires in ~7 days
- [ ] Decline messages visible to both users
- [ ] Match not visible in "active" inbox queries
- [ ] Attempting new match fails cooldown check

---

## API Testing Alternative

Instead of SQL scripts, you can test via API calls:

### 1. Create Manual Match (Alice → Emir)

```bash
curl -X POST http://localhost:3000/api/matches/manual \
  -H "Content-Type: application/json" \
  -H "Cookie: <alice-session-cookie>" \
  -d '{
    "targetFid": 543581,
    "introductionMessage": "Sizinle tanışmak istiyorum proje hakkında konuşmak istiyorum zaman ayırırsanız bugün görüşelim"
  }'
```

**Expected Response:**
```json
{
  "match": {
    "id": "<uuid>",
    "status": "proposed",
    "user_a_fid": 1111,
    "user_b_fid": 543581,
    "message": "Sizinle tanışmak istiyorum...",
    ...
  }
}
```

### 2a. Accept Match (Emir Accepts)

```bash
curl -X POST http://localhost:3000/api/matches/<match-id>/respond \
  -H "Content-Type: application/json" \
  -H "Cookie: <emir-session-cookie>" \
  -d '{
    "response": "accept"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "match": {
    "status": "accepted_by_b",
    ...
  }
}
```

### 2b. Decline Match (Emir Declines)

```bash
curl -X POST http://localhost:3000/api/matches/<match-id>/respond \
  -H "Content-Type: application/json" \
  -H "Cookie: <emir-session-cookie>" \
  -d '{
    "response": "decline",
    "reason": "Not interested at this time"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "match": {
    "status": "declined",
    ...
  }
}
```

---

## Verification Queries

### Check Match Status

```sql
SELECT
  m.id,
  m.status,
  ua.username as alice,
  ub.username as emir,
  m.a_accepted,
  m.b_accepted,
  m.meeting_link,
  m.created_at
FROM matches m
LEFT JOIN users ua ON m.user_a_fid = ua.fid
LEFT JOIN users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 1111 AND m.user_b_fid = 543581)
ORDER BY m.created_at DESC
LIMIT 1;
```

### Check Messages/Inbox

```sql
SELECT
  msg.sender_fid,
  u.username as sender,
  msg.content,
  msg.is_system_message,
  msg.created_at
FROM messages msg
LEFT JOIN users u ON msg.sender_fid = u.fid
WHERE msg.match_id = '<match-id>'
ORDER BY msg.created_at ASC;
```

### Check Cooldown

```sql
SELECT
  mc.user_a_fid,
  mc.user_b_fid,
  mc.declined_at,
  mc.cooldown_until,
  EXTRACT(EPOCH FROM (mc.cooldown_until - NOW())) / 86400 as days_remaining,
  public.check_match_cooldown(1111, 543581) as is_in_cooldown
FROM match_cooldowns mc
WHERE (mc.user_a_fid = 1111 AND mc.user_b_fid = 543581)
   OR (mc.user_a_fid = 543581 AND mc.user_b_fid = 1111)
ORDER BY mc.declined_at DESC
LIMIT 1;
```

### Check Alice's Inbox View

```sql
SELECT
  m.id,
  CASE
    WHEN m.user_a_fid = 1111 THEN ub.username
    ELSE ua.username
  END as other_user,
  m.status,
  CASE
    WHEN m.user_a_fid = 1111 THEN m.a_accepted
    ELSE m.b_accepted
  END as i_accepted,
  CASE
    WHEN m.user_a_fid = 1111 THEN m.b_accepted
    ELSE m.a_accepted
  END as they_accepted,
  m.meeting_link
FROM matches m
LEFT JOIN users ua ON m.user_a_fid = ua.fid
LEFT JOIN users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 1111 OR m.user_b_fid = 1111)
  AND m.status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending', 'accepted')
ORDER BY m.created_at DESC;
```

### Check Emir's Inbox View

```sql
SELECT
  m.id,
  CASE
    WHEN m.user_a_fid = 543581 THEN ub.username
    ELSE ua.username
  END as other_user,
  m.status,
  CASE
    WHEN m.user_a_fid = 543581 THEN m.a_accepted
    ELSE m.b_accepted
  END as i_accepted,
  CASE
    WHEN m.user_a_fid = 543581 THEN m.b_accepted
    ELSE m.a_accepted
  END as they_accepted,
  m.meeting_link
FROM matches m
LEFT JOIN users ua ON m.user_a_fid = ua.fid
LEFT JOIN users ub ON m.user_b_fid = ub.fid
WHERE (m.user_a_fid = 543581 OR m.user_b_fid = 543581)
  AND m.status IN ('proposed', 'accepted_by_a', 'accepted_by_b', 'pending', 'accepted')
ORDER BY m.created_at DESC;
```

---

## Common Issues & Troubleshooting

### Issue 1: Status Gets Overridden to 'accepted'

**Symptom:** When declining, status changes back to 'accepted'

**Cause:** Old trigger logic overrides manual status changes

**Fix:** Ensure `supabase-fix-match-triggers.sql` is applied

**Verification:**
```sql
-- Check trigger function includes decline check
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'update_match_status';

-- Should contain: IF NEW.status IN ('declined', 'cancelled') THEN
```

### Issue 2: Cooldown Not Created

**Symptom:** `check_match_cooldown()` returns false after decline

**Cause:** Cooldown trigger not firing or constraint conflict

**Fix:**
```sql
-- Check triggers exist
SELECT * FROM public.verify_trigger_fix();

-- Check unique constraint exists
SELECT conname
FROM pg_constraint
WHERE conrelid = 'public.match_cooldowns'::regclass
  AND contype = 'u';
```

### Issue 3: Messages Not Appearing

**Symptom:** System messages not showing in inbox

**Cause:** Messages table insert failed or query filtering them out

**Fix:**
```sql
-- Check if messages exist
SELECT COUNT(*)
FROM messages
WHERE match_id = '<match-id>';

-- Check message content
SELECT * FROM messages WHERE match_id = '<match-id>' ORDER BY created_at;
```

### Issue 4: Meeting Link Not Generated

**Symptom:** Both accepted but no meeting link

**Cause:** `scheduleMatch()` function failed or not called

**Check API logs:**
```bash
# Check Next.js logs for meeting service errors
grep "scheduleMatch" .next/server.log
```

**Manual fix (for testing):**
```sql
UPDATE matches
SET meeting_link = 'https://cal.com/meet/test-' || substr(md5(random()::text), 1, 8),
    scheduled_at = NOW() + INTERVAL '1 day'
WHERE id = '<match-id>';
```

---

## Cleanup After Testing

```sql
-- Remove test matches
DELETE FROM matches
WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
   OR (user_a_fid = 543581 AND user_b_fid = 1111);

-- Remove test cooldowns
DELETE FROM match_cooldowns
WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
   OR (user_a_fid = 543581 AND user_b_fid = 1111);

-- Optionally remove test user Alice (if not needed)
-- DELETE FROM users WHERE fid = 1111;
```

---

## Success Criteria

### ✅ Complete Test Pass

All of the following must be true:

**Match Creation:**
- [x] Match created with correct users and introduction message
- [x] Status starts as `proposed`
- [x] System message created

**Acceptance Flow:**
- [x] First accept updates individual acceptance flag
- [x] Status transitions correctly (`proposed` → `accepted_by_*` → `accepted`)
- [x] Both accepts trigger meeting link generation
- [x] Meeting link messages sent to both users
- [x] No cooldown created

**Decline Flow:**
- [x] Status changes to `declined` and persists
- [x] Cooldown created with 7-day duration
- [x] Decline messages sent to both users
- [x] Match not visible in active inbox
- [x] New match attempts blocked by cooldown

**Database Integrity:**
- [x] No duplicate matches created
- [x] Triggers execute in correct order
- [x] Foreign key constraints maintained
- [x] Timestamps updated correctly

---

## Test Execution Log Template

Copy this template to track your test execution:

```
Test Date: _______________
Tester: _______________
Environment: [ ] Local [ ] Staging [ ] Production

--- Test 1: Create Match Request ---
Script: test-manual-match-alice-emir.sql
Status: [ ] Pass [ ] Fail
Match ID: _______________
Notes: _______________

--- Test 2: Acceptance Flow ---
Script: test-manual-match-accept.sql
Status: [ ] Pass [ ] Fail
Meeting Link: _______________
Notes: _______________

--- Test 3: Decline Flow ---
Script: test-manual-match-decline.sql
Status: [ ] Pass [ ] Fail
Cooldown ID: _______________
Notes: _______________

--- Overall Result ---
[ ] All tests passed
[ ] Some tests failed (see notes)
[ ] Tests could not be run (blockers)

Next Actions: _______________
```

---

## Related Documentation

- [Manual Match API Documentation](app/api/matches/manual/route.ts)
- [Match Response API Documentation](app/api/matches/[id]/respond/route.ts)
- [Matchmaking System Schema](supabase-matchmaking-system.sql)
- [Trigger Fix Migration](supabase-fix-match-triggers.sql)
- [Manual Match Testing](MANUAL-MATCH-TESTING.md)

---

## Contact & Support

If you encounter issues during testing:

1. Check the troubleshooting section above
2. Review database logs for errors
3. Verify all migrations are applied
4. Check trigger execution order

For additional help, refer to the project documentation or contact the development team.
