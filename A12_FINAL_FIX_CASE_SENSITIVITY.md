# A12: Final Fix - Case Sensitivity & Query Parameter Support

## Issue

Wallet verified in database but badge still shows "Not Verified."

## Root Cause Analysis

The issue was **case sensitivity** in wallet address comparison:

1. **Database**: Stores wallet addresses in lowercase
2. **Wagmi Hook**: Returns addresses with mixed case (checksummed format)
3. **Query Mismatch**: `0x39F7...bF04` (checksummed) ≠ `0x39f7...bf04` (lowercase)

### Example

```typescript
// Wagmi returns (checksummed):
address = "0x39F7A65e8bF48E4fe8Aa8DbC8b61b4fa1B30bF04"

// Database stores (lowercase):
wallet_address = "0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04"

// Query without lowercase conversion:
.eq('wallet_address', "0x39F7A65e8bF48E4fe8Aa8DbC8b61b4fa1B30bF04")
// ❌ No match found

// Query with lowercase conversion:
.eq('wallet_address', "0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04")
// ✅ Match found!
```

---

## Fixes Applied

### 1. API Endpoint - Support Both Query Parameters

**File**: `/app/api/attestations/route.ts`

**Change**: Accept both `wallet` and `walletAddress` query parameters

```typescript
// Before
const wallet = searchParams.get('wallet');

// After
const wallet = searchParams.get('wallet') || searchParams.get('walletAddress');
```

**Reason**: Provides flexibility for different client implementations.

---

### 2. API Endpoint - Added Comprehensive Logging

```typescript
console.log('[API /api/attestations GET] Query params:', {
  wallet,
  username,
  attestationUID,
  limit,
});

console.log('[API /api/attestations GET] Querying wallet_address:', walletLower);
console.log('[API /api/attestations GET] Executing query...');
console.log('[API /api/attestations GET] Query result:', {
  found: attestations?.length || 0,
  error: fetchError?.message || null,
});
```

**Benefit**: Can trace exact query execution and results in server logs.

---

### 3. Hook - Lowercase Conversion Before Query

**File**: `/lib/hooks/useAttestationStatus.ts`

**Critical Fix**: Convert address to lowercase before querying

```typescript
// Before
const apiUrl = `/api/attestations?wallet=${encodeURIComponent(address)}&limit=1`;

// After
const walletLower = address.toLowerCase();
const apiUrl = `/api/attestations?walletAddress=${encodeURIComponent(walletLower)}&limit=1`;
```

**Added Logging**:
```typescript
console.log('[useAttestationStatus] Original address:', address);
console.log('[useAttestationStatus] Lowercase address:', walletLower);
```

---

## How It Works Now

### Complete Flow with Case Handling

```
1. User connects wallet
   Wagmi: "0x39F7A65e8bF48E4fe8Aa8DbC8b61b4fa1B30bF04"

2. Hook receives address
   [useAttestationStatus] Original address: 0x39F7A65e8bF48E4fe8Aa8DbC8b61b4fa1B30bF04

3. Hook converts to lowercase
   [useAttestationStatus] Lowercase address: 0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04

4. Hook queries API
   GET /api/attestations?walletAddress=0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04

5. API receives query
   [API] Query params: { wallet: "0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04" }
   [API] Querying wallet_address: 0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04

6. Supabase query
   SELECT * FROM attestations
   WHERE wallet_address = '0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04'

7. Match found!
   [API] Query result: { found: 1, error: null }

8. Hook updates state
   [useAttestationStatus] ✅ Wallet is verified
   [useAttestationStatus] State updated - isVerified: true

9. UI updates
   Dashboard: [✅ Verified On-Chain]
   Navbar: [✓ Verified]
```

---

## Console Output Examples

### Successful Verification Check

```
[useAttestationStatus] useEffect triggered - address: 0x39F7...bF04 isConnected: true
[useAttestationStatus] Checking attestation for wallet: 0x39F7A65e8bF48E4fe8Aa8DbC8b61b4fa1B30bF04
[useAttestationStatus] Original address: 0x39F7A65e8bF48E4fe8Aa8DbC8b61b4fa1B30bF04
[useAttestationStatus] Lowercase address: 0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04
[useAttestationStatus] Fetching from: /api/attestations?walletAddress=0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04&limit=1

--- API Side ---
[API /api/attestations GET] Query params: {
  wallet: "0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04",
  username: null,
  attestationUID: null,
  limit: 1
}
[API /api/attestations GET] Querying wallet_address: 0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04
[API /api/attestations GET] Executing query...
[API /api/attestations GET] Query result: { found: 1, error: null }

--- Back to Hook ---
[useAttestationStatus] Attestation check result: {
  success: true,
  count: 1,
  data: [{
    id: "uuid",
    username: "alice",
    walletAddress: "0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04",
    txHash: "0xabcd...",
    attestationUID: "0x9876...",
    createdAt: "2025-01-15T..."
  }]
}
[useAttestationStatus] Has attestation: true
[useAttestationStatus] ✅ Wallet is verified: { username: "alice", ... }
[useAttestationStatus] State updated - isVerified: true isLoading: false
```

---

## Database Schema Reference

```sql
CREATE TABLE public.attestations (
  id UUID PRIMARY KEY,
  username TEXT NOT NULL,
  wallet_address TEXT NOT NULL,  ← Lowercase storage
  tx_hash TEXT NOT NULL,
  attestation_uid TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_attestations_wallet_address
  ON public.attestations(wallet_address);
```

**Key Point**: `wallet_address` column stores addresses in **lowercase**.

---

## API Query Parameters

The API now supports both parameter names:

### Option 1: Using `wallet`
```
GET /api/attestations?wallet=0x39f7...&limit=1
```

### Option 2: Using `walletAddress`
```
GET /api/attestations?walletAddress=0x39f7...&limit=1
```

**Both work identically!**

---

## Testing Instructions

### Test 1: Fresh Page Load with Verified Wallet

1. Open browser console
2. Ensure wallet is verified in database
3. Connect wallet
4. Watch for these logs:

```
✅ Expected:
[useAttestationStatus] Original address: 0x39F7... (checksummed)
[useAttestationStatus] Lowercase address: 0x39f7... (lowercase)
[API] Query result: { found: 1, error: null }
[useAttestationStatus] ✅ Wallet is verified
```

5. Check UI:
   - Dashboard shows: `[✅ Verified On-Chain]`
   - Navbar shows: `[✓ Verified]`

---

### Test 2: Verify Database Record

Run this in Supabase SQL Editor:

```sql
-- Check if record exists
SELECT
  username,
  wallet_address,
  attestation_uid,
  created_at
FROM public.attestations
WHERE wallet_address = '0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04';
-- Note: Use LOWERCASE address
```

**Expected Result**: 1 row returned

**If no rows**: The wallet is not actually verified in the database.

---

### Test 3: Manual API Test

Test the API directly in browser console:

```javascript
// Test with lowercase
fetch('/api/attestations?walletAddress=0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04&limit=1')
  .then(r => r.json())
  .then(data => console.log('API Response:', data));

// Expected: { success: true, count: 1, data: [...] }
```

---

## Debugging Checklist

If badge still shows "Not Verified":

### ☑ Step 1: Check Console Logs

Look for:
```
[useAttestationStatus] Lowercase address: 0x...
```

If missing → Old code is still cached, hard refresh (Ctrl+Shift+R)

### ☑ Step 2: Check API Response

Look for:
```
[API] Query result: { found: 1, error: null }
```

If `found: 0` → Record not in database
If `error: ...` → Database query failed

### ☑ Step 3: Check Database

Run SQL query:
```sql
SELECT * FROM public.attestations
WHERE wallet_address = 'YOUR_WALLET_LOWERCASE';
```

If no rows → Complete verification process again

### ☑ Step 4: Check Case Match

```
Connected wallet: 0x39F7A65e8bF48E4fe8Aa8DbC8b61b4fa1B30bF04
Database record:  0x39f7a65e8bf48e4fe8aa8dbc8b61b4fa1b30bf04
                  ↑ Must match after lowercase conversion
```

### ☑ Step 5: Check State Update

Look for:
```
[useAttestationStatus] State updated - isVerified: true
```

If missing → React state not updating, check component re-render

---

## Common Issues & Solutions

### Issue 1: API Returns Empty Data

**Symptoms**:
```
[API] Query result: { found: 0, error: null }
```

**Causes**:
1. Wallet not verified in database
2. Case mismatch (should be fixed now)
3. Wrong wallet address

**Solution**:
- Verify wallet exists in database
- Check address matches exactly (after lowercase)

---

### Issue 2: Hook Not Refetching

**Symptoms**:
- Badge doesn't update after verification
- No new API calls in console

**Causes**:
1. Event not dispatched
2. Event listener not registered

**Solution**:
Look for:
```
[LinkAndAttest] Dispatching attestation-complete event
[useAttestationStatus] Attestation complete event received
```

---

### Issue 3: State Update But UI Not Updating

**Symptoms**:
```
[useAttestationStatus] State updated - isVerified: true
```
But badge still shows "Not Verified"

**Causes**:
1. Component not re-rendering
2. Using stale closure

**Solution**:
- Hard refresh browser (Ctrl+Shift+R)
- Check React DevTools for state

---

## Files Modified

### `/app/api/attestations/route.ts`
- ✅ Support both `wallet` and `walletAddress` query params
- ✅ Added comprehensive logging for debugging
- ✅ Log query params, execution, and results

### `/lib/hooks/useAttestationStatus.ts`
- ✅ Convert address to lowercase before querying
- ✅ Use `walletAddress` query parameter
- ✅ Added address logging (original vs lowercase)

---

## Build Status

```
✓ Compiled successfully in 5.6s
✓ Generating static pages (32/32)
✓ Build complete
```

---

## Expected Behavior

### Scenario 1: Verified Wallet Connects

1. User connects wallet: `0x39F7A65e...` (checksummed)
2. Hook converts to: `0x39f7a65e...` (lowercase)
3. API queries database with lowercase
4. **Match found!**
5. Badge updates to: `[✅ Verified On-Chain]`

### Scenario 2: Unverified Wallet Connects

1. User connects wallet
2. Hook converts to lowercase
3. API queries database
4. **No match found**
5. Badge shows: `[⚪ Not Verified]`
6. Button shows: `[Verify Wallet]`

---

## Success Criteria

✅ Console shows lowercase conversion
✅ API logs show query execution
✅ API returns correct data
✅ Hook sets isVerified = true
✅ Dashboard shows green badge
✅ Navbar shows green badge
✅ Tooltip shows on hover

---

**Status**: ✅ Fixed and Ready
**Critical Fix**: Case sensitivity handled
**Build**: Passing
**Date**: January 15, 2025

**The verification badge should now work correctly for all checksummed wallet addresses!** 🎉
