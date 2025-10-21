// app/api/cron/auto-match/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { runAutomaticMatching, shouldRunAutoMatching } from '@/lib/services/auto-match-runner';

/**
 * GET/POST /api/cron/auto-match
 * - Protected with CRON_SECRET
 * - In development, also accepts `?secret=` for convenience
 * - In production, Authorization header is REQUIRED
 */

function isDev() {
  return process.env.NODE_ENV !== 'production';
}

function unauthorized(message = 'Unauthorized') {
  return NextResponse.json({ error: message }, { status: 401 });
}

function getProvidedSecret(req: NextRequest) {
  const authHeader = req.headers.get('authorization') || '';
  // Expect "Bearer <token>"
  const tokenFromHeader = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  const tokenFromQuery = req.nextUrl.searchParams.get('secret'); // dev convenience
  return tokenFromHeader || tokenFromQuery || null;
}

async function handle(req: NextRequest) {
  try {
    const configuredSecret = process.env.CRON_SECRET || '';
    const providedSecret = getProvidedSecret(req);

    // Security rules:
    // - If CRON_SECRET is set: must match (prod & dev)
    // - If CRON_SECRET is NOT set:
    //     * allow only in development
    //     * block in production
    if (configuredSecret) {
      if (!providedSecret || providedSecret !== configuredSecret) {
        console.error('[Cron] Unauthorized access attempt (bad/missing secret)');
        return unauthorized();
      }
    } else {
      if (!isDev()) {
        console.error('[Cron] Missing CRON_SECRET in production');
        return unauthorized('Missing CRON_SECRET');
      } else {
        console.warn('[Cron] CRON_SECRET not set (allowed only in development)');
      }
    }

    console.log('[Cron] Auto-match job triggered');

    // Respect interval (skip if ran recently)
    const shouldRun = await shouldRunAutoMatching();
    if (!shouldRun) {
      console.log('[Cron] Skipping - ran recently');
      return NextResponse.json({
        success: true,
        message: 'Auto-matching ran recently, skipping',
        skipped: true,
      });
    }

    // Run matching
    const result = await runAutomaticMatching();
    console.log(
      `[Cron] Auto-match completed: ${result.matchesCreated} matches created from ${result.usersProcessed} users`
    );

    return NextResponse.json({
      success: true,
      result: {
        runId: result.runId,
        usersProcessed: result.usersProcessed,
        matchesCreated: result.matchesCreated,
        duration: result.duration,
        errors: result.errors.length > 0 ? result.errors : undefined,
      },
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error('[Cron] Auto-match error:', error);
    return NextResponse.json(
      { error: 'Failed to run automatic matching', message: errorMessage },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest) {
  return handle(request);
}

export async function POST(request: NextRequest) {
  return handle(request);
}