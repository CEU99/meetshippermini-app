# User Wallets Table - Error Fix

## Problem

Error when running `supabase-user-wallets-table.sql`:
```
ERROR: 42703: column "wallet_address" does not exist
```

## Root Cause

The original script had an issue on line 46:
```sql
GRANT USAGE ON SEQUENCE user_wallets_id_seq TO anon, authenticated, service_role;
```

This line references a sequence that doesn't exist because we're using UUID (not SERIAL) for the primary key.

## Solution

Use the fixed migration script: **`supabase-user-wallets-v2.sql`**

### Step 1: Run Diagnostic (Optional)

First, check if the table was partially created:

```sql
-- Run in Supabase SQL Editor
-- File: diagnose-user-wallets.sql
```

This will show:
- If table exists
- What columns were created (if any)
- Current indexes and constraints

### Step 2: Run Fixed Migration

```sql
-- Run in Supabase SQL Editor
-- File: supabase-user-wallets-v2.sql
```

This script will:
1. Drop existing table (if any) with CASCADE
2. Create table with correct structure
3. Create indexes
4. Enable RLS with policies
5. Grant permissions (without the problematic sequence line)
6. Verify the table structure

### Step 3: Verify Success

The script automatically verifies the table. You should see:

```
NOTICE: Creating user_wallets table...
NOTICE: ✓ Table created
NOTICE: ✓ Indexes created
NOTICE: ✓ Comments added
NOTICE: ✓ RLS enabled
NOTICE: ✓ RLS policies created
NOTICE: ✓ Permissions granted
NOTICE:
NOTICE: === Verification ===
NOTICE: Columns in user_wallets table: 6
NOTICE: ✓ All columns created successfully
```

Plus a table showing all columns:

```
column_name      | data_type                   | is_nullable | column_default
-----------------+-----------------------------+-------------+---------------------------
id               | uuid                        | NO          | uuid_generate_v4()
fid              | integer                     | NO          | NULL
wallet_address   | text                        | NO          | NULL
chain_id         | integer                     | NO          | NULL
created_at       | timestamp with time zone    | YES         | now()
updated_at       | timestamp with time zone    | YES         | now()
```

### Step 4: Test the Table

```sql
-- Test insert (should work)
INSERT INTO user_wallets (fid, wallet_address, chain_id)
VALUES (99999, '0x1234567890123456789012345678901234567890', 8453);

-- Test select
SELECT * FROM user_wallets WHERE fid = 99999;

-- Clean up test
DELETE FROM user_wallets WHERE fid = 99999;
```

## Alternative: Quick Fix Script

If you prefer a minimal fix without dropping the table:

```sql
-- fix-user-wallets-table.sql
-- Run this if table exists but has wrong structure
```

This will drop and recreate with the correct structure.

## Files

- ✅ **`supabase-user-wallets-v2.sql`** - Fixed migration (recommended)
- ⚠️ **`supabase-user-wallets-table.sql`** - Original (has bug on line 46)
- 🔍 **`diagnose-user-wallets.sql`** - Diagnostic queries
- 🔧 **`fix-user-wallets-table.sql`** - Alternative fix

## What Changed

### Before (Buggy)
```sql
-- Line 46 - WRONG: No sequence exists for UUID primary key
GRANT USAGE ON SEQUENCE user_wallets_id_seq TO anon, authenticated, service_role;
```

### After (Fixed)
```sql
-- Removed the sequence grant (not needed for UUID)
GRANT SELECT, INSERT, UPDATE, DELETE ON user_wallets TO anon, authenticated, service_role;
```

## Verification Checklist

After running the fixed script, verify:

- [ ] Table exists: `SELECT * FROM user_wallets LIMIT 0;`
- [ ] Has 6 columns: id, fid, wallet_address, chain_id, created_at, updated_at
- [ ] FID is unique: Try inserting duplicate FID (should fail)
- [ ] RLS enabled: Check policies exist
- [ ] Foreign key works: FID must exist in users table

## Expected Table Structure

```sql
CREATE TABLE user_wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fid INTEGER NOT NULL UNIQUE,
  wallet_address TEXT NOT NULL,
  chain_id INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT fk_user_wallets_fid FOREIGN KEY (fid) REFERENCES users(fid) ON DELETE CASCADE
);
```

## Testing the API

Once the table is created, test the API:

```bash
curl -X POST http://localhost:3000/api/wallets/link \
  -H "Content-Type: application/json" \
  -H "Cookie: session=YOUR_SESSION_TOKEN" \
  -d '{
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
    "chainId": 8453
  }'
```

Expected: `201 Created` with wallet data

## Troubleshooting

### Error: "table already exists"

The v2 script includes `DROP TABLE IF EXISTS`, so this shouldn't happen. If it does:

```sql
DROP TABLE user_wallets CASCADE;
-- Then re-run supabase-user-wallets-v2.sql
```

### Error: "relation users does not exist"

The foreign key requires the `users` table to exist first. Check:

```sql
SELECT table_name FROM information_schema.tables WHERE table_name = 'users';
```

If missing, you need to create the users table first.

### Error: "function uuid_generate_v4 does not exist"

Enable the extension:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

This is included in the v2 script.

---

**Status**: ✅ Fixed script ready
**Next Step**: Run `supabase-user-wallets-v2.sql` in Supabase SQL Editor
**Expected Result**: Table created successfully with all 6 columns

🔧 Problem solved!
