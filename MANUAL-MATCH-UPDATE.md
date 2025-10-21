# Manual Match Creation - Update Documentation

## 🎯 Overview

The manual match creation feature has been completely redesigned to provide a simpler, more direct matching experience. Instead of introducing two other people, users now request matches with specific individuals using their User ID (FID) or User Code.

---

## ✅ What Changed

### Previous Behavior (OLD)
- **Person A + Person B:** User selected two people from their following list to introduce
- **Optional Message:** Introduction message was optional
- **Creator Role:** User acted as a matchmaker for others
- **No Validation:** Minimal validation on message content

### New Behavior (NEW)
- **Self-Match Request:** User requests to match with ONE specific person
- **User Lookup:** Enter target user's FID or User Code directly
- **Required Message:** Introduction message is mandatory (20-100 characters)
- **Accept/Decline Flow:** Target user can accept or decline the request
- **System Messages:** Automatic notifications for acceptance/rejection
- **Cooldown Enforcement:** Respects 7-day cooldown after decline
- **Meeting Links:** Automatic meeting link generation on mutual acceptance

---

## 📋 Detailed Changes

### **Step 1: Removed Person A Field**

**Before:**
```tsx
<div className="mb-6">
  <label>Person A</label>
  <input ... /> // Search your following
</div>
```

**After:**
- Completely removed from UI
- User is automatically the requester (Person A)
- No need to select "Person A"

---

### **Step 2: Replaced Person B with User Lookup**

**Before:**
```tsx
<label>Person B</label>
<input placeholder="Search your following..." />
```

**After:**
```tsx
<label>Enter User ID (FID) or User Code</label>
<input placeholder="e.g., 12345 or ABC1234567" />
<button>Find User</button>
```

**Functionality:**
- Accepts numeric FID (e.g., `12345`)
- Accepts alphanumeric User Code (e.g., `ABC1234567`)
- Shows user profile preview with avatar, name, bio
- Validates user exists before proceeding

---

### **Step 3: Made Introduction Message Required**

**Before:**
```tsx
<label>Introduction Message (Optional)</label>
<textarea maxLength={500} />
```

**After:**
```tsx
<label>Introduction Message <span className="text-red-600">*</span></label>
<textarea
  minLength={20}
  maxLength={100}
  required
/>
<p>Required: 20-100 characters</p>
```

**Validation:**
- ✅ Minimum 20 characters
- ✅ Maximum 100 characters
- ✅ Character counter shows progress
- ✅ Visual feedback (red border if invalid, green checkmark if valid)
- ✅ Submit button disabled until valid

---

### **Step 4: Form Validation Logic**

**Validation Rules:**

1. **Target User:**
   - Must find a valid user by FID or User Code
   - Cannot match with yourself
   - User must exist in database

2. **Introduction Message:**
   - **Minimum:** 20 characters
   - **Maximum:** 100 characters
   - Cannot be empty or whitespace only

3. **Submit Button:**
   - Disabled until BOTH conditions met
   - Shows validation summary at bottom

**Visual Feedback:**
```
To send request:
✓ Find a user to match with
○ Write introduction message (20-100 chars)
```

---

### **Step 5: Matching Flow**

#### **A. Request Creation**

When user clicks "Send Match Request":

1. **Validation Checks (Backend):**
   - ✅ Target user exists
   - ✅ Not matching with self
   - ✅ Not in cooldown period (7 days after decline)
   - ✅ No active match between users
   - ✅ Requester has < 3 pending matches
   - ✅ Target user has < 3 pending matches

2. **Database Creation:**
   ```sql
   INSERT INTO matches (
     user_a_fid,        -- Requester FID
     user_b_fid,        -- Target FID
     created_by_fid,    -- Requester FID
     created_by,        -- 'user'
     status,            -- 'proposed'
     message,           -- Introduction message
     rationale,         -- { manualMatch: true, ... }
     a_accepted,        -- false
     b_accepted         -- false
   ) VALUES (...);
   ```

3. **System Message Created:**
   ```
   Match request: "[introduction message]"
   ```

---

#### **B. Target User Receives Request**

**In their Inbox:**
- See match proposal from requester
- Read introduction message
- Two options: **Accept** or **Decline**

**Acceptance Flow:**

1. Target clicks **"Accept"**
2. System updates: `b_accepted = true`
3. System message sent:
   ```
   [Target] accepted the match! Waiting for your response.
   ```
4. Both users must accept to complete match

---

#### **C. Both Users Accept**

When both `a_accepted = true` AND `b_accepted = true`:

1. **Status Update:**
   ```sql
   UPDATE matches SET status = 'accepted' WHERE id = ...;
   ```

2. **Meeting Link Generation:**
   - Calls `scheduleMatch(matchId)`
   - Generates unique meeting link (e.g., Google Meet)
   - Stores link in database

3. **System Messages Sent to BOTH Users:**

   **User A receives:**
   ```
   🎉 Match accepted! Both parties agreed to meet. Your meeting link: https://meet.google.com/abc-defg-hij
   ```

   **User B receives:**
   ```
   🎉 Match accepted! Both parties agreed to meet. Your meeting link: https://meet.google.com/abc-defg-hij
   ```

4. **Both users receive:**
   - System message in their inbox with meeting link
   - Meeting link visible in match details
   - Can start chatting
   - Same meeting link for both parties

---

#### **D. Target User Declines**

When target clicks **"Decline"**:

1. **Status Update:**
   ```sql
   UPDATE matches SET status = 'declined' WHERE id = ...;
   ```

2. **Cooldown Triggered:**
   ```sql
   INSERT INTO match_cooldowns (
     user_a_fid,
     user_b_fid,
     declined_at,
     cooldown_until  -- NOW() + INTERVAL '7 days'
   ) VALUES (...);
   ```

3. **System Messages Sent:**

   **To Decliner:**
   ```
   Match declined by [username]
   ```

   **To Requester:**
   ```
   Your match request was declined.
   ```

4. **7-Day Cooldown:**
   - Neither user can request match with each other for 7 days
   - Cooldown enforced by backend validation

---

## 🔧 Technical Implementation

### **Files Created (3)**

1. **`app/mini/create/page.tsx`** - New UI (completely rewritten)
2. **`app/api/matches/manual/route.ts`** - New API endpoint for manual matching
3. **`app/api/users/by-code/[code]/route.ts`** - User lookup by User Code

### **Files Modified (1)**

1. **`app/api/matches/[id]/respond/route.ts`** - Added system message logic

---

## 📡 API Endpoints

### **1. Create Manual Match**

**Endpoint:** `POST /api/matches/manual`

**Body:**
```json
{
  "targetFid": 12345,
  "introductionMessage": "I think we'd have a great conversation about AI!"
}
```

**Validation:**
- `targetFid` must be a valid number
- `introductionMessage` must be 20-100 characters
- Checks cooldown, active matches, pending limits

**Response (201):**
```json
{
  "match": {
    "id": "uuid",
    "user_a_fid": 11111,
    "user_b_fid": 12345,
    "status": "proposed",
    "message": "I think we'd have a great conversation about AI!",
    "created_at": "2025-10-20T12:00:00Z"
  }
}
```

**Errors:**
- `400` - Validation failed (message length, self-match, cooldown, etc.)
- `404` - Target user not found
- `500` - Server error

---

### **2. Look Up User by FID**

**Endpoint:** `GET /api/users/[fid]`

**Example:** `GET /api/users/12345`

**Response (200):**
```json
{
  "fid": 12345,
  "username": "alice",
  "display_name": "Alice",
  "avatar_url": "https://...",
  "bio": "Builder, creator, thinker",
  "user_code": "ABC1234567"
}
```

---

### **3. Look Up User by User Code**

**Endpoint:** `GET /api/users/by-code/[code]`

**Example:** `GET /api/users/by-code/ABC1234567`

**Response (200):**
```json
{
  "user": {
    "fid": 12345,
    "username": "alice",
    "display_name": "Alice",
    "avatar_url": "https://...",
    "bio": "Builder, creator, thinker",
    "user_code": "ABC1234567"
  }
}
```

**Errors:**
- `404` - User Code not found
- `400` - Invalid User Code format

---

### **4. Respond to Match**

**Endpoint:** `POST /api/matches/[id]/respond`

**Body (Accept):**
```json
{
  "response": "accept"
}
```

**Body (Decline):**
```json
{
  "response": "decline",
  "reason": "Not interested right now"  // Optional
}
```

**Response (200):**
```json
{
  "success": true,
  "match": { ... },
  "meetingLink": "https://meet.google.com/abc-defg-hij"  // If both accepted
}
```

**System Messages Created:**
- On decline: "Match declined by [username]"
- On decline (to requester): "Your match request was declined."
- On accept (partial): "[username] accepted the match! Waiting for your response."
- On accept (complete - to User A): "🎉 Match accepted! Both parties agreed to meet. Your meeting link: [link]"
- On accept (complete - to User B): "🎉 Match accepted! Both parties agreed to meet. Your meeting link: [link]"

---

## 🔐 Security & Validation

### **Backend Validation (Enforced)**

1. **Authentication:**
   - All endpoints require valid session
   - Session contains user FID

2. **Cooldown Check:**
   ```typescript
   const inCooldown = await isInCooldown(requesterFid, targetFid);
   if (inCooldown) {
     return error("7-day cooldown active");
   }
   ```

3. **Active Match Check:**
   ```typescript
   const activeMatch = await hasActiveMatch(requesterFid, targetFid);
   if (activeMatch) {
     return error("Already have active match");
   }
   ```

4. **Pending Limit Check:**
   ```typescript
   const pending = await getPendingProposalCount(requesterFid);
   if (pending >= 3) {
     return error("Max 3 pending matches");
   }
   ```

5. **Self-Match Prevention:**
   ```typescript
   if (targetFid === session.fid) {
     return error("Cannot match with yourself");
   }
   ```

---

## 🎨 User Interface

### **Form Layout**

```
┌─────────────────────────────────────┐
│  Create a Match Request             │
├─────────────────────────────────────┤
│                                     │
│  Enter User ID (FID) or User Code*  │
│  ┌───────────────────┬──────────┐  │
│  │ 12345             │ Find User│  │
│  └───────────────────┴──────────┘  │
│                                     │
│  [User Preview Card]                │
│  ┌─────────────────────────────┐   │
│  │ 👤 Alice                    │   │
│  │    @alice                   │   │
│  │    Builder, creator...      │   │
│  │                      [Change]│   │
│  └─────────────────────────────┘   │
│                                     │
│  Introduction Message*              │
│  ┌─────────────────────────────┐   │
│  │ Tell them why you'd like... │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│  Required: 20-100 characters        │
│  42/100                             │
│                                     │
│  What happens next?                 │
│  • Alice will receive your request  │
│  • They can accept or decline       │
│  • If accepted: Meeting link sent   │
│                                     │
│  ┌──────────────┬─────────┐        │
│  │ Send Request │ Cancel  │        │
│  └──────────────┴─────────┘        │
└─────────────────────────────────────┘
```

### **Validation States**

**Empty State:**
```
To send request:
○ Find a user to match with
○ Write introduction message (20-100 chars)
```

**User Found:**
```
To send request:
✓ Find a user to match with
○ Write introduction message (20-100 chars)
```

**Form Complete:**
```
To send request:
✓ Find a user to match with
✓ Write introduction message (20-100 chars)

[Send Request button enabled]
```

---

## 🧪 Testing Guide

### **Test Scenario 1: Successful Match Request**

1. **Navigate:** `http://localhost:3000/mini/create`
2. **Enter FID:** Type a valid FID (e.g., `12345`)
3. **Click:** "Find User"
4. **Verify:** User preview appears
5. **Enter Message:** Type message with 20-100 characters
6. **Verify:** Green checkmark appears, button enabled
7. **Click:** "Send Match Request"
8. **Verify:** Success message, redirect to inbox

**Expected Database State:**
```sql
SELECT * FROM matches WHERE user_a_fid = [your_fid] AND user_b_fid = 12345;
-- status = 'proposed'
-- a_accepted = false
-- b_accepted = false
-- message = [your message]
```

---

### **Test Scenario 2: User Code Lookup**

1. **Navigate:** `http://localhost:3000/mini/create`
2. **Enter User Code:** Type `ABC1234567`
3. **Click:** "Find User"
4. **Verify:** Correct user appears
5. **Complete:** Rest of flow

---

### **Test Scenario 3: Message Validation**

**Too Short:**
1. Enter: "Hi" (2 characters)
2. **Verify:** Red error: "Minimum 20 characters (2/20)"
3. **Verify:** Button disabled

**Too Long:**
1. Enter: 101 characters
2. **Verify:** Red error: "Maximum 100 characters (101/100)"
3. **Verify:** Button disabled

**Valid:**
1. Enter: "I'd love to discuss our shared interest in AI and machine learning!" (71 chars)
2. **Verify:** Green checkmark: "✓ Message looks good"
3. **Verify:** Button enabled

---

### **Test Scenario 4: Self-Match Prevention**

1. **Enter Your Own FID**
2. **Click:** "Find User"
3. **Verify:** Error: "You cannot create a match with yourself"

---

### **Test Scenario 5: Cooldown Enforcement**

**Setup:**
1. Create match with User B
2. User B declines

**Test:**
1. Try to create another match with same user
2. **Verify:** Error: "You have recently declined or cancelled a match with this user. Please wait before requesting again."

---

### **Test Scenario 6: Accept/Decline Flow**

**As Target User (User B):**

1. **Navigate:** `http://localhost:3000/mini/inbox`
2. **See:** New match proposal from User A
3. **Read:** Introduction message
4. **Click:** "Accept" or "Decline"

**If Accepted:**
- **Verify:** System message: "[Your name] accepted the match! Waiting for your response."
- **Verify:** Match status = `accepted_by_b`

**If Both Accept:**
- **Verify:** System message: "Match accepted! Your meeting link: [link]"
- **Verify:** Match status = `accepted`
- **Verify:** Meeting link appears

**If Declined:**
- **Verify:** System message: "Match declined by [your name]"
- **Verify:** System message to requester: "Your match request was declined."
- **Verify:** Match status = `declined`
- **Verify:** Cooldown created in database

---

## 📊 Database Schema

### **Matches Table**

```sql
CREATE TABLE matches (
  id UUID PRIMARY KEY,
  user_a_fid BIGINT NOT NULL,       -- Requester
  user_b_fid BIGINT NOT NULL,       -- Target
  created_by_fid BIGINT NOT NULL,   -- Always requester
  created_by TEXT,                  -- 'user' for manual
  status TEXT,                      -- 'proposed', 'accepted', 'declined'
  message TEXT,                     -- Introduction message
  rationale JSONB,                  -- { manualMatch: true, ... }
  a_accepted BOOLEAN,               -- Requester acceptance
  b_accepted BOOLEAN,               -- Target acceptance
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
);
```

### **Messages Table**

```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  match_id UUID REFERENCES matches(id),
  sender_fid BIGINT,
  content TEXT,
  is_system_message BOOLEAN,       -- true for auto-generated
  created_at TIMESTAMPTZ
);
```

### **Match Cooldowns Table**

```sql
CREATE TABLE match_cooldowns (
  id UUID PRIMARY KEY,
  user_a_fid BIGINT NOT NULL,
  user_b_fid BIGINT NOT NULL,
  declined_at TIMESTAMPTZ,
  cooldown_until TIMESTAMPTZ,      -- declined_at + 7 days
  created_at TIMESTAMPTZ
);
```

---

## 🚨 Error Handling

### **User-Facing Errors**

1. **User Not Found:**
   ```
   Error: User not found. Please check the ID or User Code and try again.
   ```

2. **Self-Match:**
   ```
   Error: You cannot create a match with yourself
   ```

3. **Cooldown Active:**
   ```
   Error: You have recently declined or cancelled a match with this user.
   Please wait before requesting again.
   ```

4. **Too Many Pending:**
   ```
   Error: You have reached the maximum of 3 pending matches.
   Please respond to your existing matches first.
   ```

5. **Active Match Exists:**
   ```
   Error: You already have an active match with this user
   ```

6. **Message Too Short:**
   ```
   Error: Introduction message must be at least 20 characters
   ```

7. **Message Too Long:**
   ```
   Error: Introduction message must be at most 100 characters
   ```

---

## 🎯 Success Criteria

✅ **User can:**
- Find users by FID or User Code
- Send match request with introduction message
- See clear validation feedback
- Receive automatic notifications on accept/decline
- Get meeting link when both accept

✅ **System enforces:**
- Message length requirements (20-100 chars)
- Cooldown periods (7 days)
- No duplicate active matches
- Pending match limits (max 3)
- No self-matching

✅ **Database maintains:**
- Match status consistency
- System message history
- Cooldown records
- Proper foreign key relationships

---

## 📝 Migration Notes

### **For Existing Users**

- Old matches created with `created_by = 'admin:[fid]'` still work
- New matches use `created_by = 'user'`
- All existing validation logic preserved
- Cooldown system applies to all matches (old and new)

### **Backwards Compatibility**

- Old API endpoint `/api/matches` still works for legacy flows
- New endpoint `/api/matches/manual` is preferred
- Both endpoints respect same validation rules

---

## 🔮 Future Enhancements

**Potential improvements:**

1. **Search by Username:**
   - Allow searching by @username in addition to FID/User Code
   - Autocomplete dropdown

2. **Match Templates:**
   - Save common introduction messages
   - Quick-fill from templates

3. **Match Preview:**
   - Show trait compatibility score before sending
   - Preview what target user will see

4. **Batch Requests:**
   - Send requests to multiple users at once
   - Rate limiting applies

5. **Scheduled Requests:**
   - Schedule request to be sent at specific time
   - Useful for different timezones

---

## 📚 Related Documentation

- [Auto-Match System](./README-AUTO-MATCH-FIX.md)
- [Matching Service](./lib/services/matching-service.ts)
- [Cooldown System](./MATCHMAKING-SYSTEM-README.md)
- [Explore Users Feature](./EXPLORE-USERS-GUIDE.md)

---

## ✅ Summary

**What was updated:**
- ✅ Removed Person A field
- ✅ Changed Person B to FID/User Code lookup
- ✅ Made introduction message required (20-100 chars)
- ✅ Added comprehensive validation
- ✅ Implemented accept/decline notifications
- ✅ Added automatic meeting link generation
- ✅ Enforced cooldown on decline

**Files created:** 4 (3 code files + 1 documentation)
**Files modified:** 1 (respond route)
**Total lines added:** ~650 lines

**Status:** ✅ **COMPLETE AND READY FOR TESTING**

---

*Generated: 2025-10-20 | Feature: Manual Match Update | Status: Complete*
