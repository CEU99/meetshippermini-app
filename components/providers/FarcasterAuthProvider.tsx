'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import { AuthClientError, AuthKitProvider, useProfile } from '@farcaster/auth-kit';
import type { FarcasterUser } from '@/lib/types';
import { apiClient } from '@/lib/api-client';

interface FarcasterAuthContextType {
  user: FarcasterUser | null;
  isAuthenticated: boolean;
  loading: boolean;
  signOut: () => Promise<void>;
}

const FarcasterAuthContext = createContext<FarcasterAuthContextType | undefined>(
  undefined
);

function AuthKitWrapper({ children }: { children: React.ReactNode }) {
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

function FarcasterAuthProviderInner({ children }: { children: React.ReactNode }) {
  const {
    isAuthenticated,
    profile,
  } = useProfile();

  const [user, setUser] = useState<FarcasterUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function handleAuthState() {
      setLoading(true);

      // PRIORITY 1: Check for dev session via API (bypasses Farcaster auth in dev)
      // NOTE: We can't read HttpOnly cookies from JavaScript, so we always call the API
      if (process.env.NODE_ENV === 'development') {
        try {
          // Verify dev session via API (cookie sent automatically)
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
          } else {
            console.log('[Auth] No dev session found, will try Farcaster auth');
          }
        } catch (error) {
          console.log('[Auth] Dev session check failed, falling back to Farcaster');
        }
      }

      // PRIORITY 2: Fall back to Farcaster auth
      if (isAuthenticated && profile) {
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
            requiresMigration?: boolean;
            migrationFile?: string;
            migrationUrl?: string;
          }>('/api/auth/session', farcasterUser);

          // Add userCode, bio, and traits to user object
          if (response.userCode) {
            farcasterUser.userCode = response.userCode;
            console.log(`✅ User code loaded: ${response.userCode}`);
          } else if (response.requiresMigration) {
            console.warn('⚠️  DATABASE MIGRATION REQUIRED');
            console.warn(`📋 File to run: ${response.migrationFile}`);
            console.warn(`🔗 Dashboard: ${response.migrationUrl}`);
            console.warn('');
            console.warn('Steps:');
            console.warn('  1. Go to https://supabase.com/dashboard');
            console.warn('  2. Select your project');
            console.warn('  3. Click "SQL Editor" → "New Query"');
            console.warn('  4. Copy and paste supabase-user-code-complete.sql');
            console.warn('  5. Click "RUN"');
            console.warn('  6. Refresh this page');
          }

          // Update bio and traits from backend
          if (response.bio) {
            farcasterUser.bio = response.bio;
          }
          if (response.traits && response.traits.length > 0) {
            farcasterUser.traits = response.traits as any;
          }

          setUser(farcasterUser);
        } catch (error) {
          console.error('Failed to create session:', error);
          setUser(farcasterUser); // Set user anyway, even if session creation failed
        }
      } else {
        setUser(null);
      }

      setLoading(false);
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
      console.error('Sign out failed:', error);
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

export function FarcasterAuthProvider({ children }: { children: React.ReactNode }) {
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
