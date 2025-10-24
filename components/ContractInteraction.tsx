'use client';

import { useState } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { isAddress } from 'viem';
import contractData from '@/contracts/MeetShipperRegistry.json';

// Contract configuration for Base Mainnet
const CONTRACT_ADDRESS = '0x13c821c62a07d4a6252382939b0afcd2e1527fd4' as const;
const CONTRACT_ABI = contractData.abi;

export default function ContractInteraction() {
  const { address: connectedAddress, isConnected } = useAccount();

  // State for link username section
  const [farcasterUsername, setFarcasterUsername] = useState('');
  const [linkSuccessMessage, setLinkSuccessMessage] = useState('');

  // State for read username section
  const [addressToQuery, setAddressToQuery] = useState('');
  const [queryAddress, setQueryAddress] = useState<`0x${string}` | undefined>();

  // Write contract hook for linkUsername
  const {
    data: linkHash,
    writeContract: linkUsernameWrite,
    isPending: isLinkPending,
    isError: isLinkError,
    error: linkError,
  } = useWriteContract();

  // Wait for transaction confirmation
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash: linkHash,
  });

  // Read contract hook for getUsername
  const {
    data: fetchedUsername,
    isLoading: isReadLoading,
    refetch: refetchUsername,
  } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: CONTRACT_ABI,
    functionName: 'getUsername',
    args: queryAddress ? [queryAddress] : undefined,
    query: {
      enabled: !!queryAddress && isAddress(queryAddress),
    },
  });

  // Handle link username submission
  const handleLinkUsername = async () => {
    if (!farcasterUsername.trim()) {
      alert('Please enter a Farcaster username');
      return;
    }

    setLinkSuccessMessage('');

    try {
      linkUsernameWrite({
        address: CONTRACT_ADDRESS,
        abi: CONTRACT_ABI,
        functionName: 'linkUsername',
        args: [farcasterUsername],
      });
    } catch (error) {
      console.error('Error linking username:', error);
    }
  };

  // Handle successful transaction
  if (isConfirmed && linkHash && !linkSuccessMessage) {
    const message = `✓ Username linked successfully! TX: ${linkHash}`;
    setLinkSuccessMessage(message);
    console.log('Transaction hash:', linkHash);
    // Clear input after success
    setFarcasterUsername('');
  }

  // Handle query username
  const handleQueryUsername = () => {
    const addressToUse = addressToQuery.trim() || connectedAddress;

    if (!addressToUse) {
      alert('Please enter an address or connect your wallet');
      return;
    }

    if (!isAddress(addressToUse)) {
      alert('Invalid Ethereum address');
      return;
    }

    setQueryAddress(addressToUse as `0x${string}`);
  };

  // Use connected wallet address
  const useConnectedAddress = () => {
    if (connectedAddress) {
      setAddressToQuery(connectedAddress);
      setQueryAddress(connectedAddress);
    }
  };

  return (
    <div className="space-y-6">
      {/* Current Connection Info */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">
          MeetShipper Registry Contract
        </h2>

        <div className="space-y-3">
          <div className="flex items-center justify-between py-2 border-b border-gray-100">
            <span className="text-sm text-gray-600">Contract Address</span>
            <span className="text-xs font-mono text-gray-900">
              {CONTRACT_ADDRESS.slice(0, 6)}...{CONTRACT_ADDRESS.slice(-4)}
            </span>
          </div>

          <div className="flex items-center justify-between py-2 border-b border-gray-100">
            <span className="text-sm text-gray-600">Network</span>
            <span className="text-sm font-medium text-gray-900">
              Base Mainnet
            </span>
          </div>

          {isConnected && connectedAddress && (
            <div className="flex items-center justify-between py-2">
              <span className="text-sm text-gray-600">Your Wallet</span>
              <span className="text-xs font-mono text-gray-900">
                {connectedAddress.slice(0, 6)}...{connectedAddress.slice(-4)}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Link Username Section */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">
          Link Farcaster Username
        </h2>

        <p className="text-sm text-gray-600 mb-4">
          Link your Farcaster username to your connected wallet address.
        </p>

        <div className="space-y-4">
          <div>
            <label htmlFor="farcaster-username" className="block text-sm font-medium text-gray-700 mb-2">
              Farcaster Username
            </label>
            <input
              id="farcaster-username"
              type="text"
              value={farcasterUsername}
              onChange={(e) => setFarcasterUsername(e.target.value)}
              placeholder="Enter your username"
              disabled={!isConnected || isLinkPending || isConfirming}
              className="w-full px-4 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-purple-500 focus:border-purple-500 text-sm text-gray-900 placeholder:text-gray-400 disabled:bg-gray-50 disabled:text-gray-500"
            />
          </div>

          <button
            onClick={handleLinkUsername}
            disabled={!isConnected || isLinkPending || isConfirming || !farcasterUsername.trim()}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            {isLinkPending || isConfirming ? (
              <>
                <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                {isConfirming ? 'Confirming...' : 'Linking...'}
              </>
            ) : (
              <>
                <svg className="-ml-1 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                </svg>
                Link Username
              </>
            )}
          </button>

          {/* Success Message */}
          {linkSuccessMessage && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-4">
              <div className="flex items-start gap-3">
                <svg className="w-5 h-5 text-green-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fillRule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                    clipRule="evenodd"
                  />
                </svg>
                <div className="flex-1">
                  <h3 className="text-sm font-semibold text-green-900">Transaction Successful</h3>
                  <p className="mt-1 text-xs text-green-700 font-mono break-all">
                    {linkSuccessMessage}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Error Message */}
          {isLinkError && linkError && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <div className="flex items-start gap-3">
                <svg className="w-5 h-5 text-red-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fillRule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                    clipRule="evenodd"
                  />
                </svg>
                <div className="flex-1">
                  <h3 className="text-sm font-semibold text-red-900">Transaction Failed</h3>
                  <p className="mt-1 text-xs text-red-700">
                    {linkError.message || 'An error occurred while linking username'}
                  </p>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Read Username Section */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">
          Query Username
        </h2>

        <p className="text-sm text-gray-600 mb-4">
          Look up the Farcaster username linked to any wallet address.
        </p>

        <div className="space-y-4">
          <div>
            <label htmlFor="query-address" className="block text-sm font-medium text-gray-700 mb-2">
              Wallet Address
            </label>
            <div className="flex gap-2">
              <input
                id="query-address"
                type="text"
                value={addressToQuery}
                onChange={(e) => setAddressToQuery(e.target.value)}
                placeholder="0x..."
                className="flex-1 px-4 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-purple-500 focus:border-purple-500 text-sm font-mono text-gray-900 placeholder:text-gray-400"
              />
              {isConnected && connectedAddress && (
                <button
                  onClick={useConnectedAddress}
                  className="px-3 py-2 text-sm font-medium text-purple-600 bg-purple-50 border border-purple-200 rounded-md hover:bg-purple-100 transition-colors"
                >
                  Use Mine
                </button>
              )}
            </div>
          </div>

          <button
            onClick={handleQueryUsername}
            disabled={isReadLoading}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            {isReadLoading ? (
              <>
                <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                Loading...
              </>
            ) : (
              <>
                <svg className="-ml-1 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                Query Username
              </>
            )}
          </button>

          {/* Query Result */}
          {queryAddress && (
            <div className="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <div className="space-y-3">
                <div className="flex items-center justify-between py-2 border-b border-gray-200">
                  <span className="text-sm text-gray-600">Queried Address</span>
                  <span className="text-xs font-mono text-gray-900">
                    {queryAddress.slice(0, 6)}...{queryAddress.slice(-4)}
                  </span>
                </div>
                <div className="flex items-center justify-between py-2">
                  <span className="text-sm text-gray-600">Linked Username</span>
                  <span className="text-sm font-semibold text-gray-900">
                    {isReadLoading ? (
                      <span className="text-gray-400">Loading...</span>
                    ) : fetchedUsername && fetchedUsername !== '' ? (
                      <span className="text-purple-600">{fetchedUsername as string}</span>
                    ) : (
                      <span className="text-gray-400">No username linked</span>
                    )}
                  </span>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Info Card */}
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <div className="flex items-start gap-3">
          <svg className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
            <path
              fillRule="evenodd"
              d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5h.253a.25.25 0 01.244.304l-.459 2.066A1.75 1.75 0 0010.747 15H11a.75.75 0 000-1.5h-.253a.25.25 0 01-.244-.304l.459-2.066A1.75 1.75 0 009.253 9H9z"
              clipRule="evenodd"
            />
          </svg>
          <div>
            <h3 className="text-sm font-semibold text-blue-900">How It Works</h3>
            <p className="mt-1 text-sm text-blue-700">
              Link your Farcaster username to your wallet address on-chain. This creates a verifiable connection
              between your Web3 wallet and your Farcaster identity. All transactions are recorded on Base Mainnet.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
