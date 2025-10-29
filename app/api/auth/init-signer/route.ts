/**
 * Initialize Delegated Signer API Route
 * Called after user authentication to set up delegated Farcaster signer
 */

import { NextRequest, NextResponse } from 'next/server';
import { getSession, updateSessionSigner } from '@/lib/auth';

const NEYNAR_API_BASE = 'https://api.neynar.com/v2';

/**
 * POST /api/auth/init-signer
 * Initialize or retrieve delegated signer for the authenticated user
 */
export async function POST(request: NextRequest) {
  try {
    console.log('[API Init Signer] Initializing delegated signer...');

    const session = await getSession();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // If session already has a signer, return it
    if (session.signerUuid) {
      console.log('[API Init Signer] ✅ Session already has delegated signer');
      return NextResponse.json({
        success: true,
        signerUuid: session.signerUuid,
        cached: true,
      });
    }

    const apiKey = process.env.NEYNAR_API_KEY;
    if (!apiKey) {
      console.error('[API Init Signer] ❌ NEYNAR_API_KEY not configured');
      return NextResponse.json(
        {
          success: false,
          error: 'Neynar API not configured',
        },
        { status: 500 }
      );
    }

    console.log('[API Init Signer] Requesting new delegated signer for FID:', session.fid);

    // Request delegated signer from Neynar
    const response = await fetch(`${NEYNAR_API_BASE}/farcaster/signer`, {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fid: session.fid,
        deadline: Math.floor(Date.now() / 1000) + 86400, // 24 hours
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[API Init Signer] ❌ Neynar API error:', response.status, errorText);

      return NextResponse.json(
        {
          success: false,
          error: 'Failed to create delegated signer',
          details: errorText,
        },
        { status: response.status }
      );
    }

    const data = await response.json();
    console.log('[API Init Signer] ✅ Delegated signer created');

    // Update session with the new signer
    if (data.signer_uuid) {
      await updateSessionSigner(data.signer_uuid);
      console.log('[API Init Signer] ✅ Signer stored in session');
    }

    return NextResponse.json({
      success: true,
      signerUuid: data.signer_uuid,
      publicKey: data.public_key,
      status: data.status,
      cached: false,
    });
  } catch (error) {
    console.error('[API Init Signer] ❌ Unexpected error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
