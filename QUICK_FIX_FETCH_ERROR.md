# Quick Fix: "fetch failed" Error on /users Page

## 🔍 Problem Identified

Your `.env.local` file has **placeholder values** instead of real Supabase credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co  ❌
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here              ❌
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here          ❌
```

This causes the API to fail when trying to connect to Supabase.

---

## ✅ Solution (5 minutes)

### Step 1: Get Your Supabase Credentials

1. Go to: **https://supabase.com/dashboard**
2. Click on your project
3. Go to: **Settings** → **API** (left sidebar)
4. You'll see these values:

   ```
   Project URL:          https://[your-id].supabase.co
   Project API keys:
     - anon public:      eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
     - service_role:     eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

### Step 2: Update .env.local

Replace the placeholder values in `/Users/Cengizhan/Desktop/meetshippermini-app/.env.local`:

```env
# Replace with your actual values from Supabase dashboard
NEXT_PUBLIC_SUPABASE_URL=https://[paste-your-project-id].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.[paste-anon-key]
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.[paste-service-key]

# Keep these as-is:
NEXT_PUBLIC_RPC_URL=https://mainnet.optimism.io
JWT_SECRET=dev-jwt-secret-change-in-production
```

### Step 3: Restart Dev Server

**IMPORTANT**: You MUST restart for env vars to take effect!

```bash
# In your terminal, press Ctrl+C to stop the server
# Then restart:
npm run dev
```

### Step 4: Test

Visit: http://localhost:3000/users

**Expected**: Users page loads without errors ✅

---

## 🧪 Verify Your Fix

Run the diagnostic script:

```bash
node scripts/diagnose-env.js
```

**Expected output:**
```
✅ ALL CHECKS PASSED - Environment looks good!
```

---

## 🚨 Still Not Working?

### Check 1: Did you restart the dev server?
```bash
# Stop (Ctrl+C) and restart:
npm run dev
```

### Check 2: Are migrations applied?

Visit Supabase dashboard → SQL Editor and run:
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public';
```

**Expected tables:**
- users
- matches
- chat_rooms
- chat_participants
- chat_messages

**If missing**, run the migrations from:
- `supabase/migrations/20250121_create_chat_tables.sql`
- Any other migration files

### Check 3: Test API directly

Visit http://localhost:3000/api/users?page=1&limit=20 in your browser.

**Expected**: JSON response with users array

**If you get an error**, check the terminal logs for the exact error message.

---

## 📖 More Details

See `FIX_LOCAL_FETCH_ERROR.md` for comprehensive troubleshooting.

---

## ✅ Chat Rooms Unaffected

This fix only addresses the Supabase connection issue. Your new chat room functionality is intact - no changes were made to the chat system.

After fixing this, both will work:
- ✅ `/users` page (user browsing)
- ✅ `/mini/chat/[roomId]` (chat rooms with 2h TTL)

---

**That's it! Your local dev should work now.** 🎉
