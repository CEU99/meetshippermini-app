# Real-Time Chat - Quick Test Checklist 🚀

## 5-Minute Verification Test

### Prerequisites ✓
```bash
# 1. Check migration is applied
npx tsx scripts/check-message-setup.ts

# Expected: ✅ All checks passed!
# If fails: See MESSAGE_SENDING_FIX.md
```

---

## Test Setup

### Step 1: Start Server
```bash
pnpm run dev
```

### Step 2: Open Two Browsers

| Browser A (Chrome) | Browser B (Firefox/Incognito) |
|-------------------|-------------------------------|
| Open `localhost:3000` | Open `localhost:3000` |
| Login as User A | Login as User B |
| Go to Inbox → Accepted | Go to Inbox → Accepted |
| Open conversation room | Open SAME room |
| **Open Console (F12)** | **Open Console (F12)** |

---

## Test Checklist

### ✅ 1. Subscription Active (BOTH Browsers)

**Console Output Expected:**
```
[Chat] 🚀 Initializing real-time subscriptions for room: ...
[Chat] ✅ Message subscription active and listening
```

- [ ] Browser A shows subscription active
- [ ] Browser B shows subscription active
- [ ] No errors in either console

---

### ✅ 2. Real-Time Message Delivery

**Browser A Actions:**
1. Type: "Hello from User A"
2. Click Send (📤)

**Browser A Console Should Show:**
```
[Chat] 📨 Received INSERT event: { message_id: ..., sender_fid: ... }
[Chat] ➕ Adding new message to state
```

**Browser B Console Should Show (SIMULTANEOUSLY):**
```
[Chat] 📨 Received INSERT event: { message_id: ..., sender_fid: ... }
[Chat] ➕ Adding new message to state
```

**Browser B UI Check:**
- [ ] Message "Hello from User A" appears **INSTANTLY**
- [ ] No refresh required
- [ ] Message shows correct avatar and name

---

### ✅ 3. Bi-Directional Communication

**Browser B Actions:**
1. Type: "Hello back from User B"
2. Click Send

**Check:**
- [ ] Browser A receives message instantly
- [ ] Both consoles show INSERT events
- [ ] Both UIs show both messages in order

---

### ✅ 4. Rapid Messaging

**Test:**
- Send 5-10 messages rapidly from both browsers

**Expected:**
- [ ] All messages appear in both browsers
- [ ] No duplicates
- [ ] Messages in correct chronological order
- [ ] Console shows: `[Chat] 📊 Total messages in state: X`

---

### ✅ 5. Presence Indicators

**Visual Check:**
- [ ] Both browsers show **green pulsing dot** + "Online"
- [ ] Close Browser B
- [ ] Browser A shows **gray dot** + "Offline" (within 5 seconds)
- [ ] Reopen Browser B
- [ ] Reconnects and shows **green dot** again

**Console Output:**
```
[Presence] 🟢 Other user is online
[Presence] ⚫ Other user is offline
```

---

### ✅ 6. Input Field Visibility

**Check:**
- [ ] Text clearly visible while typing (white on dark)
- [ ] Placeholder text visible (gray)
- [ ] Purple glow on focus
- [ ] Smooth transitions

---

### ✅ 7. Cleanup (Optional)

**Close Browser A**

**Browser A Console (before closing):**
```
[Chat] 🧹 Cleaning up real-time subscriptions
[Chat] ✅ Cleanup complete
```

---

## Quick Console Reference

### ✅ Success Indicators:
```
[Chat] ✅ Message subscription active and listening
[Chat] 📨 Received INSERT event: {...}
[Chat] ➕ Adding new message to state
[Presence] 🟢 Other user is online
```

### ❌ Error Indicators:
```
[Chat] ❌ Message subscription error: ...
[Chat] ⏱️  Message subscription timed out
[Chat] Could not find the table 'meetshipper_messages'
```

---

## Pass/Fail Criteria

### ✅ PASS - Real-Time is Working:
- Both browsers show subscription active
- Messages appear instantly without refresh
- Console shows INSERT events on both sides
- Presence indicators work
- No errors in console

### ❌ FAIL - Needs Debugging:
- Subscription errors in console
- Messages only appear after refresh
- No INSERT events received
- "Could not find table" errors

**If FAIL:** See `REALTIME_FIX_COMPLETE.md` troubleshooting section

---

## Expected Timeline

| Action | Expected Response Time |
|--------|----------------------|
| Subscription setup | < 1 second |
| Message sent → Received | < 100ms |
| UI update | Instant (< 50ms) |
| Presence update | < 5 seconds |

---

## One-Line Test

**Quick verification:**
```
Open 2 browsers → Send message from Browser A →
Message appears in Browser B within 100ms → ✅ WORKING!
```

---

## If Something Fails

### Quick Fixes:

**No Subscription:**
```bash
# Check migration
npx tsx scripts/check-message-setup.ts
```

**Timeout Errors:**
```
• Refresh both browsers
• Check Supabase dashboard is online
• Verify internet connection
```

**No INSERT Events:**
```sql
-- Run in Supabase SQL Editor
ALTER PUBLICATION supabase_realtime ADD TABLE meetshipper_messages;
```

**Duplicate Messages:**
```
• Normal in dev mode (React Strict Mode)
• Won't happen in production build
```

---

## Success Criteria Summary

**You should see:**
- ✅ "Message subscription active" in console (both browsers)
- ✅ Messages appear instantly without refresh
- ✅ "Received INSERT event" logs on every message
- ✅ Green/gray presence dots working
- ✅ Clean, visible input field (white on dark)

**Total Test Time:** ~5 minutes
**Pass Rate:** Should be 100% if migration is applied

---

## Next Steps After Passing

✅ All tests pass → **Ready for production!**

Deploy checklist:
1. Verify migration applied on production database
2. Test with production Supabase URL
3. Verify Realtime is enabled in production
4. Test with multiple users
5. Monitor console for errors

---

**Quick Reference Card**

```
┌─────────────────────────────────────┐
│  Real-Time Chat Test Summary        │
├─────────────────────────────────────┤
│ ✅ Subscription: Active             │
│ ✅ INSERT Events: Received          │
│ ✅ UI Updates: Instant              │
│ ✅ Presence: Working                │
│ ✅ Input: Clearly Visible           │
│                                     │
│ Status: WORKING ✓                   │
└─────────────────────────────────────┘
```

---

**Last Updated:** 2025-10-30
**Build Status:** ✅ Successful (4.77 kB)
