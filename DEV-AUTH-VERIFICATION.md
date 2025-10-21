# Dev Auth Verification Guide

## 🎯 What Was Fixed

**Problem:** `/mini/inbox` redirected to home even with valid dev session cookie.

**Root Cause:** `FarcasterAuthProvider` (client-side) only checked Farcaster OAuth, ignored dev session cookie.

**Solution:** Patched `FarcasterAuthProvider` to check dev session cookie FIRST, fall back to Farcaster.

---

## 📦 Files Changed

### 1. **`lib/dev-auth.ts`** (NEW)
- Server-side JWT verification utilities
- `verifyDevSession(token)` - Verify JWT token
- `getDevSessionFromCookie(value)` - Main function for guards
- `isDevAuthEnabled()` - Check if dev mode

### 2. **`components/providers/FarcasterAuthProvider.tsx`** (PATCHED)

**Changes:**
```typescript
// Added getCookie() helper to read cookies client-side

// Modified useEffect() to:
// 1. Check for dev session cookie FIRST (in development)
// 2. Call /api/dev/session to verify it
// 3. If valid, set user and skip Farcaster check
// 4. If not valid, fall back to Farcaster auth
```

**Priority order:**
1. Dev session cookie (dev mode only)
2. Farcaster OAuth (always available)

### 3. **`bootstrap-dev-users.sql`** (NEW)
- Creates/updates Alice and Emir with bio + 7 traits
- Ensures users are match-eligible
- Safe to run multiple times (uses UPSERT)

---

## ✅ Verification Steps

### Step 1: Bootstrap Test Users

```bash
# Ensure test users have bio and traits
psql <your-connection-string> -f bootstrap-dev-users.sql
```

**Expected output:**
```
✅ DEV USERS BOOTSTRAPPED SUCCESSFULLY!
Users created/updated:
  • Alice (FID 1111) - Test user
  • Emir (FID 543581) - Real user
```

**Verify in DB:**
```sql
SELECT fid, username, bio, jsonb_array_length(traits) as trait_count
FROM users
WHERE fid IN (1111, 543581);
```

Expected:
```
 fid    | username     | bio                              | trait_count
--------+--------------+----------------------------------+-------------
 1111   | alice        | Test user for manual matching... | 7
 543581 | cengizhaneu  | Builder and entrepreneur...      | 7
```

### Step 2: Clear Cookies and Restart Server

```bash
# Clear browser cookies (DevTools → Application → Cookies → Clear All)

# Restart dev server to load new code
npm run dev
```

### Step 3: Login as Alice

**Browser:**
```
http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951
```

**Expected response:**
```json
{
  "success": true,
  "authenticated": true,
  "message": "Logged in as alice",
  "session": {
    "fid": 1111,
    "username": "alice",
    "displayName": "Alice",
    "userCode": "6287777951"
  }
}
```

**curl:**
```bash
curl "http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951"
```

### Step 4: Verify Session

**Browser:**
```
http://localhost:3000/api/dev/session
```

**Expected:**
```json
{
  "authenticated": true,
  "session": {
    "fid": 1111,
    "username": "alice",
    "displayName": "Alice",
    "userCode": "6287777951",
    "expiresAt": "2025-01-..."
  }
}
```

**curl:**
```bash
curl -c cookies.txt "http://localhost:3000/api/dev/login?fid=1111&username=alice"
curl -b cookies.txt http://localhost:3000/api/dev/session
```

### Step 5: Visit Inbox (KEY TEST)

**Browser:**
```
http://localhost:3000/mini/inbox
```

**Expected behavior:**
✅ Page loads (NO redirect)
✅ Shows "Alice" in navigation
✅ Shows pending matches (if any exist)
✅ Console logs: `[Auth] ✅ Using dev session: alice`

**NOT expected:**
❌ Redirect to `/`
❌ Farcaster login prompt
❌ "Unauthorized" error

### Step 6: Accept Match (Full Flow Test)

**Prerequisites:**
```bash
# Create test match if it doesn't exist
psql <conn> -f test-manual-match-alice-emir.sql
```

**As Emir:**

1. Login:
   ```
   http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu&displayName=Emir%20Cengizhan%20Ulu&userCode=7189696562
   ```

2. Go to inbox:
   ```
   http://localhost:3000/mini/inbox
   ```

3. Find Alice's match request and click **Accept**

4. **Expected:**
   - ✅ No error
   - ✅ Status changes to "Awaiting other party"
   - ✅ Console: `[API] Respond: Match updated successfully`
   - ✅ Match moves to "Awaiting" tab

5. Verify in DB:
   ```sql
   SELECT status, a_accepted, b_accepted
   FROM matches
   WHERE user_a_fid = 1111 AND user_b_fid = 543581;
   ```

   Expected:
   ```
   status: 'accepted_by_b'
   a_accepted: false
   b_accepted: true  ✅
   ```

**As Alice:**

6. Logout:
   ```
   http://localhost:3000/api/dev/logout
   ```

7. Login as Alice:
   ```
   http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951
   ```

8. Go to inbox and click **Accept**

9. **Expected:**
   - ✅ Both accepted
   - ✅ Meeting link generated
   - ✅ System messages sent to both users
   - ✅ Match in "Accepted" tab

10. Verify final state:
    ```sql
    SELECT status, a_accepted, b_accepted, meeting_link IS NOT NULL as has_link
    FROM matches
    WHERE user_a_fid = 1111 AND user_b_fid = 543581;
    ```

    Expected:
    ```
    status: 'accepted'
    a_accepted: true
    b_accepted: true
    has_link: true  ✅
    ```

### Step 7: Logout and Verify Session Cleared

**Browser:**
```
http://localhost:3000/api/dev/logout
```

**Expected:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

**Check session:**
```
http://localhost:3000/api/dev/session
```

**Expected:**
```json
{
  "authenticated": false,
  "session": null
}
```

---

## 🔍 Browser Console Verification

Open browser DevTools console when visiting `/mini/inbox`:

**With valid dev session:**
```
[Auth] ✅ Using dev session: alice
```

**Without dev session (Farcaster fallback):**
```
[Auth] Dev session check failed, falling back to Farcaster
```

---

## 🐛 Troubleshooting

### Issue 1: Still redirecting to home

**Check:**
1. Server restarted after code changes?
   ```bash
   npm run dev
   ```

2. Browser cookies cleared?
   - DevTools → Application → Cookies → Clear All
   - Reload page

3. Dev session cookie present?
   - DevTools → Application → Cookies
   - Should see `session` cookie

4. Console logs?
   - Should see `[Auth] ✅ Using dev session: alice`
   - If you see "Dev session check failed", check logs for why

### Issue 2: Dev session not recognized

**Check API response:**
```bash
curl http://localhost:3000/api/dev/session
```

**If `authenticated: false`:**
- JWT_SECRET not set or changed
- Token expired
- Cookie not being sent

**Fix:**
```bash
# Check .env.local
cat .env.local | grep JWT_SECRET

# Restart server
npm run dev

# Login again
http://localhost:3000/api/dev/login?fid=1111&username=alice
```

### Issue 3: User not in database

**Symptoms:**
- Login works but inbox is empty
- API errors about missing user

**Fix:**
```bash
# Run bootstrap script
psql <conn> -f bootstrap-dev-users.sql

# Or manually:
psql <conn> -c "SELECT * FROM users WHERE fid = 1111;"
```

### Issue 4: Match doesn't exist

**Check:**
```sql
SELECT * FROM matches
WHERE (user_a_fid = 1111 AND user_b_fid = 543581)
   OR (user_a_fid = 543581 AND user_b_fid = 1111);
```

**Create test match:**
```bash
psql <conn> -f test-manual-match-alice-emir.sql
```

---

## 📋 Complete Test Checklist

- [ ] Bootstrap script run successfully
- [ ] Users in database with bio and traits
- [ ] Server restarted
- [ ] Browser cookies cleared
- [ ] Login as Alice → `authenticated: true`
- [ ] Session check → `authenticated: true`
- [ ] Visit `/mini/inbox` → NO redirect
- [ ] Console shows: `[Auth] ✅ Using dev session: alice`
- [ ] Navigation shows "Alice"
- [ ] Pending match visible
- [ ] Switch to Emir and accept → status changes
- [ ] Switch back to Alice and accept → meeting link generated
- [ ] Logout → `authenticated: false`

---

## 🎯 Success Criteria

All of the following must work:

1. ✅ Login via `/api/dev/login?fid=...` sets cookie
2. ✅ `/api/dev/session` shows `authenticated: true`
3. ✅ `/mini/inbox` loads without redirect
4. ✅ Can accept matches as different users
5. ✅ Match status transitions correctly
6. ✅ Meeting link generated on both accept
7. ✅ Logout clears session

---

## 📝 Quick Test Script

```bash
#!/bin/bash
# Complete verification in one script

echo "1. Bootstrap users..."
psql <conn> -f bootstrap-dev-users.sql

echo "2. Login as Alice..."
curl "http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951"

echo "3. Check session..."
curl http://localhost:3000/api/dev/session

echo "4. Visit inbox in browser:"
echo "http://localhost:3000/mini/inbox"
echo ""
echo "Expected: Page loads as Alice, no redirect"
```

---

## 🔐 Security Notes

- ✅ Dev auth only works in `NODE_ENV=development`
- ✅ All dev endpoints check `process.env.NODE_ENV`
- ✅ Production deploys automatically disable dev routes
- ✅ Dev sessions verified with same JWT_SECRET
- ✅ Cookies are httpOnly (XSS protection)

---

## 📚 Related Files

- `lib/dev-auth.ts` - Server-side verification
- `components/providers/FarcasterAuthProvider.tsx` - Client-side guard
- `app/api/dev/login/route.ts` - Login endpoint
- `app/api/dev/session/route.ts` - Session check
- `app/api/dev/logout/route.ts` - Logout
- `bootstrap-dev-users.sql` - User setup
- `test-manual-match-alice-emir.sql` - Test match

---

## 💡 How It Works

```
User visits /mini/inbox
    ↓
FarcasterAuthProvider checks:
    1. Dev session cookie exists? → Call /api/dev/session
       ✅ Valid? → Set user, skip Farcaster
       ❌ Invalid? → Continue to step 2
    2. Farcaster OAuth authenticated?
       ✅ Yes → Use Farcaster session
       ❌ No → Redirect to home
```

**Key insight:** Dev session checked FIRST, Farcaster is fallback.

---

## 🎉 Summary

After applying these patches:

- [x] Dev login sets JWT cookie
- [x] Client-side auth provider checks dev cookie first
- [x] `/mini/inbox` accepts dev sessions (no redirect)
- [x] Full match flow works with dev identities
- [x] Logout clears session properly
- [x] Falls back to Farcaster if no dev session

**Everything should now work!** 🚀
