"use client";

import { usePrivy } from "@privy-io/react-auth";

export function SignInButton() {
  // Check if Privy is configured
  const privyAppId = process.env.NEXT_PUBLIC_PRIVY_APP_ID || "";

  if (!privyAppId || privyAppId === "your_privy_app_id_here") {
    return (
      <div className="px-6 py-3 bg-amber-100 text-amber-800 font-medium rounded-xl border border-amber-200 text-center">
        ⚠️ Privy not configured. Please add NEXT_PUBLIC_PRIVY_APP_ID to .env.local
      </div>
    );
  }

  const { login, authenticated, ready } = usePrivy();

  // Don't show button if already authenticated
  if (authenticated) {
    return null;
  }

  return (
    <button
      onClick={login}
      disabled={!ready}
      className="px-6 py-3 bg-gradient-to-r from-purple-600 to-indigo-600 text-white font-semibold rounded-xl shadow-lg hover:from-purple-700 hover:to-indigo-700 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 justify-center"
    >
      {ready ? (
        <>
          <svg className="w-5 h-5" viewBox="0 0 1000 1000" fill="currentColor">
            <path d="M257.778 155.556H742.222V844.445H671.111V528.889H670.414C662.554 441.677 589.258 373.333 500 373.333C410.742 373.333 337.446 441.677 329.586 528.889H328.889V844.445H257.778V155.556Z"/>
            <path d="M128.889 253.333L154.445 227.778C179.949 202.173 218.703 202.173 244.207 227.778C269.711 253.384 269.711 292.137 244.207 317.743L128.889 433.061V253.333Z"/>
            <path d="M871.111 253.333V433.061L755.793 317.743C730.289 292.137 730.289 253.384 755.793 227.778C781.297 202.173 820.051 202.173 845.555 227.778L871.111 253.333Z"/>
          </svg>
          <span>Sign in with Farcaster</span>
        </>
      ) : (
        "Loading..."
      )}
    </button>
  );
}
