# A12: Final Fix - Column Name Typo

## Issue

The verification badge system was showing "500 Internal Server Error" when checking attestation status.

**Error Message:**
```
[useAttestationStatus] API request failed: 500 "Internal Server Error"
column attestations.walletaddress does not exist
```

**PostgreSQL Error Code:** `42703`
**Hint:** "Perhaps you meant to reference the column 'attestations.wallet_address'"

---

## Root Cause

**Typo in API route file** (`/app/api/attestations/route.ts` line 275):

```typescript
// ❌ WRONG - Missing underscore
query = query.eq('walletaddress', walletLower);

// ✅ CORRECT - With underscore
query = query.eq('wallet_address', walletLower);
```

The database column is named `wallet_address` (snake_case with underscore), but the query was using `walletaddress` (no underscore), causing PostgreSQL to throw an error that the column doesn't exist.

---

## How This Happened

This typo was introduced during the previous case sensitivity fix. The console log on line 274 correctly showed `wallet_address`, but the actual query on line 275 had the typo.

**Misleading Console Output:**
```
[API /api/attestations GET] Querying wallet_address: 0x39fa26...
```

This made it look like the query was correct, but the actual Supabase query had the typo.

---

## Fixes Applied

### 1. Fixed Column Name in GET Handler

**File**: `/app/api/attestations/route.ts` (line 275)

```typescript
// Before
query = query.eq('walletaddress', walletLower);

// After
query = query.eq('wallet_address', walletLower);
```

### 2. Ensured Lowercase Storage in POST Handler

**File**: `/app/api/attestations/route.ts` (line 157)

```typescript
wallet_address: wallet.toLowerCase(),
```

This ensures all future attestation records store wallet addresses in lowercase for consistent querying.

### 3. Updated Existing Database Records

Created and ran migration script (`fix-wallet-case.mjs`) to convert existing wallet addresses in the database to lowercase:

```javascript
const { data: attestations } = await supabase
  .from('attestations')
  .select('*');

for (const attestation of attestations) {
  const lowerWallet = attestation.wallet_address.toLowerCase();

  if (attestation.wallet_address !== lowerWallet) {
    await supabase
      .from('attestations')
      .update({ wallet_address: lowerWallet })
      .eq('id', attestation.id);
  }
}
```

**Result:** Updated 4 records from mixed case to lowercase.

---

## Complete Fix Summary

### Problem Chain

1. **Original Issue (A12):** Case sensitivity mismatch between Wagmi (checksummed) and database (varied case)
2. **First Fix:** Added `.toLowerCase()` in hook before querying
3. **Second Issue:** Database still had mixed case addresses
4. **Database Migration:** Updated all addresses to lowercase
5. **Third Issue (THIS FIX):** Typo in API query - `walletaddress` instead of `wallet_address`

### All Fixes Applied

| Issue | Fix | File | Line |
|-------|-----|------|------|
| Case sensitivity in hook | Convert to lowercase before query | `lib/hooks/useAttestationStatus.ts` | 63 |
| Case sensitivity in POST | Store lowercase | `app/api/attestations/route.ts` | 157 |
| Mixed case in database | Migration script | `fix-wallet-case.mjs` | N/A |
| **Typo in GET query** | **Fixed column name** | **`app/api/attestations/route.ts`** | **275** |

---

## Testing

### Test 1: Direct API Call

```bash
curl "http://localhost:3000/api/attestations?walletAddress=0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04&limit=1"
```

**Result:**
```json
{
  "success": true,
  "count": 1,
  "data": [
    {
      "id": "92aca8ac-5afb-41cf-9aa3-d6f5d1cc3e92",
      "username": "@cengizhaneu",
      "walletAddress": "0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04",
      "txHash": "0xc22cd115e615731bc6526f8bf0fbbdd9bd775c39877150ea28e81916e3169534",
      "attestationUID": "0x743f63f767ce227dadc983946e1852c00e638f71e78171e9a882156d0e24f051",
      "createdAt": "2025-10-24T00:28:33.735246+00:00",
      "updatedAt": "2025-10-24T02:06:23.573516+00:00"
    }
  }
}
```

✅ **API now returns correct data!**

### Test 2: Expected Console Flow

When a user with verified wallet `0x39Fa26142EC357a421D49C9A4Cf022E8fB6BbF04` connects:

```
1. Hook receives checksummed address from Wagmi:
   [useAttestationStatus] Original address: 0x39Fa26142EC357a421D49C9A4Cf022E8fB6BbF04

2. Hook converts to lowercase:
   [useAttestationStatus] Lowercase address: 0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04

3. Hook queries API:
   GET /api/attestations?walletAddress=0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04

4. API receives and logs:
   [API /api/attestations GET] Query params: { wallet: "0x39fa26...bf04" }
   [API /api/attestations GET] Querying wallet_address: 0x39fa26...bf04

5. Supabase query executes:
   SELECT * FROM attestations WHERE wallet_address = '0x39fa26...bf04'

6. Match found:
   [API /api/attestations GET] Query result: { found: 1, error: null }

7. Hook receives data:
   [useAttestationStatus] ✅ Wallet is verified

8. UI updates:
   Dashboard: [✅ Verified On-Chain]
   Navbar: [✓ Verified]
```

---

## Database Schema

```sql
CREATE TABLE public.attestations (
  id UUID PRIMARY KEY,
  username TEXT NOT NULL,
  wallet_address TEXT NOT NULL,  -- ← Correct column name with underscore
  tx_hash TEXT NOT NULL,
  attestation_uid TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_attestations_wallet_address
  ON public.attestations(wallet_address);  -- ← Indexed for fast lookups
```

---

## Verification Checklist

✅ Typo fixed in API route (`walletaddress` → `wallet_address`)
✅ POST handler stores lowercase addresses
✅ Existing database records converted to lowercase
✅ Hook converts to lowercase before querying
✅ API returns correct data for verified wallets
✅ Direct Supabase queries work
✅ Test scripts removed
✅ Dev server restarted with clean cache

---

## Files Modified

### `/app/api/attestations/route.ts`
- **Line 157:** Store wallet_address in lowercase during POST
- **Line 275:** Fixed typo - `walletaddress` → `wallet_address`

### Database
- **Migration:** Updated 4 existing records to lowercase

---

## Status

✅ **FIXED AND VERIFIED**

**Build:** Passing
**API Status:** Working
**Badge System:** Ready
**Date:** October 24, 2025

---

## Expected Behavior Now

### Scenario 1: Verified Wallet Connects

1. User connects wallet: `0x39Fa26142EC357a421D49C9A4Cf022E8fB6BbF04` (checksummed)
2. Hook converts to: `0x39fa26142ec357a421d49c9a4cf022e8fb6bbf04` (lowercase)
3. API queries database with lowercase
4. **Match found!** ✅
5. Badge updates to: `[✅ Verified On-Chain]`
6. Navbar shows: `[✓ Verified]`
7. Tooltip: "Your Farcaster username is verified on-chain"

### Scenario 2: Unverified Wallet Connects

1. User connects wallet
2. Hook converts to lowercase
3. API queries database
4. **No match found**
5. Badge shows: `[⚪ Not Verified]`
6. Button shows: `[Verify Wallet]`

---

## Key Learnings

1. **Column names in PostgreSQL are case-sensitive** when quoted, but PostgREST/Supabase expects exact matches
2. **Console logs can be misleading** if they show the correct value but the actual code has a typo
3. **Ethereum addresses should be stored in lowercase** for consistent querying across different wallet providers
4. **Always verify the actual query** being sent to the database, not just the logged values
5. **Clear Next.js cache** when troubleshooting API routes to ensure code changes are reflected

---

## Debugging Tips

If badge still doesn't work:

1. **Check API endpoint directly:**
   ```bash
   curl "http://localhost:3000/api/attestations?walletAddress=YOUR_ADDRESS_LOWERCASE"
   ```

2. **Check database directly:**
   ```sql
   SELECT * FROM attestations WHERE wallet_address = 'your_address_lowercase';
   ```

3. **Check console logs:**
   - Look for `[useAttestationStatus] ✅ Wallet is verified`
   - Look for `[API /api/attestations GET] Query result: { found: 1 }`

4. **Verify case matching:**
   ```javascript
   console.log('Wallet from Wagmi:', address);
   console.log('Wallet lowercase:', address.toLowerCase());
   console.log('Wallet in DB:', dbRecord.wallet_address);
   console.log('Match:', address.toLowerCase() === dbRecord.wallet_address);
   ```

---

**The verification badge system is now fully functional!** 🎉
