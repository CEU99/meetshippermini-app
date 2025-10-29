# User List Filtering System

## Overview

The `/users` (Explore) page now filters the user list to show only registered MeetShipper members, hiding external-only Farcaster users from the directory.

## Problem Solved

**Before:**
- All users in the database were shown in the Explore page
- External Farcaster users (never logged in) appeared alongside actual MeetShipper members
- Cluttered user directory with profiles that had never engaged with the app

**After:**
- Only users with `has_joined_meetshipper = true` are shown
- Clean, focused directory of actual MeetShipper community members
- External users remain hidden but can still receive match notifications
- Admin toggle available for debugging

## Implementation

### 1. API Route Update (`app/api/users/route.ts`)

#### Default Behavior (Filtered)

```typescript
// Filter by has_joined_meetshipper = true by default
if (!showAll) {
  query = query.eq('has_joined_meetshipper', true);
}
```

**Result:** Only registered MeetShipper members returned in API response

#### Admin Mode (`?showAll=true`)

```typescript
const showAll = searchParams.get('showAll') === 'true';

if (showAll) {
  // Show ALL users including external
  console.log('[API Users] Admin mode: showing all users');
}
```

**Usage:**
```
GET /api/users                  → Only registered members
GET /api/users?showAll=true     → All users (including external)
```

#### API Response Format

```json
{
  "users": [
    {
      "fid": 12345,
      "username": "alice",
      "display_name": "Alice",
      "avatar_url": "...",
      "bio": "...",
      "user_code": "ABC123",
      "has_joined_meetshipper": true,
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-01-20T14:25:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 42,
    "totalPages": 3
  },
  "filters": {
    "showAll": false,
    "onlyJoinedUsers": true
  }
}
```

**New Fields:**
- `has_joined_meetshipper` - Boolean flag in user object
- `filters` - Metadata showing applied filters

### 2. Frontend Update (`app/users/page.tsx`)

#### URL Parameter Support

```typescript
const showAll = searchParams.get('showAll') === 'true';

// Pass to API
if (showAll) {
  params.append('showAll', 'true');
}
```

#### Info Banner

**Normal Mode:**
```
ℹ️ Showing only registered MeetShipper members.
   External Farcaster users are excluded.
```

**Admin Mode:**
```
🔧 Admin Mode: Showing ALL users (including external Farcaster users).
   Remove ?showAll=true to see only registered members.
```

**Visual Styling:**
- Normal: Blue background (`bg-blue-50`)
- Admin: Orange background (`bg-orange-50`) for clear distinction

#### TypeScript Interface

```typescript
interface User {
  fid: number;
  username: string;
  display_name?: string;
  avatar_url?: string;
  bio?: string;
  user_code?: string;
  has_joined_meetshipper?: boolean; // ✅ Added
  created_at?: string;
  updated_at?: string;
}
```

## User Visibility Matrix

| User Type | has_joined_meetshipper | Visible in /users | Visible with ?showAll=true | Can Receive Matches |
|-----------|------------------------|-------------------|----------------------------|---------------------|
| Registered Member | `true` | ✅ Yes | ✅ Yes | ✅ Yes (in-app) |
| External Farcaster | `false` | 🚫 No | ✅ Yes | ✅ Yes (Farcaster DM) |

## Examples

### Example 1: Normal User View

**URL:** `/users`

**Database:**
```sql
users table:
├─ alice (has_joined_meetshipper = true)   ✅ SHOWN
├─ bob (has_joined_meetshipper = true)     ✅ SHOWN
├─ charlie (has_joined_meetshipper = false) ❌ HIDDEN
└─ david (has_joined_meetshipper = false)  ❌ HIDDEN
```

**Result:** Alice and Bob appear in the list

### Example 2: Admin Debug View

**URL:** `/users?showAll=true`

**Database:** (same as above)

**Result:** Alice, Bob, Charlie, and David all appear in the list

**Banner:**
```
🔧 Admin Mode: Showing ALL users (including external Farcaster users).
   Remove ?showAll=true to see only registered members.
```

### Example 3: Search with Filter

**URL:** `/users?search=alice`

**Query:**
```sql
SELECT * FROM users
WHERE has_joined_meetshipper = true
  AND (username ILIKE '%alice%' OR display_name ILIKE '%alice%')
```

**Result:** Only registered members matching "alice"

**URL:** `/users?search=alice&showAll=true`

**Query:**
```sql
SELECT * FROM users
WHERE (username ILIKE '%alice%' OR display_name ILIKE '%alice%')
-- No has_joined_meetshipper filter
```

**Result:** All users matching "alice" (including external)

## Testing

### Test Case 1: Default Filtered View

**Steps:**
1. Navigate to `/users`
2. Check the user list

**Expected:**
- ✅ Only users with `has_joined_meetshipper = true` visible
- ✅ Blue info banner shows: "Showing only registered MeetShipper members"
- ✅ External users (e.g., shortshipper, alexgrover) are hidden

**Verify:**
```sql
SELECT username, has_joined_meetshipper
FROM users
WHERE has_joined_meetshipper = true
ORDER BY updated_at DESC;
```

### Test Case 2: Admin Mode

**Steps:**
1. Navigate to `/users?showAll=true`
2. Check the user list

**Expected:**
- ✅ ALL users visible (internal + external)
- ✅ Orange info banner shows: "🔧 Admin Mode"
- ✅ External users now appear in the list

**Verify:**
```sql
SELECT username, has_joined_meetshipper
FROM users
ORDER BY updated_at DESC;
```

### Test Case 3: Search with Filter

**Steps:**
1. Navigate to `/users`
2. Search for a username that exists with `has_joined_meetshipper = false`

**Expected:**
- ✅ Search returns no results (user is filtered out)

**Steps:**
1. Navigate to `/users?showAll=true`
2. Search for the same username

**Expected:**
- ✅ Search returns the external user

### Test Case 4: Real-Time Updates

**Steps:**
1. External user logs in to MeetShipper
2. Their `has_joined_meetshipper` is updated to `true`
3. Refresh `/users` page

**Expected:**
- ✅ User now appears in the filtered list
- ✅ User was visible before in admin mode, now visible in normal mode too

## API Behavior

### Server Logs

**Normal Request:**
```
[API Users] Fetching users - showAll: false
[API Users] Filtering for has_joined_meetshipper = true
[API Users] Found 42 users
```

**Admin Request:**
```
[API Users] Fetching users - showAll: true
[API Users] Admin mode: showing all users (including external)
[API Users] Found 156 users
```

### Performance Considerations

**With Filter:**
- Smaller result set
- Faster queries
- Better user experience

**Without Filter (Admin):**
- Larger result set
- May be slower with many external users
- Only for debugging

## Benefits

✅ **Cleaner User Directory**
- Only shows actual MeetShipper community members
- No clutter from external-only profiles

✅ **Better User Experience**
- Users see relevant profiles
- Easier to find and connect with active members

✅ **Accurate Representation**
- User count reflects actual app adoption
- Community metrics are meaningful

✅ **Admin Debugging**
- `?showAll=true` lets admins see external users
- Useful for testing and troubleshooting

✅ **Consistent with Notification Logic**
- External users get Farcaster notifications
- Internal users shown in directory and get in-app notifications

## Related Systems

This filtering integrates with:

1. **External User Handling** (`EXTERNAL-USER-HANDLING.md`)
   - Uses `has_joined_meetshipper` flag
   - External users created with `false` flag

2. **Match Creation** (`app/api/matches/manual/route.ts`)
   - External users can still receive match requests
   - Notifications sent via Farcaster

3. **User Authentication** (`app/api/auth/session/route.ts`)
   - Sets `has_joined_meetshipper = true` on login
   - Transitions external → internal user

## Monitoring

### Query User Statistics

**Count by User Type:**
```sql
SELECT
  CASE
    WHEN has_joined_meetshipper = true THEN 'Registered Members'
    WHEN has_joined_meetshipper = false THEN 'External Farcaster Users'
  END as user_type,
  COUNT(*) as count
FROM users
GROUP BY has_joined_meetshipper;
```

**Recently Joined Members:**
```sql
SELECT username, created_at
FROM users
WHERE has_joined_meetshipper = true
ORDER BY created_at DESC
LIMIT 10;
```

**External Users with Activity:**
```sql
SELECT u.username, COUNT(m.id) as match_count
FROM users u
LEFT JOIN matches m ON (u.fid = m.user_b_fid)
WHERE u.has_joined_meetshipper = false
GROUP BY u.username
HAVING COUNT(m.id) > 0
ORDER BY match_count DESC;
```

## Troubleshooting

### Issue: User logged in but not appearing in list

**Check:**
```sql
SELECT fid, username, has_joined_meetshipper
FROM users
WHERE username = '<username>';
```

**Fix if `has_joined_meetshipper = false`:**
```sql
UPDATE users
SET has_joined_meetshipper = true
WHERE username = '<username>';
```

### Issue: External user appearing in normal view

**Cause:** Flag incorrectly set to `true`

**Fix:**
```sql
UPDATE users
SET has_joined_meetshipper = false
WHERE fid = <external_user_fid>
  AND last_login_at IS NULL;
```

### Issue: Need to see all users temporarily

**Solution:** Use admin mode
```
/users?showAll=true
```

## Future Enhancements

### Potential Improvements

1. **User Status Badges**
   - Visual indicator for external users in admin mode
   - Show "🟢 Active Member" vs "🟤 External Profile"

2. **Filter Toggle UI**
   - Button to switch between filtered/all views
   - No need to manually edit URL

3. **Advanced Filters**
   - Filter by join date
   - Filter by activity level
   - Filter by match count

4. **Export Functionality**
   - Export filtered user list
   - CSV/JSON download

5. **Bulk Actions**
   - Bulk update `has_joined_meetshipper`
   - Bulk cleanup of inactive external users

## Related Documentation

- `EXTERNAL-USER-HANDLING.md` - External user system architecture
- `supabase-schema.sql` - Database schema with `has_joined_meetshipper` column
- `app/api/users/route.ts` - API implementation
- `app/users/page.tsx` - Frontend implementation

---

**Last Updated:** 2025-10-29
**Version:** 1.0.0
**Status:** ✅ Production Ready
