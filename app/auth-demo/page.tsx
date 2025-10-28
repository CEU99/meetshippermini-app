"use client";

import { usePrivy } from "@privy-io/react-auth";
import { SignInButton } from "@/components/auth/SignInButton";
import { UserProfile } from "@/components/auth/UserProfile";

export default function AuthDemoPage() {
  const { authenticated, ready, user } = usePrivy();

  // Get Farcaster details if available
  const farcasterAccount = user?.farcaster;
  const fid = farcasterAccount?.fid;
  const username = farcasterAccount?.username;

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-indigo-50 p-8">
      <div className="max-w-2xl mx-auto">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold bg-gradient-to-r from-purple-600 to-indigo-600 bg-clip-text text-transparent mb-3">
            Farcaster Authentication via Privy
          </h1>
          <p className="text-gray-600">
            Connect your Farcaster account to access MeetShipper
          </p>
        </div>

        {!ready ? (
          <div className="text-center py-12">
            <div className="animate-pulse">
              <div className="h-12 w-48 bg-gray-200 rounded-xl mx-auto"></div>
            </div>
            <p className="text-gray-500 mt-4">Initializing Privy...</p>
          </div>
        ) : (
          <div className="space-y-6">
            {authenticated ? (
              <>
                <div className="backdrop-blur-xl bg-gradient-to-r from-green-50/80 to-emerald-50/80 rounded-2xl p-6 border border-green-200">
                  <p className="text-green-800 font-semibold text-center">
                    ✅ You are authenticated with Farcaster!
                  </p>
                  {fid && username && (
                    <p className="text-green-700 text-sm text-center mt-2">
                      Connected as @{username} (FID: {fid})
                    </p>
                  )}
                </div>
                <UserProfile />
              </>
            ) : (
              <>
                <div className="backdrop-blur-xl bg-gradient-to-r from-amber-50/80 to-yellow-50/80 rounded-2xl p-6 border border-amber-200">
                  <p className="text-amber-800 font-semibold text-center">
                    ⏳ Please sign in with Farcaster to continue
                  </p>
                </div>
                <div className="flex justify-center">
                  <SignInButton />
                </div>
              </>
            )}

            <div className="backdrop-blur-xl bg-white/60 rounded-2xl p-6 border border-gray-200">
              <h2 className="text-lg font-semibold text-gray-800 mb-3">
                How it works:
              </h2>
              <ul className="space-y-2 text-sm text-gray-700">
                <li className="flex items-start gap-2">
                  <span className="text-purple-600 font-bold">1.</span>
                  <span>Click "Sign in with Farcaster" to open the Privy authentication modal</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-purple-600 font-bold">2.</span>
                  <span>Connect your Farcaster account through Warpcast or another Farcaster client</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-purple-600 font-bold">3.</span>
                  <span>Your Farcaster data (FID, username, avatar, bio) is fetched automatically</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-purple-600 font-bold">4.</span>
                  <span>Your session is stored globally and accessible throughout the app</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-purple-600 font-bold">5.</span>
                  <span>UserProfile displays your Farcaster profile with sign-out option</span>
                </li>
              </ul>
            </div>

            <div className="backdrop-blur-xl bg-gradient-to-r from-blue-50/60 to-indigo-50/60 rounded-2xl p-6 border border-blue-200">
              <h2 className="text-lg font-semibold text-gray-800 mb-3">
                Why Farcaster-only?
              </h2>
              <p className="text-sm text-gray-700">
                MeetShipper is built specifically for the Farcaster community. All user profiles, connections,
                and matches are based on Farcaster data. By requiring Farcaster authentication, we ensure that
                every user has a verified Farcaster identity (FID) and can leverage their existing Farcaster
                network for meaningful connections.
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
