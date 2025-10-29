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
  signerUsed?: 'delegated' | 'global';
  signerStatus?: 'generated' | 'pending_approval' | 'approved' | 'revoked' | 'unavailable';
}

/**
 * Safely publish a cast with automatic retry logic for Neynar API overload
 * @param params - Cast parameters
 * @param retries - Number of retries remaining (default: 2)
 * @returns Neynar API response
 */
export async function safePublishCast(
  params: {
    signerUuid: string;
    text: string;
    mentions?: number[];
    embeds?: Array<{ url: string }>;
  },
  retries: number = 2
): Promise<{ success: boolean; cast?: any; error?: string }> {
  try {
    return await neynarAPI.publishCast(params);
  } catch (error: any) {
    const errorMessage = error?.message || error?.toString() || '';
    const isOverloaded = errorMessage.includes('Overloaded') || errorMessage.includes('overload');

    if (isOverloaded && retries > 0) {
      console.warn(
        `[Notification] ⚠️ Neynar API overloaded - retrying in 5 seconds... (${retries} ${retries === 1 ? 'retry' : 'retries'} remaining)`
      );
      await new Promise((resolve) => setTimeout(resolve, 5000));
      return await safePublishCast(params, retries - 1);
    }

    if (isOverloaded && retries === 0) {
      console.error('[Notification] ❌ Neynar still overloaded after retries, skipping notification');
    }

    throw error;
  }
}

/**
 * Safely send a direct cast with automatic retry logic for Neynar API overload
 * @param params - Direct cast parameters
 * @param retries - Number of retries remaining (default: 2)
 * @returns Neynar API response
 */
export async function safeSendDirectCast(
  params: {
    signerUuid: string;
    text: string;
    recipientFid: number;
  },
  retries: number = 2
): Promise<{ success: boolean; cast?: any; error?: string }> {
  try {
    return await neynarAPI.sendDirectCast(params);
  } catch (error: any) {
    const errorMessage = error?.message || error?.toString() || '';
    const isOverloaded = errorMessage.includes('Overloaded') || errorMessage.includes('overload');

    if (isOverloaded && retries > 0) {
      console.warn(
        `[Notification] ⚠️ Neynar API overloaded (DM) - retrying in 5 seconds... (${retries} ${retries === 1 ? 'retry' : 'retries'} remaining)`
      );
      await new Promise((resolve) => setTimeout(resolve, 5000));
      return await safeSendDirectCast(params, retries - 1);
    }

    if (isOverloaded && retries === 0) {
      console.error('[Notification] ❌ Neynar still overloaded after retries (DM), skipping notification');
    }

    throw error;
  }
}

/**
 * Send a match request notification to an external Farcaster user
 * @param externalUser - The Farcaster user receiving the notification
 * @param matchId - The ID of the match request
 * @param userSignerUuid - Optional: User's delegated signer UUID (falls back to global signer)
 * @returns Result of the notification attempt
 */
export async function sendMatchRequestNotification(
  externalUser: ExternalUserData,
  matchId: string,
  userSignerUuid?: string | null
): Promise<NotificationResult> {
  try {
    const apiKey = process.env.NEYNAR_API_KEY;
    const globalSignerUuid = process.env.NEYNAR_SIGNER_UUID;

    if (!globalSignerUuid || !apiKey) {
      console.warn(
        '[Notification] Missing Neynar configuration — Global signer or API key not set.'
      );
      return {
        success: false,
        error: 'Missing Neynar credentials',
        signerUsed: 'global',
        signerStatus: 'unavailable',
      };
    }

    // Determine which signer to use with automatic fallback
    let signerToUse = globalSignerUuid;
    let signerType: 'delegated' | 'global' = 'global';
    let signerStatus: NotificationResult['signerStatus'] = 'unavailable';

    // If user has a delegated signer, check its status
    if (userSignerUuid) {
      console.log('[Notification] Checking delegated signer status...');
      const statusCheck = await neynarAPI.checkSignerStatus(userSignerUuid);

      if (statusCheck.success && statusCheck.status) {
        signerStatus = statusCheck.status;
        console.log('[Notification] Delegated signer status:', statusCheck.status);

        // Only use delegated signer if it's approved
        if (statusCheck.status === 'approved') {
          signerToUse = userSignerUuid;
          signerType = 'delegated';
          console.log('[Notification] ✅ Using approved delegated signer');
        } else {
          console.log(
            '[Notification] ⚠️ Delegated signer not approved (status:',
            statusCheck.status,
            ') - falling back to global signer'
          );
          signerType = 'global';
        }
      } else {
        console.log(
          '[Notification] ⚠️ Could not check delegated signer status - falling back to global signer'
        );
        signerStatus = 'unavailable';
      }
    } else {
      console.log('[Notification] No delegated signer provided - using global signer');
    }

    const appUrl = process.env.NEXT_PUBLIC_BASE_URL || process.env.NEXT_PUBLIC_APP_URL || 'https://www.meetshipper.com';
    const joinUrl = `${appUrl}/join?ref=match-${matchId}`;

    // Construct the message
    const message = `@${externalUser.username}, you've received a match request on Meet Shipper! 🤝\nJoin to accept or decline: ${joinUrl}`;

    console.log('[Notification] Preparing to send cast via Neynar…');
    console.log('[Notification] To:', externalUser.username);
    console.log('[Notification] Mentions included:', [externalUser.fid]);
    console.log('[Notification] Using signer:', signerToUse);
    console.log('[Notification] Signer type:', signerType);
    console.log('[Notification] Signer status:', signerStatus);

    // Send the cast using Neynar API with mentions for proper notification (with retry logic)
    const result = await safePublishCast({
      signerUuid: signerToUse,
      text: message,
      mentions: [externalUser.fid], // ✅ Trigger Warpcast mention notification
      embeds: [{ url: joinUrl }],
    });

    console.log('[Notification] Neynar API response:', JSON.stringify(result, null, 2));

    // Handle response - Neynar returns { success: true, cast: { cast: { hash: "..." } } }
    const castHash = result?.cast?.cast?.hash || result?.cast?.hash;

    if (castHash) {
      console.log(
        `[Notification] ✅ Farcaster notification sent successfully to @${externalUser.username}`
      );
      console.log(`[Notification] Cast hash: ${castHash}`);
      return {
        success: true,
        castHash: castHash,
        signerUsed: signerType,
        signerStatus: signerStatus,
      };
    } else {
      console.error('[Notification] ❌ Failed to send cast - No cast hash found');
      console.error('[Notification] Response structure:', result);
      return {
        success: false,
        error: 'No cast hash returned',
        signerUsed: signerType,
        signerStatus: signerStatus,
      };
    }
  } catch (error) {
    console.error('[Notification] Unexpected error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      signerUsed: 'global',
      signerStatus: 'unavailable',
    };
  }
}

/**
 * Send a direct message (DM) to a Farcaster user
 * Requires follow relationship
 * @param recipientFid - FID of the recipient
 * @param message - Message content
 * @param userSignerUuid - Optional: User's delegated signer UUID (falls back to global signer)
 */
export async function sendDirectMessage(
  recipientFid: number,
  message: string,
  userSignerUuid?: string | null
): Promise<NotificationResult> {
  try {
    const apiKey = process.env.NEYNAR_API_KEY;
    const globalSignerUuid = process.env.NEYNAR_SIGNER_UUID;

    if (!globalSignerUuid || !apiKey) {
      console.warn('[Notification] Missing Neynar configuration for DM.');
      return {
        success: false,
        error: 'Missing Neynar credentials',
        signerUsed: 'global',
        signerStatus: 'unavailable',
      };
    }

    // Determine which signer to use with automatic fallback
    let signerToUse = globalSignerUuid;
    let signerType: 'delegated' | 'global' = 'global';
    let signerStatus: NotificationResult['signerStatus'] = 'unavailable';

    // If user has a delegated signer, check its status
    if (userSignerUuid) {
      console.log('[Notification] Checking delegated signer status for DM...');
      const statusCheck = await neynarAPI.checkSignerStatus(userSignerUuid);

      if (statusCheck.success && statusCheck.status) {
        signerStatus = statusCheck.status;
        console.log('[Notification] Delegated signer status:', statusCheck.status);

        // Only use delegated signer if it's approved
        if (statusCheck.status === 'approved') {
          signerToUse = userSignerUuid;
          signerType = 'delegated';
          console.log('[Notification] ✅ Using approved delegated signer for DM');
        } else {
          console.log(
            '[Notification] ⚠️ Delegated signer not approved (status:',
            statusCheck.status,
            ') - falling back to global signer for DM'
          );
          signerType = 'global';
        }
      } else {
        console.log(
          '[Notification] ⚠️ Could not check delegated signer status - falling back to global signer for DM'
        );
        signerStatus = 'unavailable';
      }
    } else {
      console.log('[Notification] No delegated signer provided - using global signer for DM');
    }

    console.log(`[Notification] Sending DM to FID ${recipientFid}`);
    console.log('[Notification] Using signer:', signerToUse);
    console.log('[Notification] Signer type:', signerType);
    console.log('[Notification] Signer status:', signerStatus);

    const result = await safeSendDirectCast({
      signerUuid: signerToUse,
      text: message,
      recipientFid: recipientFid,
    });

    console.log('[Notification] DM API response:', JSON.stringify(result, null, 2));

    // Handle response - Neynar returns nested structure
    const castHash = result?.cast?.cast?.hash || result?.cast?.hash;

    if (castHash) {
      console.log(`[Notification] ✅ DM sent successfully to FID ${recipientFid}`);
      console.log(`[Notification] Cast hash: ${castHash}`);
      return {
        success: true,
        castHash: castHash,
        signerUsed: signerType,
        signerStatus: signerStatus,
      };
    } else {
      console.error('[Notification] ❌ DM failed - No cast hash found');
      console.error('[Notification] Response structure:', result);
      return {
        success: false,
        error: 'No cast hash returned',
        signerUsed: signerType,
        signerStatus: signerStatus,
      };
    }
  } catch (error) {
    console.error('[Notification] DM error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      signerUsed: 'global',
      signerStatus: 'unavailable',
    };
  }
}

/**
 * Send an external suggestion notification to two Farcaster users
 * @param userAData - First Farcaster user data
 * @param userBData - Second Farcaster user data
 * @param suggestionId - The ID of the suggestion
 * @param suggesterUsername - Username of the person making the suggestion
 * @param userSignerUuid - Optional: User's delegated signer UUID (falls back to global signer)
 * @returns Result of the notification attempt
 */
export async function sendExternalSuggestionNotification(
  userAData: ExternalUserData,
  userBData: ExternalUserData,
  suggestionId: string,
  suggesterUsername: string,
  userSignerUuid?: string | null
): Promise<NotificationResult> {
  try {
    const apiKey = process.env.NEYNAR_API_KEY;
    const globalSignerUuid = process.env.NEYNAR_SIGNER_UUID;

    if (!globalSignerUuid || !apiKey) {
      console.warn(
        '[Notification] Missing Neynar configuration — Global signer or API key not set.'
      );
      return {
        success: false,
        error: 'Missing Neynar credentials',
        signerUsed: 'global',
        signerStatus: 'unavailable',
      };
    }

    // Determine which signer to use with automatic fallback
    let signerToUse = globalSignerUuid;
    let signerType: 'delegated' | 'global' = 'global';
    let signerStatus: NotificationResult['signerStatus'] = 'unavailable';

    // If user has a delegated signer, check its status
    if (userSignerUuid) {
      console.log('[Notification] Checking delegated signer status for external suggestion...');
      const statusCheck = await neynarAPI.checkSignerStatus(userSignerUuid);

      if (statusCheck.success && statusCheck.status) {
        signerStatus = statusCheck.status;
        console.log('[Notification] Delegated signer status:', statusCheck.status);

        // Only use delegated signer if it's approved
        if (statusCheck.status === 'approved') {
          signerToUse = userSignerUuid;
          signerType = 'delegated';
          console.log('[Notification] ✅ Using approved delegated signer');
        } else {
          console.log(
            '[Notification] ⚠️ Delegated signer not approved (status:',
            statusCheck.status,
            ') - falling back to global signer'
          );
          signerType = 'global';
        }
      } else {
        console.log(
          '[Notification] ⚠️ Could not check delegated signer status - falling back to global signer'
        );
        signerStatus = 'unavailable';
      }
    } else {
      console.log('[Notification] No delegated signer provided - using global signer');
    }

    const appUrl = process.env.NEXT_PUBLIC_BASE_URL || process.env.NEXT_PUBLIC_APP_URL || 'https://www.meetshipper.com';
    const suggestionUrl = `${appUrl}/suggestion/${suggestionId}`;

    // Construct the message mentioning both users
    const message = `@${userAData.username} and @${userBData.username}, ${suggesterUsername} thinks you should connect on Meet Shipper! 🤝\n\nCheck it out: ${suggestionUrl}`;

    console.log('[Notification] Preparing to send external suggestion cast via Neynar…');
    console.log('[Notification] To:', `${userAData.username} & ${userBData.username}`);
    console.log('[Notification] Mentions included:', [userAData.fid, userBData.fid]);
    console.log('[Notification] Using approved signer:', signerToUse);
    console.log('[Notification] Signer type:', signerType);
    console.log('[Notification] Signer status:', signerStatus);

    // Send the cast using Neynar API with mentions for proper notification (with retry logic)
    const result = await safePublishCast({
      signerUuid: signerToUse,
      text: message,
      mentions: [userAData.fid, userBData.fid], // ✅ Trigger Warpcast mention notification for both users
      embeds: [{ url: suggestionUrl }],
    });

    console.log('[Notification] Neynar API response:', JSON.stringify(result, null, 2));

    // Handle response - Neynar returns { success: true, cast: { cast: { hash: "..." } } }
    const castHash = result?.cast?.cast?.hash || result?.cast?.hash;

    if (castHash) {
      console.log(
        `[Notification] ✅ External suggestion mention sent successfully to @${userAData.username} and @${userBData.username}`
      );
      console.log(`[Notification] Cast hash: ${castHash}`);
      return {
        success: true,
        castHash: castHash,
        signerUsed: signerType,
        signerStatus: signerStatus,
      };
    } else {
      console.error('[Notification] ❌ Failed to send external suggestion - No cast hash found');
      console.error('[Notification] Response structure:', result);
      return {
        success: false,
        error: 'No cast hash returned',
        signerUsed: signerType,
        signerStatus: signerStatus,
      };
    }
  } catch (error) {
    console.error('[Notification] Unexpected error sending external suggestion:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      signerUsed: 'global',
      signerStatus: 'unavailable',
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