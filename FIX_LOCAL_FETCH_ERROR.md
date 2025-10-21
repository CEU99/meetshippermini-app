# Fix: TypeError "fetch failed" in Local Development

## Problem Summary
After replacing video rooms with chat rooms, accessing `/users` locally throws:
```
TypeError: fetch failed
GET /api/users?page=1&limit=20 500 in 259ms
```

This error occurs because:
1. The `/users` page makes an API call to `/api/users` via `apiClient.get()`
2. The `/api/users` endpoint tries to connect to Supabase
3. Your `.env.local` has placeholder Supabase credentials
4. Next.js 15 with Turbopack fails faster on invalid env vars

---

## Root Cause

Your `.env.local` contains:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

These are **placeholder values**, not real credentials. When the API route tries to connect to Supabase, it fails with `fetch failed` because the URL is invalid.

---

## Solution: Update .env.local with Real Credentials

### Step 1: Get Your Supabase Credentials

1. Go to: https://supabase.com/dashboard
2. Select your project
3. Click: **Settings** (left sidebar) → **API**
4. Copy the following values:

   - **Project URL** (e.g., `https://abcdefghijk.supabase.co`)
   - **anon public** key (under "Project API keys")
   - **service_role** key (under "Project API keys")

### Step 2: Update Your .env.local File

Replace the placeholder values in `.env.local`:

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_ACTUAL_PROJECT_ID.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...  # Your actual anon key
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...      # Your actual service role key

# Optional configurations (keep these as-is)
NEXT_PUBLIC_RPC_URL=https://mainnet.optimism.io
JWT_SECRET=dev-jwt-secret-change-in-production

# Video API keys (no longer needed, but safe to keep)
# WHEREBY_API_KEY=
# HUDDLE01_API_KEY=
```

### Step 3: Restart Dev Server

```bash
# Stop the current dev server (Ctrl+C)
# Then restart:
npm run dev
# or
pnpm dev
```

**Important**: Next.js caches environment variables at startup, so you MUST restart the server after changing `.env.local`.

---

## Verification Steps

### 1. Test Supabase Connection

Open http://localhost:3000/api/users?page=1&limit=20 directly in your browser.

**Expected result:**
```json
{
  "users": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "totalPages": 1
  }
}
```

**If you get an error**, check:
- Supabase credentials are correct
- You have users in your database (run migrations first)
- RLS policies allow authenticated access

### 2. Test Users Page

Visit http://localhost:3000/users

**Expected result:**
- Page loads without errors
- Users list displays (if you have users in DB)
- Search bar works

### 3. Test Chat Rooms (Ensure No Regression)

1. Go to http://localhost:3000/mini/inbox
2. Accept a test match (or create one)
3. Click "Open Chat"
4. Verify: Chat page loads, can send messages

---

## Alternative Fix: Ensure Database Migrations Ran

If you have valid credentials but still get errors, you might need to run the database migrations:

### Check if tables exist:

```sql
-- Run in Supabase SQL Editor
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('users', 'matches', 'chat_rooms', 'chat_participants', 'chat_messages');
```

**Expected**: All 5 tables should be listed.

### If tables are missing:

1. **Run migrations** from the migration guide:
   - `supabase/migrations/20250121_create_chat_tables.sql`
   - Any previous migrations for users/matches tables

2. **Seed test data** (if needed):
```sql
-- Insert a test user
INSERT INTO users (fid, username, display_name, avatar_url, bio)
VALUES
  (12345, 'testuser', 'Test User', 'https://avatar.vercel.sh/testuser', 'This is a test user for local development')
ON CONFLICT (fid) DO NOTHING;
```

---

## Additional Debugging

### Check Server Logs

When you visit `/users`, check your terminal where `npm run dev` is running. Look for:

```
[API] Error fetching users: [actual error message]
```

This will tell you exactly what's failing.

### Common Error Messages and Fixes

| Error Message | Cause | Fix |
|---------------|-------|-----|
| `invalid JWT` | Wrong service role key | Copy correct key from Supabase dashboard |
| `relation "users" does not exist` | Missing migrations | Run database migrations |
| `fetch failed` | Invalid Supabase URL | Update `NEXT_PUBLIC_SUPABASE_URL` |
| `Network error` | Supabase project paused | Resume project in Supabase dashboard |
| `RLS policy violation` | Missing RLS policies | Check RLS policies in migration files |

---

## Production Comparison

**Why it works in production but not locally:**

In production (Vercel):
- Environment variables are set correctly in Vercel dashboard
- Supabase credentials are valid
- The app uses those real values

In local development:
- `.env.local` has placeholder values
- Supabase connection fails
- API routes return 500 errors

**Solution**: Match local env vars to production env vars.

---

## Security Note

**Never commit real credentials to Git!**

Your `.env.local` file is already in `.gitignore`, which is correct. Keep it that way.

If you need to share env vars with team members:
- Use a password manager (1Password, LastPass)
- Or create a `.env.example` file with placeholder values (already exists)

---

## Quick Fix Summary

```bash
# 1. Stop dev server
Ctrl+C

# 2. Edit .env.local (use real Supabase credentials)
nano .env.local

# 3. Restart dev server
npm run dev

# 4. Test
open http://localhost:3000/users
```

**That's it!** Your local dev should now work. 🎉

---

## Still Not Working?

If you've done all the above and still get errors:

1. **Check Supabase project status**: Dashboard → Project → Ensure it's not paused
2. **Check database connectivity**: Dashboard → SQL Editor → Run `SELECT 1;`
3. **Verify migrations**: Check if all tables exist (see query above)
4. **Check browser console**: Open DevTools → Console → Look for client-side errors
5. **Try cURL test**:
   ```bash
   curl http://localhost:3000/api/users?page=1&limit=20
   ```
   - If this works but browser doesn't, it's a client-side issue
   - If this fails, it's a server-side issue

---

## Contact

If you're still stuck after trying all fixes, check:
- Supabase status page: https://status.supabase.com
- Next.js GitHub issues: https://github.com/vercel/next.js/issues
- Project logs in Vercel dashboard (for production comparison)

---

**END OF FIX GUIDE**
