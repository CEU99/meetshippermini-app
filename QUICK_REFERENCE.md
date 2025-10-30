# 🚀 Quick Reference: Realtime RLS Fix

## ⚡ 5-Minute Deployment

```bash
# 1. Apply Database Migration (1 min)
Go to: https://supabase.com/dashboard → SQL Editor
Copy: supabase/migrations/fix_realtime_rls_for_matches_and_chat.sql
Paste and Run ✅

# 2. Deploy Frontend (3 min)
git push origin main

# 3. Test (1 min)
Open 2 browser windows → Both users accept match → Both see "Open Chat"
```

---

## 📋 Verification Checklist

```sql
-- In Supabase SQL Editor:

-- ✅ Check realtime enabled
SELECT tablename FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename IN ('matches', 'chat_rooms', 'messages');
-- Expected: 3 rows

-- ✅ Check RLS policies
SELECT tablename, count(*)
FROM pg_policies
WHERE tablename IN ('matches', 'chat_rooms', 'messages')
GROUP BY tablename;
-- Expected: 3+ per table
```

---

## 🔧 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| **Migration error** | Re-run (safe, idempotent) |
| **One user stuck** | Check realtime publication |
| **No realtime events** | Restart in Dashboard → Replication |
| **RLS denied** | Verify policies active |

---

## 📊 Success Criteria

- ✅ Both users see "Open Chat" button simultaneously
- ✅ No "Loading chat room..." stuck state
- ✅ Both can enter chat room
- ✅ Messages appear in real-time

---

## 🆘 Rollback (If Needed)

```sql
-- Drop policies
DROP POLICY IF EXISTS "Both participants can view match" ON matches;
DROP POLICY IF EXISTS "Both participants can view chat room" ON chat_rooms;
DROP POLICY IF EXISTS "Both participants can view messages" ON messages;

-- Remove from publication
ALTER PUBLICATION supabase_realtime DROP TABLE matches;
ALTER PUBLICATION supabase_realtime DROP TABLE chat_rooms;
ALTER PUBLICATION supabase_realtime DROP TABLE messages;
```

---

## 📚 Full Documentation

- **Summary**: `REALTIME_FIX_SUMMARY.md`
- **Deployment**: `REALTIME_DEPLOYMENT_CHECKLIST.md`
- **Technical**: `supabase/REALTIME_RLS_FIX.md`
- **Migration**: `supabase/migrations/fix_realtime_rls_for_matches_and_chat.sql`

---

## 🎯 What Changed

### Database
- Enabled realtime on 3 tables
- Added 9 RLS policies
- Set REPLICA IDENTITY FULL

### Frontend
- Removed RLS-field dependency
- Always call `fetchMatches()` on accepted events

---

## ✅ Status

- **Build**: ✅ Passing
- **Tests**: ✅ Ready
- **Risk**: 🟢 Low
- **Downtime**: 🟢 None

---

**Ready to deploy! 🚀**
