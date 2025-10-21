# Auto-Match Fix - Visual Guide

## 🎨 The Problem (Visual Flow)

```
┌─────────────────────────────────────────────────────────┐
│  Test Users: alice (11111) & bob (22222)               │
│  Previous Match: status = 'accepted' (completed)       │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  Auto-Match Runs: findBestMatches(alice, [bob])        │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  Check: hasActiveMatch(11111, 22222)                    │
│                                                         │
│  ❌ BEFORE FIX:                                         │
│     SELECT * FROM matches                               │
│     WHERE status IN ('proposed', 'accepted_by_a',       │
│                      'accepted_by_b', 'accepted')       │
│                                    ^^^^^^^^^ BAD!       │
│     RESULT: Found old 'accepted' match                  │
│     RETURNS: true (blocked!)                            │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  hasActiveMatch = true                                  │
│  → Skip this pair                                       │
│  → No proposal created                                  │
│  → matchesCreated: 0 ❌                                 │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ The Solution (Visual Flow)

```
┌─────────────────────────────────────────────────────────┐
│  Test Users: alice (11111) & bob (22222)               │
│  Previous Match: status = 'accepted' (completed)       │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  Auto-Match Runs: findBestMatches(alice, [bob])        │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  Check: hasActiveMatch(11111, 22222)                    │
│                                                         │
│  ✅ AFTER FIX:                                          │
│     SELECT * FROM matches                               │
│     WHERE status IN ('proposed', 'accepted_by_a',       │
│                      'accepted_by_b')  ← No 'accepted'! │
│       AND created_at > NOW() - INTERVAL '24 hours'      │
│                                                         │
│     RESULT: No open matches found                       │
│     RETURNS: false (not blocked!)                       │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  hasActiveMatch = false                                 │
│  → Pair is eligible                                     │
│  → Create proposal                                      │
│  → INSERT INTO matches (status='proposed')              │
│  → matchesCreated: 1 ✅                                 │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Match Status Lifecycle

```
┌──────────────────────────────────────────────────────────┐
│                   MATCH STATUS FLOW                      │
└──────────────────────────────────────────────────────────┘

CREATION (Auto-Match)
  │
  ├──> 'proposed'  ← Created by system
  │      ↓
  │      [User A accepts]
  │      ↓
  ├──> 'accepted_by_a'  ← Partial acceptance
  │      ↓
  │      [User B accepts]
  │      ↓
  ├──> 'accepted'  ← Full acceptance (COMPLETE!)
  │      │
  │      ├─[Optional]─> 'completed'  ← Archive status
  │      │
  │      └─[User declines]─> 'declined' ──> [Cooldown created]
  │                              ↓
  │                          7-day cooldown
  │
  └──> 'cancelled'  ← Either user cancels
         ↓
      [Cooldown created]
         ↓
      7-day cooldown

┌──────────────────────────────────────────────────────────┐
│  BLOCKING RULES:                                         │
│  ✅ 'proposed', 'accepted_by_a', 'accepted_by_b'         │
│     → Block new proposals (still open)                   │
│                                                          │
│  ❌ 'accepted', 'completed'                              │
│     → Don't block (match is done)                        │
│                                                          │
│  ❌ 'declined', 'cancelled'                              │
│     → Don't block (handled by cooldown system)           │
└──────────────────────────────────────────────────────────┘
```

---

## 📊 Status Classification

```
┌─────────────────┬──────────────┬───────────────┬─────────────┐
│ Status          │ Is Open?     │ Blocks Match? │ Has Cooldown│
├─────────────────┼──────────────┼───────────────┼─────────────┤
│ proposed        │ ✅ Yes       │ ✅ Yes        │ No          │
│ accepted_by_a   │ ✅ Yes       │ ✅ Yes        │ No          │
│ accepted_by_b   │ ✅ Yes       │ ✅ Yes        │ No          │
├─────────────────┼──────────────┼───────────────┼─────────────┤
│ accepted        │ ❌ No        │ ❌ No (FIX!)  │ No          │
│ completed       │ ❌ No        │ ❌ No         │ No          │
├─────────────────┼──────────────┼───────────────┼─────────────┤
│ declined        │ ❌ No        │ ❌ No         │ ✅ Yes (7d) │
│ cancelled       │ ❌ No        │ ❌ No         │ ✅ Yes (7d) │
└─────────────────┴──────────────┴───────────────┴─────────────┘

KEY INSIGHT:
  'accepted' = Match is COMPLETE and SUCCESSFUL
  It should NOT block new proposals between same users
  (unless there's an active cooldown from decline/cancel)
```

---

## 🔍 Blocker Logic (Before vs After)

### BEFORE FIX ❌

```typescript
export async function hasActiveMatch(fidA, fidB) {
  const { data } = await supabase
    .from('matches')
    .select('id')
    .or(`...user pairs...`)
    .in('status', [
      'proposed',
      'accepted_by_a',
      'accepted_by_b',
      'accepted'  ← ❌ This finds old successful matches!
    ])
    .limit(1);

  return !!data;  // Returns true if ANY match exists
}

// Result for (11111, 22222):
// - Finds old 'accepted' match from previous test
// - Returns: true (blocked)
// - New proposal: NOT CREATED ❌
```

### AFTER FIX ✅

```typescript
export async function hasActiveMatch(fidA, fidB) {
  const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

  const { data } = await supabase
    .from('matches')
    .select('id')
    .or(`...user pairs...`)
    .in('status', [
      'proposed',
      'accepted_by_a',
      'accepted_by_b'  ← ✅ No 'accepted'!
    ])
    .gte('created_at', twentyFourHoursAgo)  ← ✅ Time limit!
    .limit(1);

  return !!data;  // Returns true ONLY if open match exists
}

// Result for (11111, 22222):
// - Old 'accepted' match is ignored (not in status list)
// - No open matches in last 24h
// - Returns: false (not blocked)
// - New proposal: CREATED ✅
```

---

## 🎯 Decision Tree

```
                    [Auto-Match Runs]
                           ↓
        ┌──────────────────┴──────────────────┐
        │ For each user pair (A, B):          │
        └──────────────────┬──────────────────┘
                           ↓
        ┌──────────────────┴──────────────────┐
        │ Calculate Score                     │
        │ → trait_similarity = 1.0            │
        │ → bio_similarity ≈ 0                │
        │ → final_score = 0.7                 │
        └──────────────────┬──────────────────┘
                           ↓
        ┌──────────────────┴──────────────────┐
        │ Score >= Threshold (0.10)?          │
        └──────────┬───────────────────┬──────┘
                   │                   │
                  YES                 NO
                   │                   │
                   ↓                   ↓
        ┌──────────┴──────┐      [Skip Pair]
        │ Check Cooldown  │
        └──────────┬──────┘
                   ↓
        ┌──────────┴──────────────────┐
        │ Has Active Cooldown?        │
        │ (declined/cancelled < 7d)   │
        └──────────┬─────────────┬────┘
                   │             │
                  NO            YES
                   │             │
                   ↓             ↓
        ┌──────────┴──────┐  [Skip Pair]
        │ hasActiveMatch? │  (Cooldown)
        └──────────┬──────┘
                   ↓
   ┌───────────────┴───────────────┐
   │ Has open match in last 24h?   │
   │ Status IN ('proposed',        │
   │            'accepted_by_a',   │
   │            'accepted_by_b')   │
   └───────┬───────────────┬───────┘
           │               │
          NO              YES
           │               │
           ↓               ↓
   ┌───────┴────────┐  [Skip Pair]
   │ Check Pending  │  (Already Open)
   │ Count < 3?     │
   └───────┬────────┘
           ↓
   ┌───────┴────────────────┐
   │ Both Users OK?         │
   └───────┬────────┬───────┘
           │        │
          YES      NO
           │        │
           ↓        ↓
   [CREATE MATCH] [Skip]
    status='proposed'
```

---

## 📈 Expected Metrics

### Before Fix

```
[Auto-Match Run]
├─ Users Fetched: 2 (alice, bob)
├─ Pairs Evaluated: 1 (alice ↔ bob)
│  ├─ Score: 0.7 ✅
│  ├─ Cooldown: false ✅
│  └─ Open Match: TRUE ❌  ← Found old 'accepted'
└─ Matches Created: 0 ❌

Blockers:
  ✅ Score Pass
  ✅ No Cooldown
  ❌ hasActiveMatch = true (WRONG!)
  ❌ Result: Skipped
```

### After Fix

```
[Auto-Match Run]
├─ Users Fetched: 2 (alice, bob)
├─ Pairs Evaluated: 1 (alice ↔ bob)
│  ├─ Score: 0.7 ✅
│  ├─ Cooldown: false ✅
│  └─ Open Match: FALSE ✅  ← Ignored old 'accepted'
└─ Matches Created: 1 ✅

Blockers:
  ✅ Score Pass
  ✅ No Cooldown
  ✅ hasActiveMatch = false (CORRECT!)
  ✅ Result: Created Proposal
```

---

## 🧪 Test Scenarios

```
Scenario 1: Fresh Users (No History)
  ┌─────────────────────────────────┐
  │ alice + bob (first time)        │
  │ → No matches                    │
  │ → No cooldowns                  │
  │ → Score: 0.7                    │
  │ → Result: ✅ MATCH CREATED      │
  └─────────────────────────────────┘

Scenario 2: Previous Completed Match
  ┌─────────────────────────────────┐
  │ alice + bob (old 'accepted')    │
  │ → BEFORE: ❌ Blocked            │
  │ → AFTER:  ✅ NOT Blocked        │
  │ → Score: 0.7                    │
  │ → Result: ✅ MATCH CREATED      │
  └─────────────────────────────────┘

Scenario 3: Recent Declined Match
  ┌─────────────────────────────────┐
  │ alice + bob (declined 2 days)   │
  │ → Cooldown: YES (5 days left)   │
  │ → Score: 0.7                    │
  │ → Result: ❌ BLOCKED (Cooldown) │
  └─────────────────────────────────┘

Scenario 4: Open Proposal
  ┌─────────────────────────────────┐
  │ alice + bob (status='proposed') │
  │ → Open Match: YES               │
  │ → Score: 0.7                    │
  │ → Result: ❌ BLOCKED (Open)     │
  └─────────────────────────────────┘

Scenario 5: Expired Cooldown
  ┌─────────────────────────────────┐
  │ alice + bob (declined 8 days)   │
  │ → Cooldown: NO (expired)        │
  │ → Open Match: NO                │
  │ → Score: 0.7                    │
  │ → Result: ✅ MATCH CREATED      │
  └─────────────────────────────────┘
```

---

## 🎬 Timeline Example

```
Day 0: First Match
  08:00 → Auto-match creates proposal (status='proposed')
  10:00 → Alice accepts (status='accepted_by_a')
  12:00 → Bob accepts (status='accepted')
          ✅ Match complete!

Day 1: Try to Re-Match
  BEFORE FIX:
    08:00 → Auto-match runs
            → hasActiveMatch finds 'accepted' match
            → ❌ Blocked (wrong!)
            → No new match

  AFTER FIX:
    08:00 → Auto-match runs
            → hasActiveMatch ignores 'accepted' status
            → ✅ Not blocked
            → New proposal created

Day 2: Decline the New Match
  10:00 → One user declines (status='declined')
          → Cooldown created (7 days)

Day 3-9: Cooldown Period
  08:00 → Auto-match runs daily
          → check_match_cooldown = true
          → ❌ Blocked by cooldown

Day 10: Cooldown Expired
  08:00 → Auto-match runs
          → check_match_cooldown = false
          → hasActiveMatch = false
          → ✅ New proposal created
```

---

## 📝 Code Change Summary

```diff
File: lib/services/matching-service.ts

  export async function hasActiveMatch(fidA, fidB) {
    const supabase = getServerSupabase();
+   const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const { data } = await supabase
      .from('matches')
      .select('id')
      .or(`and(user_a_fid.eq.${fidA},user_b_fid.eq.${fidB}),and(...)`)
-     .in('status', ['proposed', 'accepted_by_a', 'accepted_by_b', 'accepted'])
+     .in('status', ['proposed', 'accepted_by_a', 'accepted_by_b'])
+     .gte('created_at', twentyFourHoursAgo)
      .limit(1)
      .maybeSingle();

    return !!data;
  }

Changes:
  - Removed 'accepted' from status array
  + Added 24-hour time constraint
  + Added variable for readability
```

---

## ✨ Summary

**The Visual Explanation:**

1. **Before:** `'accepted'` status was checked → blocked new matches ❌
2. **After:** Only open statuses checked → allows new matches ✅
3. **Bonus:** Time constraint prevents ancient proposals from blocking

**Files to Review:**
- Code fix: `lib/services/matching-service.ts:176-197`
- Test: `test-auto-match.sh`
- Verify: `verify-matching-works.sql`

**Expected Result:**
```
matchesCreated: 1  (was 0)
```

That's the complete visual guide to the fix! 🎨
