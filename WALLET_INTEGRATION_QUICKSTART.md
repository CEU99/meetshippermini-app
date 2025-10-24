# 🚀 Wallet Integration Quick Start

## ✅ What's Done

- [x] Created `lib/wagmi.ts` (Wagmi config)
- [x] Created `app/providers.tsx` (Provider wrapper)
- [x] Updated `app/layout.tsx` (Added AppProviders)
- [x] RainbowKit styles imported globally

## ⚠️ What You Need to Do

### 1. Install Missing Dependency (30 seconds)
```bash
pnpm add @tanstack/react-query
```

### 2. Add Environment Variables (1 minute)
```bash
# Add to .env.local
NEXT_PUBLIC_BASE_RPC_URL=https://mainnet.base.org
NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
```

### 3. Start Development Server
```bash
pnpm run dev
```

## 🧪 Quick Test

Add a connect button anywhere in your app:

```typescript
import { ConnectButton } from '@rainbow-me/rainbowkit'

export function MyComponent() {
  return <ConnectButton />
}
```

## 📋 Verification

Run in browser console (on your app page):
```javascript
// Should see wagmi provider
console.log(typeof window.ethereum)

// Should see RainbowKit loaded
console.log(document.querySelector('link[href*="rainbowkit"]'))
```

## 🎯 Provider Structure

```
AppProviders (NEW)
  └── WagmiProvider
      └── QueryClientProvider
          └── RainbowKitProvider
              └── FarcasterAuthProvider (EXISTING)
                  └── Your App
```

## 🔧 Troubleshooting

**Error**: Module '@tanstack/react-query' not found
**Fix**: Run `pnpm add @tanstack/react-query`

**Error**: RPC connection failed
**Fix**: Check `.env.local` has the RPC URLs

**Error**: Styles not loading
**Fix**: Restart dev server (`pnpm run dev`)

## ✅ Success Indicators

- [ ] Dev server starts without errors
- [ ] No TypeScript errors
- [ ] App loads in browser
- [ ] No console errors
- [ ] (Optional) Connect button appears if added

## 📚 Next Steps

1. Install dependency: `pnpm add @tanstack/react-query`
2. Add env variables
3. Test wallet connection with `<ConnectButton />`
4. Build your wallet features

---

**Total Time**: ~5 minutes
**Next Command**: `pnpm add @tanstack/react-query`
