# Profile Enhancements - Setup Guide

## Overview

This guide explains the new profile features that allow users to:
- Edit their bio (up to 500 characters)
- Select 5-10 personal traits from a predefined list of 50 traits
- Display their bio and traits on the Dashboard

## Features Implemented

### 1. Bio Section
- Users can write a short bio (max 500 characters)
- Bio is displayed on the Dashboard under the username
- Editable through the "Edit Profile" page

### 2. Personal Traits (Tags)
- Users select 5-10 traits from 50 predefined options
- Traits are categorized by color based on type:
  - **Blue**: Trading focused (Trader, Scalper, Chartist, etc.)
  - **Green**: Investment focused (Investor, Hodler, Whale, etc.)
  - **Purple**: Airdrop/Reward focused (Airdropper, Drop-sniper, etc.)
  - **Yellow**: Analysis/Strategy focused (Analyst, Signal-maker, etc.)
  - **Pink**: Visionary/Builder focused (Visionary, Pioneer, Builder, etc.)
  - **Indigo**: DeFi/Platform focused (DeFi-explorer, DEX-nomad, etc.)
  - **Orange**: Community/Social focused (Social-miner, Meme-king, etc.)
  - **Red**: Personality focused (Degen, Opportunist, etc.)
- Displayed as colorful trait cards on the Dashboard
- Managed through the "Edit Profile" page

---

## Setup Instructions

### Step 1: Run the Database Migration

**CRITICAL**: You MUST run this SQL in your Supabase dashboard.

1. Go to your Supabase project: https://supabase.com/dashboard
2. Select your project (`meetshipper`)
3. Click **SQL Editor** in the left sidebar
4. Click "New Query"
5. Open the file `supabase-add-profile-fields.sql`
6. Copy ALL the SQL code
7. Paste it into the Supabase SQL Editor
8. Click **RUN** or press Ctrl/Cmd + Enter

**What this does:**
- Adds `bio` column (TEXT) if it doesn't exist
- Adds `traits` column (JSONB array)
- Creates constraints:
  - Ensures traits is always a JSON array
  - Limits traits to 0-10 items
- Creates GIN index on traits for faster queries
- Adds column comments for documentation

### Step 2: Verify the Migration

Run this query in Supabase SQL Editor to verify:

```sql
-- Check columns exist
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'users' AND column_name IN ('bio', 'traits');
```

Expected results:
- `bio` column exists with type `text`
- `traits` column exists with type `jsonb` and default `'[]'::jsonb`

### Step 3: Test the Features

1. **Clear your browser session:**
   - Sign out if you're logged in
   - Clear browser cookies (or use incognito mode)

2. **Sign in with Farcaster:**
   - Go to http://localhost:3000
   - Click "Sign in with Farcaster"
   - Complete authentication

3. **Check the Dashboard:**
   - You should see an "Edit Profile" button next to your username
   - If you haven't set traits yet, no trait cards will be displayed

4. **Edit Your Profile:**
   - Click "Edit Profile" button
   - You'll be redirected to `/profile/edit`
   - Enter a bio (optional, max 500 characters)
   - Select 5-10 traits that describe you
   - Click "Save Profile"
   - You'll be redirected back to the Dashboard

5. **Verify Display:**
   - Dashboard should now show:
     - Your bio under your username
     - Colorful trait cards below your bio
     - "Personal Traits" label

---

## File Structure

### Database
- `supabase-add-profile-fields.sql` - Database migration for bio and traits

### Backend
- `lib/constants/traits.ts` - Predefined trait list and validation functions
- `lib/types.ts` - Updated FarcasterUser interface with traits field
- `lib/supabase.ts` - Updated User interface with traits field
- `app/api/profile/route.ts` - API routes for GET/PATCH profile

### Frontend
- `app/profile/edit/page.tsx` - Edit Profile page with bio textarea and trait selector
- `app/dashboard/page.tsx` - Updated Dashboard to display bio and traits
- `components/providers/FarcasterAuthProvider.tsx` - Updated to fetch traits

---

## How It Works

### Database Schema

```sql
ALTER TABLE users ADD COLUMN bio TEXT;
ALTER TABLE users ADD COLUMN traits JSONB DEFAULT '[]'::jsonb;
```

Traits are stored as a JSON array:
```json
["Trader", "Investor", "Alpha-hunter", "Smart-money", "Hodler"]
```

### API Endpoints

#### GET /api/profile
Fetches current user's profile including bio and traits.

**Response:**
```json
{
  "fid": 543581,
  "username": "cengizhaneu",
  "displayName": "Cengizhan",
  "pfpUrl": "https://...",
  "bio": "Crypto enthusiast and builder",
  "userCode": "0123456789",
  "traits": ["Trader", "Investor", "Builder", "Alpha-hunter", "Smart-money"]
}
```

#### PATCH /api/profile
Updates user's bio and/or traits.

**Request:**
```json
{
  "bio": "Crypto enthusiast and builder",
  "traits": ["Trader", "Investor", "Builder", "Alpha-hunter", "Smart-money"]
}
```

**Validation:**
- Bio: optional, max 500 characters
- Traits: required, 5-10 items, must be from predefined list

### Frontend Components

#### Edit Profile Page (`/profile/edit`)
- Bio textarea with character counter (500 max)
- Grid of 50 trait buttons
- Selected traits highlighted with colored backgrounds
- Real-time selection counter (X / 10)
- Save button (disabled if < 5 or > 10 traits selected)

#### Dashboard (`/dashboard`)
- "Edit Profile" button next to username
- Bio displayed below username
- Trait cards displayed in a flex-wrap grid
- Each trait card colored based on category

---

## Predefined Trait List (50 total)

### Trading & Markets
1. Trader
2. Investor
3. Scalper
4. Swinger
5. Sniper
6. Chartist
7. Candle-wizard
8. Graph-reader

### Crypto Strategy
9. Airdropper
10. Alpha-hunter
11. Drop-sniper
12. Smart-money
13. Hodler
14. Whale
15. Reward-hunter
16. Airfarmer

### Analysis & Intelligence
17. Analyst
18. Signal-maker
19. Market-seer
20. Data-driven
21. Thinker
22. Tactical-mind
23. Code-breaker

### Visionary & Building
24. Visionary
25. Pioneer
26. Builder
27. Speculator
28. Earlybird
29. Hidden-gem-finder

### DeFi & Platforms
30. DeFi-explorer
31. DEX-nomad
32. CEX-veteran
33. Wallet-hopper
34. Wallet-collector
35. Staking-warrior

### Community & Social
36. Social-miner
37. Meme-king
38. Launchpad-scout
39. Trend-catcher

### Personality & Approach
40. Degen
41. Opportunist
42. Adaptive-leader
43. Emotion-proof
44. Rational-ape
45. Silent-strategist
46. Token-seeker
47. Risk-manager
48. Growth-focused
49. Beta-chaser
50. Presale-hunter

---

## Validation Rules

### Bio
- **Type**: String
- **Min Length**: 0 (optional)
- **Max Length**: 500 characters
- **Validation**: Character count enforced in UI and backend

### Traits
- **Type**: Array of strings
- **Min Items**: 5
- **Max Items**: 10
- **Valid Values**: Must be from predefined AVAILABLE_TRAITS list
- **Uniqueness**: No duplicate traits allowed
- **Validation**: Enforced in UI (disabled save button) and backend (returns error)

---

## Troubleshooting

### Traits Not Displaying

**Symptoms:** Dashboard doesn't show trait cards after saving

**Solutions:**
1. Check if migration was run:
   ```sql
   SELECT * FROM users WHERE fid = YOUR_FID;
   ```
   The `traits` column should exist and contain data.

2. Check browser console for errors

3. Clear cookies and sign in again

4. Verify traits were saved:
   ```sql
   SELECT fid, username, traits FROM users WHERE fid = YOUR_FID;
   ```

### Can't Save Profile

**Symptoms:** Save button is disabled or shows error

**Solutions:**
1. Ensure you've selected 5-10 traits (check counter: "Selected: X / 10")

2. Check browser console for validation errors

3. Try refreshing the page and re-selecting traits

### Migration Failed

**Symptoms:** SQL error when running migration

**Solutions:**
1. Check if `users` table exists:
   ```sql
   SELECT * FROM users LIMIT 1;
   ```

2. If table doesn't exist, run `supabase-schema.sql` first

3. If columns already exist, that's fine - migration is idempotent

---

## Acceptance Criteria

✅ All checks should pass:
- [ ] Migration SQL has been run in Supabase
- [ ] `users.bio` column exists (TEXT type)
- [ ] `users.traits` column exists (JSONB type, default '[]')
- [ ] Constraints exist (array type, length 0-10)
- [ ] GIN index exists on traits column
- [ ] Dashboard shows "Edit Profile" button
- [ ] Edit Profile page loads and displays current bio/traits
- [ ] Bio textarea has 500 character limit
- [ ] 50 trait buttons are displayed
- [ ] Can select/deselect traits
- [ ] Save button disabled when < 5 or > 10 traits selected
- [ ] Profile saves successfully
- [ ] Dashboard displays bio and trait cards
- [ ] Trait cards are colored by category
- [ ] Backend validates bio length (max 500)
- [ ] Backend validates traits count (5-10)
- [ ] Backend validates traits are from allowed list

---

## Next Steps

After setup is complete:

1. Test with multiple users to verify uniqueness
2. Monitor Supabase logs for any errors
3. Consider adding:
   - Trait search/filter on Edit Profile page
   - Trait popularity statistics
   - User trait-based matching suggestions
   - Trait categories/groups in UI

---

## Support

If you encounter issues:

1. Check Supabase SQL Editor logs for migration errors
2. Check Next.js console for backend errors
3. Check browser console for frontend errors
4. Verify all migration steps completed successfully
5. Try the verification queries above
