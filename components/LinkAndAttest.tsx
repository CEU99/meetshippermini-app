'use client';

import { useState, useEffect } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { EAS, SchemaEncoder } from '@ethereum-attestation-service/eas-sdk';
import { BrowserProvider } from 'ethers';
import contractData from '@/contracts/MeetShipperRegistry.json';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';

// ✅ Contract configuration
const CONTRACT_ADDRESS = '0x13c821c62a07d4a6252382939b0afcd2e1527fd4' as const;
const CONTRACT_ABI = contractData.abi;

// ✅ EAS Configuration
const EAS_CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_EAS_CONTRACT as string;
const SCHEMA_UID = process.env.NEXT_PUBLIC_EAS_SCHEMA_UID as string;

// ✅ Step status type
type StepStatus = 'pending' | 'in_progress' | 'completed' | 'error';
interface StepState {
  link: StepStatus;
  attest: StepStatus;
  save: StepStatus;
}

export default function LinkAndAttest() {
  const { address: connectedAddress, isConnected } = useAccount();
  const { user, loading: authLoading } = useFarcasterAuth();

  const [txHash, setTxHash] = useState('');
  const [attestationUID, setAttestationUID] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [warningMessage, setWarningMessage] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const [stepState, setStepState] = useState<StepState>({
    link: 'pending',
    attest: 'pending',
    save: 'pending'
  });
  const [isChecking, setIsChecking] = useState(false);
  const [alreadyLinked, setAlreadyLinked] = useState(false);
  const [existingRecord, setExistingRecord] = useState<any>(null);

  const {
    data: linkHash,
    writeContract: linkUsernameWrite,
    isPending: isLinkPending,
    isError: isLinkError,
    error: linkError,
    reset: resetLinkContract,
  } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash: linkHash
  });

  // ✅ Debug: Log auth state changes
  useEffect(() => {
    console.log('[LinkAndAttest] Auth state changed:', {
      authLoading,
      hasUser: !!user,
      fid: user?.fid,
      username: user?.username,
      displayName: user?.displayName,
    });
  }, [user, authLoading]);

  // ✅ Auto-fade success messages
  useEffect(() => {
    if (successMessage) {
      const timer = setTimeout(() => setSuccessMessage(''), 4000);
      return () => clearTimeout(timer);
    }
  }, [successMessage]);

  // ✅ Auto-progress from Step 1 to Step 2
  useEffect(() => {
    if (isConfirmed && linkHash && stepState.link === 'in_progress') {
      setTxHash(linkHash);
      setStepState(prev => ({ ...prev, link: 'completed' }));
      setSuccessMessage('Step 1 completed: Username linked! ✅');
      setTimeout(() => handleAttest(), 1000);
    }
  }, [isConfirmed, linkHash, stepState.link]);

  const clearMessages = () => {
    setSuccessMessage('');
    setWarningMessage('');
    setErrorMessage('');
  };

  const resetAll = () => {
    setStepState({ link: 'pending', attest: 'pending', save: 'pending' });
    setTxHash('');
    setAttestationUID('');
    setAlreadyLinked(false);
    setExistingRecord(null);
    clearMessages();
    resetLinkContract();
  };

  // ✅ Check for duplicates before starting
  const checkForDuplicates = async () => {
    if (!user?.username || !connectedAddress || !user?.fid) {
      return false;
    }

    setIsChecking(true);
    clearMessages();

    try {
      // Check by FID and wallet
      const fidResponse = await fetch(
        `/api/attestations?fid=${user.fid}&wallet=${encodeURIComponent(connectedAddress)}&limit=1`
      );
      const fidData = await fidResponse.json();

      if (fidData.success && fidData.data?.length > 0) {
        const record = fidData.data[0];
        setAlreadyLinked(true);
        setExistingRecord(record);
        setWarningMessage(
          `⚠️ You have already linked your Farcaster account (@${user.username}) with this wallet.`
        );
        setTxHash(record.txHash);
        setAttestationUID(record.attestationUID);
        setStepState({ link: 'completed', attest: 'completed', save: 'completed' });
        return true;
      }

      return false;
    } catch (err: any) {
      console.error('[LinkAndAttest] Error checking duplicates:', err);
      setErrorMessage('Failed to check existing records.');
      return false;
    } finally {
      setIsChecking(false);
    }
  };

  // ✅ Step 1: Link Username
  const handleLink = async () => {
    if (!user?.username) {
      return setErrorMessage('Farcaster username not available. Please log in first.');
    }
    if (!isConnected || !connectedAddress) {
      return setErrorMessage('Connect wallet first');
    }
    if (!user?.fid) {
      return setErrorMessage('Farcaster FID not available. Please log in again.');
    }

    // Pre-check for duplicates
    const isDuplicate = await checkForDuplicates();
    if (isDuplicate) {
      return; // Stop if duplicate found
    }

    clearMessages();
    setStepState(prev => ({ ...prev, link: 'in_progress' }));

    try {
      console.log('[LinkAndAttest] Linking username:', user.username);
      linkUsernameWrite({
        address: CONTRACT_ADDRESS,
        abi: CONTRACT_ABI,
        functionName: 'linkUsername',
        args: [user.username],
      });
    } catch (err: any) {
      console.error('[LinkAndAttest] Link error:', err);
      setErrorMessage(err.message || 'Failed to link username');
      setStepState(prev => ({ ...prev, link: 'error' }));
    }
  };

  // ✅ Step 2: Create Attestation
  const handleAttest = async () => {
    if (!connectedAddress || !txHash) {
      return setErrorMessage('Link username first');
    }
    if (!EAS_CONTRACT_ADDRESS || !SCHEMA_UID) {
      return setErrorMessage('EAS config missing');
    }
    if (!user?.username) {
      return setErrorMessage('Farcaster username not available');
    }

    clearMessages();
    setStepState(prev => ({ ...prev, attest: 'in_progress' }));

    try {
      console.log('[LinkAndAttest] Creating attestation for:', user.username);

      const provider = new BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const eas = new EAS(EAS_CONTRACT_ADDRESS);
      eas.connect(signer);

      const schemaEncoder = new SchemaEncoder('string username,address wallet');
      const encodedData = schemaEncoder.encodeData([
        { name: 'username', value: user.username, type: 'string' },
        { name: 'wallet', value: connectedAddress, type: 'address' },
      ]);

      const tx = await eas.attest({
        schema: SCHEMA_UID,
        data: {
          recipient: connectedAddress,
          expirationTime: BigInt(0),
          revocable: true,
          data: encodedData
        },
      });

      const uid = await tx.wait();
      console.log('[LinkAndAttest] Attestation UID:', uid);

      setAttestationUID(uid);
      setStepState(prev => ({ ...prev, attest: 'completed' }));
      setSuccessMessage('Step 2 completed: Attestation created ✅');
      setTimeout(() => handleSave(uid), 1000);
    } catch (err: any) {
      console.error('[LinkAndAttest] Attestation error:', err);
      setErrorMessage(err.message || 'Failed to create attestation');
      setStepState(prev => ({ ...prev, attest: 'error' }));
    }
  };

  // ✅ Step 3: Save to Database
  const handleSave = async (uid?: string) => {
    const attestUID = uid || attestationUID;

    if (!connectedAddress || !txHash || !attestUID) {
      return setErrorMessage('Previous steps incomplete');
    }

    if (!user?.fid) {
      setErrorMessage('User FID not available. Please log in with Farcaster.');
      setStepState(prev => ({ ...prev, save: 'error' }));
      return;
    }

    if (!user?.username) {
      setErrorMessage('User username not available. Please log in with Farcaster.');
      setStepState(prev => ({ ...prev, save: 'error' }));
      return;
    }

    console.log('[LinkAndAttest] Saving to database:', {
      fid: user.fid,
      username: user.username,
      wallet: connectedAddress,
      txHash,
      attestationUID: attestUID,
    });

    clearMessages();
    setStepState(prev => ({ ...prev, save: 'in_progress' }));

    try {
      const res = await fetch('/api/attestations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: user.username,
          wallet: connectedAddress,
          txHash,
          attestationUID: attestUID,
          fid: user.fid, // ✅ FID included!
        }),
      });

      const data = await res.json();
      console.log('[LinkAndAttest] API response:', data);

      if (!res.ok) {
        throw new Error(data.error || 'Save failed');
      }

      setStepState(prev => ({ ...prev, save: 'completed' }));
      setSuccessMessage('✅ All steps completed successfully!');

      // Dispatch event to notify other components
      console.log('[LinkAndAttest] Dispatching attestation-complete event');
      window.dispatchEvent(new Event('attestation-complete'));
    } catch (err: any) {
      console.error('[LinkAndAttest] DB save error:', err);
      setWarningMessage(`⚠️ Saved on-chain but failed in DB: ${err.message}`);
      setStepState(prev => ({ ...prev, save: 'error' }));
    }
  };

  // ✅ Loading state
  if (authLoading) {
    return (
      <div className="p-6 bg-blue-50 border border-blue-200 rounded-lg text-black">
        <div className="flex items-center gap-3">
          <svg className="animate-spin h-5 w-5 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <p>⏳ Loading Farcaster user session...</p>
        </div>
      </div>
    );
  }

  // ✅ Not authenticated
  if (!user) {
    return (
      <div className="p-6 bg-yellow-50 border border-yellow-200 rounded-lg text-black">
        <p className="font-semibold mb-2">⚠️ Farcaster Authentication Required</p>
        <p className="text-sm text-gray-600 mb-4">
          Please log in with Farcaster to link your wallet and create attestations.
        </p>
        <a
          href="/"
          className="inline-block bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700 transition"
        >
          Go to Login
        </a>
      </div>
    );
  }

  // ✅ Styling helpers
  const getButtonStyle = (status: StepStatus, active: boolean) => {
    if (status === 'completed') return 'bg-green-600 hover:bg-green-700 text-white';
    if (status === 'error') return 'bg-red-600 hover:bg-red-700 text-white';
    if (status === 'in_progress') return 'bg-blue-600 text-white cursor-wait';
    return active
      ? 'bg-gradient-to-r from-purple-600 to-blue-600 text-white hover:opacity-90'
      : 'bg-gray-300 text-gray-500 cursor-not-allowed';
  };

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

  const allStepsCompleted = Object.values(stepState).every(s => s === 'completed');

  return (
    <div className="space-y-6">
      {/* User Info Display */}
      <div className="bg-gradient-to-r from-purple-50 to-blue-50 border border-purple-200 rounded-lg p-4">
        <h3 className="text-sm font-semibold text-gray-700 mb-2">📋 Authenticated User</h3>
        <div className="grid grid-cols-2 gap-2 text-sm">
          <div>
            <span className="text-gray-600">Username:</span>
            <span className="ml-2 font-mono text-purple-700">@{user.username}</span>
          </div>
          <div>
            <span className="text-gray-600">FID:</span>
            <span className="ml-2 font-mono text-blue-700">{user.fid}</span>
          </div>
        </div>
      </div>

      {/* Main Card */}
      <div className="bg-white border border-gray-200 p-6 rounded-lg">
        <h2 className="text-lg font-semibold mb-4 text-black">
          Link Farcaster Account & Create Attestation
        </h2>

        <p className="text-sm text-gray-600 mb-4">
          Connect your Farcaster account <strong>@{user.username}</strong> to your wallet and create
          an on-chain attestation to verify ownership.
        </p>

        <div className="space-y-3">
          {/* Step 1 Button */}
          <button
            onClick={handleLink}
            disabled={
              !isConnected ||
              stepState.link !== 'pending' ||
              alreadyLinked ||
              isChecking
            }
            className={`w-full py-3 px-4 rounded-md font-medium transition-all ${getButtonStyle(
              stepState.link,
              stepState.link === 'pending' && !alreadyLinked
            )}`}
          >
            {isChecking ? '🔍 Checking...' : getButtonLabel('link', stepState.link)}
          </button>

          {/* Step 2 Button */}
          <button
            onClick={handleAttest}
            disabled={
              stepState.link !== 'completed' ||
              stepState.attest !== 'pending' ||
              alreadyLinked
            }
            className={`w-full py-3 px-4 rounded-md font-medium transition-all ${getButtonStyle(
              stepState.attest,
              stepState.link === 'completed' && !alreadyLinked
            )}`}
          >
            {getButtonLabel('attest', stepState.attest)}
          </button>

          {/* Step 3 Button */}
          <button
            onClick={() => handleSave()}
            disabled={
              stepState.attest !== 'completed' ||
              stepState.save !== 'pending' ||
              alreadyLinked
            }
            className={`w-full py-3 px-4 rounded-md font-medium transition-all ${getButtonStyle(
              stepState.save,
              stepState.attest === 'completed' && !alreadyLinked
            )}`}
          >
            {getButtonLabel('save', stepState.save)}
          </button>

          {/* Reset Button */}
          {allStepsCompleted && (
            <button
              onClick={resetAll}
              className="w-full py-2 text-purple-600 border border-purple-200 rounded-md mt-3 hover:bg-purple-50 transition"
            >
              Start New Process
            </button>
          )}
        </div>
      </div>

      {/* Messages */}
      {successMessage && (
        <div className="bg-green-50 border border-green-200 p-4 rounded-lg animate-fade-in text-black">
          {successMessage}
        </div>
      )}
      {warningMessage && (
        <div className="bg-yellow-50 border border-yellow-200 p-4 rounded-lg text-black">
          {warningMessage}
        </div>
      )}
      {errorMessage && (
        <div className="bg-red-50 border border-red-200 p-4 rounded-lg text-black">
          {errorMessage}
        </div>
      )}

      {/* Transaction Details */}
      {(txHash || attestationUID) && (
        <div className="bg-white border border-gray-200 p-6 rounded-lg">
          <h3 className="text-md font-semibold mb-3 text-black">Process Data</h3>
          <div className="space-y-3 text-sm">
            {user.username && (
              <div>
                <p className="text-gray-600 mb-1">Farcaster Username</p>
                <p className="bg-gray-100 px-3 py-2 rounded font-mono text-black">
                  @{user.username}
                </p>
              </div>
            )}
            {user.fid && (
              <div>
                <p className="text-gray-600 mb-1">Farcaster FID</p>
                <p className="bg-gray-100 px-3 py-2 rounded font-mono text-black">
                  {user.fid}
                </p>
              </div>
            )}
            {connectedAddress && (
              <div>
                <p className="text-gray-600 mb-1">Wallet Address</p>
                <p className="bg-gray-100 px-3 py-2 rounded font-mono break-all text-black">
                  {connectedAddress}
                </p>
              </div>
            )}
            {txHash && (
              <div>
                <p className="text-gray-600 mb-1">Transaction Hash</p>
                <div className="bg-blue-50 px-3 py-2 rounded">
                  <p className="font-mono break-all mb-1 text-black">{txHash}</p>
                  <a
                    href={`https://basescan.org/tx/${txHash}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 hover:underline text-xs"
                  >
                    🔗 View on Basescan
                  </a>
                </div>
              </div>
            )}
            {attestationUID && (
              <div>
                <p className="text-gray-600 mb-1">Attestation UID</p>
                <div className="bg-green-50 px-3 py-2 rounded">
                  <p className="font-mono break-all mb-1 text-black">{attestationUID}</p>
                  <a
                    href={`https://base.easscan.org/attestation/view/${attestationUID}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-green-600 hover:underline text-xs"
                  >
                    🔗 View on EAS Scan
                  </a>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
