# Quick Deployment Guide - Chat Rooms

**Time estimate: 30 minutes**
**Prerequisites**: Access to Vercel and Supabase dashboards

---

## 🚀 Deployment Steps (Follow in Order)

### 1️⃣ Database Setup (10 min)

**Supabase Dashboard → SQL Editor:**

```sql
-- Step 1a: Create tables
-- Copy/paste: supabase/migrations/20250121_create_chat_tables.sql
-- Click "Run"

-- Step 1b: Enable pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Step 1c: Schedule cleanup job
-- Copy/paste: supabase/migrations/20250121_setup_pg_cron.sql
-- Click "Run"

-- Step 1d: Verify
SELECT * FROM cron.job WHERE jobname = 'close-expired-chat-rooms';
-- ✅ Should show 1 row
```

---

### 2️⃣ Deploy Code (5 min)

```bash
cd /Users/Cengizhan/Desktop/meetshippermini-app

git add .
git commit -m "Replace video rooms with in-app chat (2h TTL)"
git push origin main
```

**Monitor**: https://vercel.com/dashboard (wait ~2 min for build)

---

### 3️⃣ Remove Old Env Vars (2 min)

**Vercel Dashboard → Settings → Environment Variables:**

Delete:
- ❌ `WHEREBY_API_KEY`
- ❌ `HUDDLE01_API_KEY`

Click "Save"

---

### 4️⃣ Backfill Existing Matches (5 min)

**Supabase Dashboard → SQL Editor:**

```sql
-- Create chat rooms for existing accepted matches
DO $$
DECLARE
  match_record RECORD;
  new_room_id UUID;
BEGIN
  FOR match_record IN
    SELECT m.id, m.user_a_fid, m.user_b_fid
    FROM matches m
    LEFT JOIN chat_rooms cr ON cr.match_id = m.id
    WHERE m.status = 'accepted' AND cr.id IS NULL
  LOOP
    INSERT INTO chat_rooms (match_id, opened_at)
    VALUES (match_record.id, now())
    RETURNING id INTO new_room_id;

    INSERT INTO chat_participants (room_id, fid)
    VALUES (new_room_id, match_record.user_a_fid),
           (new_room_id, match_record.user_b_fid);
  END LOOP;
END $$;

-- ✅ Verify: Check count
SELECT COUNT(*) FROM chat_rooms;
```

---

### 5️⃣ Test (5 min)

1. **Visit your app**: https://your-app.vercel.app/mini/inbox
2. **Accept a test match** (or find existing accepted match)
3. **Click "Open Chat"**
4. **Send a message**
5. **Verify timer starts**: Should show "2:00:00"

✅ **Success indicators:**
- No console errors
- "Open Chat" button visible
- Messages send/receive instantly
- Timer counts down

---

## 🔍 Quick Checks

### Database Health
```sql
-- Active rooms
SELECT COUNT(*) FROM chat_rooms WHERE is_closed = false;

-- Recent messages
SELECT COUNT(*) FROM chat_messages WHERE created_at > now() - interval '1 hour';

-- pg_cron status
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 3;
```

### Vercel Logs
- Dashboard → Logs → Filter "error"
- Should see zero chat-related errors

### Supabase Logs
- Dashboard → Logs → Filter "chat_rooms"
- Check for failed queries

---

## ⚠️ Rollback (If Needed)

**Vercel Dashboard:**
1. Go to "Deployments"
2. Find previous working deployment
3. Click "..." → "Promote to Production"
4. Re-add env vars: `WHEREBY_API_KEY`, `HUDDLE01_API_KEY`

**Time: ~3 minutes**

---

## 📞 Need Help?

- **Detailed guide**: See `MIGRATION_CHAT_ROOMS.md`
- **Implementation details**: See `IMPLEMENTATION_SUMMARY.md`
- **Troubleshooting**: See migration guide Step 8

---

## ✅ Post-Deployment Checklist

After 24 hours:
- [ ] Check Vercel error logs (should be clean)
- [ ] Verify pg_cron ran successfully (144 runs/day)
- [ ] Confirm at least one room auto-closed
- [ ] No user reports of issues
- [ ] Message delivery < 1 second

After 1 week:
- [ ] Review chat adoption rate
- [ ] Check average room duration
- [ ] Verify database size growth is acceptable
- [ ] Consider removing old meeting columns (optional)

---

**That's it! You're done. 🎉**
