'use client';

import { useRequireBaseNetwork, NetworkGuardResult } from '@/lib/hooks/useRequireBaseNetwork';
import { base } from 'wagmi/chains';

/**
 * Props for NetworkGuard component
 */
export interface NetworkGuardProps {
  /**
   * Optional: Pass guard result from hook (for external control)
   * If not provided, component will use hook internally
   */
  guard?: NetworkGuardResult;
  /**
   * Auto-open chain modal when on wrong network
   * Default: false
   */
  autoOpen?: boolean;
  /**
   * Show close button (allows user to dismiss banner temporarily)
   * Default: false
   */
  dismissible?: boolean;
  /**
   * Position of the banner
   * Default: 'top'
   */
  position?: 'top' | 'bottom';
}

/**
 * NetworkGuard component - displays warning banner when connected to wrong network
 *
 * @example Global usage (in app/layout.tsx):
 * ```tsx
 * <NetworkGuard autoOpen={false} position="top" />
 * ```
 *
 * @example Scoped usage (in specific page):
 * ```tsx
 * function MyPage() {
 *   const guard = useRequireBaseNetwork({ autoOpen: true });
 *
 *   if (!guard.isConnected) {
 *     return <div>Please connect wallet</div>;
 *   }
 *
 *   if (!guard.ok) {
 *     return <NetworkGuard guard={guard} />;
 *   }
 *
 *   return <div>Protected content</div>;
 * }
 * ```
 */
export function NetworkGuard({
  guard: externalGuard,
  autoOpen = false,
  dismissible = false,
  position = 'top',
}: NetworkGuardProps) {
  const internalGuard = useRequireBaseNetwork({ autoOpen });
  const guard = externalGuard || internalGuard;

  // Don't show banner if wallet not connected or network is correct
  if (!guard.isConnected || guard.ok) {
    return null;
  }

  const positionClasses =
    position === 'top'
      ? 'top-0 border-b'
      : 'bottom-0 border-t';

  return (
    <div
      className={`${positionClasses} left-0 right-0 z-50 bg-amber-50 border-amber-200`}
      role="alert"
      aria-live="polite"
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3">
        <div className="flex items-start sm:items-center justify-between gap-4 flex-col sm:flex-row">
          {/* Warning Icon + Message */}
          <div className="flex items-start gap-3 flex-1">
            <div className="flex-shrink-0">
              <svg
                className="w-5 h-5 text-amber-600 mt-0.5"
                fill="currentColor"
                viewBox="0 0 20 20"
                aria-hidden="true"
              >
                <path
                  fillRule="evenodd"
                  d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z"
                  clipRule="evenodd"
                />
              </svg>
            </div>

            <div className="flex-1 min-w-0">
              <h3 className="text-sm font-semibold text-amber-900">
                Wrong Network Detected
              </h3>
              <div className="mt-1 text-sm text-amber-700">
                {guard.currentChainName ? (
                  <p>
                    Your wallet is connected to{' '}
                    <span className="font-medium">{guard.currentChainName}</span>.
                    Please switch to{' '}
                    <span className="font-medium">
                      {guard.requiredChains.map((c) => c.name).join(' or ')}
                    </span>{' '}
                    to continue.
                  </p>
                ) : (
                  <p>
                    Please switch to{' '}
                    <span className="font-medium">
                      {guard.requiredChains.map((c) => c.name).join(' or ')}
                    </span>{' '}
                    to continue.
                  </p>
                )}

                {/* Mobile-specific instructions */}
                {!guard.canSwitch && (
                  <p className="mt-2 text-xs">
                    💡 If you're on mobile, please change the network in your wallet app.
                  </p>
                )}
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center gap-2 flex-shrink-0">
            {guard.canSwitch ? (
              <>
                <button
                  onClick={() => guard.switchNetwork(base.id)}
                  disabled={guard.isSwitching}
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-amber-600 hover:bg-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-amber-500 disabled:bg-amber-400 disabled:cursor-not-allowed transition-colors"
                >
                  {guard.isSwitching ? (
                    <>
                      <svg
                        className="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <circle
                          className="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          strokeWidth="4"
                        />
                        <path
                          className="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        />
                      </svg>
                      Switching...
                    </>
                  ) : (
                    <>
                      <svg
                        className="-ml-1 mr-2 h-4 w-4"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                        />
                      </svg>
                      Switch to Base
                    </>
                  )}
                </button>

                <button
                  onClick={() => guard.openChainModal()}
                  className="inline-flex items-center px-4 py-2 border border-amber-600 text-sm font-medium rounded-md text-amber-700 bg-white hover:bg-amber-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-amber-500 transition-colors"
                >
                  Choose Network
                </button>
              </>
            ) : (
              <button
                onClick={() => guard.openChainModal()}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-amber-600 hover:bg-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-amber-500 transition-colors"
              >
                Open Wallet
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

/**
 * Inline NetworkGuard variant - for use within page content (non-sticky)
 */
export function InlineNetworkGuard({
  guard: externalGuard,
  autoOpen = false,
}: Omit<NetworkGuardProps, 'position' | 'dismissible'>) {
  const internalGuard = useRequireBaseNetwork({ autoOpen });
  const guard = externalGuard || internalGuard;

  if (!guard.isConnected || guard.ok) {
    return null;
  }

  return (
    <div className="rounded-lg bg-amber-50 border border-amber-200 p-4">
      <div className="flex items-start gap-3">
        <div className="flex-shrink-0">
          <svg
            className="w-5 h-5 text-amber-600"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fillRule="evenodd"
              d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z"
              clipRule="evenodd"
            />
          </svg>
        </div>

        <div className="flex-1">
          <h3 className="text-sm font-semibold text-amber-900 mb-1">
            Wrong Network
          </h3>
          <p className="text-sm text-amber-700 mb-3">
            Please switch to {guard.requiredChains.map((c) => c.name).join(' or ')}.
          </p>

          <div className="flex gap-2">
            {guard.canSwitch && (
              <button
                onClick={() => guard.switchNetwork(base.id)}
                disabled={guard.isSwitching}
                className="inline-flex items-center px-3 py-1.5 text-sm font-medium rounded-md text-white bg-amber-600 hover:bg-amber-700 disabled:bg-amber-400"
              >
                {guard.isSwitching ? 'Switching...' : 'Switch Network'}
              </button>
            )}

            <button
              onClick={() => guard.openChainModal()}
              className="inline-flex items-center px-3 py-1.5 text-sm font-medium rounded-md text-amber-700 border border-amber-600 hover:bg-amber-50"
            >
              Choose Network
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
