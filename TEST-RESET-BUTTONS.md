# Quick Test: Reset Buttons Feature

## 🎯 What to Test

Two new reset buttons on Edit Profile page:
1. **Reset Bio** - Clears bio text
2. **Reset Personal Traits** - Deselects all traits

---

## ⚡ Quick Test (3 minutes)

### Setup

```bash
# 1. Login
http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu

# 2. Go to Edit Profile
http://localhost:3000/profile/edit
```

---

### Test 1: Reset Bio (1 minute)

1. **Type bio text:**
   - Enter: "This is my test bio"
   - Character count shows: 20 / 100

2. **Click "Reset Bio" (red button below textarea):**
   - Confirmation dialog appears
   - Message: "Are you sure you want to clear your bio?"
   - Click "OK"

3. **Expected result:**
   - ✅ Bio textarea clears instantly
   - ✅ Character count: 0 / 100
   - ✅ Success message: "Profile updated successfully!"
   - ✅ "Reset Bio" button becomes gray (disabled)

4. **Verify persistence:**
   - Click "Cancel" → Go to Dashboard
   - Check: Bio is empty ✅
   - Click "Edit Profile" again
   - Check: Bio still empty ✅

---

### Test 2: Reset Personal Traits (1 minute)

1. **Select 5 traits:**
   - Click any 5 trait buttons (e.g., Creative, Adventurous, etc.)
   - Counter shows: Selected: 5 / 10

2. **Click "Reset Personal Traits" (red button at bottom):**
   - Confirmation dialog appears
   - Message: "Are you sure you want to reset all personal traits?"
   - Click "OK"

3. **Expected result:**
   - ✅ All trait buttons deselected instantly
   - ✅ Counter: Selected: 0 / 10
   - ✅ Success message: "Profile updated successfully!"
   - ✅ "Reset Personal Traits" button becomes gray (disabled)
   - ✅ "Save Profile" button becomes gray (need 5-10 traits)

4. **Verify persistence:**
   - Select 5 new traits
   - Click "Save Profile"
   - Return to Edit Profile
   - Click "Reset Personal Traits" → OK
   - Go to Dashboard
   - Check: No traits visible ✅

---

### Test 3: Cancel Dialog (30 seconds)

1. **Test Bio Cancel:**
   - Add bio text
   - Click "Reset Bio"
   - Click "Cancel" in dialog
   - **Check:** ✅ Bio text unchanged

2. **Test Traits Cancel:**
   - Select 5 traits
   - Click "Reset Personal Traits"
   - Click "Cancel" in dialog
   - **Check:** ✅ Traits still selected

---

## ✅ Pass Criteria

| Test | Expected |
|------|----------|
| **Reset Bio button visible** | ✅ Red button below bio textarea |
| **Reset Traits button visible** | ✅ Red button next to Save Profile |
| **Bio resets** | ✅ Clears instantly + saves to DB |
| **Traits reset** | ✅ Deselects all + saves to DB |
| **Confirmation required** | ✅ Dialog appears before reset |
| **Cancel works** | ✅ No changes when cancelled |
| **Buttons disabled when empty** | ✅ Gray when nothing to reset |
| **Dashboard syncs** | ✅ Shows cleared data immediately |
| **Success message** | ✅ Green message appears |

---

## 🔍 Visual Verification

### Bio Section (Should Look Like This)

```
┌──────────────────────────────────────┐
│ Bio                                  │
│ ┌────────────────────────────────┐   │
│ │ [Bio textarea]                 │   │
│ │                                │   │
│ └────────────────────────────────┘   │
│                                      │
│ [Reset Bio]           0 / 100 chars  │
│  ↑ RED BUTTON                        │
└──────────────────────────────────────┘
```

### Bottom Buttons (Should Look Like This)

```
┌──────────────────────────────────────────────────┐
│                                                  │
│ [Cancel]  [Reset Personal Traits]  [Save Profile]│
│  (gray)         ↑ RED BUTTON         (purple)    │
└──────────────────────────────────────────────────┘
```

---

## 🐛 If Tests Fail

### Reset Bio button not working

**Try:**
1. Check console for errors (F12)
2. Restart dev server: `npm run dev`
3. Hard refresh: Ctrl+F5 or Cmd+Shift+R

### Reset Traits button disabled

**Reason:** No traits selected (expected behavior)

**Fix:** Select at least 1 trait, then button will enable

### Confirmation dialog not appearing

**Check:**
1. Pop-up blocker enabled?
2. Browser console errors?

**Fix:** Disable pop-up blocker for localhost

---

## 📊 Expected Console Logs

Open DevTools Console (F12), should see:

**After Reset Bio:**
```
[EditProfile] ✅ Bio reset successfully
[Dashboard] Profile update event received, updating state...
```

**After Reset Traits:**
```
[EditProfile] ✅ Traits reset successfully
[Dashboard] Profile update event received, updating state...
```

---

## 🎯 One-Liner Tests

```bash
# Reset Bio Test
Login → Edit Profile → Add bio → Reset Bio → OK → Bio clears ✅

# Reset Traits Test
Login → Edit Profile → Select 5 traits → Reset Personal Traits → OK → All deselected ✅

# Persistence Test
Reset → Go to Dashboard → No bio/traits shown ✅
```

---

## 🔧 Button States Reference

### Reset Bio Button

| Condition | State |
|-----------|-------|
| Bio is empty (0 chars) | 🔒 Disabled (gray) |
| Bio has text | ✅ Enabled (red) |
| Currently saving | 🔒 Disabled (gray) |

### Reset Personal Traits Button

| Condition | State |
|-----------|-------|
| 0 traits selected | 🔒 Disabled (gray) |
| 1+ traits selected | ✅ Enabled (red) |
| Currently saving | 🔒 Disabled (gray) |

---

## 📝 Summary

**Time Required:** 3 minutes
**Difficulty:** Easy
**Prerequisites:** Dev server running

**What to Check:**
1. ✅ Buttons are red and visible
2. ✅ Confirmation dialogs appear
3. ✅ Reset clears fields instantly
4. ✅ Changes persist in database
5. ✅ Dashboard syncs automatically
6. ✅ Success messages show
7. ✅ Cancel works properly

**Status:** Ready to test!
