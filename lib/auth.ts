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
