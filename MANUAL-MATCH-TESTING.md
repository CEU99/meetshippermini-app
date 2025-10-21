# Manual Match Testing Checklist

## 🧪 Quick Test Guide

Use this checklist to verify the manual match feature works correctly.

---

## ✅ Pre-Test Setup

- [ ] Dev server running (`npm run dev`)
- [ ] Database connected (check Supabase)
- [ ] At least 2 test users exist in database
- [ ] You know test user FIDs or User Codes

---

## 📋 Test Scenarios

### **Test 1: Basic Match Request Flow**

**Steps:**
1. Navigate to `http://localhost:3000/mini/create`
2. Enter a valid FID (e.g., `12345`)
3. Click "Find User"
4. Enter introduction message: "I'd love to connect and discuss our shared interests!"
5. Click "Send Match Request"

**Expected Results:**
- [ ] User preview appears after clicking "Find User"
- [ ] Submit button disabled until message is 20+ characters
- [ ] Green checkmark appears when message is valid
- [ ] Success message shows after submit
- [ ] Redirect to inbox after 2 seconds
- [ ] Match appears in database with `status='proposed'`

---

### **Test 2: User Code Lookup**

**Steps:**
1. Navigate to `/mini/create`
2. Enter a valid User Code (e.g., `ABC1234567`)
3. Click "Find User"

**Expected Results:**
- [ ] Correct user appears in preview
- [ ] Can complete match request flow
- [ ] Same validation as FID lookup

---

### **Test 3: Message Validation**

**Test 3a: Too Short**
1. Enter: "Hi there" (8 characters)
2. Observe validation

**Expected:**
- [ ] Red error message: "Minimum 20 characters (8/20)"
- [ ] Submit button disabled
- [ ] Character counter shows 8/100

**Test 3b: Valid Length**
1. Enter: "I think we'd work great together!" (35 characters)

**Expected:**
- [ ] Green checkmark: "✓ Message looks good"
- [ ] Submit button enabled
- [ ] Character counter shows 35/100

**Test 3c: Too Long**
1. Enter: 101+ character message

**Expected:**
- [ ] Red error: "Maximum 100 characters (101/100)"
- [ ] Textarea prevents typing past 100
- [ ] Submit button disabled

---

### **Test 4: Error Cases**

**Test 4a: User Not Found**
1. Enter FID: `99999999` (doesn't exist)
2. Click "Find User"

**Expected:**
- [ ] Error message: "User not found..."
- [ ] No user preview shown

**Test 4b: Self-Match Prevention**
1. Enter your own FID
2. Click "Find User"

**Expected:**
- [ ] Error: "You cannot create a match with yourself"

**Test 4c: Invalid Input**
1. Enter: `abc123` (not valid FID or User Code)
2. Click "Find User"

**Expected:**
- [ ] Error: "User not found..."

---

### **Test 5: Target User Accepts**

**Setup:**
1. Create match request as User A
2. Login as User B

**Steps:**
1. Navigate to `/mini/inbox` as User B
2. See match proposal from User A
3. Read introduction message
4. Click "Accept"

**Expected:**
- [ ] System message appears: "[Username] accepted the match!"
- [ ] Match status updates to `accepted_by_b`
- [ ] User A sees notification in their inbox

---

### **Test 6: Both Users Accept**

**Setup:**
1. User A creates match request
2. User B accepts

**Steps:**
1. Login as User A
2. Navigate to `/mini/inbox`
3. See User B accepted
4. Click "Accept"

**Expected:**
- [ ] User A sees system message: "🎉 Match accepted! Both parties agreed to meet. Your meeting link: [link]"
- [ ] User B sees system message: "🎉 Match accepted! Both parties agreed to meet. Your meeting link: [link]"
- [ ] Both messages contain the same meeting link
- [ ] Match status = `accepted`
- [ ] Meeting link visible to both users in their inboxes
- [ ] Both users can access the meeting link
- [ ] Can start chatting

---

### **Test 7: Target User Declines**

**Setup:**
1. Create match request as User A
2. Login as User B

**Steps:**
1. Navigate to `/mini/inbox` as User B
2. Click "Decline"
3. (Optional) Enter reason
4. Confirm decline

**Expected:**
- [ ] System message to User B: "Match declined by [username]"
- [ ] System message to User A: "Your match request was declined."
- [ ] Match status = `declined`
- [ ] Cooldown created in database
- [ ] Login as User A and try to match again → Error about cooldown

---

### **Test 8: Cooldown Enforcement**

**Setup:**
1. User A sends request to User B
2. User B declines
3. Wait for cooldown record to be created

**Test:**
1. Login as User A
2. Try to create another match with User B

**Expected:**
- [ ] Backend returns error about cooldown
- [ ] Error message displayed to user
- [ ] Match creation prevented

**Verify in Database:**
```sql
SELECT * FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((user_a, user_b), (user_b, user_a));
```
- [ ] Cooldown record exists
- [ ] `cooldown_until` = `declined_at` + 7 days

---

### **Test 9: Pending Match Limits**

**Setup:**
1. Create 3 pending matches as User A

**Test:**
1. Try to create a 4th match

**Expected:**
- [ ] Error: "You have reached the maximum of 3 pending matches..."
- [ ] Match creation prevented

---

### **Test 10: Active Match Prevention**

**Setup:**
1. User A and User B have an active match (status = 'proposed' or 'accepted_by_a')

**Test:**
1. Try to create another match between same users

**Expected:**
- [ ] Error: "You already have an active match with this user"
- [ ] Match creation prevented

---

## 🔍 Database Verification Queries

### Check Match Was Created
```sql
SELECT
  id,
  user_a_fid,
  user_b_fid,
  status,
  message,
  rationale,
  a_accepted,
  b_accepted,
  created_by
FROM matches
WHERE user_a_fid = [your_fid]
ORDER BY created_at DESC
LIMIT 1;
```

**Expected:**
- `status = 'proposed'`
- `created_by = 'user'`
- `rationale->>'manualMatch' = 'true'`
- `message` = your introduction message

### Check System Messages Created
```sql
SELECT
  sender_fid,
  content,
  is_system_message,
  created_at
FROM messages
WHERE match_id = '[match_id]'
ORDER BY created_at ASC;
```

**Expected (for accepted match):**
- First message: `Match request: "[your message]"`
- When accepted by one: `[username] accepted the match! Waiting for your response.`
- When both accept (2 messages):
  - Message for User A: `🎉 Match accepted! Both parties agreed to meet. Your meeting link: [link]`
  - Message for User B: `🎉 Match accepted! Both parties agreed to meet. Your meeting link: [link]`
- All have `is_system_message = true`
- Both meeting link messages contain the same URL

### Check Cooldown Created (After Decline)
```sql
SELECT
  user_a_fid,
  user_b_fid,
  declined_at,
  cooldown_until,
  cooldown_until > NOW() as is_active
FROM match_cooldowns
WHERE (user_a_fid, user_b_fid) IN ((a, b), (b, a))
ORDER BY declined_at DESC
LIMIT 1;
```

**Expected:**
- `is_active = true`
- `cooldown_until` = ~7 days from now

---

## 📱 UI/UX Checks

### Visual Validation
- [ ] Form layout looks clean and professional
- [ ] Avatar loads correctly in user preview
- [ ] Character counter updates in real-time
- [ ] Validation messages are clear
- [ ] Success/error states are visually distinct
- [ ] Mobile responsive (test on small screen)

### Accessibility
- [ ] All form fields have labels
- [ ] Required fields marked with asterisk
- [ ] Error messages are readable
- [ ] Can navigate form with keyboard
- [ ] Tab order makes sense

### User Experience
- [ ] Clear instructions at top of page
- [ ] "What happens next?" box is helpful
- [ ] Validation summary shows progress
- [ ] Loading states show during API calls
- [ ] Success message before redirect
- [ ] Cancel button works correctly

---

## 🐛 Common Issues & Solutions

### Issue: "User not found" for valid FID
**Check:**
- User exists in `users` table
- FID is exact match (no extra spaces)

**Fix:**
```sql
SELECT fid, username FROM users WHERE fid = [test_fid];
```

### Issue: Meeting link not generated
**Check:**
- `meeting-service.ts` is configured
- Google Meet API credentials set

**Workaround:**
- System message still sent
- Link generation can be fixed separately

### Issue: Cooldown not working
**Check:**
- Trigger `trg_match_decline` exists
- Function `handle_match_decline` exists

**Verify:**
```sql
SELECT trigger_name FROM information_schema.triggers
WHERE event_object_table = 'matches'
AND trigger_name = 'trg_match_decline';
```

### Issue: Messages not appearing
**Check:**
- Messages table has correct structure
- Match ID is valid UUID

**Debug:**
```sql
SELECT * FROM messages WHERE match_id = '[match_id]';
```

---

## ✅ Test Summary

Total Tests: **10 scenarios**
Critical Tests: **Tests 1, 5, 6, 7** (core flow)
Optional Tests: **Tests 8, 9, 10** (edge cases)

**Minimum for Sign-Off:**
- [ ] Test 1 passes (basic request)
- [ ] Test 3 passes (validation)
- [ ] Test 5 passes (target accepts)
- [ ] Test 6 passes (both accept + meeting link)
- [ ] Test 7 passes (decline + cooldown)

**All Tests Passing:**
- [ ] All 10 test scenarios completed
- [ ] No console errors
- [ ] Database state is correct
- [ ] UI/UX is polished

---

## 📊 Test Results Template

```
Test Date: ___________
Tester: ___________

Test 1: Basic Flow          [ PASS / FAIL ]
Test 2: User Code           [ PASS / FAIL ]
Test 3: Validation          [ PASS / FAIL ]
Test 4: Error Cases         [ PASS / FAIL ]
Test 5: Target Accepts      [ PASS / FAIL ]
Test 6: Both Accept         [ PASS / FAIL ]
Test 7: Decline             [ PASS / FAIL ]
Test 8: Cooldown            [ PASS / FAIL ]
Test 9: Pending Limits      [ PASS / FAIL ]
Test 10: Active Prevention  [ PASS / FAIL ]

Notes:
_________________________________
_________________________________
_________________________________

Overall Status: [ READY FOR PRODUCTION / NEEDS FIXES ]
```

---

**Status:** Ready for Testing
**Priority:** High
**Estimated Testing Time:** 30-45 minutes

---

*Testing Guide Generated: 2025-10-20*
