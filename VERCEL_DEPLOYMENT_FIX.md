# 🔧 Vercel 401 Unauthorized Fix Guide

## 🎯 Root Cause

Your `/api/suggestions/external` endpoint uses **session-based authentication (JWT cookies)**, but you're sending a **Bearer token**. I've now added support for both authentication methods.

## ✅ Solution Applied

Added **dual authentication support**:
1. **Session-based auth** (existing) - for web app users with cookies
2. **API key auth** (new) - for programmatic access with Bearer tokens

## 📋 Deployment Steps

### Step 1: Add Environment Variable to Vercel

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your project: `meetshippermini-app`
3. Navigate to: **Settings → Environment Variables**
4. Click **Add New**
5. Configure:
   ```
   Name: NEYNAR_API_KEY
   Value: 139E5CB1-7FDA-4896-8FBC-B308B05E3132
   Environment: Production ✓ (IMPORTANT: Check Production)
   ```
6. Click **Save**

### Step 2: Commit and Deploy

```bash
git add .
git commit -m "feat: add API key authentication and diagnostic endpoint"
git push origin main
```

Or trigger a manual redeploy in Vercel dashboard:
- **Deployments tab → Three dots menu → Redeploy**

### Step 3: Test with Diagnostic Endpoint (NEW!)

After deployment, test the diagnostic endpoint first:

#### Option A: GET request (quick check)
```bash
curl -v https://www.meetshipper.com/api/suggestions/external/debug \
  -H "Authorization: Bearer 139E5CB1-7FDA-4896-8FBC-B308B05E3132"
```

**Expected Response (Success):**
```json
{
  "status": "healthy",
  "diagnostics": {
    "authHeaderReceived": true,
    "authHeaderFormat": "valid",
    "envKeyLoaded": true,
    "keysMatch": true,
    "issues": ["No issues detected - authentication should work!"]
  },
  "message": "✅ Authentication is configured correctly"
}
```

**Expected Response (Missing Env Variable):**
```json
{
  "status": "unhealthy",
  "diagnostics": {
    "envKeyLoaded": false,
    "issues": ["NEYNAR_API_KEY environment variable is NOT loaded in production"],
    "recommendations": [
      "Go to Vercel Dashboard → Settings → Environment Variables",
      "Add NEYNAR_API_KEY with scope set to 'Production'",
      "Redeploy after adding the environment variable"
    ]
  }
}
```

#### Option B: POST request (full auth test)
```bash
curl -v https://www.meetshipper.com/api/suggestions/external/debug \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 139E5CB1-7FDA-4896-8FBC-B308B05E3132"
```

**Expected Response (Success):**
```json
{
  "success": true,
  "message": "✅ Authentication works! The actual endpoint should work now.",
  "authenticated": true,
  "method": "API Key"
}
```

### Step 4: Test Actual Endpoint

Once the diagnostic endpoint shows "healthy", test the real endpoint:

```bash
curl -v https://www.meetshipper.com/api/suggestions/external \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 139E5CB1-7FDA-4896-8FBC-B308B05E3132" \
  -d '{
    "userAFid": 1423504,
    "userBFid": 1423060,
    "reason": "Final production test — MeetShipper.com"
  }'
```

**Expected Response (Success):**
```json
{
  "success": true,
  "suggestion": {
    "id": "uuid-here",
    "status": "pending_external",
    "created_at": "2025-10-29T...",
    "user_a": {
      "fid": 1423504,
      "username": "...",
      "display_name": "...",
      "avatar_url": "...",
      "bio": "..."
    },
    "user_b": {
      "fid": 1423060,
      "username": "...",
      "display_name": "...",
      "avatar_url": "...",
      "bio": "..."
    }
  },
  "message": "External suggestion created! Notifications sent to @user1 and @user2 on Farcaster."
}
```

## 🔍 Troubleshooting Specific Errors

### Error 1: Environment Variable Not Loaded

**Symptoms:**
```json
{
  "error": "Unauthorized - Server configuration error",
  "message": "NEYNAR_API_KEY environment variable is not configured"
}
```

**Fix:**
1. Check Vercel Dashboard → Settings → Environment Variables
2. Verify `NEYNAR_API_KEY` exists with **Production** scope
3. If missing or wrong scope, add/update it
4. **Redeploy** (environment variables only load on new deployments)

**Verify in logs:**
```
[API] 🔹 ENV KEY: None  ← BAD (env var missing)
[API] 🔹 ENV KEY: 139E5CB1-7FDA-4896...  ← GOOD
```

### Error 2: API Key Mismatch

**Symptoms:**
```json
{
  "error": "Unauthorized - Invalid API key",
  "message": "The provided API key does not match the server configuration"
}
```

**Fix:**
1. Compare the key in your cURL command with Vercel dashboard
2. Check for extra spaces or hidden characters
3. Ensure you're using the exact same key (case-sensitive)

**Verify in logs:**
```
[API] ❌ Invalid API key - key mismatch
[API]    Provided key length: 36
[API]    Expected key length: 36
```

If lengths differ, there's a formatting issue.

### Error 3: 308 Redirect Stripping Authorization

**Symptoms:**
```bash
curl -v https://www.meetshipper.com/...
< HTTP/2 308
< location: https://www.meetshipper.com/...  # redirected
```

Then you get:
```json
{
  "error": "Unauthorized",
  "message": "No valid authentication provided"
}
```

**Verify in logs:**
```
[API] 🔹 AUTH HEADER: None  ← Header was stripped by redirect
```

**Fix:**
- Use the **final URL** after any redirects
- Or in Vercel: Settings → Domains → Ensure custom domain points directly to Production (not via redirect)

### Error 4: Invalid Header Format

**Symptoms:**
```json
{
  "error": "Unauthorized - Invalid authorization format",
  "message": "Authorization header must start with 'Bearer ' (with space)"
}
```

**Fix:**
Ensure your header has the space after "Bearer":
```bash
-H "Authorization: Bearer 139E5CB1..."  # ✅ Correct (space after Bearer)
-H "Authorization: Bearer139E5CB1..."   # ❌ Wrong (no space)
-H "Authorization: 139E5CB1..."         # ❌ Wrong (missing Bearer)
```

## 📊 Vercel Logs Analysis

To view detailed logs:
1. Go to Vercel Dashboard → Deployments
2. Click on the latest deployment
3. Go to **Functions** tab
4. Find `/api/suggestions/external` in the list
5. Click to view real-time logs

**What to look for:**

✅ **Working configuration:**
```
[API] 🔹 AUTH HEADER: Bearer 139E5CB1-7FDA-489...
[API] 🔹 ENV KEY: 139E5CB1-7FDA-489...
[API] ✅ API key authentication successful
[API] Creating external match suggestion: { authMethod: 'API Key', ... }
```

❌ **Missing env variable:**
```
[API] 🔹 AUTH HEADER: Bearer 139E5CB1-7FDA-489...
[API] 🔹 ENV KEY: None
[API] ❌ NEYNAR_API_KEY environment variable is NOT loaded
```

❌ **No header received:**
```
[API] 🔹 AUTH HEADER: None
[API] ❌ No session or valid API key found
```

## 🎯 Quick Diagnosis Checklist

Run through this checklist in order:

- [ ] **Step 1:** Environment variable exists in Vercel
  - Vercel Dashboard → Settings → Environment Variables
  - `NEYNAR_API_KEY` is listed with Production scope

- [ ] **Step 2:** Code is deployed
  - Check Deployments tab shows recent deployment
  - Status: "Ready" (not "Building" or "Error")

- [ ] **Step 3:** Diagnostic endpoint passes
  ```bash
  curl https://www.meetshipper.com/api/suggestions/external/debug \
    -H "Authorization: Bearer 139E5CB1-7FDA-4896-8FBC-B308B05E3132"
  ```
  - Response: `"status": "healthy"`

- [ ] **Step 4:** No redirect occurs
  ```bash
  curl -v https://www.meetshipper.com/api/suggestions/external/debug
  ```
  - First response line should be: `< HTTP/2 200` (not 308)

- [ ] **Step 5:** Actual endpoint works
  ```bash
  curl -X POST https://www.meetshipper.com/api/suggestions/external \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer 139E5CB1-7FDA-4896-8FBC-B308B05E3132" \
    -d '{"userAFid":1423504,"userBFid":1423060,"reason":"Test"}'
  ```
  - Response: `"success": true`

## 🔐 Optional: Update System User

The API key authentication creates a pseudo-session with default values:
```typescript
fid: 1
username: 'meetshipper-bot'
```

To use your actual account, update `/app/api/suggestions/external/route.ts` lines 48-51:

```typescript
session = {
  fid: YOUR_ACTUAL_FID,        // ← Change this
  username: 'YOUR_USERNAME',    // ← Change this
  expiresAt: Date.now() + 3600000,
};
```

This will show the correct suggester in the database and logs.

## 🚀 Expected End-to-End Flow

1. **Request sent with API key** → Vercel receives request
2. **Endpoint checks authentication** → Validates Bearer token against env variable
3. **API key matches** → Creates pseudo-session
4. **Fetches users from Farcaster** → Both users retrieved via Neynar API
5. **Upserts to database** → Users added with `has_joined_meetshipper: false`
6. **Creates suggestion** → Record inserted into `match_suggestions` table
7. **Sends Farcaster notification** → Single cast mentioning both users
8. **Returns success** → JSON response with suggestion details

Both users should receive Warpcast notification within seconds.

## 📞 Need Help?

If you're still stuck after following this guide:

1. Share the output of the diagnostic endpoint
2. Share the Vercel function logs (screenshot or copy/paste)
3. Confirm the environment variable is visible in Vercel dashboard

The diagnostic information will help identify the exact issue.
