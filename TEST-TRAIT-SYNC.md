# Quick Test: Profile Trait Synchronization

## 🎯 What This Tests

Verifies that profile traits update correctly between Edit Profile and Dashboard pages.

---

## ⚡ Quick Test (2 minutes)

### 1. Login
```
http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu
```

### 2. Go to Dashboard
```
http://localhost:3000/dashboard
```

**Check:** Note the current traits displayed under your profile

### 3. Edit Profile

Click "Edit Profile" button

**Action:**
- Deselect ALL current traits
- Select 5 NEW traits (different from before)
- Click "Save Profile"

### 4. Verify Dashboard

**Expected Result:**
- ✅ Success message appears
- ✅ Redirects to Dashboard after 1.5 seconds
- ✅ Dashboard shows ONLY the 5 new traits
- ✅ No old traits visible

### 5. Check Console

Open DevTools Console (F12), should see:
```
[EditProfile] ✅ Profile updated successfully: { bio: "...", traits: [...] }
[Dashboard] Profile update event received, updating state...
[Dashboard] Profile state updated: { bio: "...", traits: [...] }
```

---

## ✅ Pass Criteria

| Test | Expected Result |
|------|----------------|
| **Old traits removed** | ✅ Dashboard shows NO old traits |
| **New traits visible** | ✅ Dashboard shows all 5 new traits |
| **No page refresh needed** | ✅ Works without F5 |
| **Console logs present** | ✅ Event logs visible |
| **Bio also updates** | ✅ If changed, bio syncs too |

---

## 🔧 Advanced Tests

### Test A: Multiple Edits

1. Edit Profile → Change traits → Save
2. **Immediately** click "Edit Profile" again
3. Change traits again → Save
4. Verify Dashboard shows latest traits

**Expected:** ✅ Always shows most recent traits

### Test B: Tab Switching

1. Open Dashboard in Tab 1
2. Open Edit Profile in Tab 2
3. Change traits in Tab 2 → Save
4. Switch to Tab 1 (Dashboard)

**Expected:** ✅ Dashboard auto-refreshes and shows new traits

### Test C: Cancel Edit

1. Open Edit Profile
2. Change traits
3. Click "Cancel" (don't save)
4. Verify Dashboard

**Expected:** ✅ Dashboard unchanged (old traits still there)

---

## 🐛 If Tests Fail

### Issue: Old traits still showing

**Try:**
1. Check console for errors
2. Hard refresh (Ctrl+F5 / Cmd+Shift+R)
3. Restart dev server: `npm run dev`
4. Clear browser cache

### Issue: No console logs

**Check:**
1. DevTools Console open?
2. Console filter set to "All" (not "Errors" only)?
3. Page fully loaded before testing?

### Issue: "Save Profile" button disabled

**Reason:** Must select 5-10 traits (validation)

**Fix:**
- Ensure 5-10 traits selected
- Check counter: "Selected: X / 10"
- Green checkmark (✓) should appear

---

## 🔍 SQL Verification

Want to verify database behavior?

```bash
# In Supabase SQL Editor or psql:
psql <your-db-url> -f verify-trait-sync.sql
```

**What it checks:**
- ✅ Traits column exists
- ✅ Updates replace (not merge)
- ✅ Constraints enforced
- ✅ Index exists

---

## 📝 Expected Behavior Summary

### Before Fix (Broken)
```
Edit Profile → Save → Dashboard
❌ Shows old traits (cached)
```

### After Fix (Working)
```
Edit Profile → Save → Dashboard
✅ Shows new traits (synchronized)
```

### How It Works
```
Edit Profile
    ↓ saves to API
    ↓ dispatches event
    ↓ redirects
Dashboard
    ↓ receives event
    ↓ updates state
    ✅ Shows fresh traits
```

---

## 🎯 One-Liner Test

```bash
# Login, go to dashboard, edit profile, change 5 traits, save
# Result: Dashboard shows new traits immediately (no F5 needed)
```

---

**Time Required:** 2 minutes
**Difficulty:** Easy
**Prerequisites:** Dev server running
**Status:** Ready to test
