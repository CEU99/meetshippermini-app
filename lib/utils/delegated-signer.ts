/**
 * Delegated Signer Utilities
 * Client-side helpers for managing Farcaster delegated signers
 */

/**
 * Initialize delegated signer for the current user
 * Call this after successful Privy authentication
 */
export async function initializeDelegatedSigner(): Promise<{
  success: boolean;
  signerUuid?: string;
  cached?: boolean;
  error?: string;
}> {
  try {
    console.log('[Delegated Signer] Initializing...');

    const response = await fetch('/api/auth/init-signer', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      console.error('[Delegated Signer] Failed to initialize:', data.error);
      return {
        success: false,
        error: data.error || 'Failed to initialize signer',
      };
    }

    if (data.cached) {
      console.log('[Delegated Signer] ✅ Using cached signer');
    } else {
      console.log('[Delegated Signer] ✅ New signer created');
    }

    return {
      success: true,
      signerUuid: data.signerUuid,
      cached: data.cached,
    };
  } catch (error) {
    console.error('[Delegated Signer] Error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Check if user has a delegated signer
 */
export async function hasDelegatedSigner(): Promise<boolean> {
  try {
    const response = await fetch('/api/neynar/delegate');

    if (!response.ok) {
      return false;
    }

    const data = await response.json();
    return data.hasDelegate === true;
  } catch (error) {
    console.error('[Delegated Signer] Error checking signer:', error);
    return false;
  }
}
