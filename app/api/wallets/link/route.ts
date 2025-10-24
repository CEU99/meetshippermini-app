import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/auth';
import { getServerSupabase } from '@/lib/supabase';

/**
 * POST /api/wallets/link
 * Link a wallet address to the authenticated user's Farcaster account
 *
 * Request body:
 * {
 *   "address": "0x...",
 *   "chainId": 8453
 * }
 *
 * Response:
 * 201 - Wallet linked successfully
 * 400 - Invalid address or chainId
 * 401 - Unauthorized (no session)
 * 500 - Internal server error
 */
export async function POST(request: NextRequest) {
  try {
    console.log('=== POST /api/wallets/link ===');

    // Step 1: Authenticate user via JWT session
    const session = await requireAuth();
    console.log('✅ Authenticated FID:', session.fid);

    // Step 2: Parse request body
    let body;
    try {
      body = await request.json();
    } catch (error) {
      console.error('❌ Invalid JSON:', error);
      return NextResponse.json(
        { error: 'Invalid JSON in request body' },
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const { address, chainId } = body;

    console.log('📦 Request body:');
    console.log('   Address:', address);
    console.log('   Chain ID:', chainId);

    // Step 3: Validate address
    if (!address || typeof address !== 'string') {
      console.error('❌ Validation failed: address is missing or invalid');
      return NextResponse.json(
        { error: 'Address is required and must be a string' },
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Validate Ethereum address format (0x followed by 40 hex characters)
    const addressRegex = /^0x[a-fA-F0-9]{40}$/;
    if (!addressRegex.test(address)) {
      console.error('❌ Validation failed: invalid Ethereum address format');
      return NextResponse.json(
        { error: 'Invalid Ethereum address format. Must be 0x followed by 40 hexadecimal characters' },
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Step 4: Validate chainId
    if (!chainId || typeof chainId !== 'number') {
      console.error('❌ Validation failed: chainId is missing or invalid');
      return NextResponse.json(
        { error: 'Chain ID is required and must be a number' },
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Validate supported chains (Base mainnet and Base Sepolia)
    const supportedChainIds = [8453, 84532];
    if (!supportedChainIds.includes(chainId)) {
      console.error('❌ Validation failed: unsupported chain ID');
      return NextResponse.json(
        {
          error: 'Unsupported chain ID. Supported chains: 8453 (Base), 84532 (Base Sepolia)',
          supportedChainIds
        },
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    console.log('✅ Validation passed');

    // Step 5: Upsert wallet to database
    const supabase = getServerSupabase();

    // Normalize address to lowercase for consistency
    const normalizedAddress = address.toLowerCase();

    console.log('🔄 Upserting wallet for FID:', session.fid);

    const { data, error } = await supabase
      .from('user_wallets')
      .upsert(
        {
          fid: session.fid,
          wallet_address: normalizedAddress,
          chain_id: chainId,
          updated_at: new Date().toISOString(),
        },
        {
          onConflict: 'fid', // Update if fid already exists
          ignoreDuplicates: false, // Always update with new values
        }
      )
      .select()
      .single();

    // Handle database errors
    if (error) {
      console.error('❌ Database error:', error);

      // Handle specific error codes
      if (error.code === '23503') {
        // Foreign key violation - user doesn't exist
        return NextResponse.json(
          { error: 'User not found. Please ensure your Farcaster account is registered.' },
          { status: 404, headers: { 'Content-Type': 'application/json' } }
        );
      }

      if (error.code === '42P01') {
        // Table doesn't exist
        return NextResponse.json(
          {
            error: 'Database table not found. Please run supabase-user-wallets-table.sql migration.',
            migrationFile: 'supabase-user-wallets-table.sql'
          },
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
      }

      // Generic database error
      return NextResponse.json(
        { error: 'Failed to link wallet', message: error.message },
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Success
    console.log('✅ Wallet linked successfully');
    console.log('   FID:', session.fid);
    console.log('   Address:', normalizedAddress);
    console.log('   Chain ID:', chainId);

    return NextResponse.json(
      {
        ok: true,
        wallet: {
          id: data.id,
          fid: data.fid,
          address: data.wallet_address,
          chainId: data.chain_id,
          createdAt: data.created_at,
          updatedAt: data.updated_at,
        },
      },
      { status: 201, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('❌ POST /api/wallets/link error:', error);

    // Handle authentication errors
    if (error instanceof Error && error.message === 'Unauthorized') {
      return NextResponse.json(
        { error: 'Unauthorized', message: 'Please sign in to link a wallet' },
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Handle other errors
    return NextResponse.json(
      {
        error: 'Internal server error',
        message: error instanceof Error ? error.message : 'An unknown error occurred'
      },
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}
