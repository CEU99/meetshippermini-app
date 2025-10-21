# Supabase Migration Plan - Complete Execution Guide

## Overview
This guide lists **all SQL files** in your project and tells you **exactly which ones to run** on Supabase, in the correct order.

---

## ✅ Required Migrations (Run These in Order)

### **Phase 1: Core Schema Setup**

#### 1. `supabase-schema.sql`
**Purpose:** Creates the base schema (users, matches, messages, user_friends tables)
**Run this:** **ONLY if starting from scratch** (fresh database)
**Skip if:** You already have users and matches tables

```sql
-- Run in: Supabase SQL Editor
-- File: supabase-schema.sql
```

**Note:** This creates the original `update_match_status()` trigger which has the bug we're fixing later.

---

### **Phase 2: User Code System**

#### 2. `supabase-user-code-complete.sql` ✅ **RECOMMENDED**
**Purpose:** Adds 10-digit unique user codes with automatic generation
**Run this:** If you want users to have shareable codes (like `1234567890`)
**What it does:**
- Adds `user_code` column (CHAR(10))
- Creates trigger to auto-generate codes
- Backfills existing users

```sql
-- Run in: Supabase SQL Editor
-- File: supabase-user-code-complete.sql
```

**Alternative:** `supabase-user-code-migration.sql` (older version, less safe)
**Alternative:** `supabase-add-unique-id.sql` (adds TEXT unique_id instead of CHAR(10) user_code)

**Recommendation:** Use `supabase-user-code-complete.sql` - it's the most robust version.

---

### **Phase 3: Profile Features**

#### 3. `supabase-add-profile-fields-v2.sql` ✅ **RECOMMENDED**
**Purpose:** Adds bio and traits fields to users table
**Run this:** To enable profile editing features
**What it does:**
- Adds `bio` column (TEXT)
- Adds `traits` column (JSONB array)
- Adds constraints (traits must have 0-10 items)
- Creates GIN index for fast queries
- **Includes PostgREST schema cache reload**

```sql
-- Run in: Supabase SQL Editor
-- File: supabase-add-profile-fields-v2.sql
```

**Alternative:** `supabase-add-profile-fields.sql` (older version, no transaction wrapper)
**Alternative:** `test-supabase-columns.sql` (minimal version, Turkish comments)

**Recommendation:** Use `supabase-add-profile-fields-v2.sql` - it has the best error handling.

---

### **Phase 4: Matchmaking System**

#### 4. `supabase-matchmaking-system.sql`
**Purpose:** Adds matchmaking features (cooldowns, auto-matching, traits similarity)
**Run this:** To enable automatic matchmaking
**What it does:**
- Updates matches table status constraint (adds 'proposed', 'accepted_by_a', etc.)
- Creates `match_cooldowns` table (7-day cooldowns)
- Creates `auto_match_runs` table (logs matchmaking runs)
- Adds helper functions (check_match_cooldown, calculate_trait_similarity, etc.)
- Creates triggers for match acceptance and cooldowns

```sql
-- Run in: Supabase SQL Editor
-- File: supabase-matchmaking-system.sql
```

**⚠️ IMPORTANT:** This file contains the buggy `update_match_status()` trigger that we fix in Phase 5!

---

### **Phase 5: Fix Match Trigger Bug** 🔧

#### 5. `supabase-fix-match-triggers.sql` ✅ **CRITICAL FIX**
**Purpose:** Fixes the status override bug (cancelled → accepted reversion)
**Run this:** **REQUIRED** if you ran `supabase-matchmaking-system.sql`
**What it does:**
- Fixes `update_match_status()` to respect manual status changes
- Updates cooldown triggers to fire correctly
- Adds unique constraint to `match_cooldowns`
- Recreates triggers in correct order

```sql
-- Run in: Supabase SQL Editor
-- File: supabase-fix-match-triggers.sql
```

**This fixes the bug you reported!** Without this, declining/cancelling matches won't work properly.

---

## 🧪 Optional: Testing & Verification

#### 6. `test-match-trigger-fix.sql` (Optional)
**Purpose:** Tests that the trigger fix works correctly
**Run this:** After running `supabase-fix-match-triggers.sql`
**What it does:**
- Creates test matches
- Tests acceptance flow
- Tests cancellation flow
- Tests decline flow
- Verifies cooldowns are created
- Cleans up test data

```sql
-- Run in: Supabase SQL Editor
-- File: test-match-trigger-fix.sql
```

---

## 🔍 Verification Scripts (Optional, Read-Only)

These scripts don't modify anything - they just check your database state:

#### `verify-profile-columns.sql`
Checks if bio and traits columns exist with correct types.

#### `verify-schema-and-permissions.sql`
Checks columns, RLS status, and policies.

#### `supabase-reload-schema-rpc.sql`
Creates a function to reload PostgREST schema cache (useful after migrations).

---

## 📋 Complete Execution Checklist

Run these files **in order** in your Supabase SQL Editor:

```
☐ 1. supabase-schema.sql                    (Only if fresh database)
☐ 2. supabase-user-code-complete.sql        (Adds user codes)
☐ 3. supabase-add-profile-fields-v2.sql     (Adds bio + traits)
☐ 4. supabase-matchmaking-system.sql        (Adds matchmaking features)
☐ 5. supabase-fix-match-triggers.sql        (CRITICAL: Fixes trigger bug)
☐ 6. test-match-trigger-fix.sql             (Optional: Verify fix works)
```

---

## 🚀 Recommended Migration Path

### **Scenario A: Starting Fresh (New Database)**

```sql
-- Run these 5 files in order:
1. supabase-schema.sql
2. supabase-user-code-complete.sql
3. supabase-add-profile-fields-v2.sql
4. supabase-matchmaking-system.sql
5. supabase-fix-match-triggers.sql
```

### **Scenario B: Existing Database (Already Have Users/Matches Tables)**

```sql
-- Run these 4 files in order:
1. supabase-user-code-complete.sql
2. supabase-add-profile-fields-v2.sql
3. supabase-matchmaking-system.sql
4. supabase-fix-match-triggers.sql
```

### **Scenario C: Already Ran Matchmaking System (Need Bug Fix Only)**

```sql
-- Run this 1 file:
1. supabase-fix-match-triggers.sql
```

---

## ⚠️ Files You Should NOT Run

These are older versions or verification-only scripts:

| File | Reason to Skip |
|------|----------------|
| `supabase-user-code-migration.sql` | Superseded by `supabase-user-code-complete.sql` |
| `supabase-add-unique-id.sql` | Different approach (TEXT instead of CHAR(10)) |
| `supabase-add-profile-fields.sql` | Superseded by `supabase-add-profile-fields-v2.sql` |
| `test-supabase-columns.sql` | Superseded by `supabase-add-profile-fields-v2.sql` |
| `verify-profile-columns.sql` | Verification only (read-only) |
| `verify-schema-and-permissions.sql` | Verification only (read-only) |

---

## 🔧 How to Run Migrations

### Method 1: Supabase Dashboard (Recommended)

1. Go to https://supabase.com/dashboard
2. Select your project
3. Click **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy the contents of the SQL file
6. Paste into the editor
7. Click **Run** (or press Cmd/Ctrl + Enter)
8. Check for success messages

### Method 2: Command Line (Advanced)

```bash
# Set your connection string
export DATABASE_URL="postgresql://postgres:[password]@[host]:[port]/postgres"

# Run migrations in order
psql $DATABASE_URL -f supabase-schema.sql
psql $DATABASE_URL -f supabase-user-code-complete.sql
psql $DATABASE_URL -f supabase-add-profile-fields-v2.sql
psql $DATABASE_URL -f supabase-matchmaking-system.sql
psql $DATABASE_URL -f supabase-fix-match-triggers.sql
```

---

## ✅ Post-Migration Verification

After running all migrations, verify everything is working:

```sql
-- 1. Check users table structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Expected columns: fid, username, display_name, avatar_url, bio,
--                   created_at, updated_at, user_code, traits

-- 2. Check matches table structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'matches'
ORDER BY ordinal_position;

-- Expected columns: id, user_a_fid, user_b_fid, created_by_fid, status,
--                   message, a_accepted, b_accepted, created_at, updated_at,
--                   created_by, rationale, meeting_link, scheduled_at, completed_at

-- 3. Check match_cooldowns table exists
SELECT COUNT(*) FROM match_cooldowns;

-- Should return 0 (or number of existing cooldowns)

-- 4. Check triggers are configured correctly
SELECT * FROM verify_trigger_fix();

-- Should show:
-- check_match_acceptance (BEFORE UPDATE) → update_match_status()
-- trg_match_decline (AFTER UPDATE) → handle_match_decline()
-- trg_match_cancel (AFTER UPDATE) → add_cooldown_on_cancel()

-- 5. Test the trigger fix
UPDATE matches
SET status = 'cancelled'
WHERE id = (SELECT id FROM matches LIMIT 1)
RETURNING status;

-- Should return 'cancelled' (not 'accepted')
```

---

## 🐛 Troubleshooting

### Issue: "relation already exists"
**Solution:** The migration is idempotent - it's safe to run multiple times. The error means it's already applied.

### Issue: "PGRST204: Could not find bio in users"
**Solution:** Run this after migrations:
```sql
SELECT reload_pgrst_schema();
```

Or run: `supabase-reload-schema-rpc.sql`

### Issue: Status still reverting to 'accepted'
**Solution:** Re-run `supabase-fix-match-triggers.sql`

### Issue: Cooldowns not being created
**Solution:** Verify triggers exist:
```sql
SELECT tgname, tgfoid::regprocedure
FROM pg_trigger
WHERE tgrelid = 'matches'::regclass
  AND tgname IN ('trg_match_decline', 'trg_match_cancel');
```

If missing, re-run `supabase-fix-match-triggers.sql`

---

## 📊 Summary Table

| File | Purpose | When to Run | Priority |
|------|---------|-------------|----------|
| `supabase-schema.sql` | Base schema | Fresh DB only | Required (once) |
| `supabase-user-code-complete.sql` | User codes | Always | Required |
| `supabase-add-profile-fields-v2.sql` | Bio + traits | Always | Required |
| `supabase-matchmaking-system.sql` | Matchmaking | Always | Required |
| `supabase-fix-match-triggers.sql` | Bug fix | Always (after matchmaking) | **CRITICAL** |
| `test-match-trigger-fix.sql` | Testing | Optional | Nice-to-have |

---

## 🎯 Quick Start (TL;DR)

**If your database already has users and matches tables:**

```sql
-- Copy and run these 4 files in Supabase SQL Editor, in order:
1. supabase-user-code-complete.sql
2. supabase-add-profile-fields-v2.sql
3. supabase-matchmaking-system.sql
4. supabase-fix-match-triggers.sql
```

**That's it!** Your database will be fully set up with the trigger bug fixed.

---

## 📞 Need Help?

- Check the `MATCH-TRIGGER-FIX-README.md` for detailed trigger fix documentation
- Run verification scripts to diagnose issues
- Check Supabase logs for error messages
- All migrations are idempotent - safe to re-run if something fails

---

**Created:** 2025-10-20
**Last Updated:** 2025-10-20
**Status:** Complete and tested
