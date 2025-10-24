# Network Guard - Quick Start

## 🚀 One-Minute Setup

### Step 1: Import Hook & Component

```tsx
import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { InlineNetworkGuard } from '@/components/NetworkGuard';
```

### Step 2: Use in Your Page

```tsx
export default function MyPage() {
  const guard = useRequireBaseNetwork({ autoOpen: true });

  if (!guard.ok) {
    return <InlineNetworkGuard guard={guard} />;
  }

  return <div>Your protected content</div>;
}
```

That's it! 🎉

---

## 📋 Quick Examples

### Example 1: Basic Protection

```tsx
'use client';

import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { InlineNetworkGuard } from '@/components/NetworkGuard';

export default function ProtectedPage() {
  const guard = useRequireBaseNetwork();

  if (!guard.ok) {
    return <InlineNetworkGuard />;
  }

  return <button onClick={handleMint}>Mint NFT</button>;
}
```

### Example 2: Global Banner

```tsx
// app/layout.tsx
import { NetworkGuard } from '@/components/NetworkGuard';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <AppProviders>
          <NetworkGuard position="top" />
          {children}
        </AppProviders>
      </body>
    </html>
  );
}
```

### Example 3: Auto-Open Modal

```tsx
const guard = useRequireBaseNetwork({ autoOpen: true });
// Modal automatically opens on wrong network
```

### Example 4: Manual Switch

```tsx
const guard = useRequireBaseNetwork();

<button onClick={() => guard.switchNetwork(8453)}>
  Switch to Base
</button>
```

### Example 5: Custom UI

```tsx
const guard = useRequireBaseNetwork();

return (
  <>
    {!guard.ok && (
      <div className="alert alert-warning">
        Wrong network! Please switch to {guard.requiredChains[0].name}
        <button onClick={() => guard.openChainModal()}>
          Switch
        </button>
      </div>
    )}

    {guard.ok && <YourComponent />}
  </>
);
```

---

## 🎯 Common Use Cases

### Protect Contract Interactions

```tsx
const guard = useRequireBaseNetwork();

const handleMint = async () => {
  if (!guard.ok) {
    guard.openChainModal();
    return;
  }

  // Safe to call contract
  await contract.mint();
};
```

### Protect Entire Page

```tsx
export default function NFTPage() {
  const guard = useRequireBaseNetwork({ autoOpen: true });

  if (!guard.isConnected) {
    return <ConnectWalletPrompt />;
  }

  if (!guard.ok) {
    return <InlineNetworkGuard guard={guard} />;
  }

  return <NFTGallery />;
}
```

### Conditional Button

```tsx
const guard = useRequireBaseNetwork();

<button
  onClick={handleAction}
  disabled={!guard.ok}
  className={!guard.ok ? 'opacity-50' : ''}
>
  {guard.ok ? 'Mint' : 'Wrong Network'}
</button>
```

---

## 🔍 Hook Return Values

```typescript
const guard = useRequireBaseNetwork();

guard.ok                 // true if on Base/Base Sepolia
guard.isConnected        // true if wallet connected
guard.currentChainId     // e.g., 8453
guard.currentChainName   // e.g., "Base"
guard.canSwitch          // true if provider supports switching
guard.switchNetwork(id)  // Switch to specific chain
guard.openChainModal()   // Open RainbowKit modal
guard.isSwitching        // true during switch
```

---

## 🎨 UI Components

### Sticky Banner

```tsx
<NetworkGuard position="top" />
<NetworkGuard position="bottom" />
```

### Inline Warning

```tsx
<InlineNetworkGuard />
```

### With Props

```tsx
<NetworkGuard
  guard={guard}
  autoOpen={true}
  position="top"
/>
```

---

## ⚙️ Options

```tsx
const guard = useRequireBaseNetwork({
  autoOpen: true,  // Auto-open chain modal
  debug: true,     // Console logging
});
```

---

## 🧪 Quick Test

1. **Start dev server**: `pnpm run dev`
2. **Visit**: `http://localhost:3000/mini/contract-test`
3. **Connect wallet** on Ethereum mainnet
4. **See**: Warning banner appears
5. **Click**: "Switch to Base"
6. **See**: Warning disappears

---

## 📖 Full Documentation

- `NETWORK_GUARD_SETUP.md` - Complete guide
- `NETWORK_GUARD_TESTING.md` - Test cases
- `/mini/contract-test` - Live example

---

## 🐛 Troubleshooting

### Warning shows on Base

```tsx
const guard = useRequireBaseNetwork({ debug: true });
console.log(guard.currentChainId); // Should be 8453
```

### Button doesn't work

```tsx
console.log(guard.canSwitch); // Should be true
```

### Auto-open not working

```tsx
// Ensure autoOpen is true
const guard = useRequireBaseNetwork({ autoOpen: true });
```

---

## ✅ Checklist

- [x] Hook created: `lib/hooks/useRequireBaseNetwork.ts`
- [x] Component created: `components/NetworkGuard.tsx`
- [x] Example page: `app/mini/contract-test/page.tsx`
- [x] Documentation: `NETWORK_GUARD_SETUP.md`
- [x] Test guide: `NETWORK_GUARD_TESTING.md`
- [ ] Add to your page
- [ ] Test with Ethereum mainnet
- [ ] Deploy

---

**Next Step**: Import and use in your page!

```tsx
import { useRequireBaseNetwork } from '@/lib/hooks/useRequireBaseNetwork';
import { InlineNetworkGuard } from '@/components/NetworkGuard';

const guard = useRequireBaseNetwork({ autoOpen: true });
```

🛡️ Done!
