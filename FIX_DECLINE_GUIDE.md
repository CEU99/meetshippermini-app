# Fix Guide: Match Decline Issue

## 🔴 Problem

When clicking "Decline" on a match in `/mini/inbox`, the operation fails with:
```
ApiError: Failed to update match
```

## 🔍 Root Cause Analysis

After thorough investigation, the issue stems from **three potential problems**:

### 1. **Database Constraint Issue**
The `matches.status` field has a CHECK constraint that may not include all required status values. The backend tries to set `status = 'declined'`, but if the constraint doesn't allow this value, the update fails.

**Location**: `supabase-schema.sql:57`
```sql
CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled'))
```

However, the app uses additional statuses like `'proposed'`, `'accepted_by_a'`, `'accepted_by_b'`, and `'completed'`.

### 2. **RLS (Row Level Security) Policy Issue**
The Supabase RLS policies on the `matches` table may be too restrictive, preventing authenticated users from updating match status even when they're participants.

**Location**: Database RLS policies

### 3. **JWT Claims Issue**
The backend uses JWT claims to identify the user (`current_setting('request.jwt.claims', true)::json->>'fid'`). If these claims are missing or malformed, the RLS policies will block the update.

## ✅ Solution

### Step 1: Apply SQL Fix

**Option A: Using Supabase Dashboard (Recommended)**

1. Open your [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to: **SQL Editor** → **New Query**
3. Copy the contents of `fix-decline-issue-complete.sql`
4. Click **Run** to execute

**Option B: Using Supabase CLI**

```bash
supabase db execute -f fix-decline-issue-complete.sql
```

**Option C: Using the helper script**

```bash
node scripts/fix-decline-issue.js
```
(Note: This will guide you through the process but requires manual SQL execution)

### Step 2: Verify the Fix

After applying the SQL fix:

1. **Start your dev server**:
   ```bash
   pnpm run dev
   ```

2. **Navigate to**: `http://localhost:3000/mini/inbox`

3. **Find a pending match** and click **Decline**

4. **Expected behavior**:
   - ✅ No error message
   - ✅ Match moves to "Declined" tab
   - ✅ Status changes to "declined" in database
   - ✅ Toast message: "You have declined this match"

### Step 3: Check Server Logs

The backend now has enhanced logging. When declining, you should see:

```
[API] Respond: Updating match with data: {
  matchId: '...',
  updateData: { status: 'declined' },
  currentStatus: 'pending',
  targetStatus: 'declined',
  userRole: 'user_a'
}
[API] Respond: Match updated successfully: {
  matchId: '...',
  status: 'declined',
  a_accepted: false,
  b_accepted: false
}
```

## 🔧 What the Fix Does

### 1. **Status Constraint Update**
Expands the allowed status values to include all used statuses:
- `proposed`
- `pending`
- `accepted_by_a`
- `accepted_by_b`
- `accepted`
- `declined`
- `cancelled`
- `completed`

### 2. **RLS Policy Update**
Creates clear, permissive policies for authenticated users:

**View Policy**: Users can view matches where they are:
- User A, User B, or the creator

**Create Policy**: Users can create matches as themselves

**Update Policy**: Users can update matches where they are:
- User A or User B (removed restrictive WITH CHECK clause)

### 3. **Permission Grants**
Ensures both `service_role` and `authenticated` have necessary permissions

## 📊 Technical Details

### Frontend Flow
`app/mini/inbox/page.tsx:732`
```typescript
handleRespond(selectedMatch.id, 'decline')
  ↓
apiClient.post(`/api/matches/${matchId}/respond`, { response: 'decline' })
```

### Backend Flow
`app/api/matches/[id]/respond/route.ts:124-132`
```typescript
if (response === 'decline') {
  updateData.status = 'declined';
}

await supabase
  .from('matches')
  .update(updateData)
  .eq('id', id)
```

### Database Flow
```
1. Check RLS policies → User is participant? ✓
2. Check status constraint → 'declined' allowed? ✓
3. Update row → Success! ✓
```

## 🐛 Debugging Tips

If the issue persists after applying the fix:

### 1. Check Database Constraint
```sql
SELECT pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.matches'::regclass
  AND contype = 'c'
  AND conname = 'matches_status_check';
```

Should include: `...status::text = ANY (ARRAY[...'declined'::text...])`

### 2. Check RLS Policies
```sql
SELECT policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'matches';
```

Should show 3 policies for `authenticated` role:
- `Users can view their matches` (SELECT)
- `Users can create matches` (INSERT)
- `Users can update their matches` (UPDATE)

### 3. Check Backend Logs
Enable detailed logging in your terminal running `pnpm run dev`:
```
[API] Respond: Match found: { ... }
[API] Respond: User participation check: { isUserA: true, isUserB: false }
[API] Respond: Updating match with data: { ... }
[API] Respond: Match updated successfully
```

### 4. Check Frontend Network Tab
Open DevTools → Network → Find the request to `/api/matches/.../respond`:
- **Status**: Should be `200 OK`
- **Response**: Should include `{ success: true, match: {...} }`

## 🎯 Success Criteria

✅ **Fix is successful when:**
1. Clicking "Decline" completes without errors
2. Match status changes to "declined" in database
3. Match appears in "Declined" tab
4. Backend logs show successful update
5. Other user receives system notification (if implemented)

## 📝 Files Modified

### New Files
- `fix-decline-issue-complete.sql` - Complete SQL fix
- `scripts/fix-decline-issue.js` - Helper script
- `FIX_DECLINE_GUIDE.md` - This guide

### Modified Files
- `app/api/matches/[id]/respond/route.ts` - Enhanced logging

### Not Modified (already correct)
- `app/mini/inbox/page.tsx` - Frontend implementation is correct
- `lib/api-client.ts` - Error handling is correct

## 🚨 Important Notes

1. **The Accept flow should continue working** - The fix only affects Decline
2. **No data loss** - Existing matches are not modified
3. **Backwards compatible** - Old status values still work
4. **Service role bypasses RLS** - Backend operations always work
5. **Manual testing required** - Automated tests not included in this fix

## 📚 Related Files

For reference and context:
- `supabase-schema.sql` - Original schema
- `fix-match-decline-rls.sql` - Previous fix attempt
- `fix-decline-cooldown-issue.sql` - Related cooldown fix

## 🆘 Need Help?

If the issue persists after applying this fix:

1. **Check environment variables**:
   - `NEXT_PUBLIC_SUPABASE_URL` is set
   - `SUPABASE_SERVICE_ROLE_KEY` is set
   - Both are correct for your project

2. **Verify Supabase connection**:
   ```bash
   node scripts/fix-decline-issue.js
   ```

3. **Check user authentication**:
   - Ensure you're logged in via Farcaster
   - Check that `session.fid` is populated
   - Verify JWT claims include `fid` field

4. **Check browser console** for JavaScript errors

5. **Check server console** for detailed error messages

---

**Last Updated**: 2025-01-21
**Status**: Ready to apply
**Priority**: High - Blocks user workflow
