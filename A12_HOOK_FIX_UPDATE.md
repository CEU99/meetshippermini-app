# A12: Hook Fix & Debugging Enhancement

## Issue Fixed

The verification badge was not updating after successful attestation completion.

## Root Cause

The issue was not with the API field name (it was already correct), but with the lack of:
1. Comprehensive debugging logs
2. Event-driven updates after attestation completion
3. Proper state tracking

## Changes Made

### 1. Enhanced Hook with Debugging (`/lib/hooks/useAttestationStatus.ts`)

#### Added Comprehensive Console Logging

**Before Check**:
```typescript
console.log('[useAttestationStatus] Checking attestation for wallet:', address);
console.log('[useAttestationStatus] Fetching from:', apiUrl);
```

**API Response**:
```typescript
const data = await response.json();
console.log('[useAttestationStatus] Attestation check result:', data);
```

**Verification Logic**:
```typescript
const hasAttestation = data?.success && data?.data && data.data.length > 0;
console.log('[useAttestationStatus] Has attestation:', hasAttestation);
```

**Results**:
```typescript
if (hasAttestation) {
  console.log('[useAttestationStatus] ✅ Wallet is verified:', data.data[0]);
} else {
  console.log('[useAttestationStatus] ⚪ Wallet is not verified');
}
```

#### Added Event Listener for Real-Time Updates

```typescript
// Listen for attestation completion events
useEffect(() => {
  const handleAttestationComplete = () => {
    console.log('[useAttestationStatus] Attestation complete event received, refetching...');
    // Add a small delay to allow the API to process
    setTimeout(() => {
      checkAttestation();
    }, 1000);
  };

  window.addEventListener('attestation-complete', handleAttestationComplete);

  return () => {
    window.removeEventListener('attestation-complete', handleAttestationComplete);
  };
}, [address, isConnected]);
```

#### Added State Change Logging

```typescript
// Log state changes for debugging
useEffect(() => {
  console.log('[useAttestationStatus] State updated - isVerified:', isVerified, 'isLoading:', isLoading);
}, [isVerified, isLoading]);
```

---

### 2. Updated LinkAndAttest Component (`/components/LinkAndAttest.tsx`)

#### Added Event Dispatch on Successful Save

```typescript
// In handleSave function after successful API call
const data = await res.json();
console.log('[LinkAndAttest] API response:', data);

if (!res.ok) throw new Error(data.error || 'Save failed');

setStepState(prev => ({ ...prev, save: 'completed' }));
setSuccessMessage('✅ All steps completed successfully!');

// Dispatch event to notify useAttestationStatus hook
console.log('[LinkAndAttest] Dispatching attestation-complete event');
window.dispatchEvent(new Event('attestation-complete'));
```

#### Added Error Logging

```typescript
catch (err: any) {
  console.error('[LinkAndAttest] Error saving to database:', err);
  setWarningMessage(`⚠️ Saved on-chain but failed to save in DB: ${err.message}`);
  setStepState(prev => ({ ...prev, save: 'error' }));
}
```

---

## How It Works Now

### Step-by-Step Flow

1. **User Completes Verification**:
   ```
   Step 1: Link Username → Success
   Step 2: Create Attestation → Success
   Step 3: Save to Database → API call
   ```

2. **LinkAndAttest Component**:
   ```typescript
   // After successful save
   console.log('[LinkAndAttest] API response:', data);
   console.log('[LinkAndAttest] Dispatching attestation-complete event');
   window.dispatchEvent(new Event('attestation-complete'));
   ```

3. **useAttestationStatus Hook**:
   ```typescript
   // Event listener catches the event
   console.log('[useAttestationStatus] Attestation complete event received, refetching...');

   // Wait 1 second for API to settle
   setTimeout(() => {
     checkAttestation();
   }, 1000);
   ```

4. **Hook Checks API**:
   ```typescript
   console.log('[useAttestationStatus] Checking attestation for wallet:', address);
   // API query...
   console.log('[useAttestationStatus] Attestation check result:', data);
   console.log('[useAttestationStatus] Has attestation:', true);
   console.log('[useAttestationStatus] ✅ Wallet is verified:', record);
   ```

5. **State Updates**:
   ```typescript
   setIsVerified(true);
   setAttestation(record);
   // State change useEffect triggers
   console.log('[useAttestationStatus] State updated - isVerified: true');
   ```

6. **UI Updates Automatically**:
   - Dashboard: `[⚪ Not Verified]` → `[✅ Verified On-Chain]`
   - Navbar: `[Verify Wallet]` → `[✓ Verified]`

---

## Console Output Example

### Before Verification

```
[useAttestationStatus] useEffect triggered - address: 0x1234... isConnected: true
[useAttestationStatus] Checking attestation for wallet: 0x1234...
[useAttestationStatus] Fetching from: /api/attestations?wallet=0x1234...&limit=1
[useAttestationStatus] Attestation check result: { success: true, count: 0, data: [] }
[useAttestationStatus] Has attestation: false
[useAttestationStatus] ⚪ Wallet is not verified
[useAttestationStatus] State updated - isVerified: false isLoading: false
```

### After Verification

```
[LinkAndAttest] API response: { success: true, message: 'Attestation saved successfully', data: {...} }
[LinkAndAttest] Dispatching attestation-complete event
[useAttestationStatus] Attestation complete event received, refetching...
[useAttestationStatus] Checking attestation for wallet: 0x1234...
[useAttestationStatus] Fetching from: /api/attestations?wallet=0x1234...&limit=1
[useAttestationStatus] Attestation check result: { success: true, count: 1, data: [{...}] }
[useAttestationStatus] Has attestation: true
[useAttestationStatus] ✅ Wallet is verified: { username: "alice", walletAddress: "0x1234...", ... }
[useAttestationStatus] State updated - isVerified: true isLoading: false
```

---

## API Query Confirmation

The hook correctly uses the `wallet` parameter:
```typescript
const apiUrl = `/api/attestations?wallet=${encodeURIComponent(address)}&limit=1`;
```

The API route correctly maps this to `wallet_address` in Supabase:
```typescript
// In /app/api/attestations/route.ts
const wallet = searchParams.get('wallet');
if (wallet) {
  query = query.eq('wallet_address', wallet.toLowerCase());
}
```

This mapping is **correct and working as designed**.

---

## Debugging Guide

### To Check Verification Status

1. Open browser console (F12)
2. Watch for these log patterns:

**Initial Load**:
```
[useAttestationStatus] useEffect triggered
[useAttestationStatus] Checking attestation
[useAttestationStatus] Attestation check result
[useAttestationStatus] Has attestation: false/true
```

**After Completing Verification**:
```
[LinkAndAttest] Dispatching attestation-complete event
[useAttestationStatus] Attestation complete event received
[useAttestationStatus] ✅ Wallet is verified
[useAttestationStatus] State updated - isVerified: true
```

### Common Issues & Solutions

#### Issue: Badge doesn't update after verification
**Check Console For**:
```
[LinkAndAttest] Dispatching attestation-complete event
```
If missing → Event not dispatched (API save failed)

**Check Console For**:
```
[useAttestationStatus] Attestation complete event received
```
If missing → Event listener not registered

**Check Console For**:
```
[useAttestationStatus] ✅ Wallet is verified
```
If missing → API not returning data

#### Issue: API returns empty data
**Check Console For**:
```
[useAttestationStatus] Attestation check result: { success: true, count: 0, data: [] }
```
If this appears → Record not in database

**Verify**:
1. Check Supabase `attestations` table
2. Verify wallet address matches (case-sensitive)
3. Check API endpoint is working

---

## Testing Instructions

### Test Case 1: Fresh Verification

1. Connect wallet with no attestation
2. Open browser console
3. Go to `/mini/contract-test`
4. Complete all 3 steps
5. Watch console logs:
   - Should see `[LinkAndAttest] Dispatching attestation-complete event`
   - Should see `[useAttestationStatus] Attestation complete event received`
   - Should see `[useAttestationStatus] ✅ Wallet is verified`
6. Check UI:
   - Dashboard badge should change to `[✅ Verified On-Chain]`
   - Navbar button should change to `[✓ Verified]`

### Test Case 2: Already Verified

1. Use wallet that's already verified
2. Open browser console
3. Watch for:
   ```
   [useAttestationStatus] Has attestation: true
   [useAttestationStatus] ✅ Wallet is verified
   ```
4. Verify UI shows verified badges immediately

### Test Case 3: Wallet Switch

1. Start with verified wallet
2. Switch to unverified wallet
3. Watch console for:
   ```
   [useAttestationStatus] useEffect triggered - address: 0xNEW...
   [useAttestationStatus] ⚪ Wallet is not verified
   ```
4. Badges should update immediately

---

## Performance Impact

### Additional Operations

1. **Event Listener**: Negligible (one-time setup)
2. **Console Logs**: Development only (can be removed in production)
3. **Refetch Delay**: 1 second wait after completion
4. **State Logging**: Minimal React effect

### Network Impact

- No change to API calls
- Still queries only on wallet change
- Event-driven refetch prevents unnecessary calls

---

## Production Considerations

### Optional: Remove Debug Logs

To clean up console in production, wrap logs:

```typescript
const DEBUG = process.env.NODE_ENV === 'development';

if (DEBUG) {
  console.log('[useAttestationStatus] Checking attestation...');
}
```

Or use a logging utility:

```typescript
const logger = {
  log: (...args: any[]) => {
    if (process.env.NODE_ENV === 'development') {
      console.log(...args);
    }
  },
};

logger.log('[useAttestationStatus] Checking attestation...');
```

---

## Files Modified

### `/lib/hooks/useAttestationStatus.ts`
- ✅ Added comprehensive console logging
- ✅ Added event listener for `attestation-complete`
- ✅ Added state change logging
- ✅ Added 1-second delay for refetch
- ✅ Improved error messages

### `/components/LinkAndAttest.tsx`
- ✅ Added event dispatch on successful save
- ✅ Added API response logging
- ✅ Added error logging

### No Breaking Changes
- API query parameter unchanged (`wallet`)
- Component API unchanged
- State structure unchanged
- No new dependencies

---

## Build Status

```
✓ Finished writing to disk in 378ms
✓ Compiled successfully in 5.8s
✓ Generating static pages (32/32)
```

**Status**: ✅ All builds passing
**Version**: A12 - Enhanced with debugging
**Date**: January 15, 2025

---

## Summary

The hook now:
1. ✅ Logs every step for debugging
2. ✅ Listens for attestation completion events
3. ✅ Automatically refetches after completion
4. ✅ Updates UI in real-time
5. ✅ Provides clear console feedback

**The verification badge should now update automatically after attestation!** 🎉
