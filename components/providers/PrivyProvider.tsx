"use client";

import { PrivyProvider as PrivySDKProvider } from "@privy-io/react-auth";

export function PrivyProvider({ children }: { children: React.ReactNode }) {
  const privyAppId = process.env.NEXT_PUBLIC_PRIVY_APP_ID || "";

  // If no valid Privy App ID is configured, render children without Privy
  // This allows the app to build/run even without Privy configured
  if (!privyAppId || privyAppId === "your_privy_app_id_here") {
    console.warn("⚠️ Privy App ID not configured. Please add NEXT_PUBLIC_PRIVY_APP_ID to your .env.local file.");
    return <>{children}</>;
  }

  return (
    <PrivySDKProvider
      appId={privyAppId}
      config={{
        // Appearance configuration
        appearance: {
          theme: "light",
          accentColor: "#8B5CF6",
          logo: undefined,
        },
        // Farcaster-only login method
        loginMethods: ["farcaster"],
        // Embedded wallets configuration
        embeddedWallets: {
          createOnLogin: "users-without-wallets",
        },
      }}
    >
      {children}
    </PrivySDKProvider>
  );
}
