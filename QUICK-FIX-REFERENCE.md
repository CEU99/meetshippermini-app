# Auto-Match Fix - Quick Reference Card

## 🎯 The Problem

**Symptom:** `matchesCreated: 0` despite eligible users

**Root Cause:** `hasActiveMatch()` checks for status `'accepted'` which blocks new proposals for completed matches

**Evidence:**
```
trait_sim = 1.000
final_score = 0.700
passes_threshold = true
blocked_by_open_recent = TRUE  ← This is the bug!
```

---

## ⚡ The Fix (One Line)

**File:** `lib/services/matching-service.ts:186`

**Change:**
```typescript
// BEFORE (blocks on 'accepted')
.in('status', ['proposed', 'accepted_by_a', 'accepted_by_b', 'accepted'])

// AFTER (doesn't block on 'accepted')
.in('status', ['proposed', 'accepted_by_a', 'accepted_by_b'])
.gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
```

---

## 🚀 Quick Start (3 Commands)

```bash
# 1. Clean test data
psql $DATABASE_URL -f cleanup-test-matches.sql

# 2. Create session & run matching
./test-auto-match.sh

# 3. Verify in database
psql $DATABASE_URL -c "SELECT id, status, created_by FROM matches WHERE status='proposed' ORDER BY created_at DESC LIMIT 1;"
```

**Expected:** One new row with `status='proposed'` and `created_by='system'`

---

## 📋 Files Created

| File | Purpose |
|------|---------|
| `lib/services/matching-service.ts` | ✅ **FIXED** - Updated `hasActiveMatch()` |
| `app/api/dev/login/route.ts` | ✅ **NEW** - Dev login endpoint |
| `cleanup-test-matches.sql` | Cleanup script |
| `verify-matching-works.sql` | End-to-end verification |
| `test-auto-match.sh` | Automated test script |
| `AUTO-MATCH-FIX-COMPLETE.md` | Complete documentation |

---

## 🧪 Manual Testing (curl)

```bash
# 1. Login as alice
curl -X POST http://localhost:3000/api/dev/login \
  -H "Content-Type: application/json" \
  -d '{"fid": 11111, "username": "alice"}' \
  -c cookies.txt

# 2. Run auto-matching
curl -X POST http://localhost:3000/api/matches/auto-run \
  -b cookies.txt

# 3. Check result
# Should see: {"success":true,"result":{"matchesCreated":1}}
```

---

## 🔍 Verification SQL (One Query)

```sql
-- Check if matching is blocked
SELECT
  'Cooldown' AS blocker,
  public.check_match_cooldown(11111, 22222) AS blocked
UNION ALL
SELECT
  'Open Match',
  EXISTS (
    SELECT 1 FROM matches
    WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
      AND status IN ('proposed', 'accepted_by_a', 'accepted_by_b')
      AND created_at > NOW() - INTERVAL '24 hours'
  );

-- Expected: Both should be 'false'
```

---

## ✅ Success Checklist

- [ ] `hasActiveMatch()` fixed in `matching-service.ts`
- [ ] `/api/dev/login` endpoint created
- [ ] Cleanup script run: `cleanup-test-matches.sql`
- [ ] Test script run: `./test-auto-match.sh`
- [ ] Result shows: `matchesCreated: 1` (not 0)
- [ ] Database has new `proposed` match
- [ ] Verification SQL shows both blockers = `false`

---

## 🐛 If Still 0 Matches

Run diagnostic:

```sql
-- Check exact blocker for your test pair
SELECT
  11111 AS user_a,
  22222 AS user_b,
  public.check_match_cooldown(11111, 22222) AS cooldown_block,
  EXISTS (
    SELECT 1 FROM matches
    WHERE (user_a_fid, user_b_fid) IN ((11111, 22222), (22222, 11111))
      AND status IN ('proposed', 'accepted_by_a', 'accepted_by_b')
      AND created_at > NOW() - INTERVAL '24 hours'
  ) AS open_match_block,
  public.count_pending_matches(11111) AS alice_pending,
  public.count_pending_matches(22222) AS bob_pending,
  public.calculate_trait_similarity(
    (SELECT traits FROM users WHERE fid = 11111),
    (SELECT traits FROM users WHERE fid = 22222)
  ) AS trait_sim,
  (0.7 * public.calculate_trait_similarity(
    (SELECT traits FROM users WHERE fid = 11111),
    (SELECT traits FROM users WHERE fid = 22222)
  )) AS final_score;

-- All should be false/low except trait_sim and final_score (should be high)
```

---

## 📞 Key Configuration

**File:** `lib/services/matching-service.ts:10-17`

```typescript
export const MATCHING_CONFIG = {
  MIN_SCORE_THRESHOLD: 0.10,  // For testing
  MAX_PROPOSALS_PER_USER: 3,
  COOLDOWN_DAYS: 7,
  TRAIT_WEIGHT: 0.7,  // Matches your CTE
  BIO_WEIGHT: 0.3,    // Matches your CTE
  AUTO_MATCH_INTERVAL_HOURS: 3,
}
```

---

## 💡 Why This Works

**Before:**
- `'accepted'` status is checked → finds old completed match → blocks new proposal

**After:**
- Only `'proposed'`, `'accepted_by_a'`, `'accepted_by_b'` are checked
- Completed (`'accepted'`) matches don't block
- Time constraint (24h) prevents ancient proposals from blocking
- Cooldown system handles declined/cancelled matches separately

---

## 🎉 Expected Result

```bash
curl -X POST http://localhost:3000/api/cron/auto-match \
  -H "Authorization: Bearer $CRON_SECRET"

# Response:
{
  "success": true,
  "result": {
    "runId": "uuid-here",
    "usersProcessed": 2,
    "matchesCreated": 1,  ← Success! (was 0 before)
    "duration": 1234
  }
}
```

---

**That's it!** The fix is literally 2 lines of code. The rest is testing infrastructure.

**Core Fix Location:** `lib/services/matching-service.ts:186-187`
