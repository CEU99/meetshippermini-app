# Matchmaking System - Quick Setup Guide

## Prerequisites

- Existing Next.js app with Supabase configured
- Users table with `bio` and `traits` (JSONB) columns
- Node.js 18+ and npm/pnpm/yarn

## Installation Steps

### 1. Run Database Migrations

Execute these SQL files in your Supabase SQL Editor **in order**:

```bash
# If not already done:
1. supabase-schema.sql

# New matchmaking schema:
2. supabase-matchmaking-system.sql
```

This creates:
- Enhanced `matches` table with new columns
- `match_cooldowns` table
- `auto_match_runs` table
- Helper functions for matching logic

### 2. Verify Database Setup

```sql
-- Check matches table has new columns
SELECT column_name FROM information_schema.columns
WHERE table_name = 'matches';

-- Should include: created_by, rationale, meeting_link, scheduled_at

-- Test helper function
SELECT check_match_cooldown(12345, 67890);
```

### 3. Environment Variables

Add to `.env.local`:

```bash
# Required (should already exist)
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx

# Optional - Cron authentication
CRON_SECRET=generate-a-random-secret-here

# Optional - Meeting platforms
WHEREBY_API_KEY=xxx
HUDDLE01_API_KEY=xxx

# App URL (for meeting links)
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 4. File Structure

All files should already be created. Verify:

```
lib/services/
  ├── matching-service.ts       # Core matching logic
  ├── meeting-service.ts        # Meeting link generation
  └── auto-match-runner.ts      # Automatic matching orchestration

app/api/
  ├── matches/
  │   ├── route.ts              # ✓ Updated with scope filtering
  │   ├── auto-run/route.ts     # NEW - Manual trigger
  │   └── [id]/
  │       ├── respond/route.ts  # NEW - Accept/decline
  │       └── schedule/route.ts # NEW - Schedule meeting
  └── cron/
      └── auto-match/route.ts   # NEW - Cron endpoint

app/mini/inbox/page.tsx         # ✓ Updated with new UI

vercel.json                     # NEW - Cron configuration
```

### 5. Install Dependencies (if needed)

The project should have all dependencies, but verify:

```bash
npm install
# or
pnpm install
```

### 6. Test Locally

```bash
# Start dev server
npm run dev

# In another terminal, test auto-matching
curl -X POST http://localhost:3000/api/matches/auto-run \
  -H "Cookie: session=YOUR_SESSION_COOKIE"
```

### 7. Deploy to Vercel

```bash
# Deploy
vercel deploy --prod

# Vercel will automatically:
# - Read vercel.json
# - Set up cron job for /api/cron/auto-match
# - Schedule it to run every 3 hours
```

### 8. Verify Deployment

#### a. Check Cron Job

1. Go to Vercel Dashboard
2. Project → Settings → Cron Jobs
3. Should see: `/api/cron/auto-match` running `0 */3 * * *`

#### b. Test Cron Endpoint

```bash
# From Vercel logs or manually:
curl -X POST https://yourdomain.com/api/cron/auto-match \
  -H "Authorization: Bearer YOUR_CRON_SECRET"
```

#### c. Check Database

```sql
-- View auto-match runs
SELECT * FROM auto_match_runs ORDER BY started_at DESC LIMIT 5;

-- Check matches created by system
SELECT COUNT(*) FROM matches WHERE created_by = 'system';
```

---

## Testing the System

### Test 1: Manual Match (Admin)

1. Go to `/mini/create`
2. Select two users
3. Add message
4. Submit
5. Check `/mini/inbox` for both users

### Test 2: Automatic Matching

**Setup:**
1. Create 2+ users with:
   - Bio filled out
   - At least 5 traits selected
   - Some overlapping traits

**Trigger:**
```bash
curl -X POST https://yourdomain.com/api/matches/auto-run
```

**Verify:**
1. Check `auto_match_runs` table
2. Check `matches` where `created_by = 'system'`
3. Users should see proposals in inbox

### Test 3: Match Acceptance Flow

1. **User A**: Go to inbox, see pending match
2. **User A**: Click Accept
3. **User B**: Go to inbox, see pending match
4. **User B**: Click Accept
5. **Both**: Should see "Meeting Scheduled!" with link

### Test 4: Cooldown System

1. User declines match
2. Check `match_cooldowns` table
3. Run auto-match again
4. Verify same pair not re-matched

---

## Configuration Tuning

### Adjust Match Sensitivity

Edit `lib/services/matching-service.ts`:

```typescript
export const MATCHING_CONFIG = {
  // Lower threshold = more matches (but lower quality)
  MIN_SCORE_THRESHOLD: 0.65,  // Try 0.5 for more matches

  // More proposals = more choice (but potential spam)
  MAX_PROPOSALS_PER_USER: 3,  // Try 5 for more options

  // Shorter cooldown = more rematching
  COOLDOWN_DAYS: 7,  // Try 3 for faster retry

  // Adjust importance weights
  TRAIT_WEIGHT: 0.6,  // 0-1 (must sum to 1 with BIO_WEIGHT)
  BIO_WEIGHT: 0.4,
}
```

### Change Cron Frequency

Edit `vercel.json`:

```json
{
  "crons": [
    {
      "path": "/api/cron/auto-match",
      "schedule": "0 */1 * * *"  // Every hour
      // or "0 0 * * *"           // Daily at midnight
      // or "0 */6 * * *"         // Every 6 hours
    }
  ]
}
```

Cron syntax: `minute hour day month weekday`

---

## Troubleshooting

### Issue: No matches being created

**Solution:**
```sql
-- Check eligible users
SELECT COUNT(*) FROM users
WHERE bio IS NOT NULL
  AND bio != ''
  AND jsonb_array_length(COALESCE(traits, '[]'::jsonb)) >= 5;

-- If < 2, add more user profiles
```

### Issue: Scores too low

**Solution:**
```typescript
// Lower threshold in matching-service.ts
MIN_SCORE_THRESHOLD: 0.5  // was 0.65
```

### Issue: Cron not running

**Solutions:**
1. Check Vercel logs: Dashboard → Logs → Functions
2. Verify `CRON_SECRET` environment variable
3. Check `vercel.json` is in root directory
4. Redeploy: `vercel deploy --prod`

### Issue: Meeting links broken

**Solution:**
```bash
# Check environment variable
echo $NEXT_PUBLIC_APP_URL

# Should be: https://yourdomain.com (no trailing slash)
```

### Issue: Users not getting proposals

**Solution:**
```sql
-- Check pending proposals per user
SELECT user_a_fid, COUNT(*) FROM matches
WHERE status IN ('proposed', 'pending')
  AND created_at > NOW() - INTERVAL '24 hours'
GROUP BY user_a_fid
HAVING COUNT(*) >= 3;

-- Users with 3+ proposals won't get more
-- Wait 24 hours or lower MAX_PROPOSALS_PER_USER
```

---

## Monitoring Dashboard Queries

### Match Statistics

```sql
-- Overall stats
SELECT
  COUNT(*) as total_matches,
  COUNT(*) FILTER (WHERE status = 'accepted') as accepted,
  COUNT(*) FILTER (WHERE status = 'declined') as declined,
  COUNT(*) FILTER (WHERE created_by = 'system') as auto_matches,
  ROUND(AVG((rationale->>'score')::numeric), 3) as avg_score
FROM matches;

-- Recent activity
SELECT
  DATE(created_at) as date,
  COUNT(*) as matches_created,
  COUNT(*) FILTER (WHERE status = 'accepted') as accepted
FROM matches
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### System Health

```sql
-- Auto-match performance
SELECT
  started_at,
  users_processed,
  matches_created,
  EXTRACT(EPOCH FROM (completed_at - started_at)) as duration_seconds,
  status
FROM auto_match_runs
ORDER BY started_at DESC
LIMIT 10;

-- Active cooldowns
SELECT COUNT(*) as active_cooldowns
FROM match_cooldowns
WHERE cooldown_until > NOW();
```

---

## Next Steps

1. ✅ **Test the system** with real users
2. ✅ **Monitor** first few auto-match runs
3. ✅ **Tune** configuration based on results
4. 📧 **Add notifications** (email/SMS/push)
5. 📊 **Set up analytics** (match quality, acceptance rate)
6. 🎥 **Integrate** video platform (Whereby/Huddle01)

---

## Support

- **Documentation:** See `MATCHMAKING-SYSTEM-README.md`
- **Database Schema:** See `supabase-matchmaking-system.sql`
- **API Docs:** See README for endpoint details

Good luck! 🚀
