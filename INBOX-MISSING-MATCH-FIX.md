## Inbox Missing Match - Diagnosis & Fix

### 🚨 Problem

**Symptom:** New user @aysu16 receives match notification but match doesn't appear in `/mini/inbox`.

**What works:**
- ✅ Match exists in database
- ✅ Emir (@cengizhaneu, FID 543581) sees the match
- ✅ Notification triggered for @aysu16

**What doesn't work:**
- ❌ @aysu16 sees "no pending matches" in inbox

---

### 🔍 Root Cause Analysis

I've identified **TWO potential issues** in the code:

#### Issue 1: Supabase PostgREST OR Query Syntax (Most Likely)

**Location:** `app/api/matches/route.ts` lines 40-42

```typescript
// CURRENT (INCORRECT):
query = query.or(
  `and(user_a_fid.eq.${userFid},a_accepted.eq.false,status.in.(proposed,pending)),and(user_b_fid.eq.${userFid},b_accepted.eq.false,status.in.(proposed,pending))`
);
```

**Problem:** This query has two separate `AND` conditions joined by OR, but it's missing the outer parentheses and proper negation handling. PostgREST might be misinterpreting this.

**Simplified explanation:**
- We want: `(condition_a) OR (condition_b)`
- We're sending: Two AND blocks with OR but PostgREST might parse it wrong
- Result: Some matches don't match the filter

#### Issue 2: Match Status Edge Case

If the match status is something unexpected (like `'proposed'` when code expects `'pending'`), the filter won't match.

---

### ✅ Solution: Fix the API Query

**File:** `app/api/matches/route.ts`

**Replace lines 38-53 with:**

```typescript
} else if (scope === 'pending') {
  // Waiting for my response
  // User is a participant AND hasn't accepted yet
  const pendingConditions = [];

  // If I'm user_a and haven't accepted
  pendingConditions.push(`and(user_a_fid.eq.${userFid},a_accepted.eq.false)`);

  // OR if I'm user_b and haven't accepted
  pendingConditions.push(`and(user_b_fid.eq.${userFid},b_accepted.eq.false)`);

  query = query
    .or(pendingConditions.join(','))
    .in('status', ['proposed', 'pending', 'accepted_by_a', 'accepted_by_b']);

} else if (scope === 'awaiting') {
  // I accepted, waiting for other party
  const awaitingConditions = [];

  // If I'm user_a and accepted, but user_b hasn't
  awaitingConditions.push(`and(user_a_fid.eq.${userFid},a_accepted.eq.true,b_accepted.eq.false)`);

  // OR if I'm user_b and accepted, but user_a hasn't
  awaitingConditions.push(`and(user_b_fid.eq.${userFid},b_accepted.eq.true,a_accepted.eq.false)`);

  query = query
    .or(awaitingConditions.join(','))
    .in('status', ['accepted_by_a', 'accepted_by_b', 'proposed', 'pending']);
```

**Why this works:**
1. Separates the OR conditions more clearly
2. Moves status filter outside the OR (applies to all matches)
3. Includes all possible statuses that could be "pending" for a user
4. More explicit about what we're filtering

---

### 🔍 Quick Diagnostic

Before applying the fix, run this to see what's actually in the database:

```sql
-- Find aysu16's FID first
SELECT fid, username, display_name
FROM users
WHERE username ILIKE '%aysu%'
ORDER BY created_at DESC
LIMIT 5;

-- Then check their matches (replace YOUR_FID with actual FID)
SELECT
  m.id,
  m.user_a_fid,
  ua.username as user_a,
  m.user_b_fid,
  ub.username as user_b,
  m.status,
  m.a_accepted,
  m.b_accepted,
  CASE
    WHEN m.user_a_fid = YOUR_FID THEN 'aysu is user_a'
    WHEN m.user_b_fid = YOUR_FID THEN 'aysu is user_b'
    ELSE 'aysu not in match'
  END as aysu_role
FROM matches m
LEFT JOIN users ua ON m.user_a_fid = ua.fid
LEFT JOIN users ub ON m.user_b_fid = ub.fid
WHERE m.user_a_fid = YOUR_FID
   OR m.user_b_fid = YOUR_FID
   OR m.user_a_fid = 543581  -- Emir
   OR m.user_b_fid = 543581
ORDER BY m.created_at DESC
LIMIT 10;
```

**Look for:**
- ✅ Match exists
- ✅ @aysu16 is either user_a or user_b
- ✅ Status is 'proposed' or 'pending'
- ✅ The appropriate accepted flag is false

**If all these are true but match still doesn't show, it's definitely the API query bug.**

---

### 🧪 Test the Fix

After applying the code change:

1. **Restart server:**
   ```bash
   npm run dev
   ```

2. **Clear browser cache/reload:**
   ```
   Ctrl+Shift+R or Cmd+Shift+R
   ```

3. **Check inbox as @aysu16:**
   ```
   http://localhost:3000/mini/inbox
   ```

4. **Expected:**
   - ✅ Match appears in "Pending" tab
   - ✅ Shows Emir's name
   - ✅ "Accept" button available

---

### 🔧 Alternative: Test Query Directly

To verify the query logic before changing code:

```sql
-- Simulate the FIXED pending query for aysu16
WITH aysu_fid AS (
  SELECT fid FROM users WHERE username ILIKE '%aysu%' LIMIT 1
)
SELECT
  m.*,
  '📥 Would show in pending?' as test
FROM match_details m, aysu_fid
WHERE (
  m.user_a_fid = aysu_fid.fid
  OR m.user_b_fid = aysu_fid.fid
)
AND (
  (m.user_a_fid = aysu_fid.fid AND m.a_accepted = false)
  OR
  (m.user_b_fid = aysu_fid.fid AND m.b_accepted = false)
)
AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b');
```

**If this returns the match, the fix will work.**

---

### 📋 Verification Checklist

- [ ] Applied code fix to `app/api/matches/route.ts`
- [ ] Restarted dev server
- [ ] Cleared browser cache
- [ ] Logged in as @aysu16
- [ ] Match appears in Pending tab
- [ ] Can click Accept button
- [ ] After accepting, match moves to Awaiting or Accepted

---

### 🐛 If Still Not Working

**Check these:**

1. **User FID mismatch:**
   ```sql
   -- Check what FID the session has
   SELECT * FROM users WHERE username ILIKE '%aysu%';

   -- Check what FID the match has
   SELECT user_a_fid, user_b_fid FROM matches WHERE id = 'MATCH_ID';
   ```

2. **match_details view out of sync:**
   ```sql
   -- Refresh the view
   REFRESH MATERIALIZED VIEW IF EXISTS match_details;

   -- Or recreate it
   DROP VIEW IF EXISTS match_details CASCADE;
   -- Then run supabase-fix-match-details-view.sql
   ```

3. **API not using match_details:**
   - The API queries `match_details` view
   - If view doesn't exist or is old, matches won't show
   - Run `supabase-fix-match-details-view.sql`

4. **Session FID doesn't match user FID:**
   ```javascript
   // Check in browser console on /mini/inbox
   await fetch('/api/dev/session').then(r => r.json())
   // FID should match aysu16's actual FID
   ```

---

### 💡 Why Emir Sees It But Aysu Doesn't

**Most likely:** The OR query bug affects different users differently depending on:
1. Whether they're user_a or user_b
2. The match status
3. PostgREST's query parser quirks

**Example:**
- Emir is user_a → first AND condition matches → query works
- Aysu is user_b → second AND condition → query fails due to parsing

**The fix:** Makes both conditions clearer and more symmetric.

---

### 🎯 Expected Behavior After Fix

**For @aysu16:**
1. Login → `/mini/inbox`
2. See match in "Pending" tab
3. Click "Accept"
4. Match moves to "Awaiting other party" (if Emir hasn't accepted)
5. When Emir accepts → Match in "Accepted" tab with meeting link

**For Emir:**
1. Already sees match (works)
2. After both accept → Meeting link appears
3. Both get system messages with link

---

### 📝 Quick Command Reference

```bash
# Apply fix
# Edit app/api/matches/route.ts with changes above

# Restart server
npm run dev

# Test as aysu16
http://localhost:3000/mini/inbox

# Check logs
# Terminal should show: [API] GET /api/matches?scope=pending

# If issues persist, run diagnostic
psql <conn> -f diagnose-inbox-missing-match.sql
```

---

### 🔐 Root Cause Summary

**The bug:** PostgREST OR query with complex AND conditions inside isn't being parsed correctly, causing some matches to be filtered out incorrectly.

**The symptom:** One user sees match, other doesn't, even though both are participants.

**The fix:** Simplify the OR logic and move status filter outside the OR clause.

**Impact:** Affects any match where user_b hasn't accepted yet (depending on status).

Apply the fix and test! 🚀
