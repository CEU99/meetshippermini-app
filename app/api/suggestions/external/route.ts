import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';
import { neynarAPI } from '@/lib/neynar';
import { sendExternalSuggestionNotification } from '@/lib/services/farcaster-notification-service';

/**
 * POST /api/suggestions/external
 * Create a match suggestion between two external Farcaster users
 *
 * This endpoint allows suggesting matches to users who haven't joined MeetShipper yet.
 * Both users will receive Farcaster notifications with mentions.
 */
export async function POST(request: NextRequest) {
  try {
    // Support both session-based auth (cookies) and API key auth (Bearer token)
    const authHeader = request.headers.get('authorization');
    const apiKey = process.env.NEYNAR_API_KEY;

    let session = await getSession();
    let isApiKeyAuth = false;

    // If no session, check for API key authentication
    if (!session && authHeader) {
      console.log('[API] 🔹 AUTH HEADER:', authHeader ? `Bearer ${authHeader.substring(7, 27)}...` : 'None');
      console.log('[API] 🔹 ENV KEY:', apiKey ? `${apiKey.substring(0, 20)}...` : 'None');
      console.log('[API] 🔹 NODE_ENV:', process.env.NODE_ENV);
      console.log('[API] 🔹 VERCEL_ENV:', process.env.VERCEL_ENV);

      if (!apiKey) {
        console.error('[API] ❌ NEYNAR_API_KEY environment variable is NOT loaded');
        console.error('[API]    → Add NEYNAR_API_KEY to Vercel Dashboard → Settings → Environment Variables (Production scope)');
        return NextResponse.json({
          error: 'Unauthorized - Server configuration error',
          message: 'NEYNAR_API_KEY environment variable is not configured',
          help: 'Contact the administrator to configure the API key in Vercel',
        }, { status: 500 });
      }

      if (authHeader.startsWith('Bearer ')) {
        const providedKey = authHeader.substring(7); // Remove 'Bearer ' prefix

        if (providedKey === apiKey) {
          console.log('[API] ✅ API key authentication successful');
          isApiKeyAuth = true;
          // Create a pseudo-session for API key requests
          // You'll need to provide a valid FID and username for the API caller
          session = {
            fid: 1, // Default system FID - update this to match your system user
            username: 'meetshipper-bot', // Default system username
            expiresAt: Date.now() + 3600000, // 1 hour
          };
        } else {
          console.error('[API] ❌ Invalid API key - key mismatch');
          console.error('[API]    Provided key length:', providedKey.length);
          console.error('[API]    Expected key length:', apiKey.length);
          return NextResponse.json({
            error: 'Unauthorized - Invalid API key',
            message: 'The provided API key does not match the server configuration',
            help: 'Verify your API key matches the one configured in Vercel',
          }, { status: 401 });
        }
      } else {
        console.error('[API] ❌ Invalid Authorization header format');
        return NextResponse.json({
          error: 'Unauthorized - Invalid authorization format',
          message: 'Authorization header must start with "Bearer " (with space)',
          help: 'Use: -H "Authorization: Bearer YOUR_API_KEY"',
        }, { status: 401 });
      }
    }

    if (!session) {
      console.error('[API] ❌ No session or valid API key found');
      console.error('[API]    Session auth: No cookie found');
      console.error('[API]    API key auth: No Authorization header provided');
      return NextResponse.json({
        error: 'Unauthorized',
        message: 'No valid authentication provided',
        help: 'Either login to get a session cookie, or provide: -H "Authorization: Bearer YOUR_API_KEY"',
      }, { status: 401 });
    }

    const body = await request.json();
    const { userAFid, userBFid, reason } = body;

    console.log('[API] Creating external match suggestion:', {
      authMethod: isApiKeyAuth ? 'API Key' : 'Session',
      suggesterFid: session.fid,
      suggesterUsername: session.username,
      userAFid,
      userBFid,
      hasReason: !!reason,
    });

    // Validation
    if (!userAFid || !userBFid) {
      return NextResponse.json(
        { error: 'Missing required fields: userAFid and userBFid are required' },
        { status: 400 }
      );
    }

    // Validate numeric FIDs
    if (typeof userAFid !== 'number' || typeof userBFid !== 'number') {
      return NextResponse.json(
        { error: 'Invalid FID format: userAFid and userBFid must be numeric' },
        { status: 400 }
      );
    }

    if (isNaN(userAFid) || isNaN(userBFid) || userAFid <= 0 || userBFid <= 0) {
      return NextResponse.json(
        { error: 'Invalid FID: FIDs must be positive numbers' },
        { status: 400 }
      );
    }

    // Validate A ≠ B
    if (userAFid === userBFid) {
      return NextResponse.json(
        { error: 'User A and User B must be different people' },
        { status: 400 }
      );
    }

    // Validate reason length (optional, but if provided must be < 200 chars)
    const trimmedReason = reason?.trim() || 'Suggested connection on MeetShipper';
    if (trimmedReason.length > 200) {
      return NextResponse.json(
        { error: 'Reason must not exceed 200 characters' },
        { status: 400 }
      );
    }

    if (userAFid === session.fid || userBFid === session.fid) {
      return NextResponse.json(
        { error: 'Cannot suggest a match involving yourself' },
        { status: 400 }
      );
    }

    const supabase = getServerSupabase();

    // Fetch both users from Farcaster and upsert to database
    console.log('[API] Fetching User A from Farcaster:', userAFid);
    let userAData;
    try {
      const farcasterUserA = await neynarAPI.getUserByFid(userAFid);
      if (!farcasterUserA) {
        return NextResponse.json(
          { error: `User A (FID: ${userAFid}) not found on Farcaster` },
          { status: 404 }
        );
      }

      userAData = {
        fid: farcasterUserA.fid,
        username: farcasterUserA.username || `user${farcasterUserA.fid}`,
        display_name: farcasterUserA.display_name || farcasterUserA.username || `User ${farcasterUserA.fid}`,
        avatar_url: farcasterUserA.pfp_url || '',
        bio: farcasterUserA.profile?.bio?.text || '',
      };

      console.log('[API] User A found:', userAData.username);

      // Upsert User A
      const { error: upsertErrorA } = await supabase
        .from('users')
        .upsert({
          ...userAData,
          has_joined_meetshipper: false,
          updated_at: new Date().toISOString(),
        }, {
          onConflict: 'fid',
          ignoreDuplicates: false,
        });

      if (upsertErrorA) {
        console.error('[API] Error upserting User A:', upsertErrorA);
        return NextResponse.json(
          { error: 'Failed to register User A', details: upsertErrorA.message },
          { status: 500 }
        );
      }
      console.log('[API] ✅ User A upserted');
    } catch (error) {
      console.error('[API] Error fetching User A from Farcaster:', error);
      return NextResponse.json(
        { error: `User A (FID: ${userAFid}) not found on Farcaster` },
        { status: 404 }
      );
    }

    console.log('[API] Fetching User B from Farcaster:', userBFid);
    let userBData;
    try {
      const farcasterUserB = await neynarAPI.getUserByFid(userBFid);
      if (!farcasterUserB) {
        return NextResponse.json(
          { error: `User B (FID: ${userBFid}) not found on Farcaster` },
          { status: 404 }
        );
      }

      userBData = {
        fid: farcasterUserB.fid,
        username: farcasterUserB.username || `user${farcasterUserB.fid}`,
        display_name: farcasterUserB.display_name || farcasterUserB.username || `User ${farcasterUserB.fid}`,
        avatar_url: farcasterUserB.pfp_url || '',
        bio: farcasterUserB.profile?.bio?.text || '',
      };

      console.log('[API] User B found:', userBData.username);

      // Upsert User B
      const { error: upsertErrorB } = await supabase
        .from('users')
        .upsert({
          ...userBData,
          has_joined_meetshipper: false,
          updated_at: new Date().toISOString(),
        }, {
          onConflict: 'fid',
          ignoreDuplicates: false,
        });

      if (upsertErrorB) {
        console.error('[API] Error upserting User B:', upsertErrorB);
        return NextResponse.json(
          { error: 'Failed to register User B', details: upsertErrorB.message },
          { status: 500 }
        );
      }
      console.log('[API] ✅ User B upserted');
    } catch (error) {
      console.error('[API] Error fetching User B from Farcaster:', error);
      return NextResponse.json(
        { error: `User B (FID: ${userBFid}) not found on Farcaster` },
        { status: 404 }
      );
    }

    // Create the external suggestion
    const { data: suggestion, error: createError } = await supabase
      .from('match_suggestions')
      .insert({
        created_by_fid: session.fid,
        user_a_fid: userAFid,
        user_b_fid: userBFid,
        message: trimmedReason,
        status: 'pending_external',
        rationale: {
          isExternalSuggestion: true,
          reason: trimmedReason,
          userAData,
          userBData,
        },
      })
      .select()
      .single();

    if (createError) {
      console.error('[API] Error creating external suggestion:', createError);
      console.error('[API] Error code:', createError.code);
      console.error('[API] Error details:', createError.details);

      // Check for duplicate suggestion
      if (createError.code === '23505') {
        return NextResponse.json(
          {
            error: 'Duplicate suggestion',
            message: 'A pending suggestion already exists between these users',
          },
          { status: 409 }
        );
      }

      return NextResponse.json(
        {
          error: 'Failed to create external suggestion',
          details: createError.message,
          code: createError.code,
        },
        { status: 500 }
      );
    }

    console.log('[API] ✅ External suggestion created:', suggestion.id);

    // Send Farcaster notifications to both users using unified notification service
    console.log('[API] Sending notification to both users:', userAData.username, '&', userBData.username);

    try {
      const notificationResult = await sendExternalSuggestionNotification(
        userAData,
        userBData,
        suggestion.id,
        session.username,
        session.signerUuid // Pass user's delegated signer if available
      );

      if (notificationResult.success) {
        console.log('[API] ✅ External suggestion notification sent successfully');
        console.log('[API] Cast hash:', notificationResult.castHash);
        console.log('[API] Signer used:', notificationResult.signerUsed);
        console.log('[API] Signer status:', notificationResult.signerStatus);
      } else {
        console.warn('[API] ⚠️ Failed to send notification:', notificationResult.error);
        console.warn('[API] Signer used:', notificationResult.signerUsed);
        console.warn('[API] Signer status:', notificationResult.signerStatus);
        // Don't fail the suggestion creation if notification fails - it's a best-effort delivery
      }
    } catch (notifError) {
      console.error('[API] Error sending Farcaster notification:', notifError);
      // Don't fail the suggestion creation if notification fails
    }

    return NextResponse.json(
      {
        success: true,
        suggestion: {
          id: suggestion.id,
          status: suggestion.status,
          created_at: suggestion.created_at,
          user_a: userAData,
          user_b: userBData,
        },
        message: `External suggestion created! Notifications sent to @${userAData.username} and @${userBData.username} on Farcaster.`,
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('[API] External suggestions error (uncaught):', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      {
        error: 'Failed to create external suggestion',
        message: errorMessage,
      },
      { status: 500 }
    );
  }
}
