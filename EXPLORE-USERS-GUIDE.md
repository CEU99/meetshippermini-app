# Explore Users Feature - Implementation Guide

## 🎯 Overview

The "Explore Users" feature allows authenticated users to browse all registered members of the Meet Shipper community, search by name/username, and view detailed user profiles.

---

## ✅ What Was Implemented

### 1. **Navigation Link**
- Added "Explore Users" to top navigation (`components/shared/Navigation.tsx:16`)
- Appears in both desktop and mobile menus
- Route: `/users`

### 2. **Users List Page** (`app/users/page.tsx`)
**Features:**
- Displays all registered users from `public.users` table
- Real-time search by name or username (debounced 300ms)
- Pagination (20 users per page)
- Responsive design (table on desktop, card list on mobile)
- Loading states with skeleton UI
- Empty state for no results

**Data Displayed:**
- Avatar (with fallback to initials)
- Display name / Username
- @username
- Bio (truncated preview)
- Farcaster ID (FID)
- User Code (10-digit unique code)
- "View Profile" button

**Realtime Updates:**
- Supabase Realtime subscription listens for:
  - INSERT events (new users) → refetches list
  - UPDATE events (profile changes) → updates specific user in list

### 3. **User Profile Page** (`app/users/[fid]/page.tsx`)
**Features:**
- Dynamic route: `/users/[fid]`
- Full profile view with:
  - Large avatar
  - Display name, username, bio
  - Personal traits (colored badges)
  - Farcaster ID, User Code, Member Since date
- Action buttons:
  - "Create Match" → links to `/mini/create?targetFid=[fid]`
  - "View on Warpcast" → opens Farcaster profile in new tab
- Back button to users list
- Error handling for invalid/missing profiles

### 4. **API Endpoints**

**`GET /api/users`** (`app/api/users/route.ts`)
- Fetches paginated list of users
- Query params:
  - `page` (default: 1)
  - `limit` (default: 20)
  - `search` (optional, filters by username/display_name)
- Returns: `{ users: User[], pagination: {...} }`
- Ordered by `updated_at DESC` (most recently active first)

**`GET /api/users/[fid]`** (`app/api/users/[fid]/route.ts`)
- Fetches single user profile by FID
- Returns: User object or 404 error

### 5. **RLS Policy** (`supabase-users-rls-policy.sql`)
- Enables Row Level Security on `public.users` table
- Policy: "Users can read all profiles"
  - Allows all authenticated users to SELECT from users table
  - Appropriate for social/matching app with public profiles

---

## 📁 Files Created/Modified

### Created Files (6):
1. `app/users/page.tsx` - Main users list page
2. `app/users/[fid]/page.tsx` - Individual user profile page
3. `app/api/users/route.ts` - API endpoint for users list
4. `app/api/users/[fid]/route.ts` - API endpoint for single user
5. `supabase-users-rls-policy.sql` - RLS policy for read access
6. `EXPLORE-USERS-GUIDE.md` - This file

### Modified Files (1):
1. `components/shared/Navigation.tsx` - Added "Explore Users" nav item

---

## 🚀 Setup Instructions

### Step 1: Enable RLS Policy (Required)

Run this in **Supabase SQL Editor**:

```sql
-- Paste entire contents of: supabase-users-rls-policy.sql
```

This enables authenticated users to read user profiles.

### Step 2: Start Development Server

```bash
npm run dev
# or
pnpm dev
```

### Step 3: Test the Feature

1. **Navigate to Users List:**
   - Click "Explore Users" in top nav
   - Or visit: `http://localhost:3000/users`

2. **Test Search:**
   - Type in the search bar
   - Should see filtered results after 300ms

3. **Test Pagination:**
   - If you have >20 users, pagination controls appear
   - Click page numbers or prev/next buttons

4. **View Profile:**
   - Click "View Profile" on any user
   - Should navigate to `/users/[fid]`

5. **Test Realtime (Optional):**
   - Open users list in two browser tabs
   - In Supabase, insert/update a user
   - Should see changes reflect in real-time

---

## 🎨 Styling & Design

### Color Scheme
- Primary: Purple (`purple-600`, `purple-50`, etc.)
- Matches existing app design system
- Consistent with Dashboard, Navigation, and other pages

### Responsive Breakpoints
- **Mobile (< 640px):** Card-based list layout
- **Desktop (≥ 640px):** Table layout with columns

### Components Used
- Tailwind CSS utility classes
- Next.js Image component (optimized images)
- Loading skeletons (animate-pulse)
- SVG icons (search, back arrow, external link)

---

## 🔍 Key Features Explained

### 1. Search with Debouncing

```typescript
// User types → wait 300ms → then search
useEffect(() => {
  const timer = setTimeout(() => {
    setDebouncedSearch(searchTerm);
    setPage(1); // Reset to page 1 on new search
  }, 300);
  return () => clearTimeout(timer);
}, [searchTerm]);
```

**Why:** Prevents excessive API calls while user is typing.

### 2. Realtime Subscription

```typescript
const channel = supabase
  .channel('users_changes')
  .on('postgres_changes', { event: 'INSERT', ... }, (payload) => {
    fetchUsers(); // Refetch list
  })
  .on('postgres_changes', { event: 'UPDATE', ... }, (payload) => {
    setUsers(prevUsers => /* update specific user */);
  })
  .subscribe();
```

**Why:** Users see new registrations and profile updates instantly without refreshing.

### 3. Pagination Logic

```typescript
// Calculate which page numbers to show (max 5 buttons)
if (pagination.totalPages <= 5) {
  pageNum = i + 1; // Show all pages
} else if (page <= 3) {
  pageNum = i + 1; // Show first 5
} else if (page >= pagination.totalPages - 2) {
  pageNum = pagination.totalPages - 4 + i; // Show last 5
} else {
  pageNum = page - 2 + i; // Show 2 before, current, 2 after
}
```

**Why:** Keeps pagination compact even with many pages.

---

## 🧪 Testing Checklist

- [ ] **Navigation:** "Explore Users" link appears in nav
- [ ] **Page Load:** Users list loads without errors
- [ ] **Search:** Typing filters results correctly
- [ ] **Pagination:** Can navigate between pages
- [ ] **Profile View:** Clicking "View Profile" opens correct user
- [ ] **Responsive:** Works on mobile and desktop
- [ ] **Loading States:** Skeleton UI shows while loading
- [ ] **Empty State:** Shows message when no users found
- [ ] **Error Handling:** Shows error message on API failure
- [ ] **Realtime (Optional):** New users appear automatically
- [ ] **RLS Policy:** No permission errors in console

---

## 🛠️ Troubleshooting

### Issue: "Failed to fetch users"

**Possible Causes:**
1. RLS policy not enabled
2. Supabase connection error
3. API route error

**Fix:**
1. Run `supabase-users-rls-policy.sql` in Supabase
2. Check `.env.local` has correct Supabase credentials
3. Check browser console and server logs for errors

### Issue: "User not found" on profile page

**Possible Causes:**
1. Invalid FID in URL
2. User doesn't exist in database

**Fix:**
1. Verify FID is a valid number
2. Check `public.users` table in Supabase

### Issue: Realtime updates not working

**Possible Causes:**
1. Supabase Realtime not enabled
2. RLS blocking realtime events

**Fix:**
1. Enable Realtime in Supabase Dashboard → Database → Replication
2. Ensure RLS policy allows SELECT

### Issue: Images not loading

**Possible Causes:**
1. Invalid avatar URLs
2. CORS issues

**Fix:**
1. Check avatar_url values in database
2. Fallback to initials (already implemented)

---

## 📊 Database Schema

The feature uses the `public.users` table:

```sql
CREATE TABLE public.users (
  fid BIGINT PRIMARY KEY,           -- Farcaster ID
  username TEXT NOT NULL,           -- @username
  display_name TEXT,                -- Display name
  avatar_url TEXT,                  -- Profile picture URL
  bio TEXT,                         -- User bio
  user_code TEXT,                   -- 10-digit unique code
  traits JSONB,                     -- Array of trait strings
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🔐 Security Notes

1. **RLS Policy:** Only authenticated users can access user data
2. **Service Role:** API routes use service_role key (bypasses RLS)
3. **Read-Only:** Users can only read profiles, not modify others
4. **Public Profiles:** All user profiles are visible to authenticated users
   - Appropriate for social/matching app
   - Change policy if you need private profiles

---

## 🎯 Future Enhancements

Potential features to add:

1. **Filters:**
   - Filter by traits
   - Filter by join date
   - Filter by activity status

2. **Sorting:**
   - Sort by name A-Z
   - Sort by join date (newest/oldest)
   - Sort by activity

3. **Profile Page:**
   - Match history with this user
   - Mutual friends/connections
   - Direct messaging
   - Match compatibility score

4. **Bulk Actions:**
   - Select multiple users
   - Batch invite to matches

5. **User Cards:**
   - Alternative card-based layout (like Tinder)
   - Infinite scroll instead of pagination

---

## 📝 Code Quality Notes

### Best Practices Used:

✅ **TypeScript:** Full type safety with interfaces
✅ **Error Handling:** Try-catch blocks, user-friendly error messages
✅ **Loading States:** Skeleton UI prevents layout shift
✅ **Debouncing:** Reduces API calls during search
✅ **Cleanup:** Removes Realtime subscriptions on unmount
✅ **Responsive:** Mobile-first design with breakpoints
✅ **Accessibility:** Semantic HTML, ARIA labels (sr-only)
✅ **Performance:** Image optimization with Next/Image

---

## 📚 Related Documentation

- [Auto-Match System](./README-AUTO-MATCH-FIX.md)
- [Supabase SQL Guide](./SUPABASE-SQL-GUIDE.md)
- [Quick Start](./QUICK-START-SUPABASE.md)

---

## ✅ Summary

**Feature:** Explore Users
**Status:** ✅ Complete
**Files Created:** 6
**Files Modified:** 1
**Test Status:** Ready for testing

**Next Steps:**
1. Run RLS policy SQL script in Supabase
2. Start dev server and test the feature
3. Report any issues or request enhancements

---

*Generated: 2025-10-20 | Status: Complete | Ready for Testing*
