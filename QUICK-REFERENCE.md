# Matchmaking System - Quick Reference Card

## 🚀 One-Page Quick Reference

### Key Endpoints

```
POST   /api/matches                    Create manual match
GET    /api/matches?scope=<filter>     Get matches (pending/awaiting/accepted/declined)
POST   /api/matches/:id/respond        Accept/decline match
POST   /api/matches/:id/schedule       Schedule meeting
POST   /api/matches/auto-run           Trigger auto-matching manually
GET    /api/cron/auto-match            Cron endpoint (every 3 hours)
```

### Configuration Constants

```typescript
// lib/services/matching-service.ts
MIN_SCORE_THRESHOLD: 0.65    // Match quality threshold
MAX_PROPOSALS_PER_USER: 3    // Max pending proposals
COOLDOWN_DAYS: 7             // Days before rematch
TRAIT_WEIGHT: 0.6            // Trait importance
BIO_WEIGHT: 0.4              // Bio importance
```

### Match Score Formula

```
score = 0.6 × trait_similarity + 0.4 × bio_similarity

trait_similarity = shared_traits / total_unique_traits
bio_similarity = shared_keywords / total_unique_keywords
```

### Status Flow

```
proposed → accepted_by_a/b → accepted → completed
         ↘ declined
```

### Database Tables

```sql
matches             -- All matches (enhanced)
match_cooldowns     -- 7-day cooldown tracking
auto_match_runs     -- Auto-match execution logs
```

### Useful SQL Queries

```sql
-- Recent matches
SELECT * FROM match_details ORDER BY created_at DESC LIMIT 10;

-- Auto-match stats
SELECT * FROM auto_match_runs ORDER BY started_at DESC LIMIT 5;

-- Match statistics
SELECT status, COUNT(*) FROM matches GROUP BY status;

-- Active cooldowns
SELECT COUNT(*) FROM match_cooldowns WHERE cooldown_until > NOW();

-- Eligible users
SELECT COUNT(*) FROM users
WHERE bio IS NOT NULL AND jsonb_array_length(traits) >= 5;
```

### Cron Configuration

```json
// vercel.json
{
  "crons": [{
    "path": "/api/cron/auto-match",
    "schedule": "0 */3 * * *"  // Every 3 hours
  }]
}
```

### Environment Variables

```bash
NEXT_PUBLIC_SUPABASE_URL          # Required
NEXT_PUBLIC_SUPABASE_ANON_KEY     # Required
SUPABASE_SERVICE_ROLE_KEY         # Required
CRON_SECRET                       # Recommended
NEXT_PUBLIC_APP_URL               # For meeting links
```

### Common Troubleshooting

| Problem | Solution |
|---------|----------|
| No matches created | Lower MIN_SCORE_THRESHOLD to 0.5 |
| Cron not running | Check vercel.json, redeploy |
| Meeting links broken | Set NEXT_PUBLIC_APP_URL |
| Not eligible | Need bio + 5 traits |

### Testing Commands

```bash
# Manual trigger
curl -X POST https://yourdomain.com/api/matches/auto-run

# Cron test
curl -X POST https://yourdomain.com/api/cron/auto-match \
  -H "Authorization: Bearer <CRON_SECRET>"

# Get pending matches
curl https://yourdomain.com/api/matches?scope=pending
```

### Files Structure

```
lib/services/
  ├── matching-service.ts       Core logic
  ├── meeting-service.ts        Meeting links
  └── auto-match-runner.ts      Orchestration

app/api/
  ├── matches/
  │   ├── route.ts              ✓ Updated
  │   ├── auto-run/route.ts     ✓ New
  │   └── [id]/
  │       ├── respond/          ✓ New
  │       └── schedule/         ✓ New
  └── cron/auto-match/          ✓ New

app/mini/
  ├── inbox/page.tsx            ✓ Updated
  └── create/page.tsx           ✓ Updated
```

### Documentation Files

- `MATCHMAKING-SUMMARY.md` - Implementation overview
- `MATCHMAKING-SYSTEM-README.md` - Complete documentation
- `MATCHMAKING-SETUP.md` - Setup guide
- `DEPLOYMENT-CHECKLIST.md` - Deployment steps
- `QUICK-REFERENCE.md` - This file

---

**Keep this card handy for quick lookups! 📌**
