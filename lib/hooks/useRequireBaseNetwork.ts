'use client';

import { useAccount, useChainId, useSwitchChain } from 'wagmi';
import { base, baseSepolia } from 'wagmi/chains';
import { useEffect, useCallback } from 'react';
import { useChainModal } from '@rainbow-me/rainbowkit';

/**
 * Chain information for display purposes
 */
export interface ChainInfo {
  id: number;
  name: string;
  network: string;
}

/**
 * Result returned by useRequireBaseNetwork hook
 */
export interface NetworkGuardResult {
  /** Whether the current network is allowed (Base or Base Sepolia) */
  ok: boolean;
  /** Whether wallet is connected */
  isConnected: boolean;
  /** Current chain ID (undefined if not connected) */
  currentChainId?: number;
  /** Current chain name (undefined if not connected or unknown chain) */
  currentChainName?: string;
  /** List of required chains for display */
  requiredChains: ChainInfo[];
  /** Whether network switching is possible */
  canSwitch: boolean;
  /** Function to switch network programmatically */
  switchNetwork: (chainId: number) => void;
  /** Function to open RainbowKit chain modal */
  openChainModal: () => void;
  /** Whether switch is in progress */
  isSwitching: boolean;
}

/**
 * Options for useRequireBaseNetwork hook
 */
export interface UseRequireBaseNetworkOptions {
  /**
   * If true, automatically opens RainbowKit chain modal when on wrong network
   * Default: false
   */
  autoOpen?: boolean;
  /**
   * If true, logs network status to console (useful for debugging)
   * Default: false
   */
  debug?: boolean;
}

/**
 * Hook to enforce Base or Base Sepolia network requirement
 *
 * @example
 * ```tsx
 * function MyPage() {
 *   const guard = useRequireBaseNetwork({ autoOpen: true });
 *
 *   if (!guard.ok) {
 *     return <NetworkGuard guard={guard} />;
 *   }
 *
 *   return <div>Protected content</div>;
 * }
 * ```
 */
export function useRequireBaseNetwork(
  options: UseRequireBaseNetworkOptions = {}
): NetworkGuardResult {
  const { autoOpen = false, debug = false } = options;

  // Wagmi hooks
  const { isConnected } = useAccount();
  const chainId = useChainId();
  const { switchChain, isPending: isSwitching } = useSwitchChain();
  const { openChainModal } = useChainModal();

  // Define allowed chains
  const allowedChainIds = [base.id, baseSepolia.id];
  const requiredChains: ChainInfo[] = [
    { id: base.id, name: base.name, network: 'mainnet' },
    { id: baseSepolia.id, name: baseSepolia.name, network: 'testnet' },
  ];

  // Check if current chain is allowed
  const isAllowedChain = isConnected && allowedChainIds.includes(chainId);

  // Get current chain name
  const getCurrentChainName = useCallback(() => {
    if (!isConnected) return undefined;

    const chainMap: Record<number, string> = {
      [base.id]: base.name,
      [baseSepolia.id]: baseSepolia.name,
      1: 'Ethereum',
      10: 'Optimism',
      137: 'Polygon',
      42161: 'Arbitrum',
    };

    return chainMap[chainId] || `Chain ${chainId}`;
  }, [isConnected, chainId]);

  // Switch network function
  const handleSwitchNetwork = useCallback(
    (targetChainId: number) => {
      if (!switchChain) {
        if (debug) {
          console.warn('[NetworkGuard] switchChain not available');
        }
        return;
      }

      if (debug) {
        console.log('[NetworkGuard] Switching to chain:', targetChainId);
      }

      switchChain({ chainId: targetChainId });
    },
    [switchChain, debug]
  );

  // Open chain modal function
  const handleOpenChainModal = useCallback(() => {
    if (debug) {
      console.log('[NetworkGuard] Opening RainbowKit chain modal');
    }
    openChainModal?.();
  }, [openChainModal, debug]);

  // Auto-open chain modal when on wrong network
  useEffect(() => {
    if (autoOpen && isConnected && !isAllowedChain && openChainModal) {
      if (debug) {
        console.log('[NetworkGuard] Auto-opening chain modal (wrong network detected)');
      }
      openChainModal();
    }
  }, [autoOpen, isConnected, isAllowedChain, openChainModal, debug]);

  // Debug logging
  useEffect(() => {
    if (debug) {
      console.log('[NetworkGuard] Status:', {
        isConnected,
        chainId,
        chainName: getCurrentChainName(),
        isAllowed: isAllowedChain,
        canSwitch: !!switchChain,
      });
    }
  }, [debug, isConnected, chainId, isAllowedChain, switchChain, getCurrentChainName]);

  return {
    ok: isAllowedChain,
    isConnected,
    currentChainId: isConnected ? chainId : undefined,
    currentChainName: getCurrentChainName(),
    requiredChains,
    canSwitch: !!switchChain,
    switchNetwork: handleSwitchNetwork,
    openChainModal: handleOpenChainModal,
    isSwitching,
  };
}
