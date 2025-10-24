# Wallet Linking - Quick Start

## Problem & Solution

**Error**: `ERROR: 42703: column "wallet_address" does not exist`

**Solution**: Use the fixed migration script `supabase-user-wallets-v2.sql`

## Quick Setup (3 Steps)

### 1. Run Fixed Migration

```sql
-- In Supabase SQL Editor, run this file:
supabase-user-wallets-v2.sql
```

Expected output:
```
✓ Table created
✓ Indexes created
✓ Comments added
✓ RLS enabled
✓ RLS policies created
✓ Permissions granted
✓ All columns created successfully
```

### 2. Verify Table

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'user_wallets'
ORDER BY ordinal_position;
```

Expected: 6 columns (id, fid, wallet_address, chain_id, created_at, updated_at)

### 3. Test API

Sign in to your app, then:

```javascript
// In browser console
fetch('/api/wallets/link', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    address: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8',
    chainId: 8453
  })
})
  .then(res => res.json())
  .then(console.log);
```

Expected: `201 Created` with wallet data

## Files

### Use These ✅
- **`supabase-user-wallets-v2.sql`** - Fixed migration script
- **`app/api/wallets/link/route.ts`** - API endpoint (already created)
- **`WALLET_LINKING_SETUP.md`** - Full documentation

### Debugging 🔍
- **`diagnose-user-wallets.sql`** - Check table status
- **`WALLET_TABLE_FIX.md`** - Detailed troubleshooting

### Ignore ⚠️
- ~~`supabase-user-wallets-table.sql`~~ - Original (has bug)

## API Endpoint

```
POST /api/wallets/link
```

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

## Status Codes

- `201` - Success (wallet linked)
- `400` - Invalid address or chain ID
- `401` - Not authenticated
- `404` - User not found
- `500` - Database error

## Integration Example

```typescript
// hooks/useWalletLink.ts
import { useAccount } from 'wagmi';

export function useWalletLink() {
  const { address, chainId } = useAccount();

  const linkWallet = async () => {
    const res = await fetch('/api/wallets/link', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ address, chainId }),
    });
    return res.json();
  };

  return { linkWallet };
}
```

## What Was Fixed

**Original Issue** (line 46):
```sql
-- WRONG: No sequence exists for UUID primary key
GRANT USAGE ON SEQUENCE user_wallets_id_seq TO anon, authenticated, service_role;
```

**Fixed**:
```sql
-- Removed sequence grant (not needed for UUID)
GRANT SELECT, INSERT, UPDATE, DELETE ON user_wallets TO anon, authenticated, service_role;
```

## Support

- `WALLET_LINKING_SETUP.md` - Complete guide
- `WALLET_LINKING_TESTING.md` - Test cases
- `WALLET_TABLE_FIX.md` - Troubleshooting

---

**Next Command**: Run `supabase-user-wallets-v2.sql` in Supabase SQL Editor

✅ Ready to link wallets!
