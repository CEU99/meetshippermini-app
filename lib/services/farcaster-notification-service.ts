/**
 * Farcaster Notification Service
 * Handles sending notifications to Farcaster users via Neynar API
 */

import { neynarAPI } from '@/lib/neynar';

interface ExternalUserData {
  fid: number;
  username: string;
  display_name?: string;
  avatar_url?: string;
  bio?: string;
}

interface NotificationResult {
  success: boolean;
  castHash?: string;
  error?: string;
}

/**
 * Send a match request notification to an external Farcaster user
 * @param externalUser - The Farcaster user receiving the notification
 * @param matchId - The ID of the match request
 * @returns Result of the notification attempt
 */
export async function sendMatchRequestNotification(
  externalUser: ExternalUserData,
  matchId: string
): Promise<NotificationResult> {
  try {
    const signerUuid = process.env.NEYNAR_SIGNER_UUID;
    const apiKey = process.env.NEYNAR_API_KEY;

    if (!signerUuid || !apiKey) {
      console.warn(
        '[Notification] Missing Neynar configuration — Signer or API key not set.'
      );
      return {
        success: false,
        error: 'Missing Neynar credentials',
      };
    }

    const appUrl = process.env.NEXT_PUBLIC_APP_URL || 'https://meetshipper.com';
    const joinUrl = `${appUrl}/join?ref=match-${matchId}`;

    // Construct the message
    const message = `@${externalUser.username}, you’ve received a match request on Meet Shipper! 🤝\nJoin to accept or decline: ${joinUrl}`;

    console.log('[Notification] Preparing to send cast via Neynar…');
    console.log('[Notification] To:', externalUser.username);
    console.log('[Notification] Using signer:', signerUuid);

    // Send the cast using Neynar API
    const result = await neynarAPI.publishCast({
      signerUuid: signerUuid,
      text: message,
      embeds: [{ url: joinUrl }],
    });

    // Handle response
    if (result?.cast?.hash) {
      console.log(
        `[Notification] ✅ Farcaster notification sent successfully to @${externalUser.username}`
      );
      return {
        success: true,
        castHash: result.cast.hash,
      };
    } else {
      console.error('[Notification] ❌ Failed to send cast:', result);
      return {
        success: false,
        error: 'No cast hash returned',
      };
    }
  } catch (error) {
    console.error('[Notification] Unexpected error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Send a direct message (DM) to a Farcaster user
 * Requires follow relationship
 */
export async function sendDirectMessage(
  recipientFid: number,
  message: string
): Promise<NotificationResult> {
  try {
    const signerUuid = process.env.NEYNAR_SIGNER_UUID;
    const apiKey = process.env.NEYNAR_API_KEY;

    if (!signerUuid || !apiKey) {
      console.warn('[Notification] Missing Neynar credentials for DM.');
      return {
        success: false,
        error: 'Missing Neynar credentials',
      };
    }

    console.log(`[Notification] Sending DM to FID ${recipientFid}`);

    const result = await neynarAPI.sendDirectCast({
      signerUuid: signerUuid,
      text: message,
      recipientFid: recipientFid,
    });

    if (result?.cast?.hash) {
      console.log(`[Notification] ✅ DM sent successfully to FID ${recipientFid}`);
      return {
        success: true,
        castHash: result.cast.hash,
      };
    } else {
      console.error('[Notification] ❌ DM failed:', result);
      return {
        success: false,
        error: 'No cast hash returned',
      };
    }
  } catch (error) {
    console.error('[Notification] DM error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

/**
 * Verify if Farcaster notifications are configured
 */
export function areNotificationsConfigured(): boolean {
  const configured =
    !!process.env.NEYNAR_SIGNER_UUID && !!process.env.NEYNAR_API_KEY;
  console.log(
    `[Notification] Configuration status → Signer: ${
      process.env.NEYNAR_SIGNER_UUID ? '✅' : '❌'
    }, API Key: ${process.env.NEYNAR_API_KEY ? '✅' : '❌'}`
  );
  return configured;
}