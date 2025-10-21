# Quick Fix: Join Meeting 404 Error

## 🚀 30-Second Fix

### Problem
"Join Meeting" button → 404 error (link points to `/mini/meeting/<id>`)

### Root Cause
Meeting service was creating internal links instead of using Whereby/Huddle01 APIs

### Solution (Already Applied! ✓)
Updated `lib/services/meeting-service.ts` to use real meeting providers

---

## 🔧 Fix Existing Match (3 Options)

### Option A: API Call (Fastest)
```bash
# Get match ID from inbox, then:
curl -X POST http://localhost:3000/api/matches/<MATCH_ID>/regenerate-link
```

### Option B: SQL Script
```sql
-- In Supabase SQL Editor:
Run: fix-meeting-link.sql
```

### Option C: Re-accept
1. One user declines
2. One user accepts again
3. New link generated automatically

---

## ✅ Verification

**Check if fixed:**
```bash
# Visit inbox
http://localhost:3000/mini/inbox

# Click "Join Meeting"
# Should open:
# ✓ Whereby: https://*.whereby.com/*
# ✓ Huddle01: https://*.huddle01.com/*
# ✓ Google Meet: https://meet.google.com/new
# ❌ NOT: localhost:3000/mini/meeting/*
```

---

## 📊 What Changed

| Before | After |
|--------|-------|
| ❌ `/mini/meeting/<id>` | ✅ Whereby/Huddle01/Google Meet |
| ❌ 404 error | ✅ Opens real meeting |
| ❌ API keys ignored | ✅ API keys used |

---

## 📚 Full Documentation

See: `MEETING-LINK-FIX.md`

---

## 🆘 Still Broken?

1. Run diagnostic: `diagnose-meeting-link-issue.sql`
2. Restart dev server: `npm run dev`
3. Clear link: `fix-meeting-link.sql`
4. Regenerate via API endpoint
