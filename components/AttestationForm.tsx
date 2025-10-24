'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';
import { EAS, SchemaEncoder } from '@ethereum-attestation-service/eas-sdk';
import { BrowserProvider } from 'ethers';

// EAS Configuration from environment variables
const EAS_CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_EAS_CONTRACT as string;
const SCHEMA_UID = process.env.NEXT_PUBLIC_EAS_SCHEMA_UID as string;

export default function AttestationForm() {
  const { address: connectedAddress, isConnected } = useAccount();

  // Form state
  const [farcasterUsername, setFarcasterUsername] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [attestationUID, setAttestationUID] = useState('');
  const [error, setError] = useState('');

  // Check if environment variables are configured
  const isConfigured = EAS_CONTRACT_ADDRESS && SCHEMA_UID;

  // Handle attestation creation
  const handleCreateAttestation = async () => {
    if (!farcasterUsername.trim()) {
      setError('Please enter a Farcaster username');
      return;
    }

    if (!isConnected || !connectedAddress) {
      setError('Please connect your wallet first');
      return;
    }

    if (!isConfigured) {
      setError('EAS configuration missing. Please check your environment variables.');
      return;
    }

    setIsLoading(true);
    setError('');
    setAttestationUID('');

    try {
      // Check if wallet provider is available
      if (!window.ethereum) {
        throw new Error('No wallet provider found. Please install a Web3 wallet.');
      }

      // Create ethers provider and signer
      const provider = new BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      // Initialize EAS with the signer
      const eas = new EAS(EAS_CONTRACT_ADDRESS);
      eas.connect(signer);

      // Define the schema encoder
      // Schema format: string username, address wallet
      const schemaEncoder = new SchemaEncoder('string username,address wallet');

      // Encode the attestation data
      const encodedData = schemaEncoder.encodeData([
        { name: 'username', value: farcasterUsername, type: 'string' },
        { name: 'wallet', value: connectedAddress, type: 'address' },
      ]);

      // Create the attestation transaction
      const tx = await eas.attest({
        schema: SCHEMA_UID,
        data: {
          recipient: connectedAddress,
          expirationTime: BigInt(0), // No expiration
          revocable: true,
          data: encodedData,
        },
      });

      // Wait for the transaction to be mined and get the attestation UID
      const uid = await tx.wait();

      console.log('✓ Attestation created successfully! UID:', uid);
      setAttestationUID(uid);
      setFarcasterUsername(''); // Clear input on success
    } catch (err: any) {
      console.error('Error creating attestation:', err);

      // Handle specific error cases
      if (err.code === 'ACTION_REJECTED' || err.code === 4001) {
        setError('Transaction was rejected. Please try again.');
      } else if (err.message?.toLowerCase().includes('insufficient funds')) {
        setError('Insufficient funds to complete the transaction.');
      } else if (err.message?.toLowerCase().includes('user rejected')) {
        setError('Transaction rejected by user.');
      } else {
        setError(err.message || 'Failed to create attestation. Please try again.');
      }
    } finally {
      setIsLoading(false);
    }
  };

  // Generate EAS Scan URL for viewing the attestation
  const getEASScanURL = (uid: string) => {
    return `https://base.easscan.org/attestation/view/${uid}`;
  };

  return (
    <div className="space-y-6">
      {/* Configuration Warning Banner */}
      {!isConfigured && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <svg className="w-5 h-5 text-yellow-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
              <path
                fillRule="evenodd"
                d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z"
                clipRule="evenodd"
              />
            </svg>
            <div className="flex-1">
              <h3 className="text-sm font-semibold text-yellow-900">Missing EAS Configuration</h3>
              <p className="mt-1 text-xs text-yellow-700">
                {!EAS_CONTRACT_ADDRESS && 'NEXT_PUBLIC_EAS_CONTRACT is not set. '}
                {!SCHEMA_UID && 'NEXT_PUBLIC_EAS_SCHEMA_UID is not set. '}
                Please configure these environment variables to enable attestation creation.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* EAS Contract Info */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">
          Ethereum Attestation Service
        </h2>

        <div className="space-y-3">
          <div className="flex items-center justify-between py-2 border-b border-gray-100">
            <span className="text-sm text-gray-600">EAS Contract</span>
            <span className="text-xs font-mono text-gray-900">
              {EAS_CONTRACT_ADDRESS ? `${EAS_CONTRACT_ADDRESS.slice(0, 6)}...${EAS_CONTRACT_ADDRESS.slice(-4)}` : 'Not configured'}
            </span>
          </div>

          <div className="flex items-center justify-between py-2 border-b border-gray-100">
            <span className="text-sm text-gray-600">Schema UID</span>
            <span className="text-xs font-mono text-gray-900">
              {SCHEMA_UID ? `${SCHEMA_UID.slice(0, 10)}...${SCHEMA_UID.slice(-8)}` : 'Not configured'}
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

      {/* Create Attestation Form */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">
          Create Attestation
        </h2>

        <p className="text-sm text-gray-600 mb-4">
          Create an on-chain attestation linking your Farcaster username to your wallet address using the Ethereum Attestation Service.
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
              disabled={!isConnected || isLoading || !isConfigured}
              className="w-full px-4 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 text-sm text-gray-900 placeholder:text-gray-400 disabled:bg-gray-50 disabled:text-gray-500"
            />
          </div>

          {/* Display Connected Wallet Address */}
          {isConnected && connectedAddress && (
            <div className="bg-gray-50 rounded-lg p-3 border border-gray-200">
              <p className="text-xs text-gray-600">
                <span className="font-semibold">Connected Wallet:</span>{' '}
                <span className="font-mono text-gray-900">
                  {connectedAddress}
                </span>
              </p>
              <p className="text-xs text-gray-500 mt-1">
                This address will be included in the attestation.
              </p>
            </div>
          )}

          <button
            onClick={handleCreateAttestation}
            disabled={!isConnected || isLoading || !farcasterUsername.trim() || !isConfigured}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            {isLoading ? (
              <>
                <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                Creating Attestation...
              </>
            ) : (
              <>
                <svg className="-ml-1 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Create Attestation
              </>
            )}
          </button>

          {/* Success Message with Attestation UID */}
          {attestationUID && (
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
                  <h3 className="text-sm font-semibold text-green-900">Attestation Created Successfully!</h3>
                  <p className="mt-1 text-xs text-green-700">
                    Your attestation has been recorded on-chain.
                  </p>
                  <div className="mt-2 space-y-2">
                    <div className="bg-white rounded p-2 border border-green-300">
                      <span className="text-xs text-gray-600 block mb-1">Attestation UID:</span>
                      <code className="text-xs font-mono text-gray-900 break-all">{attestationUID}</code>
                    </div>
                    <a
                      href={getEASScanURL(attestationUID)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center text-xs font-medium text-green-700 hover:text-green-800 underline"
                    >
                      <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                      </svg>
                      View on EAS Scan
                    </a>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Error Message */}
          {error && (
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
                    {error}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Connection Warning */}
          {!isConnected && (
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <div className="flex items-start gap-3">
                <svg className="w-5 h-5 text-yellow-600 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fillRule="evenodd"
                    d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z"
                    clipRule="evenodd"
                  />
                </svg>
                <div className="flex-1">
                  <h3 className="text-sm font-semibold text-yellow-900">Wallet Not Connected</h3>
                  <p className="mt-1 text-xs text-yellow-700">
                    Please connect your wallet to create an attestation.
                  </p>
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
            <h3 className="text-sm font-semibold text-blue-900">About EAS Attestations</h3>
            <p className="mt-1 text-sm text-blue-700">
              The Ethereum Attestation Service (EAS) allows you to create verifiable, on-chain attestations.
              This form creates an attestation that links your username to your wallet address, providing
              cryptographic proof of the relationship. All attestations are permanently recorded on Base Mainnet.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
