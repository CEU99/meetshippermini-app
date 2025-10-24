# Wallet Linking API - Testing Guide

## Quick Test Checklist

- [ ] Database table created
- [ ] API endpoint returns 401 without auth
- [ ] API endpoint validates address format
- [ ] API endpoint validates chain ID
- [ ] Successful wallet link returns 201
- [ ] Duplicate request updates existing record (idempotent)
- [ ] Linked wallet appears in database

## Step-by-Step Testing

### 1. Create Database Table

```sql
-- Run in Supabase SQL Editor
-- File: supabase-user-wallets-table.sql
```

**Verify**:
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_name = 'user_wallets';
```

Expected output: `user_wallets`

---

### 2. Test Authentication (401)

```bash
curl -X POST http://localhost:3000/api/wallets/link \
  -H "Content-Type: application/json" \
  -d '{
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
    "chainId": 8453
  }'
```

**Expected Response**:
```json
{
  "error": "Unauthorized",
  "message": "Please sign in to link a wallet"
}
```

**Status Code**: `401`

---

### 3. Test Invalid Address Format

Sign in first, then:

```bash
# Missing 0x prefix
curl -X POST http://localhost:3000/api/wallets/link \
  -H "Content-Type: application/json" \
  -H "Cookie: session=YOUR_SESSION_TOKEN" \
  -d '{
    "address": "742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
    "chainId": 8453
  }'
```

**Expected Response**:
```json
{
  "error": "Invalid Ethereum address format. Must be 0x followed by 40 hexadecimal characters"
}
```

**Status Code**: `400`

---

### 4. Test Invalid Chain ID

```bash
curl -X POST http://localhost:3000/api/wallets/link \
  -H "Content-Type: application/json" \
  -H "Cookie: session=YOUR_SESSION_TOKEN" \
  -d '{
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
    "chainId": 1
  }'
```

**Expected Response**:
```json
{
  "error": "Unsupported chain ID. Supported chains: 8453 (Base), 84532 (Base Sepolia)",
  "supportedChainIds": [8453, 84532]
}
```

**Status Code**: `400`

---

### 5. Test Successful Wallet Link

```bash
curl -X POST http://localhost:3000/api/wallets/link \
  -H "Content-Type: application/json" \
  -H "Cookie: session=YOUR_SESSION_TOKEN" \
  -d '{
    "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8",
    "chainId": 8453
  }'
```

**Expected Response**:
```json
{
  "ok": true,
  "wallet": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "fid": 12345,
    "address": "0x742d35cc6634c0532925a3b844bc9e7595f0beb8",
    "chainId": 8453,
    "createdAt": "2025-01-23T10:30:00Z",
    "updatedAt": "2025-01-23T10:30:00Z"
  }
}
```

**Status Code**: `201`

**Note**: Address is normalized to lowercase

---

### 6. Test Idempotency (Update Existing)

Run the same request again with a different address:

```bash
curl -X POST http://localhost:3000/api/wallets/link \
  -H "Content-Type: application/json" \
  -H "Cookie: session=YOUR_SESSION_TOKEN" \
  -d '{
    "address": "0x1234567890123456789012345678901234567890",
    "chainId": 84532
  }'
```

**Expected Response**:
```json
{
  "ok": true,
  "wallet": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "fid": 12345,
    "address": "0x1234567890123456789012345678901234567890",
    "chainId": 84532,
    "createdAt": "2025-01-23T10:30:00Z",
    "updatedAt": "2025-01-23T10:35:00Z"
  }
}
```

**Status Code**: `201`

**Note**: Same `id` and `fid`, but updated `address`, `chainId`, and `updatedAt`

---

### 7. Verify in Database

```sql
SELECT * FROM user_wallets WHERE fid = 12345;
```

**Expected Output**:
```
id                                   | fid   | wallet_address                              | chain_id | created_at           | updated_at
550e8400-e29b-41d4-a716-446655440000 | 12345 | 0x1234567890123456789012345678901234567890 | 84532    | 2025-01-23 10:30:00  | 2025-01-23 10:35:00
```

---

## Browser Testing

### 1. Sign in with Farcaster

Navigate to your app and sign in via Farcaster auth.

### 2. Open Browser Console

Press `F12` or `Cmd+Option+I`

### 3. Run API Test

```javascript
// Test wallet linking
fetch('/api/wallets/link', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    address: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8',
    chainId: 8453
  })
})
  .then(res => res.json())
  .then(data => console.log('✅ Success:', data))
  .catch(err => console.error('❌ Error:', err));
```

---

## Integration Testing with Wagmi

### Create Test Component

```typescript
// components/WalletLinkTest.tsx
'use client';

import { useAccount } from 'wagmi';
import { useState } from 'react';

export function WalletLinkTest() {
  const { address, chainId, isConnected } = useAccount();
  const [result, setResult] = useState<string>('');

  const testLink = async () => {
    if (!address || !chainId) {
      setResult('❌ No wallet connected');
      return;
    }

    try {
      const response = await fetch('/api/wallets/link', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ address, chainId }),
      });

      const data = await response.json();

      if (response.ok) {
        setResult(`✅ Success: ${JSON.stringify(data, null, 2)}`);
      } else {
        setResult(`❌ Error: ${data.error}`);
      }
    } catch (error) {
      setResult(`❌ Exception: ${error}`);
    }
  };

  return (
    <div className="p-4 border rounded">
      <h3 className="text-lg font-bold mb-2">Wallet Link Test</h3>

      {isConnected ? (
        <div className="space-y-2">
          <p>Connected: {address}</p>
          <p>Chain ID: {chainId}</p>

          <button
            onClick={testLink}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Test Link Wallet
          </button>

          {result && (
            <pre className="p-2 bg-gray-100 rounded text-xs overflow-auto">
              {result}
            </pre>
          )}
        </div>
      ) : (
        <p>Please connect wallet first</p>
      )}
    </div>
  );
}
```

### Add to Page

```typescript
// app/test/page.tsx
import { WalletLinkTest } from '@/components/WalletLinkTest';

export default function TestPage() {
  return (
    <div className="container mx-auto p-8">
      <h1 className="text-2xl font-bold mb-4">Wallet Linking Test</h1>
      <WalletLinkTest />
    </div>
  );
}
```

Navigate to `/test` to use the test component.

---

## Edge Cases to Test

### Empty String Address
```json
{ "address": "", "chainId": 8453 }
```
Expected: `400 Bad Request`

### Null Address
```json
{ "address": null, "chainId": 8453 }
```
Expected: `400 Bad Request`

### Invalid Hex Characters
```json
{ "address": "0xZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ", "chainId": 8453 }
```
Expected: `400 Bad Request`

### Wrong Length (41 chars)
```json
{ "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb81", "chainId": 8453 }
```
Expected: `400 Bad Request`

### Wrong Length (39 chars)
```json
{ "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb", "chainId": 8453 }
```
Expected: `400 Bad Request`

### Negative Chain ID
```json
{ "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8", "chainId": -1 }
```
Expected: `400 Bad Request`

### Chain ID as String
```json
{ "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8", "chainId": "8453" }
```
Expected: `400 Bad Request`

### Missing Fields
```json
{ "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8" }
```
Expected: `400 Bad Request`

---

## Performance Testing

### Load Test with Multiple Users

```bash
# Install hey (HTTP load testing tool)
brew install hey

# Run 100 requests with 10 concurrent workers
hey -n 100 -c 10 -m POST \
  -H "Content-Type: application/json" \
  -H "Cookie: session=YOUR_SESSION_TOKEN" \
  -d '{"address":"0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8","chainId":8453}' \
  http://localhost:3000/api/wallets/link
```

Expected: All requests should succeed (idempotent upsert)

---

## Monitoring

### Check API Logs

Watch server logs for error messages:

```bash
# If using pnpm
pnpm run dev

# Look for console output:
# ✅ Authenticated FID: 12345
# ✅ Validation passed
# ✅ Wallet linked successfully
```

### Check Database

```sql
-- Count total linked wallets
SELECT COUNT(*) FROM user_wallets;

-- Show recent links
SELECT u.username, uw.wallet_address, uw.chain_id, uw.created_at
FROM user_wallets uw
JOIN users u ON uw.fid = u.fid
ORDER BY uw.created_at DESC
LIMIT 10;

-- Check for duplicates (should be 0)
SELECT fid, COUNT(*)
FROM user_wallets
GROUP BY fid
HAVING COUNT(*) > 1;
```

---

## Cleanup

### Remove Test Wallet

```sql
DELETE FROM user_wallets WHERE fid = 12345;
```

### Reset Auto-Increment

```sql
ALTER SEQUENCE user_wallets_id_seq RESTART WITH 1;
```

---

## Troubleshooting

### Problem: 500 Error "Database table not found"

**Cause**: Migration not run

**Solution**:
```sql
-- Run in Supabase SQL Editor
\i supabase-user-wallets-table.sql
```

### Problem: 404 Error "User not found"

**Cause**: User's FID doesn't exist in `users` table

**Solution**: Ensure user is registered via Farcaster auth before testing

### Problem: Address not normalized

**Check**:
```sql
SELECT wallet_address FROM user_wallets WHERE fid = 12345;
```

Should return lowercase address: `0x742d35cc6634c0532925a3b844bc9e7595f0beb8`

---

## Success Criteria

- ✅ All API status codes correct (201, 400, 401, 404, 500)
- ✅ Address validation working (format, length, hex characters)
- ✅ Chain ID validation working (only Base chains)
- ✅ Upsert logic working (idempotent updates)
- ✅ Address normalized to lowercase
- ✅ Timestamps updated correctly
- ✅ Database constraints enforced (unique fid, foreign key)
- ✅ No duplicate records in database

---

**Status**: Ready for testing
**Next Step**: Run through all test cases above

🧪 Happy testing!
