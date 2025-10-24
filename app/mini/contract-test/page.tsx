'use client';

import { useEffect, useState } from 'react';
import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { InlineNetworkGuard } from '@/components/NetworkGuard';
import { useAccount, useBalance } from 'wagmi';
import { Navigation } from '@/components/shared/Navigation';
import LinkAndAttest from '@/components/LinkAndAttest'; // ✅ Yeni birleşik bileşen

export default function ContractTestPage() {
  const guard = useRequireBaseNetwork({ autoOpen: true, debug: true });
  const { address, isConnected } = useAccount();
  const { data: balance } = useBalance({ address });
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <>
      <Navigation />

      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          {/* 📄 Page Header */}
          <div className="mb-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h1 className="text-3xl font-bold text-black mb-4">
              Welcome to the Contract Test Page!
            </h1>
            <p className="text-base text-black mb-4">
              Follow these steps to link your Farcaster username with your wallet and create an attestation:
            </p>
            <ol className="list-decimal list-inside space-y-2 text-black">
              <li className="text-sm">
                <span className="font-semibold">Connect Your Wallet:</span> Click the "Connect Wallet" button in the navigation bar above.
              </li>
              <li className="text-sm">
                <span className="font-semibold">Switch to Correct Network:</span> Make sure you're on Base or Base Sepolia network. If not, you'll see a prompt to switch.
              </li>
              <li className="text-sm">
                <span className="font-semibold">Link & Attest:</span> Once connected to the correct network, scroll down to enter your Farcaster username and complete the linking process.
              </li>
            </ol>
          </div>

          {/* 🔗 Connection Status */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
            <h2 className="text-lg font-semibold text-black mb-4">
              Connection Status
            </h2>

            <div className="space-y-3">
              <div className="flex items-center justify-between py-2 border-b border-gray-100">
                <span className="text-sm text-black">Wallet Connected</span>
                <span
                  className={`text-sm font-medium ${
                    mounted && isConnected ? 'text-green-600' : 'text-gray-400'
                  }`}
                >
                  {mounted ? (isConnected ? '✓ Connected' : '✗ Not Connected') : '...'}
                </span>
              </div>

              <div className="flex items-center justify-between py-2 border-b border-gray-100">
                <span className="text-sm text-black">Network Status</span>
                <span
                  className={`text-sm font-medium ${
                    mounted && guard.ok ? 'text-green-600' : 'text-amber-600'
                  }`}
                >
                  {mounted ? (guard.ok ? '✓ Correct Network' : '⚠ Wrong Network') : '...'}
                </span>
              </div>

              {mounted && guard.currentChainName && (
                <div className="flex items-center justify-between py-2 border-b border-gray-100">
                  <span className="text-sm text-black">Current Network</span>
                  <span className="text-sm font-medium text-black">
                    {guard.currentChainName} (ID: {guard.currentChainId})
                  </span>
                </div>
              )}

              <div className="flex items-center justify-between py-2">
                <span className="text-sm text-black">Required Networks</span>
                <span className="text-sm font-medium text-black">
                  {guard.requiredChains.map((c) => c.name).join(' or ')}
                </span>
              </div>
            </div>
          </div>

          {/* ⚠️ Network Guard */}
          {mounted && isConnected && !guard.ok && (
            <div className="mb-6">
              <InlineNetworkGuard guard={guard} />
            </div>
          )}

          {/* 🦊 Wallet not connected */}
          {mounted && !isConnected && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
              <div className="flex items-start gap-3">
                <svg
                  className="w-5 h-5 text-blue-600 mt-0.5"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fillRule="evenodd"
                    d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5h.253a.25.25 0 01.244.304l-.459 2.066A1.75 1.75 0 0010.747 15H11a.75.75 0 000-1.5h-.253a.25.25 0 01-.244-.304l.459-2.066A1.75 1.75 0 009.253 9H9z"
                    clipRule="evenodd"
                  />
                </svg>
                <div>
                  <h3 className="text-sm font-semibold text-black">
                    Connect Your Wallet
                  </h3>
                  <p className="mt-1 text-sm text-black">
                    Please connect your wallet using the "Connect Wallet" button in the navigation to continue.
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* ✅ Ready Section */}
          {mounted && isConnected && guard.ok && (
            <div className="space-y-6">
              <div className="bg-green-50 border border-green-200 rounded-lg p-6">
                <div className="flex items-start gap-3">
                  <svg
                    className="w-5 h-5 text-green-600 mt-0.5"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                      clipRule="evenodd"
                    />
                  </svg>
                  <div>
                    <h3 className="text-sm font-semibold text-black">
                      Ready to Interact
                    </h3>
                    <p className="mt-1 text-sm text-black">
                      You're connected to the correct network. You can now interact with smart contracts.
                    </p>
                  </div>
                </div>
              </div>

              {/* 🧩 Tek tıklamayla işlem */}
              <LinkAndAttest />
            </div>
          )}

          {/* 🧠 Debug Info */}
          {mounted && process.env.NODE_ENV === 'development' && (
            <div className="mt-8 bg-gray-800 rounded-lg p-4">
              <h3 className="text-xs font-semibold text-gray-300 mb-2">
                Debug Info
              </h3>
              <pre className="text-xs text-gray-400 overflow-auto">
                {JSON.stringify(
                  {
                    isConnected: guard.isConnected,
                    ok: guard.ok,
                    currentChainId: guard.currentChainId,
                    currentChainName: guard.currentChainName,
                    canSwitch: guard.canSwitch,
                    isSwitching: guard.isSwitching,
                  },
                  null,
                  2
                )}
              </pre>
            </div>
          )}
        </div>
      </div>
    </>
  );
}