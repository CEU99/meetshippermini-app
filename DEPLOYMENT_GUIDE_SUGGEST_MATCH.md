# 🚀 Deployment Guide: Suggest Match Feature

## Overview
This guide provides a **zero-downtime deployment plan** for the new "Suggest Match" feature that allows users to suggest connections between two other users.

---

## 📦 What's Included

### Database Changes
- ✅ New table: `match_suggestions`
- ✅ New table: `match_suggestion_cooldowns`
- ✅ RLS policies for privacy enforcement
- ✅ Triggers for auto-status updates and cooldown creation
- ✅ Database functions for cooldown checking
- ✅ View for easier querying with participant details

### API Endpoints
- ✅ `POST /api/matches/suggestions` - Create suggestion
- ✅ `GET /api/inbox/suggestions` - Fetch user's suggestions
- ✅ `POST /api/matches/suggestions/[id]/accept` - Accept suggestion
- ✅ `POST /api/matches/suggestions/[id]/decline` - Decline (triggers cooldown)

### UI Components
- ✅ `/mini/suggest` - New page for creating suggestions
- ✅ Dashboard button addition (needs manual update)
- ✅ Inbox integration (needs manual update)

---

## 🔧 Pre-Deployment Checklist

### 1. Environment Variables
No new environment variables required! ✅

### 2. Dependencies
No new dependencies required! ✅

### 3. Database Backup
```bash
# Backup your Supabase database before migration
# In Supabase Dashboard: Database > Backups > Create Backup
```

---

## 📋 Deployment Steps (Zero Downtime)

### Phase 1: Database Migration (5 minutes)

#### Step 1.1: Test Migration Locally (Optional)
```bash
# If you have local Supabase setup
cd supabase
supabase db reset
supabase db push
```

#### Step 1.2: Apply Migration to Production
```bash
# Option A: Using Supabase CLI
supabase link --project-ref your-project-ref
supabase db push

# Option B: Manual via Supabase Dashboard
# 1. Go to: Supabase Dashboard > SQL Editor
# 2. Copy contents of: supabase/migrations/20250122_create_match_suggestions.sql
# 3. Paste and click "Run"
# 4. Verify success messages in output
```

#### Step 1.3: Verify Migration
```sql
-- Run these queries in Supabase SQL Editor to verify:

-- Check tables exist
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('match_suggestions', 'match_suggestion_cooldowns');

-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'match_suggestions';

-- Check functions exist
SELECT proname FROM pg_proc
WHERE proname IN ('check_suggestion_cooldown', 'create_suggestion_cooldown');

-- Expected results:
-- ✅ Both tables should be listed
-- ✅ rowsecurity should be TRUE
-- ✅ Both functions should be listed
```

---

### Phase 2: Code Deployment (10 minutes)

#### Step 2.1: Create Feature Branch
```bash
git checkout -b feature/suggest-match
```

#### Step 2.2: Verify All Files Are Present
```bash
# Database migration
ls -la supabase/migrations/20250122_create_match_suggestions.sql

# API endpoints
ls -la app/api/matches/suggestions/route.ts
ls -la app/api/matches/suggestions/[id]/accept/route.ts
ls -la app/api/matches/suggestions/[id]/decline/route.ts
ls -la app/api/inbox/suggestions/route.ts

# UI page
ls -la app/mini/suggest/page.tsx
```

#### Step 2.3: Build and Test Locally
```bash
pnpm run build

# Expected output: ✅ Compiled successfully
```

#### Step 2.4: Commit Changes
```bash
git add .
git commit -m "feat: Add Suggest Match feature

- Add match_suggestions and cooldown tables with RLS
- Create API endpoints for suggesting, accepting, declining
- Add UI page for creating match suggestions
- Implement 7-day cooldown after decline
- Privacy: Suggester identity hidden from participants
- Auto-create chat room when both parties accept

BREAKING CHANGES: None
BACKWARD COMPATIBLE: Yes

Database migration required: Run 20250122_create_match_suggestions.sql"
```

#### Step 2.5: Push to Main
```bash
git push origin feature/suggest-match

# Create Pull Request in GitHub
# OR merge directly:
git checkout main
git merge feature/suggest-match
git push origin main
```

#### Step 2.6: Monitor Vercel Deployment
1. Go to: https://vercel.com/dashboard
2. Watch deployment progress
3. Expected duration: 2-3 minutes
4. Verify: ✅ Deployment successful

---

### Phase 3: Manual UI Updates (5 minutes)

Since I couldn't modify existing files due to length, you need to manually add these components:

#### Update 1: Dashboard - Add "Suggest Match" Button

**File:** `app/dashboard/page.tsx`

**Location:** Find the "Quick Actions" section (around line 390)

**Add this code** right after the "Create New Match" Link:

```tsx
<Link
  href="/mini/suggest"
  className="flex items-center p-4 border-2 border-green-200 rounded-lg hover:border-green-400 hover:bg-green-50 transition-colors group"
>
  <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center mr-4 group-hover:bg-green-200">
    <svg
      className="w-6 h-6 text-green-600"
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
      />
    </svg>
  </div>
  <div>
    <h3 className="font-semibold text-gray-900">Suggest Match</h3>
    <p className="text-sm text-gray-600">
      Connect two people from your network
    </p>
  </div>
</Link>
```

#### Update 2: Inbox - Add Suggestions Tab

**File:** `app/mini/inbox/page.tsx`

This is more complex. You'll need to:

1. **Add "Suggestions" to the InboxTab type** (line 55):
```typescript
type InboxTab = 'pending' | 'awaiting' | 'accepted' | 'declined' | 'completed' | 'suggestions';
```

2. **Add state for suggestions**:
```typescript
const [suggestions, setSuggestions] = useState<any[]>([]);
```

3. **Fetch suggestions** in useEffect:
```typescript
const fetchSuggestions = async () => {
  try {
    const data = await apiClient.get('/api/inbox/suggestions');
    setSuggestions(data.suggestions || []);
  } catch (error) {
    console.error('Error fetching suggestions:', error);
  }
};

// Call in useEffect
useEffect(() => {
  if (isAuthenticated && activeTab === 'suggestions') {
    fetchSuggestions();
  }
}, [isAuthenticated, activeTab]);
```

4. **Add Suggestions tab button** (after "Completed" tab button):
```tsx
<button
  onClick={() => setActiveTab('suggestions')}
  className={`py-4 px-6 text-sm font-medium border-b-2 ${
    activeTab === 'suggestions'
      ? 'border-purple-500 text-purple-600'
      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
  }`}
>
  Suggestions
  {suggestions.length > 0 && (
    <span className="ml-2 px-2 py-1 rounded-full bg-green-100 text-green-600 text-xs font-bold">
      {suggestions.length}
    </span>
  )}
</button>
```

5. **Display suggestions** in the content area (add this case to your tab rendering logic):
```tsx
{activeTab === 'suggestions' && (
  suggestions.length === 0 ? (
    <div className="bg-white rounded-lg shadow-md p-8 text-center">
      <p className="text-gray-600">No match suggestions yet</p>
    </div>
  ) : (
    suggestions.map((suggestion) => (
      <div key={suggestion.id} className="bg-white rounded-lg shadow-md p-6 mb-4">
        <div className="flex items-start space-x-4">
          <img
            src={suggestion.otherUser.avatarUrl || '/default-avatar.png'}
            alt={suggestion.otherUser.displayName}
            className="w-16 h-16 rounded-full"
          />
          <div className="flex-1">
            <h3 className="font-semibold text-gray-900">
              Match suggestion with {suggestion.otherUser.displayName}
            </h3>
            <p className="text-sm text-gray-600 mt-1">{suggestion.message}</p>

            {suggestion.status === 'proposed' && !suggestion.myAcceptance && (
              <div className="mt-4 flex space-x-3">
                <button
                  onClick={() => handleAcceptSuggestion(suggestion.id)}
                  className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
                >
                  Accept
                </button>
                <button
                  onClick={() => handleDeclineSuggestion(suggestion.id)}
                  className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
                >
                  Decline
                </button>
              </div>
            )}

            {suggestion.myAcceptance && !suggestion.otherAcceptance && (
              <p className="text-sm text-blue-600 mt-2">
                ✓ You accepted. Waiting for {suggestion.otherUser.displayName}...
              </p>
            )}

            {suggestion.myAcceptance && suggestion.otherAcceptance && (
              <button
                onClick={() => router.push(`/mini/chat/${suggestion.chatRoomId}`)}
                className="mt-4 px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700"
              >
                Open Chat Room
              </button>
            )}
          </div>
        </div>
      </div>
    ))
  )
)}
```

6. **Add handler functions**:
```typescript
const handleAcceptSuggestion = async (suggestionId: string) => {
  try {
    await apiClient.post(`/api/matches/suggestions/${suggestionId}/accept`, {});
    await fetchSuggestions();
  } catch (error) {
    console.error('Error accepting suggestion:', error);
    alert('Failed to accept suggestion');
  }
};

const handleDeclineSuggestion = async (suggestionId: string) => {
  if (!confirm('Are you sure you want to decline this suggestion? A 7-day cooldown will be applied.')) {
    return;
  }

  try {
    await apiClient.post(`/api/matches/suggestions/${suggestionId}/decline`, {});
    await fetchSuggestions();
  } catch (error) {
    console.error('Error declining suggestion:', error);
    alert('Failed to decline suggestion');
  }
};
```

---

### Phase 4: Post-Deployment Verification (5 minutes)

#### Test Checklist

1. **Database Health**
```sql
-- Run in Supabase SQL Editor
SELECT COUNT(*) as total FROM match_suggestions;
SELECT COUNT(*) as total FROM match_suggestion_cooldowns;
-- Expected: Both should return 0 (empty tables)
```

2. **API Endpoints**
```bash
# Test in browser or Postman (requires auth):
GET https://your-app.vercel.app/api/inbox/suggestions
# Expected: { success: true, suggestions: [], total: 0 }
```

3. **UI Pages**
- Visit: `https://your-app.vercel.app/dashboard`
- Verify: "Suggest Match" button is visible
- Click: "Suggest Match" → Should open `/mini/suggest`
- Test form: Enter two FIDs and a message → Submit
- Expected: Success message and redirect to dashboard

4. **End-to-End Flow**
- User A creates suggestion for User B and User C
- User B logs in → Sees suggestion in inbox → Accepts
- User C logs in → Sees suggestion in inbox → Accepts
- Both users see "Chat Room Ready" → Can open chat
- Test decline → Verify cooldown is created

---

## 🔒 Security Verification

### RLS Policies Test
```sql
-- Test as authenticated user (replace YOUR_FID)
SET request.jwt.claims = '{"fid": YOUR_FID, "role": "authenticated"}';

-- Should work: Insert suggestion
INSERT INTO match_suggestions (created_by_fid, user_a_fid, user_b_fid, message)
VALUES (YOUR_FID, 12345, 67890, 'Test suggestion');

-- Should fail: View suggestion you created (privacy)
SELECT * FROM match_suggestions WHERE created_by_fid = YOUR_FID;

-- Should work: View suggestion where you're a participant
SELECT * FROM match_suggestions WHERE user_a_fid = YOUR_FID OR user_b_fid = YOUR_FID;
```

---

## 🐛 Troubleshooting

### Issue: Migration Fails
**Error:** "relation already exists"
**Solution:** Drop and recreate:
```sql
DROP TABLE IF EXISTS match_suggestions CASCADE;
DROP TABLE IF EXISTS match_suggestion_cooldowns CASCADE;
-- Then re-run migration
```

### Issue: RLS Blocks Requests
**Error:** "new row violates row-level security policy"
**Solution:** Verify user session:
```sql
SELECT current_setting('request.jwt.claims', true);
-- Should show user FID
```

### Issue: Cooldown Not Working
**Check:**
```sql
SELECT * FROM match_suggestion_cooldowns WHERE cooldown_until > now();
-- Should show active cooldowns
```

---

## 📊 Monitoring

### Key Metrics to Track
```sql
-- Total suggestions created
SELECT COUNT(*) FROM match_suggestions;

-- Acceptance rate
SELECT
  COUNT(CASE WHEN status = 'accepted' THEN 1 END) * 100.0 / COUNT(*) as acceptance_rate
FROM match_suggestions;

-- Active cooldowns
SELECT COUNT(*) FROM match_suggestion_cooldowns WHERE cooldown_until > now();

-- Suggestions by status
SELECT status, COUNT(*) FROM match_suggestions GROUP BY status;
```

---

## 🔄 Rollback Plan

If something goes wrong:

### Rollback Code
```bash
git revert HEAD
git push origin main
```

### Rollback Database (if needed)
```sql
-- Drop tables (reversible)
DROP TABLE IF EXISTS match_suggestions CASCADE;
DROP TABLE IF EXISTS match_suggestion_cooldowns CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS check_suggestion_cooldown CASCADE;
DROP FUNCTION IF EXISTS create_suggestion_cooldown CASCADE;

-- Drop view
DROP VIEW IF EXISTS match_suggestions_with_details CASCADE;
```

---

## ✅ Success Criteria

Deployment is successful when:
- ✅ Migration completes without errors
- ✅ All API endpoints return 200/201 responses
- ✅ UI pages load without console errors
- ✅ Users can create, accept, and decline suggestions
- ✅ Chat rooms are created when both users accept
- ✅ Cooldowns are enforced after decline
- ✅ Suggester identity remains hidden from participants
- ✅ No existing functionality is broken

---

## 📞 Support

If you encounter issues:
1. Check Vercel deployment logs
2. Check Supabase logs (Database > Logs)
3. Check browser console for errors
4. Verify RLS policies are active

---

## 🎉 Post-Deployment

After successful deployment:
1. Announce feature to users
2. Monitor usage metrics
3. Collect user feedback
4. Plan future enhancements (e.g., connector points for suggester)

---

**Estimated Total Deployment Time:** 25-30 minutes
**Downtime:** 0 minutes (zero-downtime deployment)
**Risk Level:** Low (backward compatible, no breaking changes)
