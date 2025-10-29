/**
 * Neynar Delegated Signer API Route
 * Enables users to send Farcaster messages using delegated signers
 */

import { NextRequest, NextResponse } from 'next/server';
import { getSession } from '@/lib/auth';

const NEYNAR_API_BASE = 'https://api.neynar.com/v2';

/**
 * POST /api/neynar/delegate
 * Request a delegated signer token for a user's FID
 */
export async function POST(request: NextRequest) {
  try {
    console.log('[API Delegate] Creating delegated signer...');

    // Verify authentication
    const session = await getSession();
    if (!session) {
      console.log('[API Delegate] ❌ No session found');
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const apiKey = process.env.NEYNAR_API_KEY;
    if (!apiKey) {
      console.error('[API Delegate] ❌ NEYNAR_API_KEY not configured');
      return NextResponse.json(
        { error: 'Neynar API not configured' },
        { status: 500 }
      );
    }

    // Get FID from request body (optional) or use session FID
    const body = await request.json();
    const fid = body.fid || session.fid;

    // Validate FID matches session (security check)
    if (fid !== session.fid) {
      console.log('[API Delegate] ❌ FID mismatch - security violation');
      return NextResponse.json(
        { error: 'Cannot request signer for another user' },
        { status: 403 }
      );
    }

    console.log('[API Delegate] Requesting delegated signer for FID:', fid);

    // Request delegated signer from Neynar
    // Token expires in 24 hours (86400 seconds)
    const response = await fetch(`${NEYNAR_API_BASE}/farcaster/signer`, {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fid: fid,
        deadline: Math.floor(Date.now() / 1000) + 86400, // 24 hours from now
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[API Delegate] ❌ Neynar API error:', response.status, errorText);

      // Parse error if JSON
      let errorMessage = 'Failed to create delegated signer';
      try {
        const errorData = JSON.parse(errorText);
        errorMessage = errorData.message || errorMessage;
      } catch {
        errorMessage = errorText || errorMessage;
      }

      return NextResponse.json(
        {
          error: errorMessage,
          details: `Neynar API returned ${response.status}`,
        },
        { status: response.status }
      );
    }

    const data = await response.json();
    console.log('[API Delegate] ✅ Delegated signer created successfully');
    console.log('[API Delegate] Signer UUID:', data.signer_uuid);

    return NextResponse.json({
      success: true,
      signerUuid: data.signer_uuid,
      publicKey: data.public_key,
      status: data.status,
      fid: fid,
      expiresIn: 86400,
    });
  } catch (error) {
    console.error('[API Delegate] ❌ Unexpected error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      {
        error: 'Failed to create delegated signer',
        message: errorMessage,
      },
      { status: 500 }
    );
  }
}

/**
 * GET /api/neynar/delegate
 * Check if user has a valid delegated signer
 */
export async function GET(request: NextRequest) {
  try {
    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Check if session has a signer UUID
    const hasDelegate = !!(session as any).signerUuid;

    return NextResponse.json({
      hasDelegate,
      fid: session.fid,
      signerUuid: hasDelegate ? (session as any).signerUuid : null,
    });
  } catch (error) {
    console.error('[API Delegate GET] Error:', error);
    return NextResponse.json(
      { error: 'Failed to check delegate status' },
      { status: 500 }
    );
  }
}
