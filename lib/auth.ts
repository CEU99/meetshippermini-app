import { SignJWT, jwtVerify } from 'jose';
import { cookies } from 'next/headers';

const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || 'your-secret-key-change-in-production'
);

export interface SessionData {
  fid: number;
  username: string;
  displayName?: string;
  avatarUrl?: string;
  userCode?: string | null;
  signerUuid?: string | null; // Neynar delegated signer UUID
  expiresAt: number;
}

const SESSION_DURATION = 7 * 24 * 60 * 60 * 1000; // 7 days

export async function createSession(userData: Omit<SessionData, 'expiresAt'>) {
  const expiresAt = Date.now() + SESSION_DURATION;

  const token = await new SignJWT({ ...userData, expiresAt })
    .setProtectedHeader({ alg: 'HS256' })
    .setExpirationTime('7d')
    .sign(JWT_SECRET);

  const cookieStore = await cookies();
  cookieStore.set('session', token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: SESSION_DURATION / 1000,
    path: '/',
  });

  return token;
}

export async function getSession(): Promise<SessionData | null> {
  const cookieStore = await cookies();
  const token = cookieStore.get('session')?.value;

  if (!token) {
    return null;
  }

  try {
    const { payload } = await jwtVerify(token, JWT_SECRET);

    // Check if token is expired
    if (payload.expiresAt && (payload.expiresAt as number) < Date.now()) {
      return null;
    }

    return payload as unknown as SessionData;
  } catch (error) {
    console.error('Session verification failed:', error);
    return null;
  }
}

export async function deleteSession() {
  const cookieStore = await cookies();
  cookieStore.delete('session');
}

export async function requireAuth(): Promise<SessionData> {
  const session = await getSession();

  if (!session) {
    throw new Error('Unauthorized');
  }

  return session;
}

/**
 * Update session with delegated signer UUID
 * This allows adding a signer to an existing session without recreating it
 */
export async function updateSessionSigner(signerUuid: string): Promise<void> {
  const session = await getSession();

  if (!session) {
    throw new Error('No active session');
  }

  // Create new session with updated signer
  await createSession({
    fid: session.fid,
    username: session.username,
    displayName: session.displayName,
    avatarUrl: session.avatarUrl,
    userCode: session.userCode,
    signerUuid: signerUuid,
  });
}

/**
 * Get or create delegated signer for the current session
 */
export async function ensureDelegatedSigner(): Promise<string | null> {
  const session = await getSession();

  if (!session) {
    return null;
  }

  // If session already has a signer, return it
  if (session.signerUuid) {
    console.log('[Auth] Using existing delegated signer from session');
    return session.signerUuid;
  }

  try {
    // Request new delegated signer
    console.log('[Auth] Requesting new delegated signer for FID:', session.fid);

    const response = await fetch('/api/neynar/delegate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fid: session.fid }),
    });

    if (!response.ok) {
      console.error('[Auth] Failed to get delegated signer:', response.status);
      return null;
    }

    const data = await response.json();

    if (data.signerUuid) {
      // Update session with new signer
      await updateSessionSigner(data.signerUuid);
      console.log('[Auth] ✅ Delegated signer created and stored in session');
      return data.signerUuid;
    }

    return null;
  } catch (error) {
    console.error('[Auth] Error ensuring delegated signer:', error);
    return null;
  }
}
