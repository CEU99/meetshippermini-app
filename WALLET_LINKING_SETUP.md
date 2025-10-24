# ✅ Wallet Linking API Setup Complete

## Summary

A new API endpoint has been created to allow authenticated Farcaster users to link their Ethereum wallet addresses to their accounts.

## Files Created

### 1. Database Schema
**File**: `supabase-user-wallets-table.sql`

Creates the `user_wallets` table with:
- `id` (UUID, primary key)
- `fid` (integer, unique, foreign key to users)
- `wallet_address` (text, Ethereum address)
- `chain_id` (integer, 8453 for Base or 84532 for Base Sepolia)
- `created_at` and `updated_at` timestamps
- RLS policies for security
- Indexes for performance

### 2. API Route
**File**: `app/api/wallets/link/route.ts`

POST endpoint that:
- Authenticates user via Farcaster JWT session
- Validates wallet address format (0x + 40 hex chars)
- Validates chain ID (Base mainnet or Base Sepolia only)
- Upserts wallet to database (creates or updates)
- Returns proper HTTP status codes (201, 400, 401, 404, 500)

### 3. TypeScript Interface
**File**: `lib/supabase.ts` (updated)

Added `UserWallet` interface for type safety.

## Installation Steps

### 1. Create Database Table

Run the SQL migration in Supabase SQL Editor:

```bash
# Open Supabase Dashboard
# Navigate to SQL Editor
# Run: supabase-user-wallets-table.sql
```

Or via command line (if you have Supabase CLI):

```bash
psql $DATABASE_URL < supabase-user-wallets-table.sql
```

### 2. Verify Table Creation

```sql
-- Check if table exists
SELECT table_name
FROM information_schema.tables
WHERE table_name = 'user_wallets';

-- Check table structure
\d user_wallets

-- Verify RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'user_wallets';
```

## API Usage

### Endpoint

```
POST /api/wallets/link
```

### Authentication

Requires valid Farcaster JWT session cookie.

### Request Body

```json
{
  "address": "0x1234567890123456789012345678901234567890",
  "chainId": 8453
}
```

**Fields**:
- `address` (string, required): Ethereum wallet address (must match `0x[a-fA-F0-9]{40}`)
- `chainId` (number, required): Chain ID (8453 or 84532)

### Response Codes

#### 201 Created - Success

```json
{
  "ok": true,
  "wallet": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "fid": 12345,
    "address": "0x1234567890123456789012345678901234567890",
    "chainId": 8453,
    "createdAt": "2025-01-23T10:30:00Z",
    "updatedAt": "2025-01-23T10:30:00Z"
  }
}
```

#### 400 Bad Request - Invalid Input

**Missing address**:
```json
{
  "error": "Address is required and must be a string"
}
```

**Invalid address format**:
```json
{
  "error": "Invalid Ethereum address format. Must be 0x followed by 40 hexadecimal characters"
}
```

**Invalid chain ID**:
```json
{
  "error": "Unsupported chain ID. Supported chains: 8453 (Base), 84532 (Base Sepolia)",
  "supportedChainIds": [8453, 84532]
}
```

#### 401 Unauthorized - No Session

```json
{
  "error": "Unauthorized",
  "message": "Please sign in to link a wallet"
}
```

#### 404 Not Found - User Doesn't Exist

```json
{
  "error": "User not found. Please ensure your Farcaster account is registered."
}
```

#### 500 Internal Server Error - Database Error

**Table not created**:
```json
{
  "error": "Database table not found. Please run supabase-user-wallets-table.sql migration.",
  "migrationFile": "supabase-user-wallets-table.sql"
}
```

**Generic error**:
```json
{
  "error": "Failed to link wallet",
  "message": "Detailed error message"
}
```

## Testing

### Manual Test via cURL

```bash
# 1. Sign in and get session cookie
# (Use your browser or Farcaster auth flow)

# 2. Link wallet
curl -X POST http://localhost:3000/api/wallets/link \
  -H "Content-Type: application/json" \
  -H "Cookie: session=YOUR_SESSION_TOKEN" \
  -d '{
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
    "chainId": 8453
  }'
```

### Test Cases

#### ✅ Valid Request
```typescript
POST /api/wallets/link
{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
  "chainId": 8453
}
// Expected: 201 Created
```

#### ❌ Invalid Address - Missing 0x
```typescript
POST /api/wallets/link
{
  "address": "742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
  "chainId": 8453
}
// Expected: 400 Bad Request
```

#### ❌ Invalid Address - Wrong Length
```typescript
POST /api/wallets/link
{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "chainId": 8453
}
// Expected: 400 Bad Request
```

#### ❌ Invalid Chain ID
```typescript
POST /api/wallets/link
{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
  "chainId": 1
}
// Expected: 400 Bad Request
```

#### ❌ No Session
```typescript
POST /api/wallets/link
// No Cookie header
{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
  "chainId": 8453
}
// Expected: 401 Unauthorized
```

#### ✅ Update Existing Wallet (Idempotent)
```typescript
// First request
POST /api/wallets/link
{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
  "chainId": 8453
}
// Expected: 201 Created

// Second request with different address
POST /api/wallets/link
{
  "address": "0x1234567890123456789012345678901234567890",
  "chainId": 84532
}
// Expected: 201 Created (updates existing record)
```

## Integration with Wagmi

### Client-Side Usage

Create a React hook to link wallet after user connects:

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
    if (!address || !chainId || !isConnected) {
      setError('Wallet not connected');
      return false;
    }

    setIsLinking(true);
    setError(null);

    try {
      const response = await fetch('/api/wallets/link', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ address, chainId }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to link wallet');
      }

      console.log('✅ Wallet linked:', data.wallet);
      return true;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      setError(errorMessage);
      console.error('❌ Failed to link wallet:', errorMessage);
      return false;
    } finally {
      setIsLinking(false);
    }
  };

  return { linkWallet, isLinking, error };
}
```

### Usage in Component

```typescript
// components/WalletLinkButton.tsx
'use client';

import { useAccount } from 'wagmi';
import { useWalletLink } from '@/hooks/useWalletLink';

export function WalletLinkButton() {
  const { isConnected } = useAccount();
  const { linkWallet, isLinking, error } = useWalletLink();

  if (!isConnected) {
    return null;
  }

  return (
    <div>
      <button
        onClick={linkWallet}
        disabled={isLinking}
        className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-300"
      >
        {isLinking ? 'Linking...' : 'Link Wallet to Account'}
      </button>
      {error && (
        <p className="text-red-600 text-sm mt-2">{error}</p>
      )}
    </div>
  );
}
```

### Auto-Link on Connect

```typescript
// components/AutoWalletLink.tsx
'use client';

import { useAccount } from 'wagmi';
import { useEffect } from 'react';
import { useWalletLink } from '@/hooks/useWalletLink';

export function AutoWalletLink() {
  const { isConnected, address } = useAccount();
  const { linkWallet } = useWalletLink();

  useEffect(() => {
    if (isConnected && address) {
      linkWallet();
    }
  }, [isConnected, address]);

  return null;
}
```

## Database Queries

### Get User's Linked Wallet

```sql
SELECT wallet_address, chain_id, created_at, updated_at
FROM user_wallets
WHERE fid = 12345;
```

### Find User by Wallet Address

```sql
SELECT u.fid, u.username, u.display_name, uw.wallet_address, uw.chain_id
FROM users u
JOIN user_wallets uw ON u.fid = uw.fid
WHERE uw.wallet_address = '0x742d35cc6634c0532925a3b844bc9e7595f0beb8';
```

### Count Linked Wallets

```sql
SELECT COUNT(*) FROM user_wallets;
```

### Recent Wallet Links

```sql
SELECT u.username, uw.wallet_address, uw.chain_id, uw.created_at
FROM user_wallets uw
JOIN users u ON uw.fid = u.fid
ORDER BY uw.created_at DESC
LIMIT 10;
```

## Security Features

### Authentication
- ✅ JWT session validation via `requireAuth()`
- ✅ Throws 401 if no valid session

### Validation
- ✅ Address format validation (regex)
- ✅ Chain ID whitelist (only Base chains)
- ✅ Type checking for all inputs

### Database Security
- ✅ Row Level Security (RLS) enabled
- ✅ Foreign key constraint to users table
- ✅ Service role for API operations (bypasses RLS)

### Data Integrity
- ✅ Unique constraint on `fid` (one wallet per user)
- ✅ Upsert logic for idempotency
- ✅ Normalized address (lowercase)
- ✅ Automatic timestamps

## Architecture

```
User Connects Wallet
       ↓
  [RainbowKit UI]
       ↓
  useAccount() → address, chainId
       ↓
  POST /api/wallets/link
       ↓
  requireAuth() → Check JWT session
       ↓
  Validate address & chainId
       ↓
  Supabase.upsert() → user_wallets table
       ↓
  Return 201 + wallet data
```

## Troubleshooting

### Error: "Database table not found"

**Cause**: Migration not run

**Solution**: Run `supabase-user-wallets-table.sql` in Supabase SQL Editor

### Error: "User not found"

**Cause**: User's FID doesn't exist in `users` table (foreign key violation)

**Solution**: Ensure user is properly registered via Farcaster auth before linking wallet

### Error: "Invalid Ethereum address format"

**Cause**: Address doesn't match `0x[a-fA-F0-9]{40}` pattern

**Solution**: Ensure address is properly formatted with 0x prefix and 40 hex characters

### Error: "Unsupported chain ID"

**Cause**: Trying to use a chain other than Base (8453) or Base Sepolia (84532)

**Solution**: Switch to a supported chain in wallet before linking

## Next Steps

1. ✅ Run `supabase-user-wallets-table.sql` in Supabase
2. ✅ Test API endpoint with cURL or Postman
3. 🚀 Create client-side hook (`useWalletLink`)
4. 🚀 Add wallet linking UI to your app
5. 🚀 Add auto-link on wallet connect (optional)
6. 🚀 Display linked wallet in user profile

## Related Files

- `app/api/wallets/link/route.ts` - API endpoint
- `lib/supabase.ts` - TypeScript interfaces
- `lib/auth.ts` - Authentication utilities
- `supabase-user-wallets-table.sql` - Database schema
- `lib/wagmi.ts` - Wagmi configuration
- `app/providers.tsx` - RainbowKit provider

## Resources

- [Wagmi useAccount Hook](https://wagmi.sh/react/hooks/useAccount)
- [Base Network Docs](https://docs.base.org/)
- [Supabase RLS Policies](https://supabase.com/docs/guides/auth/row-level-security)
- [Ethereum Address Format](https://ethereum.org/en/developers/docs/accounts/)

---

**Status**: ✅ Implementation Complete
**Pending**: Run database migration in Supabase
**Next Command**: Run `supabase-user-wallets-table.sql` in Supabase SQL Editor

🎉 Ready to link wallets!
