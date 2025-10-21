# Dev Authentication System - Complete Guide

## 🎯 Overview

This guide shows you how to use the dev authentication system to test your app without Farcaster OAuth.

**What's included:**
- ✅ Cookie-based JWT sessions
- ✅ Login via browser URL or curl
- ✅ Session check endpoint
- ✅ Logout endpoint
- ✅ Visual login switcher page
- ✅ Auto-creates users in database

## 📦 Files Created

1. **`app/api/dev/login/route.ts`** - Login endpoint (GET with query params or POST with JSON)
2. **`app/api/dev/session/route.ts`** - Check current session
3. **`app/api/dev/logout/route.ts`** - Clear session cookie
4. **`app/dev/login/page.tsx`** - Visual login switcher UI
5. **`lib/auth.ts`** - Session helpers (already existed, works perfectly)

## 🚀 Quick Start

### Method 1: Browser (Easiest)

1. **Start dev server:**
   ```bash
   npm run dev
   ```

2. **Login as Alice:**
   ```
   http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951
   ```

3. **Check you're logged in:**
   ```
   http://localhost:3000/api/dev/session
   ```

   Expected response:
   ```json
   {
     "authenticated": true,
     "session": {
       "fid": 1111,
       "username": "alice",
       "displayName": "Alice",
       "userCode": "6287777951"
     }
   }
   ```

4. **Go to inbox:**
   ```
   http://localhost:3000/mini/inbox
   ```

5. **Logout:**
   ```
   http://localhost:3000/api/dev/logout
   ```

### Method 2: Visual Login Switcher

1. **Open the dev login page:**
   ```
   http://localhost:3000/dev/login
   ```

2. **Click "Login as" for Alice or Emir**

3. **Click "Go to Inbox"** to test the match acceptance flow

### Method 3: curl (For Testing Scripts)

```bash
# Login as Alice
curl "http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951"

# Check session (should show authenticated: true)
curl http://localhost:3000/api/dev/session

# Logout
curl http://localhost:3000/api/dev/logout

# Login as Emir
curl "http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu&displayName=Emir%20Cengizhan%20Ulu&userCode=7189696562"
```

## 🔍 Verification Steps

### Step 1: Verify Login Creates Session

```bash
# Login as Alice
curl -v "http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951" 2>&1 | grep -i "set-cookie"
```

**Expected output:**
```
< Set-Cookie: session=eyJhbGciOiJIUzI1NiJ9...; Path=/; HttpOnly; SameSite=Lax
```

**What to check:**
- ✅ `Set-Cookie` header present
- ✅ Cookie name is `session`
- ✅ `HttpOnly` flag set
- ✅ `Path=/`
- ✅ `SameSite=Lax`
- ✅ NO `Secure` flag (because localhost is http)

### Step 2: Verify Session Persists

```bash
# Save cookie to file
curl -c cookies.txt "http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951"

# Check session with saved cookie
curl -b cookies.txt http://localhost:3000/api/dev/session
```

**Expected output:**
```json
{
  "authenticated": true,
  "session": {
    "fid": 1111,
    "username": "alice",
    "displayName": "Alice",
    "userCode": "6287777951",
    "expiresAt": "2025-01-27T..."
  }
}
```

### Step 3: Verify User Created in Database

```sql
-- Check Alice exists
SELECT fid, username, display_name, user_code
FROM users
WHERE fid = 1111;
```

**Expected result:**
```
 fid  | username | display_name | user_code
------+----------+--------------+------------
 1111 | alice    | Alice        | 6287777951
```

### Step 4: Verify Inbox Access

With Alice logged in:

1. Go to `http://localhost:3000/mini/inbox`
2. You should see:
   - ✅ Navigation bar shows "Alice"
   - ✅ Pending matches (if any exist)
   - ✅ No redirect to login page

### Step 5: Verify Logout Clears Session

```bash
# Login
curl -c cookies.txt "http://localhost:3000/api/dev/login?fid=1111&username=alice"

# Verify logged in
curl -b cookies.txt http://localhost:3000/api/dev/session
# Should show authenticated: true

# Logout
curl -b cookies.txt -c cookies.txt http://localhost:3000/api/dev/logout

# Check session again
curl -b cookies.txt http://localhost:3000/api/dev/session
# Should show authenticated: false
```

## 🧪 Complete Test Scenario: Alice → Emir Match

### Scenario: Test manual match acceptance flow

1. **Create test match (SQL):**
   ```bash
   psql <your-connection> -f test-manual-match-alice-emir.sql
   ```

2. **Login as Emir:**
   ```
   http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu&displayName=Emir%20Cengizhan%20Ulu&userCode=7189696562
   ```

3. **Go to inbox:**
   ```
   http://localhost:3000/mini/inbox
   ```

4. **Find Alice's match request and click Accept**

5. **Expected:**
   - ✅ No error
   - ✅ Status changes to "Awaiting other party"
   - ✅ Terminal logs show: `[API] Respond: Match updated successfully`

6. **Verify in database:**
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

7. **Logout and login as Alice:**
   ```
   http://localhost:3000/api/dev/logout
   http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951
   ```

8. **Go to inbox and accept the match**

9. **Expected:**
   - ✅ Both accepted
   - ✅ Meeting link generated
   - ✅ System messages sent to both users

10. **Verify final state:**
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

## 🔧 Cookie Configuration

**Name:** `session`

**Settings (defined in `lib/auth.ts`):**
```typescript
{
  httpOnly: true,        // Cannot be accessed by JavaScript
  secure: false,         // false for localhost (no HTTPS)
  sameSite: 'lax',       // Allows navigation from external sites
  maxAge: 604800,        // 7 days in seconds
  path: '/',             // Available on all routes
}
```

**Why these settings:**
- `httpOnly: true` - Prevents XSS attacks
- `secure: false` - Required for localhost (http://)
- `sameSite: 'lax'` - Allows external navigation but blocks CSRF
- `maxAge: 604800` - 7 days = 7 * 24 * 60 * 60 seconds
- `path: '/'` - Cookie sent on all routes

## ❌ Common Issues & Solutions

### Issue 1: `authenticated: false` after login

**Symptoms:**
```json
{ "authenticated": false, "session": null }
```

**Possible causes:**

1. **JWT_SECRET not set or too short**
   ```bash
   # Check .env.local
   cat .env.local | grep JWT_SECRET
   ```

   **Fix:**
   ```bash
   # Add to .env.local (at least 32 characters)
   JWT_SECRET=your-super-secret-key-at-least-32-chars-long-12345678
   ```

2. **Route is cached (Next.js static optimization)**

   **Fix:** Already added `export const dynamic = 'force-dynamic'` to routes

3. **Cookie not being set**

   **Check browser DevTools:**
   - Open Application tab
   - Look for Cookies under localhost:3000
   - Should see `session` cookie

   **Fix:** Already using both `cookies().set()` and `response.cookies.set()`

4. **Secure flag on localhost**

   **Fix:** Already set `secure: false` for development

### Issue 2: Cookie not persisted across requests

**Symptoms:**
- Login works, but session check says not authenticated
- Cookie disappears after navigation

**Possible causes:**

1. **SameSite=Strict blocking cookie**

   **Fix:** Already using `sameSite: 'lax'`

2. **Path mismatch**

   **Fix:** Already using `path: '/'`

3. **Browser blocking third-party cookies**

   **Fix:** This shouldn't happen on localhost, but check browser settings

### Issue 3: Session expires immediately

**Symptoms:**
```json
{ "authenticated": false, "session": null }
```

**Check:**
```bash
# Login and immediately check
curl -c cookies.txt "http://localhost:3000/api/dev/login?fid=1111&username=alice"
curl -b cookies.txt http://localhost:3000/api/dev/session
```

**Possible causes:**

1. **expiresAt check is wrong**

   **Check code in `lib/auth.ts`:**
   ```typescript
   if (payload.expiresAt && (payload.expiresAt as number) < Date.now()) {
     return null; // Token expired
   }
   ```

   **This is correct** - compares milliseconds

2. **System clock wrong**

   **Check:**
   ```bash
   date
   ```

### Issue 4: Terminal says "Session created" but still not authenticated

**Symptoms:**
- See log: `[Dev Login] ✅ Session created for alice (1111)`
- But `/api/dev/session` says `authenticated: false`

**Diagnosis steps:**

1. **Check if cookie is actually set:**
   ```bash
   curl -v "http://localhost:3000/api/dev/login?fid=1111&username=alice" 2>&1 | grep -i set-cookie
   ```

   Should see `Set-Cookie` header

2. **Check if cookie is sent back:**
   ```bash
   curl -c cookies.txt "http://localhost:3000/api/dev/login?fid=1111&username=alice"
   cat cookies.txt
   ```

   Should see `session` cookie in file

3. **Check JWT_SECRET matches:**
   ```bash
   # Both should use same secret
   echo $JWT_SECRET
   grep JWT_SECRET .env.local
   ```

4. **Restart dev server:**
   ```bash
   # Stop server (Ctrl+C)
   npm run dev
   ```

   Environment variables are loaded on startup

### Issue 5: User not found in database

**Symptoms:**
- Login works but inbox is empty
- User queries return no results

**Check:**
```sql
SELECT * FROM users WHERE fid = 1111;
```

**If empty:**

The login endpoint should auto-create users, but if it failed:

```sql
INSERT INTO users (fid, username, display_name, user_code)
VALUES (1111, 'alice', 'Alice', '6287777951');
```

**Check logs for errors:**
```
[Dev Login] Failed to create user: <error>
```

## 📋 Pre-Flight Checklist

Before testing, verify:

- [ ] `.env.local` exists and contains:
  ```
  JWT_SECRET=<at-least-32-chars>
  NEXT_PUBLIC_SUPABASE_URL=https://...
  NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
  SUPABASE_SERVICE_ROLE_KEY=eyJ...
  ```

- [ ] Dev server is running:
  ```bash
  npm run dev
  ```

- [ ] Database is accessible:
  ```sql
  SELECT 1;
  ```

- [ ] Users table exists:
  ```sql
  \d users
  ```

- [ ] Matches table exists:
  ```sql
  \d matches
  ```

## 🎨 Test Users

### Alice (Test User)
- **FID:** 1111
- **Username:** alice
- **Display Name:** Alice
- **User Code:** 6287777951
- **Role:** Manual match sender

**Login URL:**
```
http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951
```

### Emir (Real User)
- **FID:** 543581
- **Username:** cengizhaneu
- **Display Name:** Emir Cengizhan Ulu
- **User Code:** 7189696562
- **Role:** Match target

**Login URL:**
```
http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu&displayName=Emir%20Cengizhan%20Ulu&userCode=7189696562
```

## 🔐 Security Notes

- ✅ Dev login is **disabled in production** (`NODE_ENV === 'production'` check)
- ✅ Cookies are `httpOnly` (cannot be stolen by XSS)
- ✅ JWT tokens are signed with `HS256`
- ✅ Sessions expire after 7 days
- ⚠️ `secure: false` for localhost - will be `true` in production

## 📊 API Reference

### POST /api/dev/login

Create session with JSON body.

**Request:**
```bash
curl -X POST http://localhost:3000/api/dev/login \
  -H "Content-Type: application/json" \
  -d '{
    "fid": 1111,
    "username": "alice",
    "displayName": "Alice",
    "userCode": "6287777951"
  }'
```

**Response:**
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
  },
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "hint": "Session cookie has been set..."
}
```

### GET /api/dev/login

**With params:** Create session
**Without params:** Check session

**Create session:**
```bash
curl "http://localhost:3000/api/dev/login?fid=1111&username=alice&displayName=Alice&userCode=6287777951"
```

**Check session:**
```bash
curl http://localhost:3000/api/dev/login
```

### GET /api/dev/session

Check current session status.

**Request:**
```bash
curl http://localhost:3000/api/dev/session
```

**Response (authenticated):**
```json
{
  "authenticated": true,
  "session": {
    "fid": 1111,
    "username": "alice",
    "displayName": "Alice",
    "userCode": "6287777951",
    "expiresAt": "2025-01-27T12:00:00.000Z"
  }
}
```

**Response (not authenticated):**
```json
{
  "authenticated": false,
  "session": null,
  "hint": "No active session. Login at /api/dev/login"
}
```

### GET /api/dev/logout

Clear session cookie.

**Request:**
```bash
curl http://localhost:3000/api/dev/logout
```

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully",
  "hint": "Session cookie has been cleared"
}
```

## 🎯 Success Criteria

After following this guide, you should be able to:

- [x] Login as Alice via browser URL
- [x] See `authenticated: true` at `/api/dev/session`
- [x] Access `/mini/inbox` without redirect
- [x] Accept manual match from Alice to Emir
- [x] Switch to Emir and accept the match
- [x] See meeting link generated
- [x] Logout and confirm session cleared

## 📞 Still Having Issues?

If you're still seeing `authenticated: false`:

1. **Check terminal logs** for errors:
   ```
   [Dev Login] Error: ...
   ```

2. **Verify JWT_SECRET:**
   ```bash
   echo $JWT_SECRET
   grep JWT_SECRET .env.local
   ```

3. **Restart dev server** (env vars loaded on startup):
   ```bash
   npm run dev
   ```

4. **Check browser cookies** (DevTools → Application → Cookies)

5. **Try curl with verbose:**
   ```bash
   curl -v "http://localhost:3000/api/dev/login?fid=1111&username=alice"
   ```

   Look for `Set-Cookie` in response headers

6. **Check database connection:**
   ```sql
   SELECT 1;
   ```

If none of this works, check the detailed logs in the terminal - the enhanced logging will show exactly what's failing.
