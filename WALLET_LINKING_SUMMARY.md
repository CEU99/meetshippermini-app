# Wallet Linking Feature - Implementation Summary

## Overview

A complete wallet linking system has been implemented to allow Farcaster users to link their Ethereum wallet addresses to their Meet Shipper accounts.

## What Was Created

### 1. Database Schema
**File**: `supabase-user-wallets-table.sql`

Creates `user_wallets` table with:
- UUID primary key
- Unique FID (one wallet per user)
- Wallet address (normalized to lowercase)
- Chain ID (Base mainnet or Base Sepolia)
- Timestamps
- Foreign key to users table
- RLS policies
- Indexes for performance

### 2. API Route
**File**: `app/api/wallets/link/route.ts`

**Endpoint**: `POST /api/wallets/link`

**Features**:
- ✅ Farcaster JWT authentication
- ✅ Ethereum address validation (0x + 40 hex chars)
- ✅ Chain ID validation (8453, 84532 only)
- ✅ Idempotent upsert (creates or updates)
- ✅ Address normalization (lowercase)
- ✅ Comprehensive error handling
- ✅ Proper HTTP status codes

**Request**:
```json
{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
  "chainId": 8453
}
```

**Response** (201):
```json
{
  "ok": true,
  "wallet": {
    "id": "uuid",
    "fid": 12345,
    "address": "0x742d35cc6634c0532925a3b844bc9e7595f0beb8",
    "chainId": 8453,
    "createdAt": "2025-01-23T10:30:00Z",
    "updatedAt": "2025-01-23T10:30:00Z"
  }
}
```

### 3. TypeScript Interface
**File**: `lib/supabase.ts` (updated)

Added `UserWallet` interface:
```typescript
export interface UserWallet {
  id: string;
  fid: number;
  wallet_address: string;
  chain_id: number;
  created_at: string;
  updated_at: string;
}
```

### 4. Documentation
- `WALLET_LINKING_SETUP.md` - Complete setup guide
- `WALLET_LINKING_TESTING.md` - Testing instructions
- `WALLET_LINKING_SUMMARY.md` - This file

## Installation

### Step 1: Create Database Table

```bash
# Run in Supabase SQL Editor
# File: supabase-user-wallets-table.sql
```

### Step 2: Verify API Endpoint

```bash
# Start dev server
pnpm run dev

# Test endpoint (should return 401 without auth)
curl -X POST http://localhost:3000/api/wallets/link \
  -H "Content-Type: application/json" \
  -d '{"address":"0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8","chainId":8453}'
```

### Step 3: Test with Authentication

Sign in via Farcaster, then test wallet linking through your app.

## Validation Rules

### Address Validation
- ✅ Must be a string
- ✅ Must start with "0x"
- ✅ Must be exactly 42 characters (0x + 40 hex)
- ✅ Must contain only hexadecimal characters (0-9, a-f, A-F)
- ✅ Automatically normalized to lowercase

**Valid Examples**:
- `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8`
- `0x1234567890123456789012345678901234567890`
- `0xABCDEF1234567890ABCDEF1234567890ABCDEF12`

**Invalid Examples**:
- `742d35Cc6634C0532925a3b844Bc9e7595f0bEb8` (missing 0x)
- `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb` (wrong length)
- `0xZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ` (invalid hex)

### Chain ID Validation
- ✅ Must be a number
- ✅ Must be one of: 8453 (Base) or 84532 (Base Sepolia)

**Valid**:
- `8453` (Base Mainnet)
- `84532` (Base Sepolia)

**Invalid**:
- `1` (Ethereum mainnet - not supported)
- `"8453"` (string instead of number)
- `-1` (negative number)

## Error Handling

| Status Code | Error | Cause | Solution |
|-------------|-------|-------|----------|
| 201 | Success | Wallet linked | - |
| 400 | Invalid address | Wrong format | Fix address format |
| 400 | Invalid chainId | Unsupported chain | Use Base or Base Sepolia |
| 401 | Unauthorized | No session | Sign in first |
| 404 | User not found | FID not in DB | Ensure user is registered |
| 500 | Table not found | Migration not run | Run SQL migration |
| 500 | Database error | Various | Check logs |

## Security Features

### Authentication
- JWT session validation via `requireAuth()`
- Service role for database operations

### Validation
- Regex validation for address format
- Chain ID whitelist
- Type checking for all inputs

### Database
- Row Level Security (RLS) enabled
- Unique constraint on FID
- Foreign key to users table
- Idempotent upsert (ON CONFLICT)

### Data Integrity
- Address normalization (lowercase)
- Automatic timestamps
- UUID primary key
- No duplicate FIDs allowed

## Integration with Wagmi

### Example Hook

```typescript
// hooks/useWalletLink.ts
'use client';

import { useAccount } from 'wagmi';
import { useState } from 'react';

export function useWalletLink() {
  const { address, chainId, isConnected } = useAccount();
  const [isLinking, setIsLinking] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const linkWallet = async () => {
    if (!address || !chainId) return false;

    setIsLinking(true);
    setError(null);

    try {
      const response = await fetch('/api/wallets/link', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ address, chainId }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error);
      }

      return true;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      return false;
    } finally {
      setIsLinking(false);
    }
  };

  return { linkWallet, isLinking, error };
}
```

### Example Component

```typescript
// components/WalletLinkButton.tsx
'use client';

import { useWalletLink } from '@/hooks/useWalletLink';

export function WalletLinkButton() {
  const { linkWallet, isLinking, error } = useWalletLink();

  return (
    <div>
      <button onClick={linkWallet} disabled={isLinking}>
        {isLinking ? 'Linking...' : 'Link Wallet'}
      </button>
      {error && <p className="text-red-600">{error}</p>}
    </div>
  );
}
```

## Database Queries

### Get User's Wallet
```sql
SELECT * FROM user_wallets WHERE fid = 12345;
```

### Find User by Wallet
```sql
SELECT u.*, uw.wallet_address, uw.chain_id
FROM users u
JOIN user_wallets uw ON u.fid = uw.fid
WHERE uw.wallet_address = '0x742d35cc6634c0532925a3b844bc9e7595f0beb8';
```

### Count Linked Wallets
```sql
SELECT COUNT(*) FROM user_wallets;
```

### Recent Links
```sql
SELECT u.username, uw.wallet_address, uw.created_at
FROM user_wallets uw
JOIN users u ON uw.fid = u.fid
ORDER BY uw.created_at DESC
LIMIT 10;
```

## Testing Checklist

- [ ] Run database migration
- [ ] Test 401 error (no auth)
- [ ] Test 400 error (invalid address)
- [ ] Test 400 error (invalid chain ID)
- [ ] Test 201 success (valid request)
- [ ] Test idempotency (duplicate request)
- [ ] Verify in database
- [ ] Test address normalization
- [ ] Test with real wallet connection

See `WALLET_LINKING_TESTING.md` for detailed test cases.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        User                              │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              RainbowKit Connect Button                   │
│              (Wagmi useAccount hook)                     │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ address, chainId
                        ▼
┌─────────────────────────────────────────────────────────┐
│         POST /api/wallets/link                           │
│         { address, chainId }                             │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              requireAuth()                               │
│              (Check JWT session)                         │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│         Validate Address & Chain ID                      │
│         - Regex check (0x + 40 hex)                      │
│         - Chain ID whitelist (8453, 84532)               │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│         Normalize Address (lowercase)                    │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              Supabase.upsert()                           │
│              ON CONFLICT (fid) DO UPDATE                 │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│         user_wallets Table                               │
│         - id (UUID, PK)                                  │
│         - fid (integer, unique, FK → users)              │
│         - wallet_address (text)                          │
│         - chain_id (integer)                             │
│         - created_at, updated_at                         │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│         Return 201 + Wallet Data                         │
└─────────────────────────────────────────────────────────┘
```

## Files Modified/Created

### Created
- ✅ `supabase-user-wallets-table.sql` - Database schema
- ✅ `app/api/wallets/link/route.ts` - API endpoint
- ✅ `WALLET_LINKING_SETUP.md` - Setup documentation
- ✅ `WALLET_LINKING_TESTING.md` - Testing guide
- ✅ `WALLET_LINKING_SUMMARY.md` - This summary

### Modified
- ✅ `lib/supabase.ts` - Added `UserWallet` interface

## Next Steps

### Immediate (Required)
1. Run `supabase-user-wallets-table.sql` in Supabase SQL Editor
2. Test API endpoint with cURL or Postman
3. Verify table creation in database

### Short Term (Recommended)
1. Create `useWalletLink` React hook
2. Add wallet linking button to user profile
3. Add auto-link on wallet connect (optional)
4. Display linked wallet in navigation or profile

### Future Enhancements (Optional)
1. Add wallet unlinking endpoint
2. Support multiple wallets per user
3. Add wallet verification (sign message)
4. Show linked users with same wallet
5. Wallet-based features (token gating, NFT display)

## Related Features

This wallet linking system integrates with:
- ✅ Farcaster authentication (JWT sessions)
- ✅ Wagmi wallet connection (address, chainId)
- ✅ RainbowKit UI (ConnectButton)
- ✅ Base network (mainnet + Sepolia)
- ✅ Supabase database (user_wallets table)

## Support

### Documentation
- `WALLET_LINKING_SETUP.md` - Complete setup guide
- `WALLET_LINKING_TESTING.md` - Testing instructions
- `WALLET_SETUP_COMPLETE.md` - Wagmi integration guide

### External Resources
- [Wagmi Documentation](https://wagmi.sh/)
- [RainbowKit Docs](https://www.rainbowkit.com/)
- [Base Network](https://docs.base.org/)
- [Supabase RLS](https://supabase.com/docs/guides/auth/row-level-security)

---

**Implementation Status**: ✅ Complete
**Database Migration**: ⚠️ Pending (run `supabase-user-wallets-table.sql`)
**Testing Status**: Ready for testing

🎉 Wallet linking feature is ready to deploy!
