-- Diagnose user_wallets table issue

-- Step 1: Check if table exists
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_name = 'user_wallets';

-- Step 2: If table exists, show its columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_wallets'
ORDER BY ordinal_position;

-- Step 3: Show any indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'user_wallets';

-- Step 4: Show constraints
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'user_wallets'::regclass;
