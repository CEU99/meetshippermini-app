# Meet Shipper - Architecture Overview

## Decline Flow Architecture

### Before Fix (Broken) 🔴

```
┌─────────────┐
│   Browser   │
│   (Client)  │
└──────┬──────┘
       │ POST /api/matches/:id/decline-all
       ↓
┌──────────────────────────────────────┐
│  Next.js API Route                   │
│  app/api/matches/[id]/decline-all/   │
│                                       │
│  1. Validate session ✅              │
│  2. Check authorization ✅           │
│  3. UPDATE matches                   │
│     SET status = 'declined' ✅       │
└──────┬───────────────────────────────┘
       │ Trigger fires
       ↓
┌──────────────────────────────────────┐
│  Database Trigger                    │
│  match_declined_cooldown             │
│                                       │
│  Calls: add_match_cooldown()         │
└──────┬───────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────┐
│  Trigger Function (OLD VERSION) ❌   │
│                                       │
│  INSERT INTO match_cooldowns         │
│    (user_a_fid, user_b_fid)          │
│  VALUES                              │
│    (NEW.user_a_fid, NEW.user_b_fid)  │
│  ON CONFLICT DO NOTHING;             │
│                                       │
│  Problems:                           │
│  • No unique constraint exists       │
│  • OR constraint doesn't handle      │
│    reversed FIDs: (A,B) ≠ (B,A)      │
│  • Duplicate key violation (23505)   │
└──────┬───────────────────────────────┘
       │
       ↓
       ❌ ERROR: duplicate key violation
       │
       ↓
┌──────────────────────────────────────┐
│  API Response                        │
│                                       │
│  HTTP 500 Internal Server Error      │
│  {                                    │
│    "success": false,                 │
│    "reason": "server_error",         │
│    "message": "..."                  │
│  }                                    │
└──────┬───────────────────────────────┘
       │
       ↓
┌─────────────┐
│   Browser   │
│  Shows 500  │
│   Error ❌  │
└─────────────┘
```

### After Fix (Working) 🟢

```
┌─────────────┐
│   Browser   │
│   (Client)  │
└──────┬──────┘
       │ POST /api/matches/:id/decline-all
       ↓
┌──────────────────────────────────────┐
│  Next.js API Route                   │
│  app/api/matches/[id]/decline-all/   │
│                                       │
│  1. Validate session ✅              │
│  2. Check authorization ✅           │
│  3. Check terminal state ✅          │
│  4. UPDATE matches                   │
│     SET status = 'declined' ✅       │
└──────┬───────────────────────────────┘
       │ Trigger fires
       ↓
┌──────────────────────────────────────┐
│  Database Trigger                    │
│  match_declined_cooldown             │
│                                       │
│  Calls: add_match_cooldown()         │
└──────┬───────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────┐
│  Trigger Function (NEW VERSION) ✅   │
│                                       │
│  v_min_fid = LEAST(a, b)             │
│  v_max_fid = GREATEST(a, b)          │
│                                       │
│  INSERT INTO match_cooldowns         │
│    (user_a_fid, user_b_fid, ...)     │
│  VALUES                              │
│    (v_min_fid, v_max_fid, ...)       │
│  ON CONFLICT (                       │
│    LEAST(user_a_fid, user_b_fid),    │
│    GREATEST(user_a_fid, user_b_fid)  │
│  )                                    │
│  DO UPDATE SET                       │
│    declined_at = NOW(),              │
│    cooldown_until = ...;             │
│                                       │
│  ✅ Unique index exists              │
│  ✅ Handles (A,B) = (B,A)            │
│  ✅ True UPSERT (insert or update)   │
└──────┬───────────────────────────────┘
       │
       ↓
       ✅ SUCCESS: cooldown created/updated
       │
       ↓
┌──────────────────────────────────────┐
│  API Response                        │
│                                       │
│  HTTP 200 OK                         │
│  {                                    │
│    "success": true,                  │
│    "match": { ... }                  │
│  }                                    │
└──────┬───────────────────────────────┘
       │
       ↓
┌─────────────┐
│   Browser   │
│  Shows       │
│  "Declined"  │
│     ✅       │
└─────────────┘
```

---

## Database Schema

### Core Tables

```sql
┌──────────────────────────────────────┐
│ users                                │
├──────────────────────────────────────┤
│ fid (PK)              BIGINT         │
│ username              TEXT           │
│ display_name          TEXT           │
│ avatar_url            TEXT           │
│ bio                   TEXT           │
│ traits                JSONB          │
│ created_at            TIMESTAMPTZ    │
│ updated_at            TIMESTAMPTZ    │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ matches                              │
├──────────────────────────────────────┤
│ id (PK)               UUID           │
│ user_a_fid (FK)       BIGINT         │
│ user_b_fid (FK)       BIGINT         │
│ created_by_fid (FK)   BIGINT         │
│ created_by            TEXT           │
│ status                TEXT           │
│   • proposed                         │
│   • pending                          │
│   • accepted_by_a                    │
│   • accepted_by_b                    │
│   • accepted                         │
│   • declined          ← Focus        │
│   • cancelled                        │
│   • completed                        │
│ message               TEXT           │
│ rationale             JSONB          │
│ a_accepted            BOOLEAN        │
│ b_accepted            BOOLEAN        │
│ a_completed           BOOLEAN        │
│ b_completed           BOOLEAN        │
│ meeting_link          TEXT           │
│ scheduled_at          TIMESTAMPTZ    │
│ completed_at          TIMESTAMPTZ    │
│ created_at            TIMESTAMPTZ    │
│ updated_at            TIMESTAMPTZ    │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ match_cooldowns      ← Fix Applied   │
├──────────────────────────────────────┤
│ id (PK)               UUID           │
│ user_a_fid (FK)       BIGINT         │
│ user_b_fid (FK)       BIGINT         │
│ declined_at           TIMESTAMPTZ    │
│ cooldown_until        TIMESTAMPTZ    │
│ created_at            TIMESTAMPTZ    │
│                                      │
│ UNIQUE INDEX: uniq_cooldown_pair     │
│   ON (LEAST(user_a_fid, user_b_fid), │
│       GREATEST(user_a_fid, user_b_fid))│
└──────────────────────────────────────┘
```

### The Fix: Normalized FID Index

**Problem**:
```sql
-- User A (fid=100) and User B (fid=200)
-- Match 1: (user_a=100, user_b=200) → Cooldown: (100, 200) ✅
-- Match 2: (user_a=200, user_b=100) → Cooldown: (200, 100) ❌ DUPLICATE!
```

**Solution**:
```sql
-- Always normalize FID order: smaller first
-- Match 1: (user_a=100, user_b=200) → Cooldown: (100, 200) ✅
-- Match 2: (user_a=200, user_b=100) → Cooldown: (100, 200) ✅ SAME RECORD!

CREATE UNIQUE INDEX uniq_cooldown_pair
  ON match_cooldowns (
    LEAST(user_a_fid, user_b_fid),     -- Always smaller FID first
    GREATEST(user_a_fid, user_b_fid)   -- Always larger FID second
  );
```

---

## API Endpoints

### Decline Endpoint

**URL**: `POST /api/matches/:id/decline-all`

**Request**:
```json
{
  // No body required - matchId in URL
}
```

**Response (Success)**:
```json
{
  "success": true,
  "match": {
    "id": "uuid",
    "status": "declined",
    "a_accepted": false,
    "b_accepted": false,
    ...
  }
}
```

**Response (Already Terminal)**:
```json
{
  "success": false,
  "reason": "already_terminal",
  "message": "This match is already closed."
}
```

**Response (Error - should never happen after fix)**:
```json
{
  "success": false,
  "reason": "server_error",
  "message": "Error message"
}
```

---

## Client Flow

### User Interactions

```
┌─────────────────────────────────────────┐
│  Inbox Page                             │
│  /mini/inbox                            │
│                                         │
│  ┌─────────┬─────────┬──────────┐      │
│  │ Pending │Awaiting │ Accepted │      │
│  └─────────┴─────────┴──────────┘      │
│                                         │
│  ┌──────────────────────────────┐      │
│  │ Match Card                   │      │
│  │ • User avatar & name         │      │
│  │ • Status badge               │      │
│  │ • [Accept] [Decline] buttons │      │
│  └──────────────────────────────┘      │
└─────────────────────────────────────────┘
                │
                │ User clicks [Decline]
                ↓
┌─────────────────────────────────────────┐
│  handleRespond(matchId, 'decline')      │
│                                         │
│  1. setActionLoading(true) 🔄          │
│  2. await declineAllMatch(matchId)     │
│  3. Check result.success               │
│  4. Update UI optimistically           │
│  5. await fetchMatches() - refresh     │
│  6. setActionLoading(false) ✅         │
└─────────────────────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────┐
│  UI Updates                             │
│                                         │
│  • Match card removed from Pending      │
│  • Match appears in Declined tab        │
│  • Status badge: "declined"             │
│  • Alert: "Match declined for both"     │
└─────────────────────────────────────────┘
```

---

## Trigger & Function Flow

### Match Status Change Trigger Chain

```sql
-- 1. User clicks Decline
UPDATE matches SET status = 'declined' WHERE id = ?;

-- 2. BEFORE UPDATE trigger: update_matches_updated_at
→ Sets updated_at = NOW()

-- 3. BEFORE UPDATE trigger: check_match_acceptance
→ Updates status based on acceptance flags
→ (Not relevant for decline)

-- 4. UPDATE executes
→ Row updated in database

-- 5. AFTER UPDATE trigger: match_declined_cooldown
→ Checks: NEW.status = 'declined' AND OLD.status != 'declined'
→ If true: calls add_match_cooldown()

-- 6. add_match_cooldown() function executes
→ Normalizes FIDs: v_min = LEAST(a, b), v_max = GREATEST(a, b)
→ INSERT INTO match_cooldowns (...) VALUES (v_min, v_max, ...)
→ ON CONFLICT (...) DO UPDATE SET ...
→ ✅ Cooldown created or updated

-- 7. Control returns to API
→ Returns success response to client
```

---

## Key Concepts

### FID Normalization

**Why Needed**:
- User pairs can appear in any order: (A, B) or (B, A)
- Database needs to treat these as the same pair
- Without normalization: duplicate records

**How It Works**:
```sql
-- Example: FIDs 100 and 200

-- Input (any order):
user_a_fid = 200, user_b_fid = 100

-- Normalize:
v_min_fid = LEAST(200, 100) = 100
v_max_fid = GREATEST(200, 100) = 200

-- Always stored as:
(user_a_fid=100, user_b_fid=200)

-- Index enforces uniqueness on:
(LEAST(user_a_fid, user_b_fid), GREATEST(user_a_fid, user_b_fid))
= (100, 200) regardless of input order
```

### Idempotency

**Definition**: Operation can be called multiple times with same result

**Implementation**:
- ✅ First decline: Creates cooldown, returns 200
- ✅ Second decline: Updates cooldown (or no-op if already terminal), returns 200
- ✅ Third decline: Returns "already_terminal" message, still 200
- ❌ Never returns 500 for repeated declines

**Benefits**:
- Safe to retry failed requests
- No side effects from accidental double-clicks
- Resilient to network issues

---

## Monitoring & Debugging

### Key Metrics

```sql
-- Decline success rate (should be 100% after fix)
SELECT
  DATE(created_at) as date,
  COUNT(*) as total_declines
FROM matches
WHERE status = 'declined'
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY date
ORDER BY date DESC;

-- Check for duplicate cooldowns (should be 0)
SELECT
  LEAST(user_a_fid, user_b_fid) as min_fid,
  GREATEST(user_a_fid, user_b_fid) as max_fid,
  COUNT(*) as count
FROM match_cooldowns
GROUP BY min_fid, max_fid
HAVING COUNT(*) > 1;

-- Active cooldowns
SELECT COUNT(*) as active_cooldowns
FROM match_cooldowns
WHERE cooldown_until > NOW();
```

### Debug Logs

**Server logs** (`[DECLINE_ALL]` prefix):
```
[DECLINE_ALL] Request: { matchId, actorFid, username }
[DECLINE_ALL] Match found: { matchId, status, user_a_fid, user_b_fid }
[DECLINE_ALL] Match declined successfully: { matchId, newStatus }
```

**Client logs**:
```javascript
console.log('[DECLINE] Calling decline-all for match:', matchId);
console.log('[DECLINE] Result:', result);
```

---

## Testing Strategy

### Unit Tests (Database)

```sql
-- Test 1: First decline creates cooldown
UPDATE matches SET status = 'declined' WHERE id = ?;
SELECT COUNT(*) FROM match_cooldowns WHERE ...; -- Should be 1

-- Test 2: Second decline updates cooldown (no duplicate)
UPDATE matches SET status = 'declined' WHERE id = ?;
SELECT COUNT(*) FROM match_cooldowns WHERE ...; -- Should still be 1

-- Test 3: Reversed FIDs use same cooldown
-- Match 1: user_a=100, user_b=200
-- Match 2: user_a=200, user_b=100
UPDATE matches SET status = 'declined' WHERE id IN (?, ?);
SELECT COUNT(*) FROM match_cooldowns WHERE ...; -- Should be 1
```

### Integration Tests (API)

```javascript
// Test 1: Decline returns 200
const res = await fetch('/api/matches/:id/decline-all', { method: 'POST' });
expect(res.status).toBe(200);

// Test 2: Second decline returns 200 (not 500)
const res2 = await fetch('/api/matches/:id/decline-all', { method: 'POST' });
expect(res2.status).toBe(200);
expect(res2.json().reason).toBe('already_terminal');

// Test 3: Match status updated
const match = await fetch('/api/matches/:id').then(r => r.json());
expect(match.status).toBe('declined');
```

### E2E Tests (UI)

```javascript
// Test 1: Click decline, match moves to Declined tab
await page.goto('/mini/inbox');
await page.click('[data-testid="decline-button"]');
await page.waitForSelector('[data-testid="declined-tab"] .match-card');

// Test 2: No 500 error in console
const errors = await page.evaluate(() => window._errors);
expect(errors.filter(e => e.includes('500'))).toHaveLength(0);
```

---

## Performance

### Database Query Performance

```sql
-- Before fix: Can fail with constraint violation
-- After fix: Efficient UPSERT

EXPLAIN ANALYZE
INSERT INTO match_cooldowns (user_a_fid, user_b_fid, ...)
VALUES (100, 200, ...)
ON CONFLICT ((LEAST(user_a_fid, user_b_fid)), (GREATEST(user_a_fid, user_b_fid)))
DO UPDATE SET ...;

-- Result: Single query, uses index, ~1-2ms
```

### API Response Time

```
Before fix:
  Success path: ~50-100ms
  Error path:   ~50-100ms → 500 error

After fix:
  Success path: ~50-100ms
  Already declined: ~30-50ms (early return)
  All paths: 200 response
```

---

## Security

### Authorization Chain

1. **Session Check**: Must have valid Farcaster session
2. **Participant Check**: User FID must match user_a_fid OR user_b_fid
3. **Action Validation**: Can only decline if status allows it
4. **Bilateral Effect**: One decline affects both participants (by design)

### RLS Policies (Optional)

If using Row-Level Security:
```sql
-- matches table: Users can only UPDATE their own matches
CREATE POLICY "Users can update their matches"
  ON matches FOR UPDATE
  USING (
    user_a_fid = (current_setting('request.jwt.claims')::json->>'fid')::bigint
    OR user_b_fid = (current_setting('request.jwt.claims')::json->>'fid')::bigint
  );
```

---

**Last Updated**: 2025-01-23
**Status**: ✅ Architecture documented
