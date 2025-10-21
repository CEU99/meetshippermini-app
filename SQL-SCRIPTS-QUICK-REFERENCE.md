# SQL Scripts Quick Reference

## 🚨 Important: Use the "-fixed" Versions

The original SQL diagnostic scripts use **psql-specific syntax** (`\set` variables) that doesn't work in Supabase SQL Editor.

**Always use the `-fixed.sql` versions** which are compatible with Supabase.

---

## 📋 Available Scripts

### 1. Quick Inbox Check ⚡
**Use this first** for fast diagnosis.

**File:** `quick-inbox-check-fixed.sql`

**What it does:**
- Finds user by username (e.g., aysu16)
- Shows all their matches
- Tests if matches appear with FIXED pending logic
- Provides summary with next steps

**When to use:**
- Quick verification after fix
- Check if specific user can see their matches
- Verify pending filter works

**Run in:** Supabase SQL Editor

---

### 2. Comprehensive Diagnosis 🔍
**Use this for deep troubleshooting.**

**File:** `diagnose-inbox-missing-match-fixed.sql`

**What it does:**
- 9 detailed diagnostic steps
- Tests all scope filters (inbox, pending, awaiting, accepted, declined)
- Checks match_details view
- Verifies user records
- Tests FIXED API queries
- Checks for duplicate entries

**When to use:**
- Fix not working after applying code changes
- Need to understand why match isn't showing
- Debugging asymmetric behavior between users

**Run in:** Supabase SQL Editor

---

## 🚫 Don't Use These (Broken)

❌ `diagnose-inbox-missing-match.sql` - **psql-specific, won't work in Supabase**
❌ `quick-inbox-check.sql` - **psql-specific, won't work in Supabase**

These files use `\set` variable syntax which only works in psql command-line tool, not in Supabase SQL Editor.

---

## 📝 How to Use

### Quick Check (Recommended First)

1. **Open Supabase Dashboard**
   - Go to SQL Editor

2. **Copy `quick-inbox-check-fixed.sql`**
   - Paste entire file into SQL Editor

3. **Find user FID:**
   - Run Step 1 query (first SELECT)
   - Copy the FID from results

4. **Replace AYSU_FID_HERE:**
   - Use Find & Replace (Ctrl+H)
   - Replace all `AYSU_FID_HERE` with actual FID number
   - Example: Replace with `123456`

5. **Run all queries:**
   - Select all (Ctrl+A)
   - Click "Run" or press `Ctrl+Enter`

6. **Review results:**
   - Step 1: User found
   - Step 2: All matches shown
   - Step 3: Pending filter test
   - Step 5: Summary with next steps

7. **Expected:**
   - ✅ "Match should appear in inbox after fix"
   - Pending matches count > 0

---

### Comprehensive Diagnosis (If Issues Persist)

1. **Open Supabase Dashboard**
   - Go to SQL Editor

2. **Copy `diagnose-inbox-missing-match-fixed.sql`**
   - Paste entire file into SQL Editor

3. **Find user FID:**
   - Run Step 1 query (first SELECT)
   - Copy the FID from results

4. **Replace AYSU_FID_HERE:**
   - Use Find & Replace (Ctrl+H)
   - Replace all `AYSU_FID_HERE` with actual FID number
   - Example: Replace with `123456`

5. **Optional: Change Emir's FID**
   - If needed, replace `543581` with different FID
   - Use Find & Replace: `543581` → your FID

6. **Run all queries:**
   - Select all (Ctrl+A)
   - Click "Run" or press `Ctrl+Enter`

7. **Review all 9 steps:**
   - Step 1: User lookup ✅
   - Step 2: Match record
   - Step 3: User roles (who is user_a, who is user_b)
   - Step 4: Pending query test for aysu16
   - Step 5: Pending query test for Emir
   - Step 6: match_details view check
   - Step 7: User records verification
   - Step 8: Scope summary (shows counts for all scopes)
   - Step 9: Duplicate check

8. **Interpret results:**
   - ✅ in Step 4 or 5 = FIXED query works
   - ❌ in Step 4 or 5 = Match won't show (check status/acceptance flags)
   - Step 8: pending count > 0 = Should appear after fix

---

## 🎯 Quick Troubleshooting

### Scenario 1: Match exists but doesn't show

**Run:** `quick-inbox-check-fixed.sql`

**Look for:**
- Step 2: Match appears in list? ✅
- Step 3: Says "Should show in pending"? ✅
- Step 5: Pending matches > 0? ✅

**If all yes:** Restart server, clear cache, test again
**If any no:** Run comprehensive diagnosis

---

### Scenario 2: Works for one user, not the other

**Run:** `diagnose-inbox-missing-match-fixed.sql`

**Compare:**
- Step 4 (aysu16) vs Step 5 (Emir)
- Both should show ✅

**If asymmetric:**
- Check Step 3: User roles
- Check Step 2: Status and acceptance flags
- One user may have already accepted

---

### Scenario 3: No matches at all

**Run:** `quick-inbox-check-fixed.sql`

**Check:**
- Step 1: User FID found? (not null)
- Step 2: Any matches in list? (count > 0)

**If no matches:**
- Match may have been deleted
- Wrong user FID
- Match declined/accepted already

---

## 🔧 Configuration

### How to Configure Scripts

Both fixed scripts use placeholder `AYSU_FID_HERE` that you must replace:

**Step 1: Find the FID**
```sql
-- Run Step 1 query to find user
SELECT fid, username, display_name
FROM users
WHERE username ILIKE '%aysu%'  -- Change search term here
ORDER BY created_at DESC
LIMIT 5;
```

**Step 2: Replace Placeholder**
- Copy the FID from Step 1 results
- Use Find & Replace in SQL Editor (Ctrl+H)
- Replace: `AYSU_FID_HERE`
- With: The actual FID number (e.g., `123456`)

**Step 3: Optionally Change Emir's FID**
- If needed, replace `543581` with different FID
- Use Find & Replace: `543581` → your FID

**Example:**
```sql
-- Before
WHERE m.user_a_fid = AYSU_FID_HERE

-- After (if FID is 123456)
WHERE m.user_a_fid = 123456
```

---

## 📊 Understanding Results

### Step 8 Output (Scope Summary)

```
scope     | match_count | has_matches
----------|-------------|------------
inbox     | 1           | ✅
pending   | 1           | ✅
awaiting  | 0           | ❌
accepted  | 0           | ❌
declined  | 0           | ❌
```

**Interpretation:**
- **inbox = 1, pending = 1:** Match should appear in Pending tab ✅
- **inbox = 1, pending = 0:** Query filter broken (old bug) ❌
- **awaiting = 1:** User accepted, waiting for other party
- **accepted = 1:** Both accepted, meeting scheduled
- **declined = 1:** Match declined

---

## ✅ After Running Scripts

### If Scripts Show Match Should Appear:

1. **Restart dev server**
   ```bash
   npm run dev
   ```

2. **Clear browser cache**
   - `Ctrl+Shift+R` or `Cmd+Shift+R`

3. **Test in browser**
   - Login as user
   - Go to `/mini/inbox`
   - Check Pending tab

### If Scripts Show Match Won't Appear:

**Possible reasons:**
- Match already accepted (check `a_accepted`, `b_accepted`)
- Match declined (check `status = 'declined'`)
- Wrong user FID (check Step 1 output)
- match_details view out of sync (run `supabase-fix-match-details-view.sql`)

---

## 🔗 Related Files

- **Code fix:** `app/api/matches/route.ts` (lines 38-58)
- **Fix summary:** `INBOX-FIX-SUMMARY.md`
- **Fix guide:** `INBOX-MISSING-MATCH-FIX.md`
- **Verification:** `VERIFY-INBOX-FIX.md`
- **View fix:** `supabase-fix-match-details-view.sql`

---

## 💡 Tips

1. **Always use `-fixed.sql` versions** in Supabase SQL Editor
2. **Run quick check first** before comprehensive diagnosis
3. **Check Step 8** for scope counts - most useful summary
4. **Compare Step 4 and Step 5** to verify symmetric behavior
5. **Look for ✅ symbols** - they indicate positive results

---

## 🆘 If Nothing Works

1. **Verify code fix applied:**
   ```bash
   cat app/api/matches/route.ts | grep -A 10 "scope === 'pending'"
   ```
   Should show simplified OR logic with status filter outside

2. **Check match_details view:**
   ```sql
   SELECT COUNT(*) FROM match_details;
   ```
   Should return > 0

3. **Recreate view if needed:**
   ```bash
   # Run in Supabase SQL Editor
   supabase-fix-match-details-view.sql
   ```

4. **Check session FID matches user FID:**
   ```javascript
   // Browser console
   await fetch('/api/dev/session').then(r => r.json())
   ```

---

**Summary:** Use the `-fixed.sql` versions for all diagnostics. Run quick check first, comprehensive diagnosis if needed. 🚀
