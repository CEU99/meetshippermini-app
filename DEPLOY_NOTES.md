# 🚀 Suggest Match Feature - Quick Deploy Guide

## ✅ What Was Done

This commit adds the complete "Suggest Match" feature. All code is ready to deploy!

### Files Changed:
- `app/dashboard/page.tsx` - Added "Suggest Match" button
- `app/mini/inbox/page.tsx` - Added "Suggestions" tab with UI
- `app/api/matches/suggestions/route.ts` - Create suggestion endpoint
- `app/api/matches/suggestions/[id]/accept/route.ts` - Accept endpoint
- `app/api/matches/suggestions/[id]/decline/route.ts` - Decline endpoint
- `app/api/inbox/suggestions/route.ts` - Fetch suggestions endpoint
- `app/mini/suggest/page.tsx` - Suggestion creation page
- `supabase/migrations/20250122_create_match_suggestions.sql` - Database migration

---

## 📋 Deployment Steps

### Step 1: Run Database Migration (CRITICAL - Do this first!)

**Option A: Using Supabase Dashboard (Recommended)**
1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/sql
2. Copy the contents of `supabase/migrations/20250122_create_match_suggestions.sql`
3. Paste into SQL Editor
4. Click "Run"
5. Verify success (should create 2 tables, 3 functions, 1 view, multiple RLS policies)

**Option B: Using Supabase CLI**
```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

**Verify Migration:**
```sql
-- Check tables exist
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('match_suggestions', 'match_suggestion_cooldowns');

-- Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'match_suggestions';
-- Should return: rowsecurity = true

-- Check functions exist
SELECT proname FROM pg_proc
WHERE proname IN ('check_suggestion_cooldown', 'create_suggestion_cooldown', 'update_suggestion_status');
-- Should return all 3 functions
```

---

### Step 2: Deploy to Vercel

```bash
git push origin main
```

Vercel will auto-deploy in 2-3 minutes.

---

### Step 3: Test the Feature

1. **Visit Dashboard:** https://your-app.vercel.app/dashboard
   - Verify "Suggest Match" button is visible in Quick Actions

2. **Create a Suggestion:**
   - Click "Suggest Match" button → Opens `/mini/suggest`
   - Enter two FIDs and a message
   - Submit → Should show success and redirect

3. **Check Inbox:**
   - Visit: `/mini/inbox`
   - Click "Suggestions" tab
   - Verify suggestions appear with accept/decline buttons

4. **Test Acceptance Flow:**
   - User A accepts → Status shows "Waiting for other party"
   - User B accepts → Chat room is created
   - Both users can click "Open Chat Room"

5. **Test Decline & Cooldown:**
   - Decline a suggestion
   - Try re-suggesting same pair → Should get cooldown error
   - Check database: 7-day cooldown should exist

---

## 🔒 Security Verification

Run these queries to verify RLS policies are working:

```sql
-- Test 1: Users can't see suggestions they created (privacy!)
SET request.jwt.claims = '{"fid": YOUR_FID, "role": "authenticated"}';
SELECT * FROM match_suggestions WHERE created_by_fid = YOUR_FID;
-- Should return EMPTY (RLS blocks it)

-- Test 2: Users CAN see suggestions where they're participants
SELECT * FROM match_suggestions WHERE user_a_fid = YOUR_FID OR user_b_fid = YOUR_FID;
-- Should return suggestions where you're User A or User B
```

---

## 🎯 Quick Test Commands

### Test API Endpoints:

```bash
# 1. Create suggestion (requires auth)
curl -X POST https://your-app.vercel.app/api/matches/suggestions \
  -H "Content-Type: application/json" \
  -H "Cookie: your-session-cookie" \
  -d '{
    "userAFid": 12345,
    "userBFid": 67890,
    "message": "You two should connect!"
  }'

# 2. Fetch suggestions
curl https://your-app.vercel.app/api/inbox/suggestions \
  -H "Cookie: your-session-cookie"

# 3. Accept suggestion
curl -X POST https://your-app.vercel.app/api/matches/suggestions/SUGGESTION_ID/accept \
  -H "Cookie: your-session-cookie"

# 4. Decline suggestion
curl -X POST https://your-app.vercel.app/api/matches/suggestions/SUGGESTION_ID/decline \
  -H "Cookie: your-session-cookie"
```

---

## 📊 Monitoring Queries

```sql
-- Total suggestions created
SELECT COUNT(*) FROM match_suggestions;

-- Acceptance rate
SELECT
  COUNT(CASE WHEN status = 'accepted' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) as acceptance_rate
FROM match_suggestions;

-- Active cooldowns
SELECT COUNT(*) FROM match_suggestion_cooldowns WHERE cooldown_until > now();

-- Suggestions by status
SELECT status, COUNT(*) FROM match_suggestions GROUP BY status;
```

---

## 🐛 Troubleshooting

### Issue: "Permission denied" errors
**Solution:** Check RLS policies are active:
```sql
SELECT * FROM pg_policies WHERE tablename = 'match_suggestions';
```

### Issue: Cooldown not working
**Solution:** Verify trigger exists:
```sql
SELECT tgname FROM pg_trigger WHERE tgrelid = 'match_suggestions'::regclass;
-- Should show: trigger_create_suggestion_cooldown
```

### Issue: Chat room not created
**Solution:** Check both users accepted:
```sql
SELECT id, status, a_accepted, b_accepted, chat_room_id
FROM match_suggestions
WHERE id = 'SUGGESTION_ID';
```

---

## ✅ Success Criteria

Feature is fully deployed when:
- ✅ Migration runs without errors
- ✅ "Suggest Match" button visible on Dashboard
- ✅ `/mini/suggest` page loads and form works
- ✅ Suggestions appear in Inbox under "Suggestions" tab
- ✅ Users can accept/decline suggestions
- ✅ Chat rooms auto-create when both accept
- ✅ Cooldowns prevent re-suggesting declined pairs
- ✅ No console errors or warnings

---

## 📞 Quick Reference

- **Feature Summary:** See `SUGGEST_MATCH_SUMMARY.md`
- **Detailed Deployment Guide:** See `DEPLOYMENT_GUIDE_SUGGEST_MATCH.md`
- **Database Migration:** `supabase/migrations/20250122_create_match_suggestions.sql`
- **API Endpoints:** 4 routes under `/api/matches/suggestions` and `/api/inbox/suggestions`
- **UI Pages:** `/mini/suggest` (new), `/dashboard` (updated), `/mini/inbox` (updated)

---

**Estimated Deployment Time:** 10 minutes
**Downtime:** 0 minutes (zero-downtime deployment)
**Risk Level:** Low (backward compatible, no breaking changes)

---

🎉 **Ready to deploy! Push to main and Vercel will handle the rest.**

**IMPORTANT:** Remember to run the database migration BEFORE deploying the code!
