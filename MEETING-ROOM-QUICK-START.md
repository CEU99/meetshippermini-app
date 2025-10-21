# 🚀 Meeting Room Auto-Close - Quick Start

## ⚡ TL;DR
Whereby meeting rooms now automatically close 2 hours after first participant joins, with live countdown in UI.

---

## 📦 What Was Built

✅ **Database migration** - New columns for room state tracking
✅ **Backend functions** - Room closure, timer, auto-close logic
✅ **Cron endpoint** - Periodic cleanup of expired rooms
✅ **Complete API update** - Immediate closure when both users complete
✅ **Inbox UI** - 2-hour rule message + live countdown timer
✅ **Documentation** - Comprehensive guide and test instructions

---

## 🎯 User Experience

### 1. Room Scheduled (Before First Join)
```
┌────────────────────────────────────────┐
│ ⏱️  Important: After someone joins    │
│    the meeting, you'll have 2 hours   │
│    before the room automatically       │
│    closes.                             │
│                                        │
│ [Join Meeting] [Meeting Completed]     │
└────────────────────────────────────────┘
```

### 2. Timer Running (After First Join)
```
┌────────────────────────────────────────┐
│ ⏳ Time remaining: 1h 23m              │
│    Room will automatically close       │
│    when time expires.                  │
│                                        │
│ [Join Meeting] [Meeting Completed]     │
└────────────────────────────────────────┘
```

### 3. Room Closed (Expired or Completed)
```
┌────────────────────────────────────────┐
│ 🔒 Meeting room closed. The 2-hour    │
│    window has expired.                 │
│                                        │
│ [Room Closed] [Meeting Completed]      │
└────────────────────────────────────────┘
```

---

## 🔧 Deployment Steps

### Step 1: Run Database Migration
```sql
-- In Supabase SQL Editor, run:
\i supabase-meeting-room-auto-close.sql

-- Or copy/paste the entire file contents
```

### Step 2: Set Environment Variables
```bash
# Add to Vercel/production environment
CRON_SECRET=your_secure_random_string_here  # Generate with: openssl rand -hex 32
WHEREBY_API_KEY=your_whereby_api_key        # Already exists
```

### Step 3: Configure Cron Job

**Option A: Vercel Cron (Recommended)**
File already created: `vercel.json`
```json
{
  "crons": [{
    "path": "/api/cron/close-expired-rooms",
    "schedule": "*/5 * * * *"
  }]
}
```
Deploy to Vercel - cron will auto-configure.

**Option B: External Service (cron-job.org)**
1. Go to https://cron-job.org/
2. Create new cron job:
   - URL: `https://yourdomain.com/api/cron/close-expired-rooms`
   - Interval: Every 5-10 minutes
   - Header: `Authorization: Bearer YOUR_CRON_SECRET`

### Step 4: Deploy and Test
```bash
# Deploy to Vercel
git add .
git commit -m "Implement meeting room auto-close system"
git push

# Wait for deployment, then test
curl -H "Authorization: Bearer YOUR_CRON_SECRET" \
  https://yourdomain.com/api/cron/close-expired-rooms
```

---

## 🧪 Quick Test

### Test Countdown UI
1. Create a match and accept it
2. Navigate to Inbox → Accepted tab
3. **Expected:** Blue box with "After someone joins, you'll have 2 hours"

### Test Manual Closure
1. Both users click "Meeting Completed"
2. **Expected:**
   - Match moves to Completed tab
   - Room state changes to 'closed'
   - Whereby room deleted

### Test Cron Endpoint
```bash
curl -X GET http://localhost:3000/api/cron/close-expired-rooms \
  -H "Authorization: Bearer YOUR_CRON_SECRET"

# Expected response:
{
  "success": true,
  "expiredCount": 0,
  "closedCount": 0,
  "errors": []
}
```

---

## 📁 Files Modified/Created

### New Files
- `supabase-meeting-room-auto-close.sql` - Database migration
- `app/api/cron/close-expired-rooms/route.ts` - Cron endpoint
- `MEETING-ROOM-AUTO-CLOSE-GUIDE.md` - Comprehensive guide
- `MEETING-ROOM-QUICK-START.md` - This file

### Modified Files
- `lib/services/meeting-service.ts` - Added 5 new functions (lines 275-519)
- `app/api/matches/[id]/complete/route.ts` - Added room closure (lines 221-233)
- `app/mini/inbox/page.tsx` - Added countdown UI (lines 47-50, 65, 79-85, 268-298, 554-623)

---

## 🔍 Verification Queries

### Check Migration Success
```sql
-- Should return 4 rows
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'matches'
  AND column_name IN ('meeting_started_at', 'meeting_expires_at', 'meeting_closed_at', 'meeting_state');
```

### Check Room States
```sql
SELECT
  meeting_state,
  COUNT(*) as count
FROM matches
WHERE meeting_link IS NOT NULL
GROUP BY meeting_state;
```

### Find Expired Rooms
```sql
SELECT * FROM get_expired_meeting_rooms();
```

---

## 🐛 Common Issues

### Issue: Countdown not showing
**Solution:** Ensure `meeting_expires_at` is set in database. This happens automatically when timer starts.

### Issue: Cron not running
**Solution:**
1. Check `CRON_SECRET` is set in environment
2. Verify cron is configured (Vercel dashboard → Cron Jobs)
3. Test manually with curl

### Issue: Room not closing
**Solution:** Check server logs for errors. Ensure `WHEREBY_API_KEY` is valid.

---

## 📊 Success Criteria

- ✅ Database migration runs without errors
- ✅ Inbox shows 2-hour rule message
- ✅ Countdown updates every second
- ✅ "Join Meeting" button disables when closed
- ✅ Both users completing closes room immediately
- ✅ Cron endpoint responds successfully
- ✅ Old rooms cleaned up retroactively

---

## 📞 Support

For detailed information, see: `MEETING-ROOM-AUTO-CLOSE-GUIDE.md`

For issues, check server logs and database state:
```bash
# Server logs
npm run dev

# Database state
SELECT id, meeting_state, meeting_started_at, meeting_expires_at, meeting_closed_at
FROM matches
WHERE meeting_link IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;
```

---

**Status:** ✅ Ready for Production
**Last Updated:** 2025-10-21
