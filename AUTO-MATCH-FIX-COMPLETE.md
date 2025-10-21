# Auto-Match Fix - Complete Diagnostic & Solution

## 🎯 Root Cause Identified

Your `hasActiveMatch()` function in `matching-service.ts:173-190` is checking for ANY match with status `['proposed', 'accepted_by_a', 'accepted_by_b', 'accepted']` **without a time constraint**.

This means:
- ✅ Your test users (11111, 22222) have previous `accepted` and `cancelled` matches
- ❌ The `hasActiveMatch()` check finds the old `accepted` match
- ❌ **Result: `blocked_by_open_recent = true`** even though it's not actually "open"

The status `'accepted'` should be considered "closed/completed" for matching purposes, not blocking.

---

## 📋 Complete Fix Package

### 1. **Fix `hasActiveMatch()` - Only Block on Truly Open Statuses**

**File:** `lib/services/matching-service.ts`

**Current Code (Lines 173-190):**
```typescript
export async function hasActiveMatch(fidA: number, fidB: number): Promise<boolean> {
  const supabase = getServerSupabase();

  const { data, error } = await supabase
    .from('matches')
    .select('id')
    .or(`and(user_a_fid.eq.${fidA},user_b_fid.eq.${fidB}),and(user_a_fid.eq.${fidB},user_b_fid.eq.${fidA})`)
    .in('status', ['proposed', 'accepted_by_a', 'accepted_by_b', 'accepted']) // ❌ 'accepted' blocks!
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error('Error checking active match:', error);
    return false;
  }

  return !!data;
}
```

**Fixed Code:**
```typescript
/**
 * Check if users already have an open/pending match
 * Only blocks on truly "open" statuses that need action
 * 'accepted' is considered complete and doesn't block
 * 'declined' and 'cancelled' are handled by cooldown system
 */
export async function hasActiveMatch(fidA: number, fidB: number): Promise<boolean> {
  const supabase = getServerSupabase();

  // Only check for truly open/pending statuses within last 24 hours
  const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  const { data, error } = await supabase
    .from('matches')
    .select('id')
    .or(`and(user_a_fid.eq.${fidA},user_b_fid.eq.${fidB}),and(user_a_fid.eq.${fidB},user_b_fid.eq.${fidA})`)
    .in('status', ['proposed', 'accepted_by_a', 'accepted_by_b']) // ✅ Removed 'accepted'
    .gte('created_at', twentyFourHoursAgo) // ✅ Added time constraint
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error('Error checking active match:', error);
    return false;
  }

  return !!data;
}
```

**Why This Works:**
- ✅ `'accepted'` status is no longer blocking (it's a completed match)
- ✅ Only truly pending proposals block (`'proposed'`, `'accepted_by_a'`, `'accepted_by_b'`)
- ✅ Time constraint prevents ancient proposals from blocking
- ✅ Declined/cancelled matches are handled by the cooldown system separately

---

### 2. **Update Configuration for Testing**

**File:** `lib/services/matching-service.ts` (Lines 10-17)

**For Local Testing:**
```typescript
export const MATCHING_CONFIG = {
  MIN_SCORE_THRESHOLD: 0.10,  // ✅ Lowered for testing
  MAX_PROPOSALS_PER_USER: 3,
  COOLDOWN_DAYS: 7,
  TRAIT_WEIGHT: 0.7,  // ✅ Increased to match your CTE
  BIO_WEIGHT: 0.3,    // ✅ Decreased to match your CTE
  AUTO_MATCH_INTERVAL_HOURS: 3,
  RECENT_MATCH_WINDOW_HOURS: 24,  // ✅ New: window for "recent" check
} as const;
```

---

### 3. **Create Dev Login Endpoint**

**File:** `app/api/dev/login/route.ts` (NEW)

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { createSession } from '@/lib/auth';

/**
 * POST /api/dev/login
 * Development-only endpoint to create test sessions
 *
 * SECURITY: Disable this in production!
 *
 * Usage:
 * curl -X POST http://localhost:3000/api/dev/login \
 *   -H "Content-Type: application/json" \
 *   -d '{"fid": 11111, "username": "alice"}' \
 *   -c cookies.txt
 */
export async function POST(request: NextRequest) {
  // SECURITY: Only allow in development
  if (process.env.NODE_ENV === 'production') {
    return NextResponse.json(
      { error: 'Dev login disabled in production' },
      { status: 403 }
    );
  }

  try {
    const body = await request.json();
    const { fid, username, displayName, avatarUrl, userCode } = body;

    if (!fid || !username) {
      return NextResponse.json(
        { error: 'fid and username are required' },
        { status: 400 }
      );
    }

    // Create session
    const token = await createSession({
      fid,
      username,
      displayName: displayName || username,
      avatarUrl: avatarUrl || `https://avatar.vercel.sh/${username}`,
      userCode,
    });

    return NextResponse.json({
      success: true,
      message: 'Session created',
      session: {
        fid,
        username,
        displayName: displayName || username,
      },
      token, // Include token for reference
    });
  } catch (error: any) {
    console.error('[Dev Login] Error:', error);
    return NextResponse.json(
      { error: 'Failed to create session', message: error.message },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/dev/login
 * Clear session cookie
 */
export async function DELETE(request: NextRequest) {
  if (process.env.NODE_ENV === 'production') {
    return NextResponse.json(
      { error: 'Dev login disabled in production' },
      { status: 403 }
    );
  }

  const { deleteSession } = await import('@/lib/auth');
  await deleteSession();

  return NextResponse.json({ success: true, message: 'Session cleared' });
}
```

---

### 4. **SQL Cleanup Script for Testing**

**File:** `cleanup-test-matches.sql` (NEW)

```sql
-- =====================================================================
-- CLEANUP: Remove test matches between users for fresh testing
-- =====================================================================
-- Run this to reset test data between 11111 and 22222
-- =====================================================================

-- 1. View current matches
SELECT
  id,
  user_a_fid,
  user_b_fid,
  status,
  created_at,
  a_accepted,
  b_accepted
FROM matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC;

-- 2. View current cooldowns
SELECT
  id,
  user_a_fid,
  user_b_fid,
  declined_at,
  cooldown_until,
  cooldown_until > NOW() AS is_active
FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY declined_at DESC;

-- 3. Delete test cooldowns (allows immediate re-matching)
DELETE FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

-- 4. OPTIONAL: Delete old test matches (use with caution)
-- Uncomment to delete old matches between test users:
-- DELETE FROM matches
-- WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
--   AND status IN ('accepted', 'cancelled', 'declined');

-- 5. OPTIONAL: Archive instead of delete
-- UPDATE matches
-- SET status = 'completed'
-- WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
--   AND status = 'accepted';

-- 6. Verify cleanup
SELECT COUNT(*) AS remaining_matches
FROM matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

SELECT COUNT(*) AS remaining_cooldowns
FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111));

-- Expected: 0 cooldowns, 0 or few matches
```

---

### 5. **SQL Verification Queries**

**File:** `verify-matching-works.sql` (NEW)

```sql
-- =====================================================================
-- VERIFICATION: End-to-End Matching Flow
-- =====================================================================

-- Test users: 11111 (alice), 22222 (bob)

-- =====================================================================
-- STEP 1: Verify test users exist with proper data
-- =====================================================================

SELECT
  fid,
  username,
  bio,
  jsonb_array_length(COALESCE(traits, '[]'::jsonb)) AS trait_count,
  CASE
    WHEN bio IS NOT NULL AND bio <> ''
      AND jsonb_array_length(COALESCE(traits, '[]'::jsonb)) >= 5
    THEN 'eligible'
    ELSE 'not_eligible'
  END AS eligibility
FROM users
WHERE fid IN (11111, 22222);

-- Expected: Both users should show 'eligible'

-- =====================================================================
-- STEP 2: Check match scoring manually
-- =====================================================================

SELECT
  public.calculate_trait_similarity(
    (SELECT traits FROM users WHERE fid = 11111),
    (SELECT traits FROM users WHERE fid = 22222)
  ) AS trait_similarity;

-- Expected: Should return value between 0 and 1

-- =====================================================================
-- STEP 3: Check for blocking conditions
-- =====================================================================

-- 3a. Check cooldown
SELECT public.check_match_cooldown(11111, 22222) AS has_cooldown;
-- Expected: false (no active cooldown)

-- 3b. Check open matches in last 24h
SELECT
  id,
  status,
  created_at,
  NOW() - created_at AS age
FROM matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status IN ('proposed', 'accepted_by_a', 'accepted_by_b')
  AND created_at > NOW() - INTERVAL '24 hours';
-- Expected: 0 rows (no open matches)

-- 3c. Check pending proposal count
SELECT public.count_pending_matches(11111) AS alice_pending;
SELECT public.count_pending_matches(22222) AS bob_pending;
-- Expected: Both should be < 3

-- =====================================================================
-- STEP 4: After running auto-match, verify new proposal
-- =====================================================================

-- Find the newest match
SELECT
  id,
  user_a_fid,
  user_b_fid,
  status,
  created_by,
  rationale,
  a_accepted,
  b_accepted,
  created_at
FROM matches
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY created_at DESC
LIMIT 1;

-- Expected:
-- status = 'proposed'
-- created_by = 'system'
-- rationale contains score, trait overlap, etc.

-- =====================================================================
-- STEP 5: Test acceptance flow
-- =====================================================================

-- 5a. User A accepts
UPDATE matches
SET a_accepted = true
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status = 'proposed'
RETURNING id, status, a_accepted, b_accepted;

-- Expected: status should change to 'accepted_by_a'

-- 5b. User B accepts
UPDATE matches
SET b_accepted = true
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status = 'accepted_by_a'
RETURNING id, status, a_accepted, b_accepted;

-- Expected: status should change to 'accepted'

-- =====================================================================
-- STEP 6: Test decline flow and cooldown
-- =====================================================================

-- 6a. Decline the match
UPDATE matches
SET status = 'declined'
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
  AND status = 'accepted'
RETURNING id, status;

-- Expected: status should be 'declined' (not revert to 'accepted')

-- 6b. Verify cooldown was created
SELECT
  id,
  user_a_fid,
  user_b_fid,
  declined_at,
  cooldown_until,
  cooldown_until > NOW() AS is_active,
  EXTRACT(DAYS FROM (cooldown_until - declined_at)) AS cooldown_days
FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
ORDER BY declined_at DESC
LIMIT 1;

-- Expected:
-- is_active = true
-- cooldown_days = 7

-- 6c. Verify cooldown blocks new matches
SELECT public.check_match_cooldown(11111, 22222) AS should_be_blocked;
-- Expected: true

-- =====================================================================
-- SUCCESS CRITERIA
-- =====================================================================

-- ✅ Step 1: Both users are eligible
-- ✅ Step 2: Trait similarity calculates correctly
-- ✅ Step 3: No blocking conditions initially
-- ✅ Step 4: New 'proposed' match is created
-- ✅ Step 5: Acceptance flow works (proposed → accepted_by_a → accepted)
-- ✅ Step 6: Decline creates cooldown, blocks future matches
```

---

## 🚀 Complete Testing Checklist

### **Phase 1: Setup**

```bash
# 1. Apply the code fix to matching-service.ts
# (See section 1 above)

# 2. Create dev login endpoint
# (Create app/api/dev/login/route.ts - see section 3)

# 3. Clean up test data in Supabase
# Run: cleanup-test-matches.sql (section 4)
```

### **Phase 2: Test Auto-Matching**

```bash
# 1. Login as test user (creates session cookie)
curl -X POST http://localhost:3000/api/dev/login \
  -H "Content-Type: application/json" \
  -d '{"fid": 11111, "username": "alice"}' \
  -c cookies.txt

# Expected output:
# {
#   "success": true,
#   "message": "Session created",
#   "session": { "fid": 11111, "username": "alice", ... }
# }

# 2. Run auto-match via authenticated endpoint
curl -X POST http://localhost:3000/api/matches/auto-run \
  -b cookies.txt

# Expected output:
# {
#   "success": true,
#   "result": {
#     "runId": "...",
#     "usersProcessed": 2,
#     "matchesCreated": 1,  ← Should be 1, not 0!
#     "duration": 1234
#   }
# }

# 3. Verify match was created in database
# Run SQL: SELECT * FROM matches WHERE ... (see verify-matching-works.sql STEP 4)
```

### **Phase 3: Test Accept/Decline Flow**

```bash
# Run the SQL queries in verify-matching-works.sql STEP 5 and STEP 6
# This tests the complete flow including cooldowns
```

### **Phase 4: Verify Cooldown Blocking**

```bash
# 1. Check cooldown is active
# SQL: SELECT public.check_match_cooldown(11111, 22222);
# Expected: true

# 2. Try to run auto-match again
curl -X POST http://localhost:3000/api/cron/auto-match \
  -H "Authorization: Bearer ${CRON_SECRET}"

# Expected:
# {
#   "success": true,
#   "result": {
#     "matchesCreated": 0  ← Blocked by cooldown
#   }
# }
```

---

## 📊 Expected Results Summary

| Test | Before Fix | After Fix |
|------|------------|-----------|
| Auto-match creates proposal | ❌ 0 matches | ✅ 1 match |
| blocked_by_open_recent | ❌ true (wrong) | ✅ false (correct) |
| Acceptance flow | ✅ Works | ✅ Works |
| Decline creates cooldown | ✅ Works | ✅ Works |
| Cooldown blocks matching | ✅ Works | ✅ Works |
| Dev login endpoint | ❌ Doesn't exist | ✅ Created |

---

## 🔍 Debugging Commands

If matches still aren't created, run these diagnostics:

```sql
-- Check exact scoring for your test pair
WITH test_users AS (
  SELECT fid, username, bio, traits
  FROM users
  WHERE fid IN (11111, 22222)
),
scores AS (
  SELECT
    a.fid AS user_a_fid,
    a.username AS user_a_name,
    b.fid AS user_b_fid,
    b.username AS user_b_name,
    public.calculate_trait_similarity(a.traits, b.traits) AS trait_sim,
    -- Bio similarity (approximate with keyword count)
    0.0 AS bio_sim,
    (0.7 * public.calculate_trait_similarity(a.traits, b.traits) + 0.3 * 0.0) AS final_score
  FROM test_users a
  CROSS JOIN test_users b
  WHERE a.fid < b.fid
)
SELECT
  *,
  CASE WHEN final_score >= 0.10 THEN 'PASS' ELSE 'FAIL' END AS threshold_check,
  public.check_match_cooldown(user_a_fid, user_b_fid) AS cooldown_block,
  EXISTS (
    SELECT 1 FROM matches m
    WHERE (m.user_a_fid, m.user_b_fid) IN ((user_a_fid, user_b_fid), (user_b_fid, user_a_fid))
      AND m.status IN ('proposed', 'accepted_by_a', 'accepted_by_b')
      AND m.created_at > NOW() - INTERVAL '24 hours'
  ) AS open_match_block
FROM scores;

-- Expected output:
-- trait_sim: 1.000
-- bio_sim: ~0
-- final_score: 0.700
-- threshold_check: PASS
-- cooldown_block: false
-- open_match_block: false  ← This should be false after fix!
```

---

## 🎯 The Fix in One Sentence

**Remove `'accepted'` from the `hasActiveMatch()` status array and add a 24-hour time window** — completed matches shouldn't block new proposals.

---

## 📝 Files to Create/Modify

1. ✏️ **MODIFY:** `lib/services/matching-service.ts` (fix `hasActiveMatch()`)
2. ➕ **CREATE:** `app/api/dev/login/route.ts` (dev login endpoint)
3. ➕ **CREATE:** `cleanup-test-matches.sql` (cleanup script)
4. ➕ **CREATE:** `verify-matching-works.sql` (verification queries)

---

## ⚡ Quick Fix Command

If you just want the minimal code change, replace lines 173-190 in `lib/services/matching-service.ts`:

```typescript
// BEFORE (blocking 'accepted')
.in('status', ['proposed', 'accepted_by_a', 'accepted_by_b', 'accepted'])

// AFTER (not blocking 'accepted')
.in('status', ['proposed', 'accepted_by_a', 'accepted_by_b'])
.gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
```

That's the root cause and complete solution! 🚀
