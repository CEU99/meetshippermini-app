import { jwtVerify } from 'jose';

/**
 * Dev Authentication Utilities
 *
 * These functions verify dev session cookies created by /api/dev/login
 * and are used by server-side guards to allow dev login without Farcaster OAuth
 */

const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || 'your-secret-key-change-in-production'
);

export interface DevSessionData {
  fid: number;
  username: string;
  displayName?: string;
  avatarUrl?: string;
  userCode?: string;
  expiresAt: number;
}

/**
 * Verify a dev session JWT token
 *
 * @param token - The JWT token string
 * @returns Session data if valid, null otherwise
 */
export async function verifyDevSession(
  token: string
): Promise<DevSessionData | null> {
  if (!token || token.trim() === '') {
    return null;
  }

  try {
    const { payload } = await jwtVerify(token, JWT_SECRET);

    // Check if token is expired
    if (payload.expiresAt && (payload.expiresAt as number) < Date.now()) {
      console.log('[Dev Auth] Token expired');
      return null;
    }

    // Validate required fields
    if (!payload.fid || !payload.username) {
      console.log('[Dev Auth] Invalid token: missing fid or username');
      return null;
    }

    return payload as unknown as DevSessionData;
  } catch (error) {
    console.log('[Dev Auth] Token verification failed:', error instanceof Error ? error.message : 'Unknown error');
    return null;
  }
}

/**
 * Get dev session from cookie value
 *
 * This is the main function used by server-side guards
 *
 * @param cookieValue - The session cookie value (JWT token)
 * @returns Session data if valid, null otherwise
 */
export async function getDevSessionFromCookie(
  cookieValue: string | undefined
): Promise<DevSessionData | null> {
  if (!cookieValue) {
    return null;
  }

  return verifyDevSession(cookieValue);
}

/**
 * Check if dev auth is enabled
 *
 * Dev auth is only available in development mode
 */
export function isDevAuthEnabled(): boolean {
  return process.env.NODE_ENV !== 'production';
}
