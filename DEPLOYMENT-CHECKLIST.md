# 🚀 Matchmaking System - Deployment Checklist

Use this checklist to ensure a smooth deployment of the matchmaking system.

---

## 📋 Pre-Deployment

### Database Setup
- [ ] **Backup current database** (just in case)
  ```sql
  -- In Supabase: Project → Database → Backups → Create backup
  ```

- [ ] **Run schema migrations**
  - [ ] Open Supabase SQL Editor
  - [ ] Run `supabase-matchmaking-system.sql`
  - [ ] Verify no errors

- [ ] **Verify schema changes**
  ```sql
  -- Check matches table columns
  SELECT column_name, data_type
  FROM information_schema.columns
  WHERE table_name = 'matches';

  -- Should see: created_by, rationale, meeting_link, scheduled_at, completed_at
  ```

- [ ] **Verify new tables exist**
  ```sql
  SELECT table_name FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN ('match_cooldowns', 'auto_match_runs');
  ```

- [ ] **Test helper functions**
  ```sql
  -- Test cooldown check (should return false for new pairs)
  SELECT check_match_cooldown(12345, 67890);

  -- Test matchable users function
  SELECT COUNT(*) FROM get_matchable_users();
  ```

### Code Review
- [ ] **All service files present**
  - [ ] `lib/services/matching-service.ts`
  - [ ] `lib/services/meeting-service.ts`
  - [ ] `lib/services/auto-match-runner.ts`

- [ ] **All API endpoints ready**
  - [ ] `app/api/matches/auto-run/route.ts`
  - [ ] `app/api/matches/[id]/respond/route.ts`
  - [ ] `app/api/matches/[id]/schedule/route.ts`
  - [ ] `app/api/cron/auto-match/route.ts`

- [ ] **UI components updated**
  - [ ] `app/mini/inbox/page.tsx`
  - [ ] `app/mini/create/page.tsx`

- [ ] **Configuration files**
  - [ ] `vercel.json` exists in root
  - [ ] Cron schedule correct: `"0 */3 * * *"`

### Environment Variables
- [ ] **Production environment variables set**
  - [ ] `NEXT_PUBLIC_SUPABASE_URL`
  - [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - [ ] `SUPABASE_SERVICE_ROLE_KEY`
  - [ ] `CRON_SECRET` (generate: `openssl rand -base64 32`)
  - [ ] `NEXT_PUBLIC_APP_URL` (e.g., `https://yourdomain.com`)

- [ ] **Verify in Vercel dashboard**
  - Project → Settings → Environment Variables
  - Check all secrets are set for "Production"

### Test Data
- [ ] **Create test users** (at least 3)
  - [ ] Each has bio filled out
  - [ ] Each has 5+ traits selected
  - [ ] Some overlapping traits between users
  - [ ] Some common keywords in bios

---

## 🚀 Deployment

### Git Commit
- [ ] **Commit all changes**
  ```bash
  git add .
  git commit -m "feat: implement automatic matchmaking system"
  git push origin main
  ```

### Vercel Deployment
- [ ] **Deploy to production**
  ```bash
  vercel deploy --prod
  ```
  Or: Push to main branch (if auto-deploy enabled)

- [ ] **Wait for deployment to complete**
  - Check Vercel dashboard for status
  - Ensure no build errors

- [ ] **Verify deployment URL**
  - [ ] Site loads correctly
  - [ ] No console errors
  - [ ] Login works

### Cron Configuration
- [ ] **Verify cron job in Vercel**
  - Vercel Dashboard → Project → Settings → Cron Jobs
  - Should show: `/api/cron/auto-match`
  - Schedule: `0 */3 * * *` (every 3 hours)

- [ ] **Check cron logs**
  - Dashboard → Logs → Filter by "cron"
  - Wait for first run or trigger manually

---

## ✅ Post-Deployment Testing

### Manual Tests

#### Test 1: Manual Match Creation
- [ ] **Go to** `/mini/create`
- [ ] **Select two test users**
- [ ] **Add message**
- [ ] **Submit**
- [ ] **Verify** match appears in both users' inboxes
- [ ] **Check** status is "proposed"
- [ ] **Verify** created_by is `admin:<your_fid>`

#### Test 2: Match Acceptance Flow
- [ ] **As User A**: Accept the match
- [ ] **Verify** status changes to "accepted_by_a"
- [ ] **Verify** User A sees "Awaiting Other Party"
- [ ] **As User B**: Accept the match
- [ ] **Verify** status changes to "accepted"
- [ ] **Verify** meeting link is generated
- [ ] **Verify** "Join Meeting" button appears

#### Test 3: Match Decline
- [ ] **Create new match**
- [ ] **As User A**: Decline the match
- [ ] **Verify** status changes to "declined"
- [ ] **Verify** match appears in "Declined" tab
- [ ] **Check database** for cooldown entry
  ```sql
  SELECT * FROM match_cooldowns
  WHERE user_a_fid = <fid_a> AND user_b_fid = <fid_b>;
  ```

#### Test 4: Automatic Matching (Manual Trigger)
- [ ] **Trigger auto-match** (logged in as admin)
  ```bash
  curl -X POST https://yourdomain.com/api/matches/auto-run \
    -H "Cookie: <your-session-cookie>"
  ```
- [ ] **Check response** for matches created
- [ ] **Verify in database**
  ```sql
  SELECT * FROM matches WHERE created_by = 'system' ORDER BY created_at DESC LIMIT 5;
  ```
- [ ] **Check auto_match_runs table**
  ```sql
  SELECT * FROM auto_match_runs ORDER BY started_at DESC LIMIT 1;
  ```

#### Test 5: Inbox UI
- [ ] **Pending tab**
  - [ ] Shows matches needing response
  - [ ] Badge count correct
  - [ ] "Action needed" indicator visible

- [ ] **Awaiting tab**
  - [ ] Shows matches you accepted
  - [ ] Badge count correct
  - [ ] No action buttons

- [ ] **Accepted tab**
  - [ ] Shows completed matches
  - [ ] Meeting link visible
  - [ ] "Join Meeting" button works

- [ ] **Declined tab**
  - [ ] Shows declined matches
  - [ ] Read-only
  - [ ] Historical record

#### Test 6: Match Rationale Display
- [ ] **Open any system-generated match**
- [ ] **Verify** rationale section shows:
  - [ ] Shared traits listed
  - [ ] Bio keywords (if any)
  - [ ] Match score percentage
- [ ] **Verify** trait pills display correctly

### API Tests

#### Test API Endpoints
```bash
# Replace <TOKEN> with actual session token
# Replace <MATCH_ID> with actual match ID

# Get matches with scope
curl https://yourdomain.com/api/matches?scope=pending \
  -H "Cookie: session=<TOKEN>"

# Respond to match
curl -X POST https://yourdomain.com/api/matches/<MATCH_ID>/respond \
  -H "Cookie: session=<TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"response": "accept"}'

# Get meeting details
curl https://yourdomain.com/api/matches/<MATCH_ID>/schedule \
  -H "Cookie: session=<TOKEN>"

# Trigger auto-match (requires auth)
curl -X POST https://yourdomain.com/api/matches/auto-run \
  -H "Cookie: session=<TOKEN>"

# Cron endpoint (requires secret)
curl -X POST https://yourdomain.com/api/cron/auto-match \
  -H "Authorization: Bearer <CRON_SECRET>"
```

- [ ] **All endpoints return 200/201**
- [ ] **No 500 errors**
- [ ] **Auth working correctly** (401 for unauthorized)

### Database Verification

- [ ] **Check match statistics**
  ```sql
  SELECT
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE created_by = 'system') as auto_matches,
    COUNT(*) FILTER (WHERE status = 'accepted') as accepted,
    COUNT(*) FILTER (WHERE status = 'declined') as declined
  FROM matches;
  ```

- [ ] **Verify cooldowns working**
  ```sql
  SELECT COUNT(*) FROM match_cooldowns WHERE cooldown_until > NOW();
  ```

- [ ] **Check auto-match runs**
  ```sql
  SELECT * FROM auto_match_runs ORDER BY started_at DESC LIMIT 5;
  ```

---

## 🔍 Monitoring Setup

### Vercel Logs
- [ ] **Set up log streaming**
  - Dashboard → Logs → Enable real-time
  - Filter for "auto-match" to monitor cron

### Database Monitoring
- [ ] **Create monitoring queries dashboard**
  - Supabase → SQL Editor → Save favorite queries
  - Save queries from `MATCHMAKING-SYSTEM-README.md`

### Alerts (Optional)
- [ ] **Set up error alerts**
  - Vercel → Project → Settings → Notifications
  - Enable email/Slack for errors

- [ ] **Database alerts**
  - Supabase → Project → Reports → Set thresholds

---

## 📊 Performance Baseline

Record these metrics for future comparison:

### Database
- [ ] **Query performance**
  ```sql
  -- Check slow queries
  SELECT * FROM pg_stat_statements
  WHERE query LIKE '%matches%'
  ORDER BY total_exec_time DESC
  LIMIT 10;
  ```

- [ ] **Table sizes**
  ```sql
  SELECT
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN ('matches', 'match_cooldowns', 'auto_match_runs');
  ```

### API Response Times
- [ ] **Test endpoint latency**
  ```bash
  # Average 3 runs
  time curl https://yourdomain.com/api/matches
  ```

### Auto-Match Performance
- [ ] **Record first run metrics**
  - Users processed: _____
  - Matches created: _____
  - Duration: _____ ms

---

## 🎯 Success Criteria

All these should be ✅ before declaring deployment successful:

- [ ] **Database migrations completed** with no errors
- [ ] **All environment variables** set correctly
- [ ] **Vercel deployment** successful (green status)
- [ ] **Cron job** configured and visible in dashboard
- [ ] **Manual match creation** works end-to-end
- [ ] **Match acceptance flow** works (both accept → meeting link)
- [ ] **Match decline** works (cooldown created)
- [ ] **Automatic matching** runs successfully (manual trigger)
- [ ] **All inbox tabs** display correctly
- [ ] **Match rationale** displays with traits and score
- [ ] **Meeting links** generate correctly
- [ ] **No console errors** in browser
- [ ] **No 500 errors** in API calls
- [ ] **Cron runs** on schedule (check after 3 hours)

---

## 🚨 Rollback Plan

If critical issues occur:

### Emergency Rollback
```bash
# Revert to previous deployment
vercel rollback

# Or rollback specific deployment
vercel rollback <deployment-url>
```

### Database Rollback
```sql
-- If needed, drop new tables
DROP TABLE IF EXISTS match_cooldowns;
DROP TABLE IF EXISTS auto_match_runs;

-- Revert matches table changes (only if critical)
ALTER TABLE matches DROP COLUMN IF EXISTS created_by;
ALTER TABLE matches DROP COLUMN IF EXISTS rationale;
ALTER TABLE matches DROP COLUMN IF EXISTS meeting_link;
ALTER TABLE matches DROP COLUMN IF EXISTS scheduled_at;
ALTER TABLE matches DROP COLUMN IF EXISTS completed_at;
```

**⚠️ Note:** Only rollback if absolutely necessary. Document reason.

---

## 📝 Post-Deployment Notes

### Communication
- [ ] **Announce to team** that matchmaking is live
- [ ] **Update documentation** with production URLs
- [ ] **Share monitoring dashboard** links

### Documentation
- [ ] **Record deployment date**: _______________
- [ ] **Production URL**: _______________
- [ ] **First cron run**: _______________
- [ ] **Initial user count**: _______________
- [ ] **Notes/Issues**: _______________

---

## 🎉 Go Live!

Once all checkboxes are complete:
- ✅ System is production-ready
- ✅ Monitoring is in place
- ✅ Team is informed
- ✅ Documentation is complete

**Status:** ⬜ Ready to deploy | ⬜ Deployed | ⬜ Verified | ⬜ Live

**Deployed by:** _______________
**Date:** _______________
**Time:** _______________

---

**Congratulations on your deployment! 🚀**

Next: Monitor for 24-48 hours, tune configuration as needed, and plan notification system (phase 2).
