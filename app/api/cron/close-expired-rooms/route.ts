import { NextRequest, NextResponse } from 'next/server';
import { autoCloseExpiredRooms } from '@/lib/services/meeting-service';

/**
 * GET /api/cron/close-expired-rooms
 *
 * Cron endpoint to automatically close expired meeting rooms
 *
 * This endpoint should be called periodically (every 5-10 minutes) by:
 * - Vercel Cron Jobs (vercel.json configuration)
 * - External cron service (e.g., cron-job.org, EasyCron)
 * - Supabase Edge Functions with pg_cron
 *
 * Security: Add CRON_SECRET to .env and verify it here to prevent unauthorized access
 */
export async function GET(request: NextRequest) {
  try {
    // Verify cron secret for security
    const authHeader = request.headers.get('authorization');
    const cronSecret = process.env.CRON_SECRET;

    if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
      console.error('[Cron] Unauthorized access attempt');
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    console.log('[Cron] Starting auto-close job...');
    const startTime = Date.now();

    // Run the auto-close function
    const result = await autoCloseExpiredRooms();

    const duration = Date.now() - startTime;

    console.log('[Cron] Auto-close job completed:', {
      duration: `${duration}ms`,
      ...result,
    });

    return NextResponse.json({
      success: true,
      ...result,
      duration_ms: duration,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    console.error('[Cron] Error in auto-close job:', error);
    return NextResponse.json(
      {
        success: false,
        error: 'Internal server error',
        message: error?.message,
      },
      { status: 500 }
    );
  }
}

// Also allow POST for flexibility with different cron services
export async function POST(request: NextRequest) {
  return GET(request);
}
