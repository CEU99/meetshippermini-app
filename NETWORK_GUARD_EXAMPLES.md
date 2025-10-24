# Network Guard - Code Examples

## Complete Examples for Common Scenarios

### Example 1: Simple Page Protection

**Use Case**: Protect an entire page from wrong network access.

```tsx
// app/mini/mint-nft/page.tsx
'use client';

import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { InlineNetworkGuard } from '@/components/NetworkGuard';
import { Navigation } from '@/components/shared/Navigation';

export default function MintNFTPage() {
  const guard = useRequireBaseNetwork({ autoOpen: true });

  return (
    <>
      <Navigation />

      <div className="container mx-auto p-8">
        <h1 className="text-3xl font-bold mb-6">Mint NFT</h1>

        {/* Show warning if on wrong network */}
        {!guard.ok && <InlineNetworkGuard guard={guard} />}

        {/* Protected content - only shown on correct network */}
        {guard.ok && (
          <div>
            <p>You're ready to mint!</p>
            <button onClick={handleMint}>Mint NFT</button>
          </div>
        )}
      </div>
    </>
  );
}
```

---

### Example 2: Button-Level Protection

**Use Case**: Protect a specific action button.

```tsx
'use client';

import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { useContractWrite } from 'wagmi';

export default function MintButton() {
  const guard = useRequireBaseNetwork();
  const { write: mint, isLoading } = useContractWrite({
    address: '0x...',
    abi: contractABI,
    functionName: 'mint',
  });

  const handleClick = () => {
    if (!guard.ok) {
      // Show modal instead of minting
      guard.openChainModal();
      return;
    }

    // Safe to mint
    mint();
  };

  return (
    <button
      onClick={handleClick}
      disabled={isLoading}
      className={`
        px-6 py-3 rounded-lg font-semibold
        ${guard.ok
          ? 'bg-blue-600 hover:bg-blue-700 text-white'
          : 'bg-amber-100 text-amber-900 border-2 border-amber-400'
        }
      `}
    >
      {!guard.ok && '⚠️ '}
      {isLoading ? 'Minting...' : guard.ok ? 'Mint NFT' : 'Wrong Network'}
    </button>
  );
}
```

---

### Example 3: Global App Protection

**Use Case**: Show persistent warning across all pages.

```tsx
// app/layout.tsx
import type { Metadata } from 'next';
import AppProviders from '@/app/providers';
import { NetworkGuard } from '@/components/NetworkGuard';
import { FarcasterAuthProvider } from '@/components/providers/FarcasterAuthProvider';
import './globals.css';

export const metadata: Metadata = {
  title: 'Meet Shipper',
  description: 'Connect on Base',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <AppProviders>
          <FarcasterAuthProvider>
            {/* Global network guard - shows on all pages */}
            <NetworkGuard position="top" />

            {children}
          </FarcasterAuthProvider>
        </AppProviders>
      </body>
    </html>
  );
}
```

---

### Example 4: Multiple Protected Actions

**Use Case**: Page with several contract interactions.

```tsx
'use client';

import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { InlineNetworkGuard } from '@/components/NetworkGuard';

export default function DeFiPage() {
  const guard = useRequireBaseNetwork({ autoOpen: true });

  // Helper to guard contract calls
  const withNetworkCheck = (action: () => void) => {
    return () => {
      if (!guard.ok) {
        guard.openChainModal();
        return;
      }
      action();
    };
  };

  return (
    <div className="container mx-auto p-8">
      <h1>DeFi Dashboard</h1>

      {!guard.ok && (
        <div className="mb-6">
          <InlineNetworkGuard guard={guard} />
        </div>
      )}

      <div className="grid grid-cols-3 gap-4">
        {/* All buttons automatically guarded */}
        <button onClick={withNetworkCheck(handleStake)}>
          Stake Tokens
        </button>

        <button onClick={withNetworkCheck(handleUnstake)}>
          Unstake Tokens
        </button>

        <button onClick={withNetworkCheck(handleClaim)}>
          Claim Rewards
        </button>
      </div>
    </div>
  );
}
```

---

### Example 5: Custom Warning Design

**Use Case**: Match your app's design system.

```tsx
'use client';

import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { base } from 'wagmi/chains';

export default function CustomWarningPage() {
  const guard = useRequireBaseNetwork();

  if (!guard.ok) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-amber-50 to-orange-50">
        <div className="max-w-md w-full mx-4">
          {/* Custom warning card */}
          <div className="bg-white rounded-2xl shadow-2xl p-8 border-4 border-amber-400">
            <div className="text-center mb-6">
              <div className="w-20 h-20 bg-amber-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-12 h-12 text-amber-600" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
                </svg>
              </div>

              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                Network Mismatch
              </h1>

              <p className="text-gray-600 mb-1">
                You're currently on:
              </p>
              <p className="text-lg font-semibold text-amber-600 mb-4">
                {guard.currentChainName || 'Unknown Network'}
              </p>

              <p className="text-gray-600 mb-1">
                Please switch to:
              </p>
              <p className="text-lg font-semibold text-blue-600">
                {guard.requiredChains.map(c => c.name).join(' or ')}
              </p>
            </div>

            <div className="space-y-3">
              {guard.canSwitch && (
                <button
                  onClick={() => guard.switchNetwork(base.id)}
                  disabled={guard.isSwitching}
                  className="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors disabled:bg-blue-400"
                >
                  {guard.isSwitching ? (
                    <span className="flex items-center justify-center">
                      <svg className="animate-spin h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                      </svg>
                      Switching Network...
                    </span>
                  ) : (
                    'Switch to Base Mainnet'
                  )}
                </button>
              )}

              <button
                onClick={() => guard.openChainModal()}
                className="w-full py-3 border-2 border-gray-300 hover:border-gray-400 text-gray-700 font-semibold rounded-lg transition-colors"
              >
                Choose Network Manually
              </button>
            </div>

            {!guard.canSwitch && (
              <p className="mt-4 text-xs text-gray-500 text-center">
                💡 Please change the network in your wallet app
              </p>
            )}
          </div>
        </div>
      </div>
    );
  }

  return <div>Your protected page content</div>;
}
```

---

### Example 6: Form Submission Guard

**Use Case**: Protect form submission that requires contract interaction.

```tsx
'use client';

import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { useState } from 'react';

export default function StakingForm() {
  const guard = useRequireBaseNetwork();
  const [amount, setAmount] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Check network before submitting
    if (!guard.ok) {
      alert('Please switch to Base network first');
      guard.openChainModal();
      return;
    }

    // Proceed with staking
    try {
      await stakeTokens(amount);
      alert('Staked successfully!');
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="max-w-md mx-auto p-6">
      {!guard.ok && (
        <div className="mb-4 p-3 bg-amber-50 border border-amber-200 rounded">
          <p className="text-sm text-amber-800">
            ⚠️ You must be on Base network to stake tokens
          </p>
          <button
            type="button"
            onClick={() => guard.openChainModal()}
            className="mt-2 text-sm text-amber-700 underline"
          >
            Switch Network
          </button>
        </div>
      )}

      <input
        type="number"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        placeholder="Amount to stake"
        className="w-full px-4 py-2 border rounded mb-4"
      />

      <button
        type="submit"
        disabled={!guard.ok}
        className={`
          w-full py-3 rounded font-semibold
          ${guard.ok
            ? 'bg-blue-600 hover:bg-blue-700 text-white'
            : 'bg-gray-300 text-gray-500 cursor-not-allowed'
          }
        `}
      >
        {guard.ok ? 'Stake Tokens' : 'Wrong Network - Cannot Stake'}
      </button>
    </form>
  );
}
```

---

### Example 7: Conditional Feature Rendering

**Use Case**: Hide features that require specific network.

```tsx
'use client';

import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';

export default function Dashboard() {
  const guard = useRequireBaseNetwork();

  return (
    <div className="container mx-auto p-8">
      <h1>Dashboard</h1>

      {/* Always show */}
      <section className="mb-8">
        <h2>Your Profile</h2>
        <p>Username: @user</p>
      </section>

      {/* Only show on Base */}
      {guard.ok ? (
        <section className="mb-8">
          <h2>NFT Collection</h2>
          <div className="grid grid-cols-3 gap-4">
            {/* NFT cards */}
          </div>
        </section>
      ) : (
        <section className="mb-8">
          <div className="bg-gray-100 border border-gray-300 rounded-lg p-6 text-center">
            <p className="text-gray-600 mb-4">
              NFT features are only available on Base network
            </p>
            <button
              onClick={() => guard.openChainModal()}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              Switch to Base
            </button>
          </div>
        </section>
      )}

      {/* Always show */}
      <section>
        <h2>Settings</h2>
        <p>Manage your account</p>
      </section>
    </div>
  );
}
```

---

### Example 8: Hook with Custom Logic

**Use Case**: Add custom behavior beyond basic network check.

```tsx
'use client';

import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { useEffect, useState } from 'react';

export default function CustomHookPage() {
  const guard = useRequireBaseNetwork({ debug: true });
  const [hasSeenWarning, setHasSeenWarning] = useState(false);

  // Track network changes
  useEffect(() => {
    if (!guard.ok && !hasSeenWarning) {
      console.log('User landed on wrong network');
      setHasSeenWarning(true);

      // Optional: Track analytics
      // analytics.track('wrong_network_detected', {
      //   chainId: guard.currentChainId,
      //   chainName: guard.currentChainName,
      // });
    }

    if (guard.ok && hasSeenWarning) {
      console.log('User switched to correct network');

      // Optional: Track successful switch
      // analytics.track('network_switched', {
      //   chainId: guard.currentChainId,
      // });
    }
  }, [guard.ok, guard.currentChainId, hasSeenWarning]);

  return (
    <div>
      {/* Your content */}
    </div>
  );
}
```

---

### Example 9: Multi-Step Process

**Use Case**: Guard each step of a multi-step flow.

```tsx
'use client';

import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { InlineNetworkGuard } from '@/components/NetworkGuard';
import { useState } from 'react';

export default function MultiStepMint() {
  const guard = useRequireBaseNetwork({ autoOpen: true });
  const [step, setStep] = useState(1);

  const canProceed = guard.isConnected && guard.ok;

  return (
    <div className="container mx-auto p-8">
      <h1>Mint NFT - Step {step} of 3</h1>

      {!guard.ok && (
        <div className="mb-6">
          <InlineNetworkGuard guard={guard} />
        </div>
      )}

      {step === 1 && (
        <div>
          <h2>Choose Your NFT</h2>
          <button
            onClick={() => setStep(2)}
            disabled={!canProceed}
            className={!canProceed ? 'opacity-50' : ''}
          >
            Next
          </button>
        </div>
      )}

      {step === 2 && (
        <div>
          <h2>Customize Attributes</h2>
          <button onClick={() => setStep(1)}>Back</button>
          <button
            onClick={() => setStep(3)}
            disabled={!canProceed}
          >
            Next
          </button>
        </div>
      )}

      {step === 3 && (
        <div>
          <h2>Confirm & Mint</h2>
          <button onClick={() => setStep(2)}>Back</button>
          <button
            onClick={handleMint}
            disabled={!canProceed}
          >
            Mint NFT
          </button>
        </div>
      )}
    </div>
  );
}
```

---

### Example 10: Debug Panel (Development)

**Use Case**: Show network info during development.

```tsx
'use client';

import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';

export default function DebugPage() {
  const guard = useRequireBaseNetwork({ debug: true });

  return (
    <div className="container mx-auto p-8">
      <h1>Your App Content</h1>

      {/* Debug panel - only in development */}
      {process.env.NODE_ENV === 'development' && (
        <div className="fixed bottom-4 right-4 bg-gray-900 text-white rounded-lg shadow-xl p-4 max-w-sm">
          <h3 className="font-bold text-sm mb-2">🔍 Network Debug</h3>

          <div className="space-y-1 text-xs font-mono">
            <div className="flex justify-between">
              <span className="text-gray-400">Status:</span>
              <span className={guard.ok ? 'text-green-400' : 'text-red-400'}>
                {guard.ok ? '✓ OK' : '✗ Wrong'}
              </span>
            </div>

            <div className="flex justify-between">
              <span className="text-gray-400">Connected:</span>
              <span>{guard.isConnected ? 'Yes' : 'No'}</span>
            </div>

            <div className="flex justify-between">
              <span className="text-gray-400">Chain ID:</span>
              <span>{guard.currentChainId || '-'}</span>
            </div>

            <div className="flex justify-between">
              <span className="text-gray-400">Chain:</span>
              <span>{guard.currentChainName || '-'}</span>
            </div>

            <div className="flex justify-between">
              <span className="text-gray-400">Can Switch:</span>
              <span>{guard.canSwitch ? 'Yes' : 'No'}</span>
            </div>

            <div className="flex justify-between">
              <span className="text-gray-400">Switching:</span>
              <span>{guard.isSwitching ? 'Yes' : 'No'}</span>
            </div>
          </div>

          <div className="mt-3 pt-3 border-t border-gray-700">
            <p className="text-xs text-gray-400 mb-2">Required:</p>
            <div className="space-y-1">
              {guard.requiredChains.map(chain => (
                <div key={chain.id} className="text-xs">
                  {chain.name} ({chain.id})
                </div>
              ))}
            </div>
          </div>

          <button
            onClick={() => guard.openChainModal()}
            className="mt-3 w-full py-1.5 bg-blue-600 hover:bg-blue-700 rounded text-xs"
          >
            Open Chain Modal
          </button>
        </div>
      )}
    </div>
  );
}
```

---

## Tips & Best Practices

### ✅ Do's

1. **Use `autoOpen: true` for critical pages**
   ```tsx
   const guard = useRequireBaseNetwork({ autoOpen: true });
   ```

2. **Check `ok` flag before contract calls**
   ```tsx
   if (!guard.ok) {
     guard.openChainModal();
     return;
   }
   await contract.mint();
   ```

3. **Show loading state during switch**
   ```tsx
   <button disabled={guard.isSwitching}>
     {guard.isSwitching ? 'Switching...' : 'Switch Network'}
   </button>
   ```

4. **Use debug mode during development**
   ```tsx
   const guard = useRequireBaseNetwork({ debug: true });
   ```

5. **Handle disconnected state**
   ```tsx
   if (!guard.isConnected) {
     return <div>Please connect wallet</div>;
   }
   ```

### ❌ Don'ts

1. **Don't skip network check on contract calls**
   ```tsx
   // BAD
   await contract.mint();

   // GOOD
   if (!guard.ok) return;
   await contract.mint();
   ```

2. **Don't assume `canSwitch` is always true**
   ```tsx
   // BAD
   guard.switchNetwork(8453);

   // GOOD
   if (guard.canSwitch) {
     guard.switchNetwork(8453);
   } else {
     guard.openChainModal();
   }
   ```

3. **Don't ignore mobile users**
   ```tsx
   // GOOD - Show alternative instructions
   {!guard.canSwitch && (
     <p>Please change network in your wallet app</p>
   )}
   ```

4. **Don't forget TypeScript types**
   ```tsx
   // Use the provided interfaces
   import type { NetworkGuardResult } from '@/lib/hooks/useRequireBaseNetwork';
   ```

---

**More Examples**: See `/mini/contract-test` for a complete working example.
