# 🚀 MeetShipper: Realtime RLS Fix - Deployment Checklist

## Quick Start (5 Minutes)

### Step 1: Apply Database Migration ⚡
```bash
# Option A: Via Supabase Dashboard (Easiest)
1. Open: https://supabase.com/dashboard/project/YOUR_PROJECT/sql/new
2. Copy contents of: supabase/migrations/fix_realtime_rls_for_matches_and_chat.sql
3. Paste and click "Run"
4. Wait for success message ✅

# Option B: Via Supabase CLI
cd /Users/Cengizhan/Desktop/meetshippermini-app
supabase db push
```

### Step 2: Deploy Frontend Changes 🎨
```bash
# The frontend changes are already committed
# Just deploy to production:

# If using Vercel:
git push origin main

# If using another platform:
pnpm run build
# Then deploy the .next folder
```

### Step 3: Verify (2 Minutes) ✅

**Quick Test:**
1. Open two browser windows
2. Window 1: Login as User A
3. Window 2: Login as User B
4. Create match between A and B
5. Both accept the match
6. **Expected**: Both see "Open Chat" button at the same time ✅

---

## Detailed Verification

### Database Verification

Run in Supabase SQL Editor:

```sql
-- 1. Check realtime publication
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename IN ('matches', 'chat_rooms', 'messages');
-- Expected: 3 rows

-- 2. Check replica identity
SELECT tablename,
       CASE relreplident
           WHEN 'f' THEN '✅ FULL (correct)'
           ELSE '❌ NOT FULL (needs fix)'
       END as status
FROM pg_class
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE tablename IN ('matches', 'chat_rooms', 'messages')
  AND schemaname = 'public';
-- Expected: All should show "✅ FULL (correct)"

-- 3. Check RLS policies count
SELECT tablename, count(*) as policy_count
FROM pg_policies
WHERE tablename IN ('matches', 'chat_rooms', 'messages')
GROUP BY tablename
ORDER BY tablename;
-- Expected:
--   matches: 3+ policies
--   chat_rooms: 3+ policies
--   messages: 3+ policies
```

### Frontend Verification

**Check browser console logs:**

When User B accepts a match, User A's console should show:
```
[Inbox] Match status updated to accepted: {...}
[Inbox] Force refreshed matches after accepted update
```

---

## Pre-Deployment Checklist

- [ ] Database migration file exists: `supabase/migrations/fix_realtime_rls_for_matches_and_chat.sql`
- [ ] Frontend code updated: `app/mini/inbox/page.tsx` (line 165-168)
- [ ] Build passes: `pnpm run build` completes successfully ✅ (already verified)
- [ ] No TypeScript errors ✅
- [ ] Have Supabase dashboard access
- [ ] Have production deployment access

---

## Post-Deployment Checklist

- [ ] Database migration ran successfully (no errors in SQL editor)
- [ ] Realtime publication includes matches, chat_rooms, messages
- [ ] All tables have REPLICA IDENTITY FULL
- [ ] RLS policies are active
- [ ] Frontend deployed successfully
- [ ] Test with two users:
  - [ ] Both users see realtime updates
  - [ ] Both users see "Open Chat" button simultaneously
  - [ ] Both users can enter chat room
  - [ ] Messages appear in real-time for both users

---

## Rollback Plan (If Needed)

### If Database Migration Fails:

```sql
-- Drop the newly created policies
DROP POLICY IF EXISTS "Both participants can view match" ON matches;
DROP POLICY IF EXISTS "Users can update their match response" ON matches;
DROP POLICY IF EXISTS "Users can create matches" ON matches;
DROP POLICY IF EXISTS "Both participants can view chat room" ON chat_rooms;
DROP POLICY IF EXISTS "Both participants can update chat room" ON chat_rooms;
DROP POLICY IF EXISTS "System can create chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Both participants can view messages" ON messages;
DROP POLICY IF EXISTS "Both participants can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update messages in their rooms" ON messages;

-- Remove tables from publication
ALTER PUBLICATION supabase_realtime DROP TABLE matches;
ALTER PUBLICATION supabase_realtime DROP TABLE chat_rooms;
ALTER PUBLICATION supabase_realtime DROP TABLE messages;
```

### If Frontend Needs Rollback:

```bash
# Revert to previous commit
git revert HEAD
git push origin main
```

---

## Expected Timeline

| Step | Duration | Status |
|------|----------|--------|
| Apply database migration | 1 minute | ⏳ |
| Deploy frontend | 3-5 minutes | ⏳ |
| Verification | 2 minutes | ⏳ |
| **Total** | **6-8 minutes** | ⏳ |

---

## Support & Troubleshooting

### Issue: Migration fails with "policy already exists"

**Solution:** Some policies may already exist. Drop them first:
```sql
-- List existing policies
SELECT policyname FROM pg_policies WHERE tablename = 'matches';

-- Drop conflicting policies
DROP POLICY IF EXISTS "policy_name_here" ON matches;
```

Then re-run the migration.

### Issue: Realtime events not firing

**Solution 1:** Restart realtime in Supabase Dashboard:
- Go to Database → Replication
- Toggle off/on for affected tables

**Solution 2:** Check client-side realtime connection:
```typescript
// Add to inbox page useEffect
console.log('Realtime channel status:', channel.state);
```

### Issue: One user still can't see the button

**Check RLS with this query:**
```sql
-- Test as User A
SELECT id, status, user_a_fid, user_b_fid
FROM matches
WHERE id = 'your-match-id';
-- Should return the match
```

If no results, RLS policy is blocking. Verify user authentication:
```sql
SELECT auth.uid(), u.fid
FROM users u
WHERE u.id = auth.uid();
```

---

## Monitoring (Post-Deployment)

### Key Metrics to Watch

1. **Realtime Connection Success Rate**
   - Monitor frontend console logs
   - Look for successful subscription messages

2. **Match Acceptance Success Rate**
   - Both users should see status update within 1-2 seconds

3. **Chat Room Access Success Rate**
   - Both users should see "Open Chat" button
   - Both should be able to enter the room

### Error Monitoring

Watch for these in production logs:
- ❌ `RLS policy violation`
- ❌ `Permission denied for table matches`
- ❌ `Failed to subscribe to realtime channel`

---

## Success Criteria ✅

The deployment is successful when:

- [ ] Database migration completes without errors
- [ ] Frontend build passes (already verified ✅)
- [ ] Frontend deployed to production
- [ ] Both users receive realtime events
- [ ] Both users see "Open Chat" button simultaneously
- [ ] Chat room works for both participants
- [ ] Messages appear in real-time for both users
- [ ] No RLS violations in logs

---

## Contact

If you encounter issues:
1. Check `supabase/REALTIME_RLS_FIX.md` for detailed troubleshooting
2. Review Supabase logs in Dashboard
3. Check browser console for frontend errors

---

**Ready to deploy? Let's go! 🚀**
