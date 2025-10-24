# Attestation API Documentation

## Overview
The `/api/attestations` endpoint manages EAS (Ethereum Attestation Service) attestation records in Supabase.

## Database Setup

Before using the API, run the SQL schema in your Supabase dashboard:

```bash
# File: supabase-attestations-table.sql
# Run this in Supabase SQL Editor
```

This will create:
- `attestations` table with proper indexes
- Row Level Security (RLS) policies
- Auto-update triggers for `updated_at`

## API Endpoints

### POST /api/attestations

Creates a new attestation record.

**Request Body:**
```json
{
  "username": "string (min: 1, max: 255)",
  "wallet": "0x... (42 chars, valid Ethereum address)",
  "txHash": "0x... (66 chars, valid transaction hash)",
  "attestationUID": "string (min: 1, max: 255)"
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Attestation saved successfully",
  "data": {
    "id": "uuid",
    "username": "alice",
    "walletAddress": "0x1234...",
    "txHash": "0xabcd...",
    "attestationUID": "0x...",
    "createdAt": "2025-01-23T10:30:00Z"
  }
}
```

**Error Responses:**

- **400 Bad Request** - Validation failed
```json
{
  "success": false,
  "error": "Validation failed",
  "details": [
    {
      "field": "wallet",
      "message": "Invalid Ethereum wallet address"
    }
  ]
}
```

- **409 Conflict** - Attestation already exists
```json
{
  "success": false,
  "error": "Attestation already exists",
  "details": "This attestation UID has already been recorded"
}
```

- **500 Internal Server Error** - Database or server error
```json
{
  "success": false,
  "error": "Failed to save attestation",
  "details": "Error message"
}
```

### GET /api/attestations

Retrieves attestation records with optional filtering.

**Query Parameters:**
- `limit` (optional): Number of records to return (1-100, default: 20)
- `wallet` (optional): Filter by wallet address (0x...)
- `username` (optional): Filter by username
- `attestationUID` (optional): Filter by attestation UID

**Example Requests:**
```bash
# Get last 20 attestations
GET /api/attestations

# Get last 50 attestations
GET /api/attestations?limit=50

# Get attestations for a specific wallet
GET /api/attestations?wallet=0x1234567890123456789012345678901234567890

# Get attestations for a specific username
GET /api/attestations?username=alice

# Get a specific attestation
GET /api/attestations?attestationUID=0xabcd...

# Combine filters
GET /api/attestations?wallet=0x1234...&limit=10
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "count": 2,
  "data": [
    {
      "id": "uuid",
      "username": "alice",
      "walletAddress": "0x1234...",
      "txHash": "0xabcd...",
      "attestationUID": "0x...",
      "createdAt": "2025-01-23T10:30:00Z",
      "updatedAt": "2025-01-23T10:30:00Z"
    },
    {
      "id": "uuid",
      "username": "bob",
      "walletAddress": "0x5678...",
      "txHash": "0xefgh...",
      "attestationUID": "0x...",
      "createdAt": "2025-01-23T09:15:00Z",
      "updatedAt": "2025-01-23T09:15:00Z"
    }
  ]
}
```

**Error Responses:**

- **400 Bad Request** - Invalid parameters
```json
{
  "success": false,
  "error": "Invalid limit parameter",
  "details": "Limit must be between 1 and 100"
}
```

- **500 Internal Server Error** - Database or server error
```json
{
  "success": false,
  "error": "Failed to fetch attestations",
  "details": "Error message"
}
```

## Environment Variables

Ensure these are set in `.env.local`:

```bash
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# EAS Configuration (used by LinkAndAttest component)
NEXT_PUBLIC_EAS_CONTRACT=0x4200000000000000000000000000000000000021
NEXT_PUBLIC_EAS_SCHEMA_UID=0x...
```

## Example Usage with cURL

### Create an attestation:
```bash
curl -X POST http://localhost:3000/api/attestations \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "wallet": "0x1234567890123456789012345678901234567890",
    "txHash": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
    "attestationUID": "0xuid1234567890"
  }'
```

### Get attestations:
```bash
# Get last 20
curl http://localhost:3000/api/attestations

# Filter by wallet
curl "http://localhost:3000/api/attestations?wallet=0x1234567890123456789012345678901234567890"

# Filter by username with limit
curl "http://localhost:3000/api/attestations?username=alice&limit=10"
```

## Integration with LinkAndAttest Component

The `LinkAndAttest.tsx` component can be updated to save attestations to the database after successful creation:

```typescript
// After attestation is created successfully
const response = await fetch('/api/attestations', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    username: farcasterUsername,
    wallet: connectedAddress,
    txHash: linkHash,
    attestationUID: uid,
  }),
});

if (response.ok) {
  console.log('Attestation saved to database');
}
```

## Features

✅ **Type-safe validation** using Zod
✅ **Duplicate prevention** - checks for existing attestation UIDs
✅ **Flexible filtering** - search by wallet, username, or attestation UID
✅ **Pagination support** - limit parameter (1-100)
✅ **Error handling** - comprehensive 400/409/500 responses
✅ **Database indexes** - optimized for fast queries
✅ **Row Level Security** - Supabase RLS enabled
✅ **TypeScript** - full type safety with Next.js 14 App Router

## Testing

1. **Run the SQL schema** in Supabase SQL Editor
2. **Start the dev server**: `pnpm run dev`
3. **Test POST** with the cURL examples above
4. **Test GET** with various filters
5. **Verify in Supabase** - check the `attestations` table

## Notes

- The API uses the **service role key** for server-side operations (bypasses RLS)
- Wallet addresses are validated using regex: `^0x[a-fA-F0-9]{40}$`
- Transaction hashes are validated: `^0x[a-fA-F0-9]{64}$`
- Maximum limit is 100 records per request
- Results are ordered by `created_at DESC` (newest first)
- Duplicate attestation UIDs return 409 Conflict

## Security Considerations

- ✅ Input validation with Zod
- ✅ SQL injection protection via Supabase client
- ✅ RLS policies for public read access
- ✅ Service role key stored in environment variable
- ⚠️ Consider adding authentication for POST requests in production
- ⚠️ Consider rate limiting to prevent abuse
