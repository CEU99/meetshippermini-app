# Quick Start - Supabase Edition

## ⚡ 3 Steps to Fix Auto-Matching

### **Step 1: Clean Data (Supabase)**

1. Open **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy & paste: `cleanup-test-matches-supabase.sql`
4. Click **RUN**

**Expected:** See "CLEANUP COMPLETE!" in logs

---

### **Step 2: Test Matching (Terminal)**

```bash
# In your project directory
./test-auto-match.sh
```

**Expected:**
```json
{
  "success": true,
  "result": {
    "matchesCreated": 1  ← Success!
  }
}
```

---

### **Step 3: Verify (Supabase)**

1. **Supabase SQL Editor** → **New Query**
2. Copy & paste: `verify-matching-works-supabase.sql`
3. Click **RUN**

**Expected:** See ✅ marks for all checks

---

## 📋 File Reference

### ✅ For Supabase SQL Editor:
- `cleanup-test-matches-supabase.sql`
- `verify-matching-works-supabase.sql`

### ✅ For Terminal (psql):
- `cleanup-test-matches.sql`
- `verify-matching-works.sql`

**Use the `-supabase` versions in Supabase!** The regular versions use `\echo` which causes syntax errors.

---

## 🎯 Quick Database Check

After Step 2, verify in Supabase SQL Editor:

```sql
-- Quick: Did it work?
SELECT id, status, created_by,
       rationale->>'score' AS score
FROM matches
WHERE status = 'proposed'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected:**
- 1 row
- `status = 'proposed'`
- `created_by = 'system'`
- Recent timestamp

---

## 🔄 To Test Again

1. Run `cleanup-test-matches-supabase.sql` (Supabase)
2. Run `./test-auto-match.sh` (Terminal)
3. Check result

---

## 🐛 Troubleshooting

### "Syntax error at or near \"

**Cause:** Using regular `.sql` file in Supabase

**Fix:** Use `-supabase.sql` version instead

### "matchesCreated: 0"

**Cause:** Old matches or cooldowns blocking

**Fix:**
1. Run cleanup script
2. Check eligibility query in cleanup script output
3. All blockers should show "OK"

### "Unauthorized" when testing

**Fix:** Code fix already includes dev login endpoint
```bash
# Login first
curl -X POST http://localhost:3000/api/dev/login \
  -d '{"fid": 11111, "username": "alice"}' \
  -c cookies.txt

# Then test
curl -X POST http://localhost:3000/api/matches/auto-run \
  -b cookies.txt
```

---

## ✅ Success Checklist

- [ ] Code fix applied (`lib/services/matching-service.ts`)
- [ ] Dev login endpoint created (`app/api/dev/login/route.ts`)
- [ ] Cleanup script run (Supabase)
- [ ] Auto-match test run (Terminal)
- [ ] Result shows `matchesCreated: 1` ✅
- [ ] Verification script confirms (Supabase)

---

**That's it! 3 steps and you're done.** 🚀

Use `-supabase.sql` files in Supabase SQL Editor to avoid syntax errors!
