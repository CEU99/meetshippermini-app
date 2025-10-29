'use client';

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { AuthKitProvider, useProfile } from '@farcaster/auth-kit';
import type { FarcasterUser } from '@/lib/types';
import { apiClient } from '@/lib/api-client';
import { initializeDelegatedSigner } from '@/lib/utils/delegated-signer';

interface FarcasterAuthContextType {
  user: FarcasterUser | null;
  isAuthenticated: boolean;
  loading: boolean;
  signOut: () => Promise<void>;
}

const FarcasterAuthContext = createContext<FarcasterAuthContextType | undefined>(
  undefined
);

function AuthKitWrapper({ children }: { children: ReactNode }) {
  const config = {
    relay: 'https://relay.farcaster.xyz',
    rpcUrl: process.env.NEXT_PUBLIC_RPC_URL || 'https://mainnet.optimism.io',
    domain: typeof window !== 'undefined' ? window.location.host : 'localhost:3000',
    siweUri: typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3000',
  };

  return (
    <AuthKitProvider config={config}>
      {children}
    </AuthKitProvider>
  );
}

function FarcasterAuthProviderInner({ children }: { children: ReactNode }) {
  const { isAuthenticated, profile } = useProfile();
  const [user, setUser] = useState<FarcasterUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function handleAuthState() {
      console.log('[FarcasterAuth] Auth state:', { isAuthenticated, profile });
      setLoading(true);

      try {
        // PRIORITY 1: Check for dev session (bypasses Farcaster in development)
        if (process.env.NODE_ENV === 'development') {
          try {
            const devResponse = await apiClient.get<{
              authenticated: boolean;
              session: {
                fid: number;
                username: string;
                displayName?: string;
                userCode?: string;
                avatarUrl?: string;
              } | null;
            }>('/api/dev/session');

            if (devResponse.authenticated && devResponse.session) {
              console.log('[Auth] ✅ Using dev session:', devResponse.session.username);

              const devUser: FarcasterUser = {
                fid: devResponse.session.fid,
                username: devResponse.session.username,
                displayName: devResponse.session.displayName || devResponse.session.username,
                pfpUrl: devResponse.session.avatarUrl || `https://avatar.vercel.sh/${devResponse.session.username}`,
                bio: '',
                userCode: devResponse.session.userCode,
              };

              setUser(devUser);
              setLoading(false);
              return; // Exit early - dev session takes priority
            }
          } catch {
            console.log('[Auth] Dev session check failed, falling back to Farcaster');
          }
        }

        // PRIORITY 2: Use Farcaster Auth Kit
        if (isAuthenticated && profile) {
          console.log('[Auth] ✅ Farcaster profile found:', profile);

          const farcasterUser: FarcasterUser = {
            fid: profile.fid,
            username: profile.username,
            displayName: profile.displayName || profile.username,
            pfpUrl: profile.pfpUrl || '',
            bio: profile.bio || '',
          };

          // Store session in backend and get user_code
          try {
            const response = await apiClient.post<{
              success: boolean;
              userCode: string | null;
              bio?: string;
              traits?: string[];
            }>('/api/auth/session', farcasterUser);

            // Add userCode from backend
            if (response.userCode) {
              farcasterUser.userCode = response.userCode;
              console.log(`✅ User code loaded: ${response.userCode}`);
            }

            // Update bio and traits from backend
            if (response.bio) {
              farcasterUser.bio = response.bio;
            }
            if (response.traits && response.traits.length > 0) {
              farcasterUser.traits = response.traits as unknown as typeof farcasterUser.traits;
            }

            setUser(farcasterUser);
            console.log('[Auth] ✅ User authenticated:', farcasterUser);

            // Initialize delegated signer for Farcaster messaging
            // This runs in the background and doesn't block authentication
            initializeDelegatedSigner()
              .then((result) => {
                if (result.success) {
                  console.log('[Auth] ✅ Delegated signer initialized:', result.cached ? 'cached' : 'new');
                } else {
                  console.warn('[Auth] ⚠️ Failed to initialize delegated signer:', result.error);
                  // Don't fail auth if signer init fails - it's optional
                }
              })
              .catch((error) => {
                console.error('[Auth] Error initializing delegated signer:', error);
              });
          } catch (error) {
            console.error('[Auth] Failed to create session:', error);
            setUser(farcasterUser); // Set user anyway, even if session creation failed
          }
        } else {
          // Not authenticated
          setUser(null);
          console.log('[Auth] User not authenticated');
        }
      } catch (error) {
        console.error('[Auth] Error handling auth state:', error);
        setUser(null);
      } finally {
        setLoading(false);
      }
    }

    handleAuthState();
  }, [isAuthenticated, profile]);

  const signOut = async () => {
    try {
      // Clear backend session
      await apiClient.post('/api/auth/logout');

      setUser(null);

      // Redirect to home
      if (typeof window !== 'undefined') {
        window.location.href = '/';
      }
    } catch (error) {
      console.error('[Auth] Sign out failed:', error);
    }
  };

  return (
    <FarcasterAuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        loading,
        signOut,
      }}
    >
      {children}
    </FarcasterAuthContext.Provider>
  );
}

export function FarcasterAuthProvider({ children }: { children: ReactNode }) {
  return (
    <AuthKitWrapper>
      <FarcasterAuthProviderInner>{children}</FarcasterAuthProviderInner>
    </AuthKitWrapper>
  );
}

export function useFarcasterAuth() {
  const context = useContext(FarcasterAuthContext);
  if (context === undefined) {
    throw new Error('useFarcasterAuth must be used within FarcasterAuthProvider');
  }
  return context;
}
