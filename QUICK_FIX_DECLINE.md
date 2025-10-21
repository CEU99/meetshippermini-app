# 🚀 QUICK FIX: Decline Button Not Working

## The Problem
When clicking "Decline" on a match in the inbox, you get one of these errors:
```
Failed to update match
Error: duplicate key value violates unique constraint "uniq_cooldown_pair"
```
OR
```
ApiError: Failed to update match
(No specific error message)
```

## Root Causes
1. **Cooldown duplicate key issue** - Cooldown trigger tries to INSERT duplicate
2. **Status constraint issue** - Database doesn't allow 'declined' status
3. **RLS policy issue** - Row-level security blocks the update

## The Complete Solution (5 minutes)

### Option A: Complete Fix (Recommended)

**Step 1:** Open Supabase SQL Editor
Go to: https://mpsnsxmznxvoqcslcaom.supabase.co → **SQL Editor** → **New Query**

**Step 2:** Run the complete fix
```bash
# Copy contents of fix-decline-issue-complete.sql
# Paste into SQL Editor
# Click RUN
```

This fixes:
- ✅ Status constraint (allows 'declined')
- ✅ RLS policies (permits updates)
- ✅ Permissions (grants UPDATE to authenticated)

**Step 3:** Test it (see "Step 4" below)

---

### Option B: Quick Cooldown Fix Only

If you only have the cooldown duplicate key error, use this minimal fix:

**Step 1:** Open Supabase SQL Editor
**Step 2:** Copy & Paste This Code

```sql
-- Fix for Decline Button Issue
CREATE OR REPLACE FUNCTION public.add_match_cooldown()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_min_fid BIGINT;
  v_max_fid BIGINT;
  v_existing_id UUID;
BEGIN
  IF NEW.status = 'declined' AND (OLD.status IS NULL OR OLD.status IS DISTINCT FROM 'declined') THEN
    v_min_fid := LEAST(NEW.user_a_fid, NEW.user_b_fid);
    v_max_fid := GREATEST(NEW.user_a_fid, NEW.user_b_fid);

    SELECT id INTO v_existing_id
    FROM public.match_cooldowns
    WHERE LEAST(user_a_fid, user_b_fid) = v_min_fid
      AND GREATEST(user_a_fid, user_b_fid) = v_max_fid;

    IF v_existing_id IS NOT NULL THEN
      UPDATE public.match_cooldowns
      SET declined_at = NOW(), cooldown_until = NOW() + INTERVAL '7 days'
      WHERE id = v_existing_id;
    ELSE
      INSERT INTO public.match_cooldowns (user_a_fid, user_b_fid, declined_at, cooldown_until)
      VALUES (v_min_fid, v_max_fid, NOW(), NOW() + INTERVAL '7 days');
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
```

### Step 3: Click RUN

### Step 4: Test It
1. Go to your inbox: http://localhost:3000/mini/inbox
2. Click "Decline" on any pending match
3. ✅ Should work without errors!

---

## What These Fixes Do

### Complete Fix (fix-decline-issue-complete.sql)
1. **Status Constraint** - Adds all required status values including 'declined'
2. **RLS Policies** - Creates permissive policies for authenticated users
3. **Permissions** - Grants UPDATE permission to authenticated role

### Cooldown Fix (above code)
- **Before:** Tries to INSERT duplicate cooldown → ❌ Error
- **After:** Checks if cooldown exists → UPDATE if exists, INSERT if not → ✅ Success

## 🔍 Which Fix Do I Need?

Run this test to find out:
```bash
# In Supabase SQL Editor, run:
cat scripts/test-decline-permissions.sql
```

The output will tell you:
- ✅ All checks passed → No fix needed (check backend logs)
- ⚠️ Missing status constraint → Run **fix-decline-issue-complete.sql**
- ⚠️ Duplicate key error → Run the cooldown fix above

## 📁 Files Available

**New comprehensive fix:**
- `fix-decline-issue-complete.sql` - Complete SQL fix ⭐ **USE THIS**
- `scripts/test-decline-permissions.sql` - Test current state
- `scripts/fix-decline-issue.js` - Helper script
- `FIX_DECLINE_GUIDE.md` - Detailed documentation

**Old cooldown-specific fix:**
- `fix-decline-MINIMAL.sql` - Just cooldown fix
- `fix-decline-cooldown-issue-v2.sql` - Cooldown fix + verification
- `DECLINE_FIX_INSTRUCTIONS.md` - Old documentation

## 🆘 Need Help?

**For detailed explanation:** Read `FIX_DECLINE_GUIDE.md`

**For debugging:**
1. Check browser console for JavaScript errors
2. Check server logs for: `[API] Respond: Error updating match`
3. Run test: `scripts/test-decline-permissions.sql`
4. Verify env vars: `NEXT_PUBLIC_SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`
