# Quick Guide: Meeting Completed Feature

## 🚀 Setup (3 Steps)

### 1. Run SQL Migration
```sql
-- In Supabase SQL Editor:
add-meeting-completed-feature.sql
```

### 2. Restart Server
```bash
npm run dev
```

### 3. Test
```bash
# Login as Emir
http://localhost:3000/api/dev/login?fid=543581&username=cengizhaneu

# Go to inbox → Accepted tab → Click "Meeting Completed"
http://localhost:3000/mini/inbox
```

---

## 📊 What Gets Added

| Component | What's New |
|-----------|------------|
| **Database** | `a_completed`, `b_completed` columns |
| **Trigger** | Auto-sets `status = 'completed'` when both true |
| **API** | `POST /api/matches/:id/complete` |
| **UI** | New "Completed" tab |
| **UI** | Yellow "Meeting Completed" button |

---

## 🎯 User Flow

```
1. Both users accept → status = 'accepted'
2. Meeting link generated
3. User A clicks "Meeting Completed" → a_completed = true
4. User B clicks "Meeting Completed" → b_completed = true
5. Trigger fires → status = 'completed'
6. Match moves to "Completed" tab ✅
```

---

## 🧪 Quick Test

```sql
-- In Supabase SQL Editor:
test-meeting-completed-feature.sql
```

---

## 📁 Files

**Created:**
- `app/api/matches/[id]/complete/route.ts` - API endpoint
- `add-meeting-completed-feature.sql` - Migration
- `test-meeting-completed-feature.sql` - Tests
- `MEETING-COMPLETED-FEATURE.md` - Full docs

**Modified:**
- `app/api/matches/route.ts` - Added 'completed' scope
- `app/mini/inbox/page.tsx` - Added tab + button

---

## ✅ Verification

After migration, check:

```sql
-- Should show a_completed, b_completed columns
SELECT column_name FROM information_schema.columns
WHERE table_name = 'matches'
  AND column_name LIKE '%completed%';

-- Should show trigger
SELECT trigger_name FROM information_schema.triggers
WHERE trigger_name = 'check_match_completion';
```

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| Button doesn't show | Check match is `accepted` + has `meeting_link` |
| Status not changing | Re-run migration, check trigger exists |
| Already completed error | User already marked - expected behavior |

---

## 📚 Full Documentation

See: `MEETING-COMPLETED-FEATURE.md`
