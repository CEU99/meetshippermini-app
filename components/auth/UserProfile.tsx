"use client";

import { usePrivy } from "@privy-io/react-auth";
import { SignOutButton } from "./SignOutButton";
import Image from "next/image";

export function UserProfile() {
  const { user, authenticated, ready } = usePrivy();

  // Don't show if not authenticated
  if (!authenticated || !ready || !user) {
    return null;
  }

  // Get Farcaster details
  const farcasterAccount = user.farcaster;
  const fid = farcasterAccount?.fid;
  const username = farcasterAccount?.username;
  const displayName = farcasterAccount?.displayName || username || "Farcaster User";
  const pfp = farcasterAccount?.pfp;
  const bio = farcasterAccount?.bio;

  // If user doesn't have Farcaster connected, show a helpful message
  if (!farcasterAccount) {
    return (
      <div className="backdrop-blur-xl bg-gradient-to-r from-amber-50/80 to-yellow-50/80 rounded-2xl p-6 border border-amber-200">
        <p className="text-amber-800 font-semibold text-center mb-2">
          ⚠️ Farcaster account not connected
        </p>
        <p className="text-sm text-amber-700 text-center">
          Please connect your Farcaster account from the Privy popup to continue.
        </p>
      </div>
    );
  }

  return (
    <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg p-6">
      <div className="flex items-center gap-4 mb-4">
        {pfp ? (
          <Image
            src={pfp}
            alt={displayName}
            width={64}
            height={64}
            className="rounded-full border-2 border-purple-200"
          />
        ) : (
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-purple-400 to-indigo-500 flex items-center justify-center text-white text-2xl font-bold border-2 border-purple-200">
            {displayName.charAt(0).toUpperCase()}
          </div>
        )}
        <div className="flex-1">
          <h2 className="text-xl font-semibold text-gray-800">{displayName}</h2>
          <p className="text-sm text-purple-600 font-medium">
            @{username}
          </p>
          <p className="text-xs text-gray-500">
            FID: {fid}
          </p>
        </div>
      </div>

      {bio && (
        <div className="mb-4 text-sm text-gray-700 bg-white/50 rounded-lg p-3">
          <p className="italic">{bio}</p>
        </div>
      )}

      <div className="border-t border-purple-100 pt-4 space-y-3">
        <div className="text-sm text-gray-700">
          <p className="font-medium mb-2">Account Details:</p>
          <div className="space-y-1 text-xs bg-white/50 rounded-lg p-3">
            <p><span className="font-semibold">Privy User ID:</span> {user.id}</p>
            <p><span className="font-semibold">Farcaster FID:</span> {fid}</p>
            {user.createdAt && (
              <p><span className="font-semibold">Member since:</span> {new Date(user.createdAt).toLocaleDateString()}</p>
            )}
          </div>
        </div>

        <SignOutButton />
      </div>
    </div>
  );
}
