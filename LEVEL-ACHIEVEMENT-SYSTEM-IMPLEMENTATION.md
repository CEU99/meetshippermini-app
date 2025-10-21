# 🎯 Level & Achievement System - Complete Implementation Guide

**Date:** 2025-10-20
**Status:** ✅ Backend Complete | 🔄 UI In Progress
**Applies to:** All users (production-level feature)

---

## 📋 Overview

This document provides a complete implementation guide for the Level & Achievement System, which rewards users for meaningful actions with points that contribute to level progression from 0 to 20.

### System Design
- **Level Range:** 0-20
- **Points per Level:** 100
- **Max Points:** 2000
- **Achievement Model:** One-time rewards (idempotent)
- **Wave System:** Achievements unlock in 4 waves

---

## ✅ Completed: Backend Implementation

### 1. Database Schema (`supabase-level-achievement-system.sql`)

#### Tables Created:
- **`user_levels`** - Stores user level progression
  - `user_fid` (PK, FK → users)
  - `points_total` (int, 0-2000)
  - `level` (computed: FLOOR(points_total / 100), max 20)
  - `level_progress` (computed: points_total % 100)
  - `created_at`, `updated_at`

- **`user_achievements`** - Stores earned achievements
  - `id` (UUID PK)
  - `user_fid` (FK → users)
  - `code` (text, unique per user)
  - `points` (int)
  - `awarded_at` (timestamp)
  - **Unique constraint:** (user_fid, code)

#### Helper Functions:
- `award_achievement(user_fid, code, points)` - Idempotent achievement awarding
- `get_user_level(user_fid)` - Get level info
- `get_user_achievements(user_fid)` - Get earned achievements
- `check_profile_achievements(user_fid)` - Check bio/traits
- `check_match_request_achievements(user_fid)` - Check match counts
- `check_meeting_achievements(user_fid)` - Check meeting counts

---

### 2. Achievement Definitions (`lib/constants/achievements.ts`)

#### Wave 1: Profile Setup (200 points = Level 2)
| Code | Title | Description | Points |
|------|-------|-------------|--------|
| `bio_done` | Bio Master | Fill out your bio | 50 |
| `traits_done` | Trait Hunter | Select 5+ personal traits | 50 |
| `sent_5` | First Connections | Send 5 match requests | 100 |

#### Wave 2: Active Networker (300 points = Level 5)
| Code | Title | Description | Points |
|------|-------|-------------|--------|
| `sent_10` | Connector | Send 10 match requests | 100 |
| `sent_20` | Network Builder | Send 20 match requests | 100 |
| `sent_30` | Super Connector | Send 30 match requests | 100 |

#### Wave 3: Meeting Achievements (1200 points = Level 17)
| Code | Title | Description | Points |
|------|-------|-------------|--------|
| `joined_1` | First Meeting | Complete 1 meeting | 400 |
| `joined_5` | Meeting Regular | Complete 5 meetings | 400 |
| `joined_10` | Meeting Pro | Complete 10 meetings | 400 |

#### Wave 4: Final Achievement (400 points = Level 20 MAX)
| Code | Title | Description | Points |
|------|-------|-------------|--------|
| `joined_40` | Legendary Networker | Complete 40 meetings | 400 |

---

### 3. API Endpoints Implemented

#### GET `/api/level/me`
Returns current user's level information.

**Response:**
```json
{
  "user_fid": 1394398,
  "points_total": 350,
  "level": 3,
  "level_progress": 50,
  "is_max_level": false,
  "updated_at": "2025-10-20T..."
}
```

#### GET `/api/achievements/me`
Returns earned achievements for current user.

**Response:**
```json
{
  "achievements": [
    {
      "code": "bio_done",
      "title": "Bio Master",
      "description": "Fill out your bio",
      "points": 50,
      "icon": "📝",
      "awarded_at": "2025-10-20T...",
      "wave": 1
    }
  ],
  "total_earned": 5,
  "total_available": 10
}
```

---

### 4. Achievement Triggers Integrated

#### Profile Updates (`app/api/profile/route.ts`)
✅ Checks and awards:
- `bio_done` - When bio is filled
- `traits_done` - When 5+ traits selected

**Integration Point:** After successful profile update (line 371-385)

```typescript
const achievementsAwarded = await checkProfileAchievements(session.fid);
```

#### Match Requests (`app/api/matches/manual/route.ts`)
✅ Checks and awards:
- `sent_5`, `sent_10`, `sent_20`, `sent_30` - Based on unique recipients

**Integration Point:** After successful match creation (line 164-178)

```typescript
const achievementsAwarded = await checkMatchRequestAchievements(requesterFid);
```

#### Completed Meetings (`app/api/matches/[id]/complete/route.ts`)
✅ Checks and awards for BOTH users:
- `joined_1`, `joined_5`, `joined_10`, `joined_40` - Based on completed meetings

**Integration Point:** When both users mark meeting as completed (line 191-218)

```typescript
const [achievementsA, achievementsB] = await Promise.all([
  checkMeetingAchievements(match.user_a_fid),
  checkMeetingAchievements(match.user_b_fid),
]);
```

---

### 5. Achievement Service (`lib/services/achievement-service.ts`)

Provides helper functions for awarding and checking achievements:
- `awardAchievement(userFid, code, points)` - Award single achievement
- `checkProfileAchievements(userFid)` - Check bio/traits criteria
- `checkMatchRequestAchievements(userFid)` - Check unique match counts
- `checkMeetingAchievements(userFid)` - Check completed meeting counts
- `checkAllAchievements(userFid)` - Check all at once (for recalculation)

**Key Features:**
- ✅ Idempotent (awards once only)
- ✅ Automatic point calculation
- ✅ Level updates in real-time
- ✅ Error handling (doesn't break main flow)

---

## 🔄 In Progress: UI Implementation

### Next Steps

#### 1. Add Level Progress Bar to Dashboard

**Location:** `app/dashboard/page.tsx`

**Requirements:**
- Horizontal progress bar next to "Edit Profile" button
- Display current level (e.g., "Level 3" or "Max Level")
- Progress bar shows percentage (0-100%)
- Responsive design for mobile

**Example Layout:**
```
┌────────────────────────────────────────┐
│ Profile Section                        │
│ ┌────────────┐                         │
│ │   Avatar   │  Username               │
│ │            │  @handle                │
│ └────────────┘                         │
│                                        │
│ Level 3 ██████████░░░░░░░░░░░ 50/100  │
│                                        │
│ [Edit Profile]                         │
└────────────────────────────────────────┘
```

**Implementation Pseudocode:**
```typescript
// 1. Fetch level data
const { data: levelData } = await fetch('/api/level/me');

// 2. Calculate percentage
const percentage = (levelData.level_progress / 100) * 100;

// 3. Render progress bar
<div className="w-full bg-gray-200 rounded-full h-4">
  <div
    className="bg-purple-600 h-4 rounded-full"
    style={{ width: `${percentage}%` }}
  />
</div>
```

---

#### 2. Create Achievements Section with Horizontal Card Layout

**Location:** Create new component `components/dashboard/Achievements.tsx`

**Requirements:**
- Three cards per row (horizontal layout)
- Wave-based progressive unlock system
- Responsive (2+1 on tablet, 1 per row on mobile)
- Show locked/unlocked states
- Display points earned
- "How to earn" tooltips for locked cards

**Wave Display Logic:**
```
Wave 1: [ Bio ] [ Traits ] [ 5 Requests ]
         ↓ All 3 completed
Wave 2: [ 10 Req ] [ 20 Req ] [ 30 Req ]
         ↓ All 3 completed
Wave 3: [ 1 Meet ] [ 5 Meet ] [ 10 Meet ]
         ↓ All 3 completed
Wave 4: [ 40 Meetings ] (centered)
```

**Card States:**
- ✅ **Completed:** Green border, checkmark, points shown
- 🔓 **Unlocked:** Blue border, "How to earn" shown
- 🔒 **Locked:** Gray, hidden until previous wave complete

**Example Card Component:**
```tsx
interface AchievementCardProps {
  achievement: Achievement;
  earned: boolean;
  locked: boolean;
}

function AchievementCard({ achievement, earned, locked }: AchievementCardProps) {
  return (
    <div className={`
      rounded-lg p-4 border-2
      ${earned ? 'border-green-500 bg-green-50' : 'border-gray-300'}
      ${locked ? 'opacity-50' : ''}
    `}>
      <div className="text-4xl">{achievement.icon}</div>
      <h3 className="font-bold">{achievement.title}</h3>
      <p className="text-sm">{achievement.description}</p>
      <p className="text-purple-600 font-bold">+{achievement.points}pts</p>
      {earned && <span className="text-green-600">✓ Completed</span>}
      {!earned && !locked && (
        <p className="text-xs text-gray-600">{achievement.howToEarn}</p>
      )}
    </div>
  );
}
```

---

## 🧪 Testing Plan

### Test 1: Profile Achievements
1. Navigate to Edit Profile
2. Fill out bio → Should award `bio_done` (+50pts)
3. Select 5+ traits → Should award `traits_done` (+50pts)
4. Check Dashboard: Level should be 1, progress 0/100

### Test 2: Match Request Achievements
1. Create 5 match requests to unique users
2. Should award `sent_5` (+100pts)
3. Create 5 more (total 10) → Award `sent_10` (+100pts)
4. Create 10 more (total 20) → Award `sent_20` (+100pts)
5. Create 10 more (total 30) → Award `sent_30` (+100pts)

### Test 3: Meeting Achievements
1. Complete 1 meeting (both users confirm)
2. Should award `joined_1` (+400pts) to BOTH users
3. Complete 4 more (total 5) → Award `joined_5` (+400pts)
4. Complete 5 more (total 10) → Award `joined_10` (+400pts)
5. Complete 30 more (total 40) → Award `joined_40` (+400pts)

### Test 4: Idempotency
1. Award `bio_done`
2. Update bio again
3. Should NOT award again (already exists)
4. Points should remain same

### Test 5: Wave Progression
1. Complete Wave 1 (bio + traits + 5 requests)
2. Dashboard should show Wave 2 cards
3. Wave 3 cards should still be hidden

---

## 📦 Setup Instructions

### Step 1: Run Database Migration
```bash
# In Supabase SQL Editor, run:
# File: supabase-level-achievement-system.sql
```

**Verify:**
```sql
SELECT table_name FROM information_schema.tables
WHERE table_name IN ('user_levels', 'user_achievements');

-- Should return both tables
```

### Step 2: Install Dependencies
```bash
npm install
```

### Step 3: Restart Dev Server
```bash
npm run dev
```

### Step 4: Test API Endpoints
```bash
# Test level endpoint
curl http://localhost:3000/api/level/me

# Test achievements endpoint
curl http://localhost:3000/api/achievements/me
```

**Expected:** Both should return 401 (need authentication) or valid data if logged in.

---

## 🔍 Troubleshooting

### Issue: Tables don't exist
**Solution:** Run `supabase-level-achievement-system.sql` in Supabase SQL Editor

### Issue: Functions not found
**Solution:** Verify functions exist:
```sql
SELECT routine_name FROM information_schema.routines
WHERE routine_name LIKE '%achievement%' OR routine_name LIKE '%level%';
```

### Issue: Achievements not awarding
**Check:**
1. Server logs for `[Achievement]` entries
2. Database: `SELECT * FROM user_achievements WHERE user_fid = YOUR_FID;`
3. Trigger integration points are correct

### Issue: Level not updating
**Check:**
1. `user_levels` table: `SELECT * FROM user_levels WHERE user_fid = YOUR_FID;`
2. Computed columns are working: `level` and `level_progress`
3. Points capped at 2000

---

## 📊 Database Queries for Debugging

### Check user's current level
```sql
SELECT * FROM user_levels WHERE user_fid = 1394398;
```

### Check user's achievements
```sql
SELECT * FROM user_achievements WHERE user_fid = 1394398 ORDER BY awarded_at;
```

### Count total points
```sql
SELECT user_fid, SUM(points) as total_points
FROM user_achievements
WHERE user_fid = 1394398
GROUP BY user_fid;
```

### Check match request count
```sql
SELECT COUNT(DISTINCT
  CASE
    WHEN created_by_fid = 1394398 THEN
      CASE
        WHEN user_a_fid = 1394398 THEN user_b_fid
        ELSE user_a_fid
      END
  END
) as unique_recipients
FROM matches
WHERE created_by_fid = 1394398;
```

### Check completed meetings count
```sql
SELECT COUNT(*) as completed_meetings
FROM matches
WHERE (user_a_fid = 1394398 OR user_b_fid = 1394398)
  AND status = 'completed';
```

---

## 🚀 Deployment Checklist

- [x] Database schema created
- [x] Helper functions implemented
- [x] API endpoints created (`/api/level/me`, `/api/achievements/me`)
- [x] Achievement service created
- [x] Profile update trigger integrated
- [x] Match request trigger integrated
- [x] Meeting completion trigger integrated
- [ ] Dashboard level progress bar added
- [ ] Achievements section component created
- [ ] Horizontal card layout implemented
- [ ] Wave system UI logic implemented
- [ ] Responsive design tested
- [ ] End-to-end testing completed
- [ ] Production deployment

---

## 🎨 UI Design Specifications

### Colors
- **Primary:** Purple 600 (#9333EA)
- **Success:** Green 500 (#10B981)
- **Locked:** Gray 300 (#D1D5DB)
- **Background:** Gray 50 (#F9FAFB)

### Typography
- **Level Label:** Font bold, size lg
- **Card Title:** Font bold, size md
- **Card Description:** Font normal, size sm
- **Points:** Font bold, Purple 600

### Spacing
- **Card Grid:** gap-4 (1rem)
- **Card Padding:** p-4 (1rem)
- **Section Margin:** mb-8 (2rem)

### Breakpoints
- **Desktop (lg):** 3 cards per row
- **Tablet (md):** 2 cards per row
- **Mobile (sm):** 1 card per row

---

## 📚 File Reference

### Backend Files Created/Modified
1. `supabase-level-achievement-system.sql` - Database schema
2. `lib/constants/achievements.ts` - Achievement definitions
3. `lib/services/achievement-service.ts` - Achievement logic
4. `app/api/level/me/route.ts` - Level API endpoint
5. `app/api/achievements/me/route.ts` - Achievements API endpoint
6. `app/api/profile/route.ts` - Added profile achievement trigger
7. `app/api/matches/manual/route.ts` - Added match request achievement trigger
8. `app/api/matches/[id]/complete/route.ts` - Added meeting achievement trigger

### Frontend Files To Create
1. `components/dashboard/LevelProgress.tsx` - Level progress bar component
2. `components/dashboard/Achievements.tsx` - Achievement cards section
3. `components/dashboard/AchievementCard.tsx` - Individual card component
4. `app/dashboard/page.tsx` - Update to include new components

---

## ✅ Success Criteria

The Level & Achievement System is complete when:
1. ✅ Database tables exist and are accessible
2. ✅ API endpoints return correct data
3. ✅ Achievements award automatically on triggers
4. ✅ Points accumulate correctly
5. ✅ Level calculates correctly (0-20)
6. [ ] Dashboard shows level progress bar
7. [ ] Achievement cards display horizontally
8. [ ] Wave system unlocks progressively
9. [ ] All 10 achievements are functional
10. [ ] System works for all users (new and existing)

---

## 🎉 Summary

**Completed:**
- ✅ Complete database schema with computed columns
- ✅ 10 achievements across 4 waves
- ✅ 2 API endpoints for level and achievements
- ✅ Automatic triggers for profile, matches, and meetings
- ✅ Idempotent awarding system
- ✅ Full error handling and logging

**Remaining:**
- 🔄 Dashboard UI with level progress bar
- 🔄 Horizontal achievement card layout
- 🔄 Wave-based progressive unlock UI
- 🔄 Responsive design implementation
- 🔄 End-to-end testing

This system is production-ready from a backend perspective and will work permanently for all users once the UI is completed.
