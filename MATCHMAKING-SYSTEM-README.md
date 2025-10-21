# Matchmaking System Documentation

## Overview

This is a comprehensive automatic and manual matchmaking system that matches users based on:
- **Trait overlap** (shared characteristics)
- **Bio similarity** (common keywords and interests)
- **Two-sided consent** (both users must accept)
- **Meeting scheduling** (automatic link generation after acceptance)

---

## Architecture

### Database Schema

Run `supabase-matchmaking-system.sql` to set up the enhanced schema:

```sql
-- New columns on matches table:
- created_by: 'system' | 'admin:<fid>'
- rationale: JSONB with match reasoning
- meeting_link: Generated meeting URL
- scheduled_at: When meeting was scheduled
- completed_at: When meeting finished

-- New tables:
- match_cooldowns: Prevents re-matching too soon
- auto_match_runs: Logs of automatic matching runs
```

### Services

#### 1. **Matching Service** (`lib/services/matching-service.ts`)

Core business logic for finding matches:

```typescript
// Configuration
MATCHING_CONFIG = {
  MIN_SCORE_THRESHOLD: 0.65,     // Minimum match score
  MAX_PROPOSALS_PER_USER: 3,     // Max pending proposals per user
  COOLDOWN_DAYS: 7,              // Days before re-matching
  TRAIT_WEIGHT: 0.6,             // Trait importance
  BIO_WEIGHT: 0.4,               // Bio importance
}

// Key functions:
- calculateTraitSimilarity()
- calculateBioSimilarity()
- calculateMatchScore()
- findBestMatches()
- createMatchProposal()
```

**Match Score Formula:**
```
overall_score = 0.6 * trait_similarity + 0.4 * bio_similarity

trait_similarity = shared_traits / total_unique_traits (Jaccard)
bio_similarity = shared_keywords / total_unique_keywords (Jaccard)
```

#### 2. **Auto-Match Runner** (`lib/services/auto-match-runner.ts`)

Orchestrates automatic matching:

```typescript
// Main function
runAutomaticMatching()
  → getMatchableUsers()          // Users with bio + 5+ traits
  → findBestMatches(user, all)   // Top 3 matches per user
  → createMatchProposal()        // Create proposals
  → Track in auto_match_runs
```

#### 3. **Meeting Service** (`lib/services/meeting-service.ts`)

Handles meeting link generation:

```typescript
scheduleMatch(matchId)
  → Check both accepted
  → generateMeetingLink()
  → Update match with link
  → Create system message
```

**Meeting Platforms Supported:**
- Custom (MVP - `/mini/meeting/:id`)
- Whereby (requires API key)
- Huddle01 (requires API key)

---

## API Endpoints

### Match Operations

#### `POST /api/matches`
Create manual match (admin/user initiated)

**Request:**
```json
{
  "userAFid": 12345,
  "userBFid": 67890,
  "message": "You both love DeFi!"
}
```

**Response:**
```json
{
  "match": { ... },
  "status": "proposed"
}
```

#### `GET /api/matches?scope=<filter>`
Fetch matches with filtering

**Scopes:**
- `pending` - Needs my response
- `awaiting` - I accepted, waiting on other party
- `accepted` - Both accepted
- `declined` - Declined matches
- `inbox` - All relevant matches

#### `POST /api/matches/:id/respond`
Accept or decline a match

**Request:**
```json
{
  "response": "accept" | "decline",
  "reason": "optional decline reason"
}
```

**Response:**
```json
{
  "success": true,
  "match": { ... },
  "meetingLink": "https://..." // If both accepted
}
```

#### `POST /api/matches/:id/schedule`
Manually schedule/reschedule meeting

**Response:**
```json
{
  "success": true,
  "meetingLink": "https://..."
}
```

### Automatic Matching

#### `POST /api/matches/auto-run`
Manually trigger automatic matching (for testing)

**Response:**
```json
{
  "success": true,
  "result": {
    "runId": "uuid",
    "usersProcessed": 150,
    "matchesCreated": 45,
    "duration": 2345,
    "errors": []
  }
}
```

#### `GET /api/matches/auto-run`
Get recent auto-match run history

### Cron Job

#### `GET /api/cron/auto-match`
Scheduled endpoint (runs every 3 hours)

**Authentication:**
```bash
Authorization: Bearer <CRON_SECRET>
```

---

## Matching Logic

### Eligibility Criteria

Users are eligible for automatic matching if:
- ✅ Have a bio (not null or empty)
- ✅ Have at least 5 traits selected
- ✅ Not in cooldown period with potential match
- ✅ No active match with potential partner
- ✅ Less than 3 pending proposals in last 24h

### Matching Algorithm

```
FOR each user in matchable_users:
  1. Get all other matchable users
  2. FOR each candidate:
     - Skip if same user
     - Skip if in cooldown (7 days after decline)
     - Skip if active match exists
     - Calculate trait similarity (Jaccard index)
     - Calculate bio similarity (keyword overlap)
     - Compute overall score = 0.6*traits + 0.4*bio
     - IF score >= 0.65:
       - Add to potential matches
  3. Sort by score descending
  4. Take top 3 matches
  5. Create match proposals with rationale
```

### Cooldown System

When a user declines a match:
- **Cooldown period:** 7 days
- **Prevents:** Re-proposing same pair during cooldown
- **Cleanup:** Expired cooldowns auto-deleted

### Match Lifecycle

```
proposed → accepted_by_a/b → accepted → [meeting] → completed
         ↘ declined
```

**Status Flow:**
1. **proposed** - Initial state, needs responses
2. **accepted_by_a** - User A accepted, waiting on B
3. **accepted_by_b** - User B accepted, waiting on A
4. **accepted** - Both accepted, meeting scheduled
5. **declined** - One or both declined
6. **completed** - Meeting finished

---

## UI Components

### Inbox (`/mini/inbox`)

**Four tabs:**

1. **Pending** - Matches needing your response
   - Shows "Action needed" badge
   - Accept/Decline buttons
   - Displays match rationale

2. **Awaiting Other Party** - You accepted, waiting
   - Shows who you're waiting on
   - Read-only view

3. **Accepted** - Active matches with meetings
   - "Join Meeting" button
   - Meeting link displayed
   - Can reschedule

4. **Declined** - Historical record
   - View decline reasons
   - Read-only

**Match Card Features:**
- Profile photo
- Match rationale (shared traits + bio keywords)
- Match score percentage
- Creator info (system vs admin)
- Message from introducer (if manual match)

---

## Configuration

### Environment Variables

```bash
# Required
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx

# Optional - Cron security
CRON_SECRET=your-secret-key

# Optional - Meeting platforms
WHEREBY_API_KEY=xxx
HUDDLE01_API_KEY=xxx
NEXT_PUBLIC_APP_URL=https://yourdomain.com
```

### Tuning Parameters

Edit `lib/services/matching-service.ts`:

```typescript
export const MATCHING_CONFIG = {
  MIN_SCORE_THRESHOLD: 0.65,     // Lower = more matches
  MAX_PROPOSALS_PER_USER: 3,     // Higher = more spam
  COOLDOWN_DAYS: 7,              // Higher = fewer rematches
  TRAIT_WEIGHT: 0.6,             // Trait importance
  BIO_WEIGHT: 0.4,               // Bio importance
  AUTO_MATCH_INTERVAL_HOURS: 3,  // Cron frequency
}
```

---

## Deployment

### Step 1: Database Setup

```bash
# Run in Supabase SQL Editor
1. supabase-schema.sql (base schema)
2. supabase-matchmaking-system.sql (matching extensions)
```

### Step 2: Deploy Application

```bash
# Vercel deployment
vercel deploy

# Vercel will automatically set up cron from vercel.json
```

### Step 3: Verify Cron

Check Vercel dashboard → Project → Settings → Cron Jobs

Should show:
```
/api/cron/auto-match - Runs every 3 hours (0 */3 * * *)
```

### Step 4: Test Manually

```bash
# Trigger auto-matching manually
curl -X POST https://yourdomain.com/api/matches/auto-run \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN"

# Check run history
curl https://yourdomain.com/api/matches/auto-run \
  -H "Authorization: Bearer YOUR_SESSION_TOKEN"
```

---

## Monitoring

### Check Auto-Match Runs

```sql
SELECT * FROM auto_match_runs
ORDER BY started_at DESC
LIMIT 10;
```

### Check Match Statistics

```sql
-- Matches by source
SELECT created_by, COUNT(*)
FROM matches
GROUP BY created_by;

-- Match acceptance rate
SELECT
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM matches), 2) as percentage
FROM matches
GROUP BY status;

-- Average match score
SELECT
  AVG((rationale->>'score')::numeric) as avg_score
FROM matches
WHERE created_by = 'system';
```

### Check Active Cooldowns

```sql
SELECT
  ua.username as user_a,
  ub.username as user_b,
  cooldown_until
FROM match_cooldowns mc
JOIN users ua ON mc.user_a_fid = ua.fid
JOIN users ub ON mc.user_b_fid = ub.fid
WHERE cooldown_until > NOW()
ORDER BY cooldown_until DESC;
```

---

## Troubleshooting

### No Matches Being Created

**Check:**
1. Users have bio and ≥5 traits
   ```sql
   SELECT COUNT(*) FROM users
   WHERE bio IS NOT NULL
   AND jsonb_array_length(traits) >= 5;
   ```

2. Score threshold not too high
   - Lower `MIN_SCORE_THRESHOLD` in config

3. Cooldowns not blocking everyone
   ```sql
   SELECT COUNT(*) FROM match_cooldowns
   WHERE cooldown_until > NOW();
   ```

### Cron Not Running

**Check:**
1. `vercel.json` deployed
2. Cron secret set correctly
3. Check Vercel logs: Dashboard → Functions → Logs

### Meeting Links Not Generating

**Check:**
1. Both users accepted
2. `NEXT_PUBLIC_APP_URL` set
3. Check logs for meeting service errors

---

## Future Enhancements

### High Priority
- [ ] Email/SMS notifications for new matches
- [ ] In-app notification system
- [ ] Meeting reminders
- [ ] Video call integration (Whereby/Huddle01)

### Medium Priority
- [ ] ML-based matching (vector embeddings)
- [ ] User feedback on match quality
- [ ] Advanced scheduling (time slot picker)
- [ ] Match history analytics

### Low Priority
- [ ] Match filters (industry, location)
- [ ] Batch matching for events
- [ ] Admin dashboard
- [ ] A/B testing for match algorithms

---

## Testing

### Manual Testing Checklist

- [ ] Create manual match
- [ ] User A accepts match
- [ ] User B accepts match
- [ ] Meeting link generated
- [ ] Join meeting button works
- [ ] Decline match
- [ ] Cooldown prevents rematch
- [ ] Run auto-matching manually
- [ ] Check match rationale displays
- [ ] Test all inbox tabs

### Load Testing

```bash
# Simulate 1000 users
# Check auto-match performance
time curl -X POST http://localhost:3000/api/matches/auto-run
```

Expected performance:
- < 5s for 100 users
- < 30s for 1000 users
- < 2min for 10,000 users

---

## Support

For issues or questions:
1. Check Supabase logs
2. Check Vercel function logs
3. Review database queries
4. Check cron execution history

---

## License

MIT
