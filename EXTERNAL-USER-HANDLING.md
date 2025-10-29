# External Farcaster User Handling System

## Overview

This document explains how MeetShipper handles external Farcaster users (users who exist on Farcaster but have never logged into MeetShipper).

## Problem Statement

**Before Fix:**
- Every Farcaster user was upserted into the `users` table without tracking whether they had actually joined MeetShipper
- Users who had never logged in were incorrectly treated as "internal users"
- Farcaster notifications were not sent to these users
- Database bloated with thousands of unused user entries

**After Fix:**
- Users are marked with `has_joined_meetshipper` flag
- External-only users receive Farcaster notifications
- Database accurately reflects who has actually used the app
- Clean separation between app users and imported profiles

## Solution Architecture

### Database Schema

Added `has_joined_meetshipper` column to `users` table:

```sql
ALTER TABLE public.users
ADD COLUMN has_joined_meetshipper BOOLEAN NOT NULL DEFAULT true;
```

**Values:**
- `true` - User has logged into MeetShipper (authenticated via Privy + Farcaster)
- `false` - User exists only as minimal record for foreign key integrity (never logged in)

### User States

```
┌────────────────────────────────────────────────────────────┐
│                      User States                            │
└────────────────────────────────────────────────────────────┘

1. INTERNAL USER (has_joined_meetshipper = true)
   ├─ Has logged into MeetShipper
   ├─ Full profile in database
   ├─ Can receive in-app notifications
   └─ No Farcaster cast notifications needed

2. EXTERNAL USER (has_joined_meetshipper = false)
   ├─ Never logged into MeetShipper
   ├─ Minimal record in database (for foreign keys)
   ├─ Receives Farcaster cast notifications
   └─ Can later become internal user by logging in

3. UNKNOWN USER (not in database at all)
   ├─ Fetched from Farcaster via Neynar
   ├─ Minimal record created with has_joined_meetshipper = false
   ├─ Treated same as External User
   └─ Receives Farcaster cast notifications
```

## Implementation Details

### 1. User Login Flow (`/app/api/auth/session/route.ts`)

When user authenticates via Privy + Farcaster:

```typescript
await supabase.from('users').upsert({
  fid,
  username,
  display_name: displayName,
  avatar_url: pfpUrl,
  bio: bio,
  has_joined_meetshipper: true, // ✅ Mark as joined
  updated_at: new Date().toISOString(),
});
```

**Result:** User is marked as having joined MeetShipper

### 2. Match Creation Flow (`/app/api/matches/manual/route.ts`)

#### Step 1: Lookup Target User

```typescript
const { data: targetUser } = await supabase
  .from('users')
  .select('fid, username, display_name, avatar_url, bio, has_joined_meetshipper')
  .eq('fid', targetFid)
  .single();
```

#### Step 2: Determine External Status

```typescript
if (targetUser && !targetUser.has_joined_meetshipper) {
  // User exists but hasn't joined - treat as external
  isExternalUser = true;
  externalUserData = {
    fid: targetUser.fid,
    username: targetUser.username,
    display_name: targetUser.display_name,
    avatar_url: targetUser.avatar_url,
    bio: targetUser.bio,
  };
}
```

#### Step 3: Fetch from Farcaster (if not in DB)

```typescript
if ((userError || !targetUser) && !isExternalUser) {
  // Fetch from Neynar
  const farcasterUser = await neynarAPI.getUserByFid(targetFid);

  // Create minimal record
  await supabase.from('users').upsert({
    fid: farcasterUser.fid,
    username: farcasterUser.username,
    display_name: farcasterUser.display_name,
    avatar_url: farcasterUser.pfp_url,
    bio: farcasterUser.profile?.bio?.text,
    has_joined_meetshipper: false, // ✅ Mark as external-only
  });

  isExternalUser = true;
}
```

#### Step 4: Send Notifications (if external)

```typescript
if (isExternalUser && externalUserData) {
  await sendMatchRequestNotification(
    externalUserData,
    match.id,
    session.signerUuid
  );
}
```

### 3. Notification Logic

**Internal Users (has_joined_meetshipper = true):**
- No Farcaster cast sent
- In-app notification only
- User sees match in their inbox

**External Users (has_joined_meetshipper = false):**
- Farcaster cast sent via Neynar
- Includes join link for MeetShipper
- If they join, `has_joined_meetshipper` updated to `true`

## User Journey Examples

### Example 1: New External User

```
1. Alice (MeetShipper user) sends match to Bob (FID: 12345)
2. Bob is not in users table
3. System fetches Bob from Farcaster via Neynar
4. Minimal record created: has_joined_meetshipper = false
5. Match created with status: 'pending_external'
6. Farcaster cast sent to Bob
7. Bob receives notification on Farcaster
```

### Example 2: External User Joins Later

```
1. Bob clicks MeetShipper link from Farcaster
2. Bob authenticates via Privy
3. Session created: has_joined_meetshipper = true
4. Bob is now an internal user
5. Future matches to Bob: no Farcaster cast needed
6. Bob sees matches in-app
```

### Example 3: Existing External User

```
1. Alice sent match to Charlie last week
2. Charlie exists with has_joined_meetshipper = false
3. Alice sends another match to Charlie
4. System checks DB, finds Charlie
5. Sees has_joined_meetshipper = false
6. Treats as external user
7. Sends Farcaster notification again
```

## Benefits

✅ **Accurate User Tracking**
- Know exactly who has used the app
- Differentiate between app users and external profiles

✅ **Correct Notification Routing**
- External users get Farcaster notifications
- Internal users get in-app notifications only

✅ **Database Integrity**
- Foreign key constraints satisfied
- Minimal records for external users
- Full profiles for internal users

✅ **Scalability**
- No unnecessary data storage
- Clean user model
- Easy to query and filter

✅ **User Experience**
- External users receive notifications via Farcaster
- Clear onboarding path when they join
- Seamless transition from external to internal

## Testing

### Test Case 1: External User Never Seen Before

**Steps:**
1. Use a Farcaster account that has never logged into MeetShipper
2. Send a match request to this user from authenticated account
3. Verify:
   - ✅ Minimal record created with `has_joined_meetshipper = false`
   - ✅ Match created with status `pending_external`
   - ✅ Farcaster cast sent
   - ✅ No in-app notification

**Expected Logs:**
```
[API] User not in database, fetching from Farcaster: 12345
[API] External Farcaster user found: alice
[API] 💾 Creating minimal record for external user...
[API] ✅ External user record created (has_joined_meetshipper = false)
[API] Sending Farcaster notification to external user...
[API] ✅ Notification sent successfully
```

### Test Case 2: External User Already in DB

**Steps:**
1. Use an account with `has_joined_meetshipper = false` in DB
2. Send match request to this user
3. Verify:
   - ✅ User fetched from DB
   - ✅ Treated as external (isExternalUser = true)
   - ✅ Farcaster notification sent
   - ✅ No duplicate DB record

**Expected Logs:**
```
[API] ✅ Target user found in database: bob
[API] Has joined MeetShipper: false
[API] User exists in DB but has not joined MeetShipper - treating as external
[API] Sending Farcaster notification to external user...
```

### Test Case 3: External User Joins MeetShipper

**Steps:**
1. External user (has_joined_meetshipper = false) clicks link
2. User authenticates via Privy
3. Verify:
   - ✅ `has_joined_meetshipper` updated to `true`
   - ✅ Full profile updated with auth data
   - ✅ User now appears as internal

**Expected Logs:**
```
[Auth] ✅ User authenticated: bob
[Database] Upsert user with has_joined_meetshipper = true
```

### Test Case 4: Internal User Match

**Steps:**
1. Send match to user with `has_joined_meetshipper = true`
2. Verify:
   - ✅ isExternalUser = false
   - ✅ No Farcaster cast sent
   - ✅ Match status `proposed` (not `pending_external`)
   - ✅ In-app notification only

**Expected Logs:**
```
[API] ✅ Target user found in database: charlie
[API] Has joined MeetShipper: true
[API] 💾 Creating match in database...
[API] Match status: proposed
(No Farcaster notification logs)
```

## Monitoring & Analytics

### Queries for Monitoring

**Count Internal vs External Users:**
```sql
SELECT
  has_joined_meetshipper,
  COUNT(*) as user_count
FROM users
GROUP BY has_joined_meetshipper;
```

**Find External Users with Matches:**
```sql
SELECT
  u.fid,
  u.username,
  COUNT(m.id) as match_count
FROM users u
LEFT JOIN matches m ON (u.fid = m.user_b_fid)
WHERE u.has_joined_meetshipper = false
GROUP BY u.fid, u.username
ORDER BY match_count DESC;
```

**External → Internal Conversion Rate:**
```sql
-- Find users who started as external and later joined
SELECT COUNT(*) FROM users
WHERE has_joined_meetshipper = true
AND updated_at > created_at + INTERVAL '1 day';
```

## Migration Guide

If you have existing users in the database before this update:

**Option 1: Mark all as internal (safest)**
```sql
UPDATE users
SET has_joined_meetshipper = true;
```

**Option 2: Identify external users by login activity**
```sql
-- Mark users without sessions as external
UPDATE users
SET has_joined_meetshipper = false
WHERE last_login_at IS NULL;
```

## Future Enhancements

### Potential Improvements

1. **Welcome Flow for Converting Users**
   - Special onboarding for external users joining
   - Show pending match requests on first login

2. **Analytics Dashboard**
   - Track external user conversion rate
   - Monitor Farcaster notification success rate

3. **Bulk Migration Tools**
   - Import Farcaster users in bulk
   - Pre-populate with has_joined_meetshipper = false

4. **Notification Preferences**
   - Let users choose notification method
   - Email, Farcaster, or in-app

## Troubleshooting

### Issue: External user not receiving notifications

**Check:**
1. Verify `has_joined_meetshipper = false` in database
2. Check `isExternalUser = true` in server logs
3. Verify Neynar signer configured (`NEYNAR_SIGNER_UUID`)
4. Check Farcaster API rate limits

**Debug Query:**
```sql
SELECT fid, username, has_joined_meetshipper
FROM users
WHERE fid = <target_fid>;
```

### Issue: User marked as external after logging in

**Fix:**
```sql
UPDATE users
SET has_joined_meetshipper = true
WHERE fid = <user_fid>;
```

### Issue: Foreign key constraint violation

**Cause:** Trying to create match without user record

**Fix:** System should auto-create minimal record. If not:
```sql
INSERT INTO users (fid, username, has_joined_meetshipper)
VALUES (<fid>, '<username>', false);
```

## References

**Related Files:**
- `supabase/migrations/add-has-joined-meetshipper.sql` - Database migration
- `app/api/auth/session/route.ts` - User login (sets true)
- `app/api/matches/manual/route.ts` - Match creation logic
- `lib/services/farcaster-notification-service.ts` - Notifications

**Related Documentation:**
- `DELEGATED-SIGNER-SYSTEM.md` - Farcaster messaging setup

---

**Last Updated:** 2025-10-29
**Version:** 1.0.0
**Status:** ✅ Production Ready
