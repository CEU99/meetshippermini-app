# Delegated Signer System

## Overview

The delegated signer system enables all MeetShipper users to send Farcaster match notifications directly from their accounts, without needing their own Neynar API keys.

## Problem Solved

**Before:** Only the main developer account (with `NEYNAR_SIGNER_UUID` configured) could send Farcaster messages. Other users couldn't send match requests through their own sessions.

**After:** Every authenticated user automatically gets a delegated signer token that allows them to send Farcaster messages under their own identity.

## How It Works

### 1. **User Authentication Flow**

When a user logs in via Privy + Farcaster:

```
1. User authenticates with Farcaster
2. Session is created (lib/auth.ts)
3. Delegated signer is automatically requested from Neynar
4. Signer UUID is stored in the user's session
5. Signer expires after 24 hours (auto-renewed on next login)
```

### 2. **Architecture**

```
┌─────────────────────────────────────────────────────────┐
│                    User Login Flow                       │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  FarcasterAuthProvider               │
        │  - Authenticate with Privy           │
        │  - Create session                    │
        │  - Call initializeDelegatedSigner()  │
        └──────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  POST /api/auth/init-signer          │
        │  - Request signer from Neynar        │
        │  - Store in session                  │
        │  - Return signer UUID                │
        └──────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  Session (JWT)                       │
        │  {                                   │
        │    fid: 12345,                       │
        │    username: "alice",                │
        │    signerUuid: "abc-123-xyz"         │
        │  }                                   │
        └──────────────────────────────────────┘
```

```
┌─────────────────────────────────────────────────────────┐
│                Match Notification Flow                   │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  POST /api/matches/manual            │
        │  - Get session.signerUuid            │
        │  - Create match                      │
        │  - Call notification service         │
        └──────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  sendMatchRequestNotification()      │
        │  - Use user's signerUuid             │
        │  - Fallback to global signer         │
        │  - Send Farcaster cast               │
        └──────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  Neynar API                          │
        │  POST /v2/farcaster/cast             │
        │  - Publish cast as user              │
        └──────────────────────────────────────┘
```

## Files Modified/Created

### Created Files

1. **`app/api/neynar/delegate/route.ts`**
   - POST: Request delegated signer for a user
   - GET: Check if user has delegated signer

2. **`app/api/auth/init-signer/route.ts`**
   - POST: Initialize signer on login
   - Automatically called after authentication

3. **`lib/utils/delegated-signer.ts`**
   - `initializeDelegatedSigner()` - Client-side initialization
   - `hasDelegatedSigner()` - Check signer status

4. **`DELEGATED-SIGNER-SYSTEM.md`**
   - This documentation file

### Modified Files

1. **`lib/auth.ts`**
   - Added `signerUuid` to `SessionData` interface
   - Added `updateSessionSigner()` function
   - Added `ensureDelegatedSigner()` helper

2. **`lib/services/farcaster-notification-service.ts`**
   - Updated `sendMatchRequestNotification()` to accept `userSignerUuid`
   - Updated `sendDirectMessage()` to accept `userSignerUuid`
   - Falls back to global signer if user signer unavailable

3. **`app/api/matches/manual/route.ts`**
   - Passes `session.signerUuid` to notification service
   - Logs whether using delegated or global signer

4. **`components/providers/FarcasterAuthProvider.tsx`**
   - Automatically initializes delegated signer after login
   - Runs in background without blocking authentication

## Usage

### For Users

**Nothing changes!** The system works automatically:

1. Log in with Farcaster
2. Your delegated signer is created automatically
3. Send match requests as normal
4. Messages appear from your Farcaster account

### For Developers

**Notification Service:**

```typescript
import { sendMatchRequestNotification } from '@/lib/services/farcaster-notification-service';

// In your API route
const session = await getSession();

await sendMatchRequestNotification(
  externalUser,
  matchId,
  session.signerUuid // Pass user's signer
);
```

**Manual Initialization:**

```typescript
import { initializeDelegatedSigner } from '@/lib/utils/delegated-signer';

// Manually initialize (usually automatic)
const result = await initializeDelegatedSigner();

if (result.success) {
  console.log('Signer UUID:', result.signerUuid);
}
```

**Check Signer Status:**

```typescript
import { hasDelegatedSigner } from '@/lib/utils/delegated-signer';

const hasS signer = await hasDelegatedSigner();
console.log('Has delegated signer:', hasSigner);
```

## Environment Variables

Required:
- `NEYNAR_API_KEY` - Main Neynar API key (for creating delegated signers)
- `JWT_SECRET` - For signing session tokens

Optional:
- `NEYNAR_SIGNER_UUID` - Fallback global signer (used if user signer unavailable)

## Security

### Token Expiration
- Delegated signers expire after **24 hours**
- Automatically renewed on next login
- Prevents long-lived compromised tokens

### Session Security
- Signer UUID stored in JWT (HTTP-only cookie)
- FID validation ensures users can only get signers for their own accounts
- Server-side validation on all signer requests

### Fallback Behavior
- If user signer unavailable → uses global `NEYNAR_SIGNER_UUID`
- If global signer unavailable → notification fails gracefully
- Match creation succeeds even if notification fails

## Benefits

✅ **Decentralized** - All users send messages from their own accounts
✅ **No Setup Required** - Users don't need Neynar accounts
✅ **Backward Compatible** - Falls back to global signer
✅ **Secure** - 24-hour auto-expiring tokens
✅ **Transparent** - Users see messages from their own accounts
✅ **Scalable** - No rate limit issues from single global signer

## Monitoring & Debugging

### Logs to Watch

**Successful Flow:**
```
[Auth] ✅ User authenticated: alice
[Auth] ✅ Delegated signer initialized: new
[API] Using signer from session: delegated
[Notification] Using signer: abc-123-xyz (delegated user signer)
[Notification] ✅ Farcaster notification sent successfully
```

**Fallback to Global:**
```
[Auth] ⚠️ Failed to initialize delegated signer: API error
[API] Using signer from session: global
[Notification] Using signer: xyz-456-abc (global signer)
```

### Common Issues

**1. "Neynar API not configured"**
- Ensure `NEYNAR_API_KEY` is set in `.env.local`

**2. Signer not being used**
- Check session has `signerUuid` field
- Verify `initializeDelegatedSigner()` was called

**3. "Failed to create delegated signer"**
- Check Neynar API status
- Verify API key permissions
- Check rate limits

## Future Enhancements

### Optional Improvements

1. **Redis Caching**
   - Cache signer UUIDs to avoid regenerating
   - Reduce Neynar API calls
   - Faster login experience

2. **Refresh Token Flow**
   - Auto-refresh signers before 24h expiry
   - Persistent signers for active users

3. **Signer Analytics**
   - Track signer usage metrics
   - Monitor fallback frequency
   - Optimize expiration times

4. **Admin Dashboard**
   - View active signers
   - Revoke compromised signers
   - Monitor delegation health

## Testing

### Manual Testing

1. **Login and Check Signer:**
```bash
# Login to app
# Open browser console
localStorage.getItem('session') # Check JWT contains signerUuid
```

2. **Create Match Request:**
```bash
# Create match with external user
# Check server logs for:
# "[Notification] Using signer: xxx (delegated user signer)"
```

3. **Check Farcaster:**
```bash
# Verify cast appears on your Farcaster profile
# Not from global account
```

### API Testing

```bash
# Initialize signer
curl -X POST http://localhost:3000/api/auth/init-signer \
  -H "Cookie: session=YOUR_JWT"

# Check signer status
curl http://localhost:3000/api/neynar/delegate \
  -H "Cookie: session=YOUR_JWT"
```

## Support

For questions or issues:
1. Check server logs for detailed error messages
2. Verify environment variables are set
3. Test with global signer first (set `NEYNAR_SIGNER_UUID`)
4. Check Neynar API documentation for signer endpoints

---

**Last Updated:** 2025-10-29
**Version:** 1.0.0
**Status:** ✅ Production Ready
