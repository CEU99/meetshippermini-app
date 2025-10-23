# ⚠️ IMPORTANT: Use MASTER_DB_SETUP_SUPABASE.sql

## Issue with Original File

The original `MASTER_DB_SETUP.sql` file contains `\echo` commands which are **psql-specific** and cause syntax errors in Supabase SQL Editor:

```
ERROR: 42601: syntax error at or near "\"
```

## ✅ Solution

Use **`MASTER_DB_SETUP_SUPABASE.sql`** instead!

This version:
- ✅ Works perfectly in Supabase SQL Editor
- ✅ Uses `RAISE NOTICE` instead of `\echo`
- ✅ Includes all the same functionality
- ✅ Has identical output and results

## Quick Reference

| File | Use For | Works In |
|------|---------|----------|
| `FIX_DECLINE_FINAL.sql` | Fix decline 500 error only | ✅ Supabase & psql |
| `MASTER_DB_SETUP_SUPABASE.sql` | Complete fresh database setup | ✅ Supabase SQL Editor |
| `MASTER_DB_SETUP.sql` | Complete fresh database setup | ✅ psql command line only |
| `test_decline_fix.sql` | Test the decline fix | ✅ Supabase & psql |

## Recommended Approach

### For Fresh Database:
```
Run: MASTER_DB_SETUP_SUPABASE.sql in Supabase SQL Editor
```

### For Existing Database (Just Fix Decline):
```
Run: FIX_DECLINE_FINAL.sql in Supabase SQL Editor
```

---

**Both approaches will fix the decline 500 error!** ✅
