"use client";

import { usePrivy } from "@privy-io/react-auth";

/**
 * Custom hook to easily access Farcaster data from Privy
 * Returns Farcaster account details including FID, username, pfp, etc.
 */
export function useFarcaster() {
  const { user, authenticated, ready } = usePrivy();

  // Get Farcaster account details
  const farcasterAccount = user?.farcaster;

  return {
    // Authentication state
    isAuthenticated: authenticated,
    isReady: ready,

    // Farcaster account data
    hasFarcaster: !!farcasterAccount,
    fid: farcasterAccount?.fid,
    username: farcasterAccount?.username,
    displayName: farcasterAccount?.displayName,
    pfp: farcasterAccount?.pfp,
    bio: farcasterAccount?.bio,

    // Full account object (if needed)
    farcasterAccount,

    // Full Privy user object (if needed)
    user,
  };
}
