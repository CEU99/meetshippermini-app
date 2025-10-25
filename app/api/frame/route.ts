import { NextRequest, NextResponse } from 'next/server';

// === CONFIGURATION ===
const BASE_URL =
  process.env.NODE_ENV === 'production'
    ? 'https://meetshipper.com'
    : 'http://localhost:3000';

const FRAME_IMAGE = `${BASE_URL}/cover.png`;

// === FRAME HTML GENERATOR ===
function generateFrameHTML(
  image: string,
  buttons: { label: string; action?: string }[],
  postUrl: string,
  state?: string
) {
  const buttonTags = buttons
    .map(
      (btn, idx) => `
    <meta property="fc:frame:button:${idx + 1}" content="${btn.label}" />
    ${btn.action ? `<meta property="fc:frame:button:${idx + 1}:action" content="${btn.action}" />` : ''}
    ${btn.action === 'post_redirect'
      ? `<meta property="fc:frame:button:${idx + 1}:target" content="${BASE_URL}/mini/contract-test" />`
      : ''}`
    )
    .join('');

  return `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>MeetShipper - Base Mini App</title>

    <!-- Open Graph -->
    <meta property="og:title" content="MeetShipper - Connect & Meet on Base" />
    <meta property="og:description" content="Find your perfect match and verify on Base blockchain" />
    <meta property="og:image" content="${image}" />

    <!-- Farcaster Frame Tags -->
    <meta property="fc:frame" content="vNext" />
    <meta property="fc:frame:image" content="${image}" />
    <meta property="fc:frame:image:aspect_ratio" content="1.91:1" />
    <meta property="fc:frame:post_url" content="${postUrl}" />
    ${state ? `<meta property="fc:frame:state" content="${encodeURIComponent(state)}" />` : ''}
    ${buttonTags}

    <!-- Base Chain Support -->
    <meta property="fc:frame:chain" content="base" />
  </head>
  <body style="margin:0">
    <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;font-family:system-ui,-apple-system,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;">
      <h1 style="font-size:3rem;margin-bottom:1rem;">MeetShipper</h1>
      <p style="font-size:1.5rem;margin-bottom:2rem;">Base Mini App Frame</p>
      <img src="${image}" alt="Frame Preview" style="max-width:600px;width:90%;border-radius:12px;box-shadow:0 10px 40px rgba(0,0,0,0.3);" />
      <p style="margin-top:2rem;opacity:0.9;">
        <span 
          style="color:white;text-decoration:none;cursor:pointer;transition:all 0.3s;"
          onmouseover="this.style.opacity='0.7';this.style.textDecoration='underline';"
          onmouseout="this.style.opacity='1';this.style.textDecoration='none';"
          onclick="const url='${BASE_URL}/api/frame'; window.open(url, '_blank');"
        >
          🔗 Open this in Farcaster to interact
        </span>
      </p>
    </div>
  </body>
</html>`;
}

// === PARSE FARCASTER FRAME MESSAGE ===
async function parseFrameMessage(req: NextRequest) {
  try {
    const body = await req.json();
    const { untrustedData, trustedData } = body;

    return {
      fid: untrustedData?.fid,
      buttonIndex: untrustedData?.buttonIndex,
      inputText: untrustedData?.inputText,
      state: untrustedData?.state,
      castId: untrustedData?.castId,
      messageBytes: trustedData?.messageBytes,
    };
  } catch (error) {
    console.error('Error parsing frame message:', error);
    return null;
  }
}

// === GET HANDLER ===
export async function GET(req: NextRequest) {
  const postUrl = `${BASE_URL}/api/frame`;

  const html = generateFrameHTML(
    FRAME_IMAGE,
    [
      { label: 'Start Match', action: 'post' },
      { label: 'View Stats', action: 'post' },
      { label: 'Verify on Base', action: 'post_redirect' },
    ],
    postUrl
  );

  return new NextResponse(html, {
    headers: {
      'Content-Type': 'text/html',
      'Cache-Control': 'public, max-age=60',
    },
  });
}

// === POST HANDLER ===
export async function POST(req: NextRequest) {
  const frameData = await parseFrameMessage(req);

  if (!frameData) {
    return new NextResponse('Invalid frame message', { status: 400 });
  }

  const { fid, buttonIndex } = frameData;
  const postUrl = `${BASE_URL}/api/frame`;

  switch (buttonIndex) {
    case 1:
      const matchHtml = generateFrameHTML(
        FRAME_IMAGE,
        [
          { label: '🎯 Finding Match...', action: 'post' },
          { label: 'View Profile', action: 'post' },
          { label: 'Open App', action: 'post_redirect' },
        ],
        postUrl,
        JSON.stringify({ fid, step: 'matching' })
      );
      return new NextResponse(matchHtml, { headers: { 'Content-Type': 'text/html' } });

    case 2:
      const statsHtml = generateFrameHTML(
        FRAME_IMAGE,
        [
          { label: '« Back', action: 'post' },
          { label: 'Refresh Stats', action: 'post' },
          { label: 'Open Dashboard', action: 'post_redirect' },
        ],
        postUrl,
        JSON.stringify({ fid, step: 'stats' })
      );
      return new NextResponse(statsHtml, { headers: { 'Content-Type': 'text/html' } });

    case 3:
      return NextResponse.redirect(`${BASE_URL}/mini/contract-test?fid=${fid}`, 302);

    default:
      return GET(req);
  }
}

// === OPTIONS HANDLER ===
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}