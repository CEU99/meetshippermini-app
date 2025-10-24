import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { getServerSupabase } from '@/lib/supabase';

// ============================================================================
// Zod Validation Schemas
// ============================================================================

const createAttestationSchema = z.object({
  username: z.string().min(1, 'Username is required').max(255, 'Username is too long'),
  wallet: z.string().regex(/^0x[a-fA-F0-9]{40}$/, 'Invalid Ethereum wallet address'),
  txHash: z.string().regex(/^0x[a-fA-F0-9]{64}$/, 'Invalid transaction hash'),
  attestationUID: z.string().min(1, 'Attestation UID is required').max(255, 'Attestation UID is too long'),
  fid: z.number().int().positive('FID must be a valid Farcaster user ID'), // 🔥 added
});

type CreateAttestationInput = z.infer<typeof createAttestationSchema>;

// ============================================================================
// Database Types
// ============================================================================

interface Attestation {
  id: string;
  username: string;
  wallet_address: string;
  tx_hash: string;
  attestation_uid: string;
  fid: number | null;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// POST Handler - Create a new attestation record
// ============================================================================

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const validationResult = createAttestationSchema.safeParse(body);

    if (!validationResult.success) {
      const errors = validationResult.error.issues.map((err: any) => ({
        field: err.path.join('.'),
        message: err.message,
      }));
      return NextResponse.json(
        { success: false, error: 'Validation failed', details: errors },
        { status: 400 }
      );
    }

    const { username, wallet, txHash, attestationUID, fid } = validationResult.data;

    const supabase = getServerSupabase();

    // 🔒 Check for duplicates (username + wallet + fid)
    const { data: existingRecords, error: checkError } = await supabase
      .from('attestations')
      .select('username, wallet_address, fid')
      .or(`username.eq.${username},wallet_address.eq.${wallet.toLowerCase()}`)
      .eq('fid', fid);

    if (checkError) {
      console.error('Error checking for existing records:', checkError);
      return NextResponse.json(
        { success: false, error: 'Database error while checking duplicates', details: checkError.message },
        { status: 500 }
      );
    }

    if (existingRecords && existingRecords.length > 0) {
      const existingUsername = existingRecords.find(r => r.username === username);
      const existingWallet = existingRecords.find(r => r.wallet_address.toLowerCase() === wallet.toLowerCase());

      if (existingUsername && existingWallet) {
        return NextResponse.json(
          { success: false, error: 'Record already exists for this username and wallet' },
          { status: 409 }
        );
      } else if (existingUsername) {
        return NextResponse.json(
          { success: false, error: `Record already exists for username "${username}"` },
          { status: 409 }
        );
      } else if (existingWallet) {
        return NextResponse.json(
          { success: false, error: `Record already exists for wallet ${wallet}` },
          { status: 409 }
        );
      }
    }

    // 🔎 Check if attestation UID already exists for this user
    const { data: existingAttestation, error: uidCheckError } = await supabase
      .from('attestations')
      .select('attestation_uid')
      .eq('attestation_uid', attestationUID)
      .eq('fid', fid)
      .single();

    if (uidCheckError && uidCheckError.code !== 'PGRST116') {
      console.error('Error checking attestation UID:', uidCheckError);
      return NextResponse.json(
        { success: false, error: 'Database error while checking attestation UID', details: uidCheckError.message },
        { status: 500 }
      );
    }

    if (existingAttestation) {
      return NextResponse.json(
        { success: false, error: 'Attestation UID already exists for this user' },
        { status: 409 }
      );
    }

    // ✅ Insert with FID isolation
    const { data: newAttestation, error: insertError } = await supabase
      .from('attestations')
      .insert({
        username,
        wallet_address: wallet.toLowerCase(),
        tx_hash: txHash,
        attestation_uid: attestationUID,
        fid, // ✅ FID kaydediliyor
      })
      .select()
      .single();

    if (insertError) {
      console.error('Error inserting attestation:', insertError);
      return NextResponse.json(
        { success: false, error: 'Failed to save attestation', details: insertError.message },
        { status: 500 }
      );
    }

    return NextResponse.json(
      {
        success: true,
        message: 'Attestation saved successfully',
        data: {
          id: newAttestation.id,
          username: newAttestation.username,
          walletAddress: newAttestation.wallet_address,
          fid: newAttestation.fid,
          txHash: newAttestation.tx_hash,
          attestationUID: newAttestation.attestation_uid,
          createdAt: newAttestation.created_at,
        },
      },
      { status: 200 }
    );
  } catch (error: any) {
    console.error('Unexpected error in POST /api/attestations:', error);
    if (error instanceof SyntaxError) {
      return NextResponse.json({ success: false, error: 'Invalid JSON in request body' }, { status: 400 });
    }
    return NextResponse.json(
      { success: false, error: 'Internal server error', details: error.message || 'Unknown error' },
      { status: 500 }
    );
  }
}

// ============================================================================
// GET Handler - Retrieve attestation records (filtered by FID)
// ============================================================================

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const fid = searchParams.get('fid'); // 🔥 Optional filter by FID
    const limit = parseInt(searchParams.get('limit') || '20', 10);
    const wallet = searchParams.get('wallet') || searchParams.get('walletAddress');
    const username = searchParams.get('username');
    const attestationUID = searchParams.get('attestationUID');

    const supabase = getServerSupabase();

    let query = supabase
      .from('attestations')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (fid) query = query.eq('fid', Number(fid)); // ✅ isolation filter
    if (wallet) query = query.eq('wallet_address', wallet.toLowerCase());
    if (username) query = query.eq('username', username);
    if (attestationUID) query = query.eq('attestation_uid', attestationUID);

    const { data: attestations, error: fetchError } = await query;

    if (fetchError) {
      console.error('Error fetching attestations:', fetchError);
      return NextResponse.json(
        { success: false, error: 'Failed to fetch attestations', details: fetchError.message },
        { status: 500 }
      );
    }

    const formatted = attestations.map((a: Attestation) => ({
      id: a.id,
      username: a.username,
      walletAddress: a.wallet_address,
      txHash: a.tx_hash,
      attestationUID: a.attestation_uid,
      fid: a.fid,
      createdAt: a.created_at,
    }));

    return NextResponse.json({ success: true, count: formatted.length, data: formatted }, { status: 200 });
  } catch (error: any) {
    console.error('Unexpected error in GET /api/attestations:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error', details: error.message || 'Unknown error' },
      { status: 500 }
    );
  }
}