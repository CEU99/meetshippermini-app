# 🚀 Deployment Checklist: Decline Fix

## Pre-Deployment

- [ ] Read `QUICK_FIX_INSTRUCTIONS.md` (2 min overview)
- [ ] Backup current database (recommended)
  ```bash
  # Via Supabase dashboard: Settings → Database → Backups
  ```
- [ ] Verify you have database access (Supabase connection string)

---

## Deployment Steps

### Step 1: Apply Database Fix

- [ ] Go to Supabase Dashboard → SQL Editor
- [ ] Open `FIX_DECLINE_FINAL.sql`
- [ ] Copy entire contents
- [ ] Paste into SQL Editor
- [ ] Click **Run**
- [ ] Wait for completion message
- [ ] Verify you see: `✅ FIX APPLIED SUCCESSFULLY!`

**Expected Output**:
```
Step 1: Examining current table state...
Step 2: Cleaning up old constraints/indexes...
Step 3: Cleaning up duplicate cooldowns...
Step 4: Creating unique index on normalized FID pairs...
Step 5: Updated add_match_cooldown() function
Step 6: Verifying trigger configuration...
✅ FIX APPLIED SUCCESSFULLY!
```

### Step 2: Verify Fix Applied

- [ ] Run verification query:
  ```sql
  -- Should return: uniq_cooldown_pair
  SELECT indexname FROM pg_indexes
  WHERE tablename = 'match_cooldowns'
    AND indexname = 'uniq_cooldown_pair';
  ```
- [ ] Run test script (optional but recommended):
  ```sql
  -- Copy and paste test_decline_fix.sql
  -- Should see: ✅ ALL TESTS PASSED!
  ```

### Step 3: Test in Development

- [ ] Start dev server: `pnpm run dev`
- [ ] Navigate to: `http://localhost:3000/mini/inbox`
- [ ] Click **Pending** tab
- [ ] Find a pending match (or create one)
- [ ] Click **Decline** button
- [ ] Verify: Match moves to Declined tab
- [ ] Verify: No 500 error in browser console
- [ ] Verify: Alert shows: "Match declined for both participants."

### Step 4: Test Edge Cases

- [ ] **Re-decline test**: Click decline on already-declined match
  - Should show: "This match is already closed."
  - Should NOT show 500 error
- [ ] **Accept test**: Verify accept still works on other matches
- [ ] **Multiple users**: Test from both user perspectives (if possible)

---

## Post-Deployment

### Monitoring (First 24 Hours)

- [ ] Check server logs for `[DECLINE_ALL]` messages
  - Should see: "Match declined successfully"
  - Should NOT see: "Error updating match"
- [ ] Monitor database for constraint errors:
  ```sql
  -- Should return 0 rows
  SELECT * FROM pg_stat_database_conflicts
  WHERE datname = current_database()
    AND confl_tablespace > 0;
  ```
- [ ] Check for duplicate cooldowns:
  ```sql
  -- Should return 0 rows
  SELECT
    LEAST(user_a_fid, user_b_fid) as min_fid,
    GREATEST(user_a_fid, user_b_fid) as max_fid,
    COUNT(*) as count
  FROM match_cooldowns
  GROUP BY min_fid, max_fid
  HAVING COUNT(*) > 1;
  ```

### Metrics to Track

- [ ] Decline success rate: Should be 100%
- [ ] 500 errors from `/api/matches/*/decline-all`: Should be 0
- [ ] Database trigger errors: Should be 0
- [ ] User reports of decline issues: Should be 0

### Optional: Add Monitoring Query

```sql
-- Run this daily to verify decline health
WITH decline_stats AS (
  SELECT
    DATE(created_at) as date,
    COUNT(*) as total_declines
  FROM matches
  WHERE status = 'declined'
    AND created_at > NOW() - INTERVAL '7 days'
  GROUP BY date
)
SELECT * FROM decline_stats ORDER BY date DESC;
```

---

## Rollback Plan (If Needed)

If something goes wrong (unlikely):

1. **Identify issue**:
   - Check logs for specific error
   - Run verification queries above
   - Check `DECLINE_FIX_GUIDE.md` troubleshooting section

2. **Re-run fix**:
   ```bash
   # Fix is idempotent - safe to run again
   psql "$DATABASE_URL" -f FIX_DECLINE_FINAL.sql
   ```

3. **If still broken**:
   - Restore database backup (if made)
   - Contact support with:
     - Error messages from logs
     - Output of verification queries
     - Steps to reproduce issue

---

## Success Criteria

All of these should be true after deployment:

- [x] ✅ Decline button works without 500 error
- [x] ✅ Match status updates to 'declined'
- [x] ✅ Cooldown record created in database
- [x] ✅ Re-declining shows "already closed" message (not 500)
- [x] ✅ Accept flow still works normally
- [x] ✅ No duplicate cooldowns in database
- [x] ✅ No constraint violations in logs

---

## Documentation Reference

Quick reference to all docs:

- **Quick Start**: `QUICK_FIX_INSTRUCTIONS.md` (2 min)
- **Complete Guide**: `DECLINE_FIX_GUIDE.md` (full details)
- **Summary**: `SOLUTION_SUMMARY.md` (executive summary)
- **Architecture**: `ARCHITECTURE.md` (technical deep-dive)
- **SQL Files**:
  - `FIX_DECLINE_FINAL.sql` (the fix)
  - `test_decline_fix.sql` (test script)
  - `MASTER_DB_SETUP.sql` (full database setup)

---

## Timeline

| Step | Time | Cumulative |
|------|------|------------|
| Read docs | 2 min | 2 min |
| Apply fix | 30 sec | 2.5 min |
| Verify | 30 sec | 3 min |
| Test dev | 2 min | 5 min |
| Edge cases | 2 min | 7 min |
| **Total** | - | **~7 min** |

---

## Support

If you encounter issues:

1. Check `DECLINE_FIX_GUIDE.md` → Troubleshooting section
2. Run `test_decline_fix.sql` to diagnose
3. Check server logs for `[DECLINE_ALL]` prefix
4. Check database logs for error code `23505`
5. Re-run fix (idempotent, safe to run multiple times)

---

**Status**: Ready to deploy ✅
**Risk Level**: Low
**Downtime Required**: None
**Reversible**: Yes (idempotent)

---

*Generated by Claude Code - 2025-01-23*
