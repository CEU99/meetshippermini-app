"use client";

import { usePrivy } from "@privy-io/react-auth";

export function SignOutButton() {
  const { logout, authenticated, ready } = usePrivy();

  // Don't show button if not authenticated
  if (!authenticated) {
    return null;
  }

  return (
    <button
      onClick={logout}
      disabled={!ready}
      className="px-4 py-2 bg-red-100 text-red-700 font-medium rounded-lg hover:bg-red-200 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed border border-red-200"
    >
      {ready ? "Sign out" : "Loading..."}
    </button>
  );
}
