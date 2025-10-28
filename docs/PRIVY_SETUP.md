# Farcaster Authentication via Privy - Setup Guide

This guide will help you integrate Farcaster-only authentication through Privy into your MeetShipper Next.js application.

## Prerequisites

- A Privy account (sign up at https://dashboard.privy.io/)
- A Farcaster account (needed for testing)
- Node.js and pnpm installed
- Next.js 13+ project

## Setup Steps

### 1. Create a Privy App

1. Go to https://dashboard.privy.io/
2. Sign up or log in to your account
3. Click "Create New App"
4. Fill in your app details:
   - App Name: MeetShipper (or your app name)
   - App URL: `http://localhost:3000` (for development)
5. Copy your **App ID** from the dashboard

### 1.5. Enable Farcaster Login Method

**IMPORTANT:** Before proceeding, you must enable Farcaster in your Privy dashboard:

1. In the Privy dashboard, go to your app
2. Navigate to **Settings** → **Login Methods**
3. Enable **Farcaster**
4. Save your changes

Without this step, users won't be able to sign in with Farcaster!

### 2. Configure Environment Variables

Add your Privy App ID to `.env.local`:

```bash
NEXT_PUBLIC_PRIVY_APP_ID=your_actual_privy_app_id_here
```

Replace `your_actual_privy_app_id_here` with the App ID from step 1.

### 3. Components Overview

The following components have been created for you:

#### PrivyProvider (`components/providers/PrivyProvider.tsx`)
- Wraps your app to provide Privy context
- Already integrated in `app/layout.tsx`
- Configures Privy with email and wallet login methods

#### SignInButton (`components/auth/SignInButton.tsx`)
- Displays "Sign in with Privy" button
- Hidden when user is already authenticated
- Shows helpful message if Privy is not configured

#### SignOutButton (`components/auth/SignOutButton.tsx`)
- Displays "Sign out" button
- Only visible when user is authenticated

#### UserProfile (`components/auth/UserProfile.tsx`)
- Shows user's avatar (generated initial)
- Displays user's email or wallet address
- Shows account details (ID, member since date)
- Includes sign-out button

### 4. Usage in Your App

The auth demo page is available at `/auth-demo`. To use Farcaster authentication in your own pages:

#### Using the `useFarcaster` Hook (Recommended)

```tsx
"use client";

import { useFarcaster } from "@/components/auth";
import { SignInButton, UserProfile } from "@/components/auth";

export default function MyPage() {
  const { isAuthenticated, isReady, hasFarcaster, fid, username, displayName, pfp } = useFarcaster();

  if (!isReady) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      {isAuthenticated && hasFarcaster ? (
        <>
          <h1>Welcome, {displayName || username}!</h1>
          <p>Your FID: {fid}</p>
          {pfp && <img src={pfp} alt={username} />}
          <UserProfile />
        </>
      ) : (
        <>
          <h1>Please sign in with Farcaster</h1>
          <SignInButton />
        </>
      )}
    </div>
  );
}
```

#### Using `usePrivy` Directly

```tsx
"use client";

import { usePrivy } from "@privy-io/react-auth";
import { SignInButton, UserProfile } from "@/components/auth";

export default function MyPage() {
  const { authenticated, ready, user } = usePrivy();
  const farcasterAccount = user?.farcaster;

  if (!ready) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      {authenticated && farcasterAccount ? (
        <>
          <h1>Welcome, @{farcasterAccount.username}!</h1>
          <p>FID: {farcasterAccount.fid}</p>
          <UserProfile />
        </>
      ) : (
        <>
          <h1>Please sign in</h1>
          <SignInButton />
        </>
      )}
    </div>
  );
}
```

### 5. Available Hooks and Data

#### `useFarcaster()` Hook

Custom hook that provides easy access to Farcaster data:

- `isAuthenticated`: Boolean indicating if user is logged in
- `isReady`: Boolean indicating if Privy has initialized
- `hasFarcaster`: Boolean indicating if user has Farcaster connected
- `fid`: User's Farcaster ID (number)
- `username`: Farcaster username (string)
- `displayName`: Farcaster display name (string)
- `pfp`: Profile picture URL (string)
- `bio`: User's Farcaster bio (string)
- `farcasterAccount`: Full Farcaster account object
- `user`: Full Privy user object

#### `usePrivy()` Hook

The standard Privy hook provides:

- `authenticated`: Boolean indicating if user is logged in
- `ready`: Boolean indicating if Privy has initialized
- `user`: User object with Farcaster data in `user.farcaster`
- `user.farcaster.fid`: Farcaster ID
- `user.farcaster.username`: Username
- `user.farcaster.displayName`: Display name
- `user.farcaster.pfp`: Profile picture
- `user.farcaster.bio`: Bio
- `login()`: Function to open Farcaster login modal
- `logout()`: Function to sign out user

### 6. Configuration Options

The Farcaster-only configuration is set in `components/providers/PrivyProvider.tsx`:

```tsx
<PrivySDKProvider
  appId={privyAppId}
  config={{
    appearance: {
      theme: "light", // or "dark"
      accentColor: "#8B5CF6", // Purple brand color
      logo: undefined, // Optional: Your logo URL
    },
    loginMethods: ["farcaster"], // Farcaster-only authentication
    embeddedWallets: {
      createOnLogin: "users-without-wallets", // Auto-create wallet for users
    },
  }}
>
```

**Why Farcaster-only?**
- MeetShipper is built specifically for the Farcaster community
- All user data (profiles, FIDs, avatars) comes from Farcaster
- Ensures every user has a verified Farcaster identity
- Leverages existing Farcaster social graph for meaningful connections

### 7. Testing

1. **Ensure Farcaster is enabled** in your Privy dashboard (Settings → Login Methods → Enable Farcaster)

2. Start your development server:
   ```bash
   pnpm dev
   ```

3. Navigate to `http://localhost:3000/auth-demo`

4. Click "Sign in with Farcaster"

5. The Privy modal will open with **only** Farcaster as an option

6. Connect your Farcaster account through Warpcast or another Farcaster client

7. Complete the authentication flow

8. You should see your Farcaster profile (avatar, username, FID, bio) with sign-out option

## Troubleshooting

### "Privy not configured" message
- Ensure `NEXT_PUBLIC_PRIVY_APP_ID` is set in `.env.local`
- Restart your development server after adding env variables
- Verify the App ID is correct in Privy dashboard

### Farcaster option not showing in Privy modal
- **Most common issue:** Farcaster is not enabled in Privy dashboard
- Go to Privy Dashboard → Your App → Settings → Login Methods
- Enable "Farcaster" and save
- Refresh your app

### "Farcaster account not connected" warning
- User signed in but didn't connect Farcaster
- This shouldn't happen with Farcaster-only config
- If it does, check that `loginMethods: ["farcaster"]` is set correctly in PrivyProvider

### Build errors
- The app is configured to build successfully even without Privy configured
- Warning messages (`⚠️ Privy App ID not configured`) are expected if App ID is not set
- Once configured, warnings will disappear

### Authentication not working
- Check browser console for errors
- Verify your App ID is valid in Privy dashboard
- Check Privy dashboard for any domain restrictions
- Ensure your app URL matches the one configured in Privy
- Make sure you have a Farcaster account to test with

### Cannot access Farcaster data
- Check that user is authenticated: `const { authenticated } = usePrivy()`
- Check that Farcaster is connected: `const { hasFarcaster } = useFarcaster()`
- Use optional chaining: `user?.farcaster?.username`
- Log the user object to inspect available data: `console.log(user)`

## Production Deployment

Before deploying to production:

1. **Enable Farcaster** in your Privy production app dashboard
2. Add your production domain in Privy dashboard (Settings → Allowed Domains)
3. Set `NEXT_PUBLIC_PRIVY_APP_ID` in your hosting platform's environment variables
4. Update `NEXT_PUBLIC_APP_URL` to your production URL
5. Test Farcaster authentication on staging environment first
6. Verify that only Farcaster login appears (no email/wallet options)

## Additional Resources

- [Privy Documentation](https://docs.privy.io/)
- [Privy React SDK](https://docs.privy.io/guide/react)
- [Privy Dashboard](https://dashboard.privy.io/)
- [Privy Farcaster Guide](https://docs.privy.io/guide/react/recipes/authentication/farcaster)
- [Farcaster Documentation](https://docs.farcaster.xyz/)

## Security Notes

- ✅ `NEXT_PUBLIC_PRIVY_APP_ID` is safe to expose (public)
- ✅ Never commit actual API keys to version control
- ✅ Use different Privy apps for development and production
- ✅ Privy handles authentication securely - no passwords stored in your app
- ✅ Farcaster authentication is cryptographically verified
- ✅ User's FID is their verified on-chain Farcaster identity

## Integration with MeetShipper

### Using Farcaster Data in Your App

Once authenticated, you can access Farcaster data throughout your app:

```tsx
import { useFarcaster } from "@/components/auth";

function MyComponent() {
  const { fid, username, displayName, pfp, bio } = useFarcaster();

  // Use FID for database queries
  // Use username/displayName for UI display
  // Use pfp for avatars
  // Use bio for profile pages

  return (
    <div>
      <img src={pfp} alt={username} />
      <h1>{displayName}</h1>
      <p>@{username} (FID: {fid})</p>
      <p>{bio}</p>
    </div>
  );
}
```

### Syncing with Supabase

After Farcaster login, you can sync user data to your Supabase database:

```tsx
import { useFarcaster } from "@/components/auth";
import { useEffect } from "react";

function Dashboard() {
  const { isAuthenticated, fid, username, displayName, pfp } = useFarcaster();

  useEffect(() => {
    if (isAuthenticated && fid) {
      // Sync Farcaster data to your database
      fetch("/api/users/sync", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fid, username, displayName, pfp }),
      });
    }
  }, [isAuthenticated, fid, username, displayName, pfp]);

  return <div>Dashboard content</div>;
}
```

## Summary

You now have Farcaster-only authentication via Privy integrated into your MeetShipper app:

✅ Users can sign in with their Farcaster account only
✅ No email or wallet login options appear
✅ Farcaster data (FID, username, avatar, bio) is automatically fetched
✅ `useFarcaster()` hook provides easy access to user data
✅ Session is managed globally via PrivyProvider
✅ Glassmorphic UI design preserved
✅ Auth state accessible throughout the app

Visit `/auth-demo` to test the full authentication flow!
