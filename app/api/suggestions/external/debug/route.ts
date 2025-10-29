import { NextRequest, NextResponse } from 'next/server';

/**
 * GET /api/suggestions/external/debug
 * Diagnostic endpoint to troubleshoot 401 Unauthorized issues
 *
 * Usage:
 * curl https://www.meetshipper.com/api/suggestions/external/debug \
 *   -H "Authorization: Bearer YOUR_KEY"
 */
export async function GET(request: NextRequest) {
  const authHeader = request.headers.get('authorization');
  const apiKey = process.env.NEYNAR_API_KEY;

  // Safe truncation for logging (don't expose full keys)
  const truncatedHeader = authHeader
    ? `${authHeader.substring(0, 30)}...${authHeader.substring(authHeader.length - 4)}`
    : null;

  const truncatedEnvKey = apiKey
    ? `${apiKey.substring(0, 20)}...${apiKey.substring(apiKey.length - 4)}`
    : null;

  const providedKey = authHeader?.startsWith('Bearer ')
    ? authHeader.substring(7)
    : null;

  const diagnostics = {
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'unknown',
    vercelEnv: process.env.VERCEL_ENV || 'not-vercel',

    // Check 1: Authorization header received?
    authHeaderReceived: !!authHeader,
    authHeaderFormat: authHeader?.startsWith('Bearer ') ? 'valid' : 'invalid',
    authHeaderPreview: truncatedHeader,

    // Check 2: Environment variable loaded?
    envKeyLoaded: !!apiKey,
    envKeyPreview: truncatedEnvKey,

    // Check 3: Do they match?
    keysMatch: providedKey && apiKey ? providedKey === apiKey : false,

    // Diagnostics
    issues: [] as string[],
    recommendations: [] as string[],
  };

  // Issue detection
  if (!authHeader) {
    diagnostics.issues.push('No Authorization header received');
    diagnostics.recommendations.push('Ensure your request includes: -H "Authorization: Bearer YOUR_KEY"');
    diagnostics.recommendations.push('Check if a redirect (308) is stripping the header');
  } else if (!authHeader.startsWith('Bearer ')) {
    diagnostics.issues.push('Authorization header format is invalid');
    diagnostics.recommendations.push('Header must start with "Bearer " (note the space)');
  }

  if (!apiKey) {
    diagnostics.issues.push('NEYNAR_API_KEY environment variable is NOT loaded in production');
    diagnostics.recommendations.push('Go to Vercel Dashboard → Settings → Environment Variables');
    diagnostics.recommendations.push('Add NEYNAR_API_KEY with scope set to "Production"');
    diagnostics.recommendations.push('Redeploy after adding the environment variable');
  }

  if (providedKey && apiKey && providedKey !== apiKey) {
    diagnostics.issues.push('API key mismatch - the provided key does not match the environment variable');
    diagnostics.recommendations.push('Verify the key in your Vercel dashboard matches the one in your request');
    diagnostics.recommendations.push('Ensure there are no extra spaces or characters');
  }

  if (diagnostics.issues.length === 0 && providedKey && apiKey && providedKey === apiKey) {
    diagnostics.issues.push('No issues detected - authentication should work!');
    diagnostics.recommendations.push('Try the actual POST request to /api/suggestions/external');
    diagnostics.recommendations.push('If still failing, check for CORS or other middleware issues');
  }

  const statusCode = diagnostics.issues.length > 0 && !diagnostics.keysMatch ? 400 : 200;

  return NextResponse.json({
    status: diagnostics.keysMatch ? 'healthy' : 'unhealthy',
    diagnostics,
    message: diagnostics.keysMatch
      ? '✅ Authentication is configured correctly'
      : '❌ Authentication configuration has issues',
  }, { status: statusCode });
}

/**
 * POST /api/suggestions/external/debug
 * Test the actual authentication logic without creating a suggestion
 */
export async function POST(request: NextRequest) {
  const authHeader = request.headers.get('authorization');
  const apiKey = process.env.NEYNAR_API_KEY;

  console.log('[DEBUG] 🔹 Received POST request');
  console.log('[DEBUG] 🔹 AUTH HEADER:', authHeader ? `Bearer ${authHeader.substring(7, 27)}...` : 'None');
  console.log('[DEBUG] 🔹 ENV KEY:', apiKey ? `${apiKey.substring(0, 20)}...` : 'None');
  console.log('[DEBUG] 🔹 NODE_ENV:', process.env.NODE_ENV);
  console.log('[DEBUG] 🔹 VERCEL_ENV:', process.env.VERCEL_ENV);

  // Simulate the actual auth logic
  if (!authHeader) {
    console.log('[DEBUG] ❌ No Authorization header');
    return NextResponse.json({
      error: 'No Authorization header',
      help: 'Include: -H "Authorization: Bearer YOUR_KEY"',
    }, { status: 401 });
  }

  if (!authHeader.startsWith('Bearer ')) {
    console.log('[DEBUG] ❌ Invalid Authorization header format');
    return NextResponse.json({
      error: 'Invalid Authorization header format',
      help: 'Must start with "Bearer " (with space)',
    }, { status: 401 });
  }

  if (!apiKey) {
    console.log('[DEBUG] ❌ NEYNAR_API_KEY not loaded');
    return NextResponse.json({
      error: 'NEYNAR_API_KEY environment variable not loaded',
      help: 'Add to Vercel Dashboard → Settings → Environment Variables (Production scope)',
    }, { status: 500 });
  }

  const providedKey = authHeader.substring(7);

  if (providedKey !== apiKey) {
    console.log('[DEBUG] ❌ API key mismatch');
    console.log('[DEBUG]    Provided length:', providedKey.length);
    console.log('[DEBUG]    Expected length:', apiKey.length);
    console.log('[DEBUG]    First 20 chars match:', providedKey.substring(0, 20) === apiKey.substring(0, 20));
    return NextResponse.json({
      error: 'Invalid API key',
      help: 'The provided key does not match NEYNAR_API_KEY',
    }, { status: 401 });
  }

  console.log('[DEBUG] ✅ Authentication successful!');

  return NextResponse.json({
    success: true,
    message: '✅ Authentication works! The actual endpoint should work now.',
    authenticated: true,
    method: 'API Key',
  }, { status: 200 });
}
