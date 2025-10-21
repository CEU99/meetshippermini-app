# Fix: Suggest Match Feature - "Failed to create suggestion" Error

## Problem Summary

The "Suggest Match" feature is failing with the error: **"Failed to create suggestion"**

### Root Cause
The `match_suggestions` table **does not exist** in your Supabase database. The migration file exists in `supabase/migrations/20250122_create_match_suggestions.sql` but hasn't been run yet.

**Error Details:**
- Error Code: `PGRST205`
- Message: "Could not find the table 'public.match_suggestions' in the schema cache"

## Solution: Run the Migration

You need to run the migration SQL in your Supabase database. There are **two SQL files** to run in order:

### Step 1: Create the match_suggestions table

**File:** `temp-migration.sql` (generated) or `supabase/migrations/20250122_create_match_suggestions.sql`

This migration creates:
- `match_suggestions` table
- `match_suggestion_cooldowns` table
- RLS policies
- Helper functions for cooldown management
- Triggers for auto-updating status

### Step 2: Fix the RLS policies

**File:** `fix-match-suggestions-rls-v2.sql`

This fixes a problem where the service role policy prevents the API from inserting suggestions.

## How to Apply the Fix

### Option 1: Using Supabase Dashboard (Recommended)

1. **Open Supabase Dashboard**
   - Go to: https://mpsnsxmznxvoqcslcaom.supabase.co
   - Navigate to: **SQL Editor** → **New Query**

2. **Run Migration 1: Create Tables**
   ```bash
   # Copy the contents of temp-migration.sql
   cat temp-migration.sql
   ```
   - Paste the entire SQL into the Supabase SQL Editor
   - Click **RUN**
   - You should see success messages like:
     ```
     ✅ match_suggestions table created successfully
     ✅ match_suggestion_cooldowns table created successfully
     ```

3. **Run Migration 2: Fix RLS**
   ```bash
   # Copy the contents of fix-match-suggestions-rls-v2.sql
   cat fix-match-suggestions-rls-v2.sql
   ```
   - Paste into a new SQL query
   - Click **RUN**
   - You should see:
     ```
     ✅ Service role policy removed from match_suggestions
     ✅ Service role policy removed from match_suggestion_cooldowns
     ```

### Option 2: Using Supabase CLI (If installed)

```bash
# Install Supabase CLI (if not already installed)
npm install -g supabase

# Run the migrations
supabase db push

# Then run the RLS fix
psql "$DATABASE_URL" < fix-match-suggestions-rls-v2.sql
```

### Option 3: Using psql directly

If you have PostgreSQL client installed:

```bash
# Get your database connection string from Supabase Dashboard
# Settings → Database → Connection string

psql "your-connection-string" < temp-migration.sql
psql "your-connection-string" < fix-match-suggestions-rls-v2.sql
```

## Verify the Fix

After running both migrations, test the Suggest Match feature:

1. Go to: http://localhost:3000/mini/suggest (or your deployment URL)
2. Select two different users
3. Write a message (20-100 characters)
4. Click "Create Match Suggestion"

You should see:
- ✅ "Match suggestion created successfully!"
- Redirect to dashboard

## Technical Details

### Why This Happened

1. **Missing Table**: The migration was added to the codebase but never executed on the database
2. **RLS Policy Issue**: The migration creates a service role policy that checks JWT claims, but the API uses service role key which should bypass RLS entirely

### What the Fix Does

1. **Creates the schema**: Tables, indexes, constraints, triggers
2. **Removes problematic policies**: The service role policies are removed so that the service role key can bypass RLS (standard Supabase behavior)

### Database Schema Created

**match_suggestions table:**
- `id` - UUID primary key
- `created_by_fid` - Who suggested the match (hidden from participants)
- `user_a_fid` - First participant
- `user_b_fid` - Second participant
- `message` - Introduction message (20-100 chars)
- `status` - Current status (proposed, accepted, declined, etc.)
- `a_accepted` / `b_accepted` - Individual acceptance flags
- `chat_room_id` - Link to chat room (when both accept)
- Timestamps and constraints

**match_suggestion_cooldowns table:**
- Tracks 7-day cooldowns after declined suggestions
- Prevents spam suggestions between same users

## Files Modified

- ✅ `app/api/matches/suggestions/route.ts` - Enhanced error logging
- ✅ `temp-migration.sql` - Migration SQL (generated)
- ✅ `fix-match-suggestions-rls-v2.sql` - RLS policy fix
- ✅ `scripts/run-migration.js` - Helper script
- ✅ `scripts/fix-suggestions-rls-simple.js` - Diagnostic script

## Support

If you encounter any issues:

1. Check the Supabase Dashboard → Table Editor
   - Verify `match_suggestions` table exists
   - Verify `match_suggestion_cooldowns` table exists

2. Check SQL Editor → History
   - Review executed queries for errors

3. Check API logs:
   ```bash
   pnpm run dev
   ```
   - Try creating a suggestion
   - Look for detailed error messages in console

4. Verify environment variables:
   ```bash
   cat .env.local | grep SUPABASE
   ```
   - `NEXT_PUBLIC_SUPABASE_URL` should be set
   - `SUPABASE_SERVICE_ROLE_KEY` should be set

## Next Steps

After the fix is applied:

1. ✅ Test creating a suggestion
2. ✅ Test viewing suggestions in the inbox
3. ✅ Test accepting a suggestion
4. ✅ Test declining a suggestion
5. ✅ Verify cooldown works (7 days after decline)

---

**Status:** Ready to apply
**Priority:** High (feature is completely broken without this fix)
**Impact:** All suggest match functionality will work after applying this fix
