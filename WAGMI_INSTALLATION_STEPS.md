# Wagmi Installation Steps

## ✅ Current Status

- [x] `wagmi` (v2.18.2) - Already installed ✅
- [x] `viem` (v2.38.3) - Already installed ✅
- [ ] `@tanstack/react-query` - **Needs to be installed**

## 📦 Installation Command

Run this command to install the missing dependency:

```bash
pnpm add @tanstack/react-query
```

**OR** if you prefer npm/yarn:
```bash
npm install @tanstack/react-query
# or
yarn add @tanstack/react-query
```

## 📋 Complete Setup Checklist

### 1. Install Dependencies ✅ (Partially Done)
```bash
# Already installed:
# - wagmi@2.18.2 ✅
# - viem@2.38.3 ✅

# Need to install:
pnpm add @tanstack/react-query
```

### 2. Create Wagmi Config ✅ (Done)
- [x] File created: `lib/wagmi.ts`
- [x] Exports `wagmiConfig`

### 3. Add Environment Variables
Create or update `.env.local`:

```bash
# Base Mainnet RPC
NEXT_PUBLIC_BASE_RPC_URL=https://mainnet.base.org

# Base Sepolia Testnet RPC
NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
```

### 4. Set Up Providers (Next Step)
Update or create `app/providers.tsx`:

```typescript
'use client'

import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { wagmiConfig } from '@/lib/wagmi'
import { ReactNode } from 'react'

const queryClient = new QueryClient()

export function Providers({ children }: { children: ReactNode }) {
  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </WagmiProvider>
  )
}
```

### 5. Wrap Your App
Update `app/layout.tsx`:

```typescript
import { Providers } from './providers'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  )
}
```

## 🚀 Quick Start

Run these commands in order:

```bash
# 1. Install missing dependency
pnpm add @tanstack/react-query

# 2. Create .env.local if not exists
cat > .env.local << 'EOF'
NEXT_PUBLIC_BASE_RPC_URL=https://mainnet.base.org
NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
EOF

# 3. Start dev server
pnpm run dev
```

## 🧪 Verify Installation

After installation, verify with:

```bash
# Check package.json
cat package.json | grep -E "(wagmi|viem|@tanstack/react-query)"

# Expected output:
# "@tanstack/react-query": "^5.x.x"
# "viem": "^2.38.3"
# "wagmi": "^2.18.2"
```

## 📝 Version Compatibility

| Package | Version | Status |
|---------|---------|--------|
| wagmi | ^2.18.2 | ✅ Installed |
| viem | ^2.38.3 | ✅ Installed |
| @tanstack/react-query | ^5.x | ⚠️ Need to install |

**Note**: Wagmi v2 requires:
- viem ^2.x ✅
- @tanstack/react-query ^5.x ⚠️

## 🔧 Troubleshooting

### If installation fails:

```bash
# Clear cache and reinstall
rm -rf node_modules pnpm-lock.yaml
pnpm install
pnpm add @tanstack/react-query
```

### If TypeScript errors appear:

```bash
# Regenerate types
pnpm run build
```

### If RPC connection fails:

1. Check environment variables are set
2. Verify RPC URLs are accessible
3. Try public RPCs first before using API keys

## ✅ Final Checklist

- [ ] Install `@tanstack/react-query`
- [ ] Verify all packages installed correctly
- [ ] Add environment variables to `.env.local`
- [ ] Create/update `app/providers.tsx`
- [ ] Wrap app with providers in `app/layout.tsx`
- [ ] Test wallet connection
- [ ] Verify no TypeScript errors

---

**Current Status**: Config file ready, need to install `@tanstack/react-query`
**Next Command**: `pnpm add @tanstack/react-query`
