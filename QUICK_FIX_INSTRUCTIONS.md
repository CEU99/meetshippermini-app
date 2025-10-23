# ⚡ Quick Fix: Decline 500 Error

## Problem
Clicking "Decline" in Inbox → Pending returns HTTP 500 error.

## Solution (2 minutes)

### Step 1: Apply Database Fix

**Via Supabase Dashboard**:
1. Go to Supabase → SQL Editor
2. Paste the contents of `FIX_DECLINE_FINAL.sql`
3. Click **Run**
4. Wait for: `✅ FIX APPLIED SUCCESSFULLY!`

**OR via command line**:
```bash
export DATABASE_URL='your_supabase_connection_string'
psql "$DATABASE_URL" -f FIX_DECLINE_FINAL.sql
```

### Step 2: Test

1. Restart app: `pnpm run dev`
2. Go to: `http://localhost:3000/mini/inbox`
3. Click **Decline** on any pending match
4. ✅ Should work without error!

## What It Fixes

- ❌ **Before**: Decline → 500 error (duplicate key violation)
- ✅ **After**: Decline → 200 success (idempotent, works every time)

## Root Cause

Database trigger `add_match_cooldown()` was trying to INSERT cooldown records without proper UPSERT logic, causing duplicate key errors when:
- Same match declined twice
- User pair already has cooldown (from different match)
- FIDs stored in reverse order

## The Fix

Creates unique index on normalized FID pairs: `LEAST(a, b), GREATEST(a, b)` and updates trigger to use proper `ON CONFLICT ... DO UPDATE`.

## Files

- **Fix SQL**: `FIX_DECLINE_FINAL.sql`
- **Test SQL**: `test_decline_fix.sql`
- **Full Guide**: `DECLINE_FIX_GUIDE.md`
- **Master Setup**: `MASTER_DB_SETUP_SUPABASE.sql` (for fresh Supabase DB)

## Need Help?

See `DECLINE_FIX_GUIDE.md` for:
- Detailed explanation
- Full SQL setup list
- Troubleshooting steps
- Testing guide

---

**Estimated Time**: 2 minutes
**Risk Level**: Low (idempotent, safe to run multiple times)
**Impact**: Fixes decline flow completely
