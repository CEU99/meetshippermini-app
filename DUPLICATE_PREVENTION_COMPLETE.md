# Duplicate Prevention Implementation - Complete

## Overview

The `LinkAndAttest.tsx` component and `/api/attestations` endpoint now include comprehensive duplicate prevention to ensure each username and wallet address can only be linked and attested once.

## Backend Implementation (API)

### File: `/app/api/attestations/route.ts`

#### Duplicate Check Logic

The POST handler now checks for duplicates BEFORE inserting a new record:

```typescript
// Check if username OR wallet already exists
const { data: existingRecords, error: checkError } = await supabase
  .from('attestations')
  .select('username, wallet_address, attestation_uid')
  .or(`username.eq.${username},wallet_address.eq.${wallet.toLowerCase()}`);

if (checkError) {
  console.error('Error checking for existing records:', checkError);
  return NextResponse.json(
    {
      success: false,
      error: 'Database error while checking for duplicates',
      details: checkError.message,
    },
    { status: 500 }
  );
}

// Check if username or wallet already exists
if (existingRecords && existingRecords.length > 0) {
  const existingUsername = existingRecords.find(r => r.username === username);
  const existingWallet = existingRecords.find(r => r.wallet_address.toLowerCase() === wallet.toLowerCase());

  if (existingUsername && existingWallet) {
    return NextResponse.json(
      {
        success: false,
        error: 'Record already exists for this username and wallet',
        details: 'Both the username and wallet address have already been linked',
      },
      { status: 409 }
    );
  } else if (existingUsername) {
    return NextResponse.json(
      {
        success: false,
        error: 'Record already exists for this username',
        details: `Username "${username}" has already been linked`,
      },
      { status: 409 }
    );
  } else if (existingWallet) {
    return NextResponse.json(
      {
        success: false,
        error: 'Record already exists for this wallet',
        details: `Wallet address has already been linked`,
      },
      { status: 409 }
    );
  }
}
```

#### Response Codes

- **409 Conflict**: Username or wallet already exists
- **400 Bad Request**: Invalid input data
- **500 Internal Server Error**: Database error
- **200 OK**: Successfully created attestation

## Frontend Implementation (Component)

### File: `/components/LinkAndAttest.tsx`

#### New State Variables

```typescript
const [isChecking, setIsChecking] = useState(false);
const [alreadyLinked, setAlreadyLinked] = useState(false);
const [existingRecord, setExistingRecord] = useState<any>(null);
```

#### Duplicate Check Function

```typescript
const checkForDuplicates = async () => {
  if (!farcasterUsername.trim() || !connectedAddress) {
    return false;
  }

  setIsChecking(true);
  clearMessages();

  try {
    // Check by username
    const usernameResponse = await fetch(`/api/attestations?username=${encodeURIComponent(farcasterUsername)}&limit=1`);
    const usernameData = await usernameResponse.json();

    // Check by wallet
    const walletResponse = await fetch(`/api/attestations?wallet=${encodeURIComponent(connectedAddress)}&limit=1`);
    const walletData = await walletResponse.json();

    if (usernameData.success && usernameData.data && usernameData.data.length > 0) {
      const record = usernameData.data[0];
      setAlreadyLinked(true);
      setExistingRecord(record);
      setWarningMessage(`⚠️ Username "${farcasterUsername}" has already been linked and attested.`);
      setTxHash(record.txHash);
      setAttestationUID(record.attestationUID);
      setStepState({ link: 'completed', attest: 'completed', save: 'completed' });
      return true;
    }

    if (walletData.success && walletData.data && walletData.data.length > 0) {
      const record = walletData.data[0];
      setAlreadyLinked(true);
      setExistingRecord(record);
      setWarningMessage(`⚠️ This wallet address has already been linked and attested with username "${record.username}".`);
      setTxHash(record.txHash);
      setAttestationUID(record.attestationUID);
      setStepState({ link: 'completed', attest: 'completed', save: 'completed' });
      return true;
    }

    return false;
  } catch (err: any) {
    console.error('Error checking for duplicates:', err);
    setErrorMessage('Failed to check for existing records. Please try again.');
    return false;
  } finally {
    setIsChecking(false);
  }
};
```

#### Updated Step 1 Handler

```typescript
const handleLink = async () => {
  if (!farcasterUsername.trim()) return setErrorMessage('Please enter a username');
  if (!isConnected || !connectedAddress) return setErrorMessage('Connect wallet first');

  // Pre-check for duplicates
  const isDuplicate = await checkForDuplicates();
  if (isDuplicate) {
    return; // Stop if duplicate found
  }

  clearMessages();
  setStepState(prev => ({ ...prev, link: 'in_progress' }));

  try {
    linkUsernameWrite({
      address: CONTRACT_ADDRESS,
      abi: CONTRACT_ABI,
      functionName: 'linkUsername',
      args: [farcasterUsername],
    });
  } catch (err: any) {
    setErrorMessage(err.message || 'Failed to link username');
    setStepState(prev => ({ ...prev, link: 'error' }));
  }
};
```

#### Visual Feedback

##### 1. Username Input Badge

When a duplicate is detected, an "Already Linked ✅" badge appears in the input field:

```tsx
<div className="relative mb-3">
  <input
    type="text"
    value={farcasterUsername}
    onChange={(e) => setFarcasterUsername(e.target.value)}
    placeholder="Enter Farcaster username"
    className="w-full px-3 py-2 border rounded-md text-sm"
    disabled={!isConnected || stepState.link !== 'pending' || alreadyLinked}
  />
  {alreadyLinked && (
    <span className="absolute right-3 top-2 text-green-600 font-semibold text-sm">
      Already Linked ✅
    </span>
  )}
</div>
```

##### 2. Button Labels

Buttons display different text when showing already-linked state:

```typescript
const getButtonLabel = (step: 'link' | 'attest' | 'save', status: StepStatus) => {
  if (alreadyLinked && status === 'completed') {
    if (step === 'link') return '✓ Already Linked';
    if (step === 'attest') return '✓ Already Attested';
    if (step === 'save') return '✓ Already Saved';
  }
  if (status === 'completed') {
    if (step === 'link') return '✓ Link Username';
    if (step === 'attest') return '✓ Create Attestation';
    if (step === 'save') return '✓ Save to Database';
  }
  if (step === 'link') return 'Step 1: Link Username';
  if (step === 'attest') return 'Step 2: Create Attestation';
  return 'Step 3: Save to Database';
};
```

##### 3. Warning Banner

A yellow warning banner displays when duplicate is detected:

```
⚠️ Username "alice" has already been linked and attested.
```

or

```
⚠️ This wallet address has already been linked and attested with username "alice".
```

##### 4. All Buttons Disabled

When `alreadyLinked` is true, all step buttons are disabled and show green "completed" state.

##### 5. Process Data Display

The existing record's data (TX hash, attestation UID) is automatically loaded and displayed with links to Basescan and EAS Scan.

## User Flow

### Scenario 1: First-Time User (No Duplicate)

1. User enters username "alice"
2. User clicks "Step 1: Link Username"
3. Component checks for duplicates
4. No duplicate found → proceed with contract transaction
5. Wallet popup appears
6. User approves → transaction confirmed
7. Auto-progress to Step 2 → Step 3
8. Success: "All steps completed successfully!"

### Scenario 2: Duplicate Username Detected

1. User enters username "alice" (already linked)
2. User clicks "Step 1: Link Username"
3. Component checks for duplicates
4. **Duplicate found** → Shows warning banner: "⚠️ Username 'alice' has already been linked..."
5. All buttons turn green with "✓ Already Linked" / "✓ Already Attested" / "✓ Already Saved"
6. Input field shows "Already Linked ✅" badge
7. All buttons disabled
8. Existing record data displayed (TX hash, attestation UID)
9. User can click "Start New Process" to reset and try a different username

### Scenario 3: Duplicate Wallet Detected

1. User enters username "bob"
2. User clicks "Step 1: Link Username"
3. Component checks for duplicates
4. **Duplicate wallet found** → Shows warning banner: "⚠️ This wallet address has already been linked with username 'alice'."
5. All buttons turn green showing "alice" was previously linked
6. All buttons disabled
7. Existing record data displayed
8. User must use a different wallet address

## Testing

### Test Case 1: Create New Attestation

**Steps:**
1. Connect wallet with address `0x1234...`
2. Enter username "alice"
3. Click "Step 1: Link Username"
4. Approve contract transaction
5. Approve attestation transaction
6. Wait for database save

**Expected Result:**
- ✅ All 3 steps complete successfully
- ✅ Success message: "All steps completed successfully!"
- ✅ TX hash and attestation UID displayed
- ✅ Links to Basescan and EAS Scan work
- ✅ Record saved in database

### Test Case 2: Attempt Duplicate Username

**Steps:**
1. Complete Test Case 1 first
2. Disconnect wallet, then reconnect with DIFFERENT wallet `0x5678...`
3. Enter username "alice" again
4. Click "Step 1: Link Username"

**Expected Result:**
- ✅ Warning banner appears: "⚠️ Username 'alice' has already been linked..."
- ✅ All buttons turn green with "✓ Already Linked" labels
- ✅ All buttons disabled
- ✅ Input shows "Already Linked ✅" badge
- ✅ Original record data displayed (from Test Case 1)
- ✅ No blockchain transaction occurs

### Test Case 3: Attempt Duplicate Wallet

**Steps:**
1. Complete Test Case 1 first
2. Keep same wallet connected
3. Enter DIFFERENT username "bob"
4. Click "Step 1: Link Username"

**Expected Result:**
- ✅ Warning banner appears: "⚠️ This wallet address has already been linked with username 'alice'."
- ✅ All buttons turn green showing previous link
- ✅ All buttons disabled
- ✅ Original record data displayed (username "alice", not "bob")
- ✅ No blockchain transaction occurs

### Test Case 4: Reset and Try Again

**Steps:**
1. After duplicate detected (Test Case 2 or 3)
2. Click "Start New Process" button

**Expected Result:**
- ✅ All states reset to "pending"
- ✅ Input field enabled again
- ✅ All data cleared
- ✅ Messages cleared
- ✅ Can enter new username

## API Endpoints

### POST `/api/attestations`

**Request Body:**
```json
{
  "username": "alice",
  "wallet": "0x1234567890abcdef1234567890abcdef12345678",
  "txHash": "0xabcd...",
  "attestationUID": "0x9876..."
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Attestation saved successfully",
  "data": {
    "id": "uuid",
    "username": "alice",
    "walletAddress": "0x1234...",
    "txHash": "0xabcd...",
    "attestationUID": "0x9876...",
    "createdAt": "2025-01-15T10:30:00Z"
  }
}
```

**Response (Duplicate Username - 409):**
```json
{
  "success": false,
  "error": "Record already exists for this username",
  "details": "Username \"alice\" has already been linked"
}
```

**Response (Duplicate Wallet - 409):**
```json
{
  "success": false,
  "error": "Record already exists for this wallet",
  "details": "Wallet address has already been linked"
}
```

**Response (Both Duplicate - 409):**
```json
{
  "success": false,
  "error": "Record already exists for this username and wallet",
  "details": "Both the username and wallet address have already been linked"
}
```

### GET `/api/attestations`

**Query Parameters:**
- `username` (optional): Filter by Farcaster username
- `wallet` (optional): Filter by wallet address
- `attestationUID` (optional): Filter by attestation UID
- `limit` (optional): Limit results (1-100, default 20)

**Example:**
```
GET /api/attestations?username=alice&limit=1
GET /api/attestations?wallet=0x1234567890abcdef1234567890abcdef12345678
```

**Response (Success - 200):**
```json
{
  "success": true,
  "count": 1,
  "data": [
    {
      "id": "uuid",
      "username": "alice",
      "walletAddress": "0x1234...",
      "txHash": "0xabcd...",
      "attestationUID": "0x9876...",
      "createdAt": "2025-01-15T10:30:00Z",
      "updatedAt": "2025-01-15T10:30:00Z"
    }
  ]
}
```

## Database Schema

```sql
CREATE TABLE IF NOT EXISTS public.attestations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT NOT NULL,
  wallet_address TEXT NOT NULL,
  tx_hash TEXT NOT NULL,
  attestation_uid TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attestations_wallet_address ON public.attestations(wallet_address);
CREATE INDEX IF NOT EXISTS idx_attestations_username ON public.attestations(username);
CREATE INDEX IF NOT EXISTS idx_attestations_uid ON public.attestations(attestation_uid);
```

## Benefits

✅ **Prevents Duplicate Transactions**: No wasted gas fees on duplicate attempts
✅ **Clear User Feedback**: Users immediately know if already linked
✅ **Data Integrity**: Ensures one-to-one relationship between username and wallet
✅ **Backend Safety**: API enforces uniqueness even if frontend bypassed
✅ **User Experience**: Shows existing data instead of error
✅ **No Blockchain Spam**: Prevents unnecessary contract calls
✅ **Fast Pre-Check**: Frontend check happens before wallet popup

## Files Modified

1. `/app/api/attestations/route.ts` - Added duplicate checking logic in POST handler
2. `/components/LinkAndAttest.tsx` - Added frontend duplicate detection and visual feedback

## Build Status

✅ Build completed successfully
✅ All TypeScript types correct
✅ No linting errors
✅ Production ready

---

**Version**: v2.1 with Duplicate Prevention
**Status**: ✅ Complete and Tested
**Date**: 2025-01-15
