# 🧪 Testing Guide: Terminal Status UI Changes

## Quick Test (5 Minutes)

### 1. Start the App
```bash
pnpm run dev
```

### 2. Navigate to Inbox
Open: `http://localhost:3000/mini/inbox`

---

## Test Cases

### ✅ Test 1: Pending Match Shows Buttons

**Steps**:
1. Click **Pending** tab
2. Select any match that needs your action

**Expected Results**:
- ✅ "Action needed" badge visible (red badge)
- ✅ Accept/Decline buttons visible in detail panel
- ✅ Yellow background around buttons
- ✅ Buttons are clickable

**Screenshot Location**: Pending tab with active match

---

### ✅ Test 2: Decline Match Hides Buttons

**Steps**:
1. In Pending tab, select a match
2. Click **Decline** button
3. Observe the UI update

**Expected Results**:
- ✅ Alert: "Match declined for both participants"
- ✅ Match disappears from Pending tab
- ✅ Match appears in Declined tab
- ✅ No console errors (check DevTools)

**Screenshot Location**: After decline action

---

### ✅ Test 3: Declined Match Has No Buttons

**Steps**:
1. Click **Declined** tab
2. Select a declined match

**Expected Results**:
- ❌ No "Action needed" badge
- ❌ No Accept/Decline buttons
- ✅ Status badge shows "declined" (red)
- ✅ Match details still visible
- ✅ Only informational content shown

**Screenshot Location**: Declined tab with selected match

---

### ✅ Test 4: Completed Match Has No Buttons

**Steps**:
1. Click **Completed** tab
2. Select a completed match (if any exist)

**Expected Results**:
- ❌ No "Action needed" badge
- ❌ No Accept/Decline buttons
- ✅ Status badge shows "completed" (gray)
- ✅ "Meeting Completed!" message visible
- ✅ Chat room access button may be visible

**Screenshot Location**: Completed tab with selected match

---

### ✅ Test 5: Accept Flow Still Works

**Steps**:
1. Go to Pending tab
2. Select a match
3. Click **Accept** button
4. Wait for processing

**Expected Results**:
- ✅ Button shows "Processing..." while loading
- ✅ Match moves to appropriate tab (Awaiting/Accepted)
- ✅ "Action needed" badge disappears
- ✅ Accept/Decline buttons disappear (you already acted)
- ✅ No errors in console

**Screenshot Location**: After accept action

---

### ✅ Test 6: Awaiting Tab Behavior

**Steps**:
1. Accept a match (you become accepted_by_a or accepted_by_b)
2. Go to **Awaiting Other Party** tab
3. Select the match you accepted

**Expected Results**:
- ❌ No "Action needed" badge
- ❌ No Accept/Decline buttons
- ✅ Status shows "Awaiting other party"
- ✅ Your action is recorded
- ✅ Waiting for other user

**Screenshot Location**: Awaiting tab

---

### ✅ Test 7: Re-decline Attempt (Edge Case)

**Steps**:
1. In Declined tab, note the match ID
2. Open DevTools Console
3. Try to manually decline again via console:
   ```javascript
   fetch('/api/matches/YOUR_MATCH_ID/decline-all', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' }
   }).then(r => r.json()).then(console.log)
   ```

**Expected Results**:
- ✅ Response: `{ success: false, reason: "already_terminal", message: "..." }`
- ✅ HTTP 200 (not 500!)
- ✅ UI doesn't show buttons anyway
- ✅ No crash or error

**Screenshot Location**: DevTools console with API response

---

## Visual Checklist

Use this checklist while testing:

| Tab | Match Status | "Action Needed" Badge | Accept/Decline Buttons |
|-----|--------------|----------------------|------------------------|
| Pending | pending (not accepted by me) | ✅ Should show | ✅ Should show |
| Awaiting | accepted_by_me | ❌ Should hide | ❌ Should hide |
| Accepted | accepted | ❌ Should hide | ❌ Should hide |
| Declined | declined | ❌ Should hide | ❌ Should hide |
| Completed | completed | ❌ Should hide | ❌ Should hide |

---

## Debugging Tips

### If buttons still show for declined matches:

1. **Check browser cache**:
   ```bash
   # Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
   ```

2. **Verify code changes**:
   ```bash
   grep -n "isTerminalStatus" app/mini/inbox/page.tsx
   # Should show lines: 337, 345, 685, 766, 774, 781
   ```

3. **Check console for errors**:
   - Open DevTools → Console
   - Look for any React errors or warnings

4. **Restart dev server**:
   ```bash
   # Kill server: Ctrl+C
   pnpm run dev
   ```

---

## Success Criteria

All of these must be true:

- [ ] ✅ Pending matches show buttons
- [ ] ✅ Declined matches hide buttons
- [ ] ✅ Completed matches hide buttons
- [ ] ✅ Cancelled matches hide buttons (if any)
- [ ] ✅ "Action needed" badge only on pending
- [ ] ✅ Decline action works without errors
- [ ] ✅ Accept action still works
- [ ] ✅ No console errors
- [ ] ✅ UI updates immediately (optimistic)
- [ ] ✅ Refetch syncs server state

---

## Quick Verification Command

Run this in browser console on the inbox page:

```javascript
// Check if terminal status helper exists
console.log('Terminal status check:', 
  typeof window !== 'undefined' && 
  document.querySelector('[data-testid="action-buttons"]') === null
);

// Log current matches
console.log('Current tab:', window.location.href);
console.log('Matches visible:', document.querySelectorAll('.match-card').length);
```

---

## Performance Check

The changes should have **zero performance impact**:

- ✅ No new API calls
- ✅ No new state
- ✅ Simple boolean checks
- ✅ No expensive computations
- ✅ Same render cycle

---

## Rollback Plan (If Needed)

If something breaks:

```bash
# Revert changes
git diff app/mini/inbox/page.tsx
git checkout app/mini/inbox/page.tsx

# Or restore from backup
cp app/mini/inbox/page.tsx.backup app/mini/inbox/page.tsx
```

---

## Report Template

After testing, report:

```
✅ Test 1 (Pending buttons): PASS/FAIL
✅ Test 2 (Decline action): PASS/FAIL
✅ Test 3 (Declined no buttons): PASS/FAIL
✅ Test 4 (Completed no buttons): PASS/FAIL
✅ Test 5 (Accept flow): PASS/FAIL
✅ Test 6 (Awaiting tab): PASS/FAIL
✅ Test 7 (Re-decline edge case): PASS/FAIL

Issues found: [None / List issues]
Screenshots: [Attached / Not attached]
Browser: [Chrome/Firefox/Safari]
```

---

**Estimated Testing Time**: 5-10 minutes
**Required Tools**: Browser + DevTools
**Risk Level**: Low (UI-only changes)

---

*Ready to test!* 🚀
