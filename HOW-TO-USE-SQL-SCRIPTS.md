# How to Use SQL Diagnostic Scripts

Quick guide for running the inbox diagnostic SQL scripts in Supabase.

---

## ⚡ Quick Start (5 Steps)

### 1. Open Supabase SQL Editor
- Go to your Supabase Dashboard
- Click **SQL Editor** in left sidebar

### 2. Copy the Script
**Choose one:**
- **Fast check:** Copy `quick-inbox-check-fixed.sql`
- **Deep diagnosis:** Copy `diagnose-inbox-missing-match-fixed.sql`

Paste into SQL Editor

### 3. Run Step 1 to Find User FID
- **Select only the first query** (Step 1)
- Click **Run** or press `Ctrl+Enter`
- Look at results, find the row with your user
- **Copy the FID** (example: `123456`)

### 4. Replace the Placeholder
- Press `Ctrl+H` (Find & Replace)
- Find: `AYSU_FID_HERE`
- Replace with: The FID you copied (example: `123456`)
- Click **Replace All**

### 5. Run All Queries
- Press `Ctrl+A` (Select All)
- Click **Run** or press `Ctrl+Enter`
- Review all results

---

## 📸 Visual Example

```
Step 1 Result:
┌────────┬────────────┬──────────────┐
│  fid   │  username  │ display_name │
├────────┼────────────┼──────────────┤
│ 123456 │ aysu16     │ Aysu User    │ ← Copy this FID
└────────┴────────────┴──────────────┘

Find & Replace:
┌─────────────────────────────────────┐
│ Find:    AYSU_FID_HERE              │
│ Replace: 123456                     │ ← Paste FID here
│                                     │
│ [Replace All]                       │
└─────────────────────────────────────┘

After replacement, queries will look like:
WHERE m.user_a_fid = 123456  ← Was AYSU_FID_HERE
   OR m.user_b_fid = 123456  ← Was AYSU_FID_HERE
```

---

## 🎯 What to Look For

### Quick Check Script Results

**Step 1:** User found
- ✅ FID appears in results
- ❌ No FID? User doesn't exist

**Step 2:** All matches shown
- Shows all matches involving the user
- Note the role: "user_a" or "user_b"

**Step 3:** Pending filter test
- ✅ "Should show in pending" = Fix will work
- ❌ "Already accepted" = Match already processed

**Step 5:** Summary
- ✅ "Match should appear in inbox after fix"
- Tells you next steps to apply fix

---

### Comprehensive Diagnosis Results

**Step 1-3:** Basic info
- User FID, match record, user roles

**Step 4-5:** Critical tests
- ✅ Shows match will appear for user
- ❌ Shows match won't appear (check why)

**Step 6-7:** System checks
- match_details view exists
- Users exist in database

**Step 8:** Scope summary (most important)
```
┌──────────┬──────────────┬──────────────┐
│  scope   │ match_count  │ has_matches  │
├──────────┼──────────────┼──────────────┤
│ inbox    │      1       │      ✅      │
│ pending  │      1       │      ✅      │ ← Should be > 0
│ awaiting │      0       │      ❌      │
│ accepted │      0       │      ❌      │
│ declined │      0       │      ❌      │
└──────────┴──────────────┴──────────────┘
```

**Step 9:** Duplicate check
- ✅ OK = No duplicates
- ⚠️ DUPLICATE FID = Data integrity issue

---

## 🚨 Common Issues

### Issue 1: "Column AYSU_FID_HERE does not exist"

**Cause:** You forgot to replace the placeholder

**Fix:**
1. Press `Ctrl+H`
2. Find: `AYSU_FID_HERE`
3. Replace with: Actual FID number
4. Click "Replace All"

---

### Issue 2: "No rows returned" in Step 1

**Cause:** Username search didn't match

**Fix:**
1. Edit Step 1 query
2. Change `'%aysu%'` to match your username
3. Example: `'%john%'` to find users with "john"

```sql
-- Original
WHERE username ILIKE '%aysu%'

-- Modified
WHERE username ILIKE '%yourname%'
```

---

### Issue 3: Step 8 shows "pending = 0" but "inbox = 1"

**Meaning:** This is the exact bug! The filter is broken.

**Fix:**
1. The code fix in `app/api/matches/route.ts` will solve this
2. Restart server: `npm run dev`
3. Test in browser

---

### Issue 4: Script runs but shows empty results

**Possible causes:**
- Match doesn't exist
- User FID is wrong
- Match was deleted

**Debug:**
1. Check Step 2: Does match appear?
2. If no: Match doesn't exist
3. Verify FID with: `SELECT * FROM users WHERE username = 'aysu16'`

---

## 💡 Tips

### Tip 1: Run Step 1 First

Always run Step 1 alone first to get the FID. Don't run the whole script with `AYSU_FID_HERE` placeholders.

### Tip 2: Use Find & Replace

Don't manually edit each line. Use `Ctrl+H` to replace all occurrences at once.

### Tip 3: Save the FID

Write down the FID somewhere. You might need it for debugging later.

### Tip 4: Check Step 8 First

In comprehensive diagnosis, Step 8 (scope summary) gives you the quickest answer about whether the fix will work.

### Tip 5: Compare Step 4 vs Step 5

If one user's query works (✅) but the other doesn't (❌), that's asymmetric behavior - exactly what the fix addresses.

---

## 🎓 Understanding the Scripts

### Why Two Scripts?

**`quick-inbox-check-fixed.sql`** (5 steps)
- Fast verification
- Good for: "Does the fix work?"
- Takes: ~30 seconds

**`diagnose-inbox-missing-match-fixed.sql`** (9 steps)
- Deep diagnosis
- Good for: "Why doesn't it work?"
- Takes: ~2 minutes

### What Do They Test?

Both scripts test the **FIXED** pending query logic:

```sql
-- The fix
WHERE (m.user_a_fid = YOUR_FID OR m.user_b_fid = YOUR_FID)
  AND (
    (m.user_a_fid = YOUR_FID AND m.a_accepted = false)
    OR
    (m.user_b_fid = YOUR_FID AND m.b_accepted = false)
  )
  AND m.status IN ('proposed', 'pending', 'accepted_by_a', 'accepted_by_b')
```

If this query returns results, the fix will work.

---

## 📋 Checklist

Before running scripts:
- [ ] Supabase SQL Editor open
- [ ] Script copied and pasted
- [ ] Step 1 run to find FID
- [ ] FID copied from results

To replace placeholder:
- [ ] Press `Ctrl+H`
- [ ] Find: `AYSU_FID_HERE`
- [ ] Replace: Actual FID number
- [ ] Click "Replace All"

After running:
- [ ] Step 1: User found ✅
- [ ] Step 3 (quick) or Step 4-5 (comprehensive): Shows ✅
- [ ] Step 8 (comprehensive): pending > 0
- [ ] Summary: "Match should appear after fix"

---

## 🆘 Still Having Issues?

### If scripts won't run:
1. Check you replaced `AYSU_FID_HERE`
2. Verify FID is a number (not text)
3. Make sure you're in Supabase SQL Editor (not psql)

### If results don't make sense:
1. Run `quick-inbox-check-fixed.sql` first
2. Check Step 2: Does match exist?
3. If match exists but pending = 0, apply code fix

### If you need help:
1. Save the Step 8 results
2. Share the scope summary
3. Note which steps show ✅ vs ❌

---

## 🎉 Success Looks Like

```
Step 8: Scope Summary
┌──────────┬──────────────┬──────────────┐
│  scope   │ match_count  │ has_matches  │
├──────────┼──────────────┼──────────────┤
│ inbox    │      1       │      ✅      │
│ pending  │      1       │      ✅      │ ← This is the key!
└──────────┴──────────────┴──────────────┘

Summary:
✅ Match should appear in inbox after fix

Next steps:
  1. Restart dev server (npm run dev)
  2. Clear browser cache
  3. Login as aysu16
  4. Go to /mini/inbox
  5. Check Pending tab
```

If you see this, the fix will work! 🚀

---

**Related docs:**
- `SQL-SCRIPTS-QUICK-REFERENCE.md` - Full reference
- `INBOX-FIX-COMPLETE.md` - Complete fix guide
- `VERIFY-INBOX-FIX.md` - Testing guide
