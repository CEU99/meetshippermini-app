'use client';

import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';

export interface AttestationData {
  id: string;
  username: string;
  walletAddress: string;
  txHash: string;
  attestationUID: string;
  createdAt: string;
  updatedAt: string;
}

export interface AttestationStatus {
  isVerified: boolean;
  isLoading: boolean;
  error: string | null;
  attestation: AttestationData | null;
  refetch: () => Promise<void>;
}

/**
 * Custom hook to check if the connected wallet has an attestation
 *
 * @returns {AttestationStatus} Object containing verification status and attestation data
 *
 * @example
 * ```tsx
 * const { isVerified, isLoading, attestation } = useAttestationStatus();
 *
 * if (isLoading) return <Spinner />;
 * if (isVerified) return <VerifiedBadge />;
 * return <NotVerifiedBadge />;
 * ```
 */
export function useAttestationStatus(): AttestationStatus {
  const { address, isConnected } = useAccount();
  const [isVerified, setIsVerified] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [attestation, setAttestation] = useState<AttestationData | null>(null);

  const checkAttestation = async () => {
    // Reset state if wallet not connected
    if (!isConnected || !address) {
      console.log('[useAttestationStatus] Wallet not connected, resetting state');
      setIsVerified(false);
      setAttestation(null);
      setError(null);
      setIsLoading(false);
      return;
    }

    console.log('[useAttestationStatus] Checking attestation for wallet:', address);
    setIsLoading(true);
    setError(null);

    try {
      // Query API to check if this wallet has an attestation
      // Use walletAddress param and lowercase the address to match database format
      const walletLower = address.toLowerCase();
      const apiUrl = `/api/attestations?walletAddress=${encodeURIComponent(walletLower)}&limit=1`;
      console.log('[useAttestationStatus] Fetching from:', apiUrl);
      console.log('[useAttestationStatus] Original address:', address);
      console.log('[useAttestationStatus] Lowercase address:', walletLower);

      const response = await fetch(apiUrl);

      if (!response.ok) {
        console.error('[useAttestationStatus] API request failed:', response.status, response.statusText);
        throw new Error('Failed to check attestation status');
      }

      const data = await response.json();
      console.log('[useAttestationStatus] Attestation check result:', data);

      // Check if attestation exists
      const hasAttestation = data?.success && data?.data && data.data.length > 0;
      console.log('[useAttestationStatus] Has attestation:', hasAttestation);

      if (hasAttestation) {
        // Attestation found - wallet is verified
        console.log('[useAttestationStatus] ✅ Wallet is verified:', data.data[0]);
        setIsVerified(true);
        setAttestation(data.data[0]);
      } else {
        // No attestation found
        console.log('[useAttestationStatus] ⚪ Wallet is not verified');
        setIsVerified(false);
        setAttestation(null);
      }
    } catch (err: any) {
      console.error('[useAttestationStatus] Error checking attestation status:', err);
      setError(err.message || 'Failed to check verification status');
      setIsVerified(false);
      setAttestation(null);
    } finally {
      setIsLoading(false);
      console.log('[useAttestationStatus] Check complete. isVerified:', isVerified);
    }
  };

  // Check attestation when wallet address changes
  useEffect(() => {
    console.log('[useAttestationStatus] useEffect triggered - address:', address, 'isConnected:', isConnected);
    checkAttestation();
  }, [address, isConnected]);

  // Listen for attestation completion events (from LinkAndAttest component)
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

  // Log state changes for debugging
  useEffect(() => {
    console.log('[useAttestationStatus] State updated - isVerified:', isVerified, 'isLoading:', isLoading);
  }, [isVerified, isLoading]);

  return {
    isVerified,
    isLoading,
    error,
    attestation,
    refetch: checkAttestation,
  };
}
