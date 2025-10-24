# Wagmi Wallet Integration Setup

## ✅ Configuration Created

**File**: `lib/wagmi.ts`

This file exports `wagmiConfig` for wallet integration using Wagmi v2.

## 🔧 Required Environment Variables

Add these to your `.env.local` file:

```bash
# Base Mainnet RPC URL
NEXT_PUBLIC_BASE_RPC_URL=https://mainnet.base.org

# Base Sepolia Testnet RPC URL
NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
```

### Recommended RPC Providers

You can use public RPC endpoints or your own provider:

#### Option 1: Public RPCs (Free)
```bash
NEXT_PUBLIC_BASE_RPC_URL=https://mainnet.base.org
NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
```

#### Option 2: Alchemy (Better performance)
```bash
NEXT_PUBLIC_BASE_RPC_URL=https://base-mainnet.g.alchemy.com/v2/YOUR_API_KEY
NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

#### Option 3: Infura
```bash
NEXT_PUBLIC_BASE_RPC_URL=https://base-mainnet.infura.io/v3/YOUR_PROJECT_ID
NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL=https://base-sepolia.infura.io/v3/YOUR_PROJECT_ID
```

## 📦 Required Dependencies

Make sure these packages are installed:

```bash
pnpm add wagmi viem @tanstack/react-query
```

## 🔗 Usage in Providers

Import in your `app/providers.tsx`:

```typescript
import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { wagmiConfig } from '@/lib/wagmi'

const queryClient = new QueryClient()

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </WagmiProvider>
  )
}
```

## 📝 Configuration Details

### Chains Supported
- **Base Mainnet** (`chainId: 8453`)
- **Base Sepolia Testnet** (`chainId: 84532`)

### Transport
- Uses HTTP transport for both chains
- RPC URLs loaded from environment variables
- Falls back to public RPC if env vars not set

## 🧪 Testing

### Check Configuration
```typescript
import { wagmiConfig } from '@/lib/wagmi'

console.log('Chains:', wagmiConfig.chains)
console.log('Transports:', wagmiConfig.transports)
```

### Verify Environment Variables
```bash
# In terminal
echo $NEXT_PUBLIC_BASE_RPC_URL
echo $NEXT_PUBLIC_BASE_SEPOLIA_RPC_URL
```

### Test in App
```typescript
import { useAccount, useConnect } from 'wagmi'

function WalletButton() {
  const { address, isConnected } = useAccount()
  const { connect, connectors } = useConnect()

  if (isConnected) {
    return <div>Connected: {address}</div>
  }

  return (
    <button onClick={() => connect({ connector: connectors[0] })}>
      Connect Wallet
    </button>
  )
}
```

## 🔒 Security Notes

1. **RPC URLs**: Use `NEXT_PUBLIC_` prefix so they're available in browser
2. **API Keys**: Keep private RPC API keys secure
3. **Rate Limits**: Public RPCs have rate limits - use private RPC for production
4. **Chain IDs**: Wagmi validates chain IDs automatically

## 📚 Additional Resources

- [Wagmi Documentation](https://wagmi.sh/)
- [Base Network](https://base.org/)
- [Viem Documentation](https://viem.sh/)

## ✅ Checklist

- [x] Created `lib/wagmi.ts`
- [ ] Added environment variables to `.env.local`
- [ ] Installed required packages (`wagmi`, `viem`, `@tanstack/react-query`)
- [ ] Imported in `app/providers.tsx`
- [ ] Wrapped app with `WagmiProvider`
- [ ] Tested wallet connection

---

**Status**: ✅ Configuration file created
**Next Step**: Add environment variables and set up providers
**File Location**: `lib/wagmi.ts`
