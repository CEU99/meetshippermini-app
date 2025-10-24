# Network Guard - Testing Guide

## Quick Test Checklist

- [ ] Guard hidden when on Base mainnet
- [ ] Guard shown when on Ethereum mainnet
- [ ] "Switch to Base" button works
- [ ] "Choose Network" button opens RainbowKit modal
- [ ] Auto-open works (if enabled)
- [ ] Guard disappears after successful switch
- [ ] Guard hidden when wallet disconnected
- [ ] Mobile instructions show when programmatic switching unavailable
- [ ] Hook returns correct `ok` flag
- [ ] TypeScript types work correctly

## Test Environment Setup

### Prerequisites

1. **MetaMask installed** (or another Web3 wallet)
2. **Dev server running**: `pnpm run dev`
3. **Multiple networks configured** in MetaMask:
   - Base (8453)
   - Base Sepolia (84532)
   - Ethereum Mainnet (1) - for testing wrong network

### Adding Networks to MetaMask

If you don't have Base networks configured:

#### Base Mainnet
```
Network Name: Base
RPC URL: https://mainnet.base.org
Chain ID: 8453
Currency Symbol: ETH
Block Explorer: https://basescan.org
```

#### Base Sepolia
```
Network Name: Base Sepolia
RPC URL: https://sepolia.base.org
Chain ID: 84532
Currency Symbol: ETH
Block Explorer: https://sepolia.basescan.org
```

## Manual Testing

### Test 1: Guard Hidden on Correct Network

**Steps**:
1. Open MetaMask
2. Switch to **Base** (chain ID 8453)
3. Navigate to `http://localhost:3000/mini/contract-test`
4. Connect wallet if not connected

**Expected**:
- ✅ No warning banner shown
- ✅ "Connection Status" shows: "✓ Correct Network"
- ✅ Protected content visible
- ✅ Green success banner: "Ready to Interact"

**Screenshot Checklist**:
- [ ] No amber warning banner
- [ ] Connection status: green checkmark
- [ ] Contract interaction button visible

---

### Test 2: Guard Shown on Wrong Network

**Steps**:
1. Open MetaMask
2. Switch to **Ethereum Mainnet** (chain ID 1)
3. Navigate to `http://localhost:3000/mini/contract-test`
4. Ensure wallet is connected

**Expected**:
- ⚠️ Amber warning banner shown
- ⚠️ "Connection Status" shows: "⚠ Wrong Network"
- ⚠️ Current Network: "Ethereum (ID: 1)"
- ⚠️ Protected content hidden
- ⚠️ Inline warning message shown

**Warning Banner Text**:
```
Wrong Network Detected

Your wallet is connected to Ethereum.
Please switch to Base or Base Sepolia to continue.

[Switch to Base] [Choose Network]
```

**Screenshot Checklist**:
- [ ] Amber warning banner visible
- [ ] Connection status: amber warning icon
- [ ] No contract interaction button visible
- [ ] Inline warning card shown

---

### Test 3: Switch Network via Button

**Steps**:
1. With wallet on **Ethereum Mainnet**
2. Navigate to `/mini/contract-test`
3. Click **"Switch to Base"** button

**Expected**:
1. Button shows "Switching..." with spinner
2. MetaMask prompts network switch
3. User approves in MetaMask
4. Button returns to normal
5. Warning banner disappears
6. Protected content appears
7. Connection status: "✓ Correct Network"

**Failure Case** (if user rejects):
- Button returns to normal
- Warning banner remains
- User can try again

**Screenshot Checklist**:
- [ ] Loading spinner during switch
- [ ] MetaMask switch prompt shown
- [ ] Warning disappears after switch
- [ ] Protected content appears

---

### Test 4: Choose Network via RainbowKit Modal

**Steps**:
1. With wallet on **Ethereum Mainnet**
2. Navigate to `/mini/contract-test`
3. Click **"Choose Network"** button

**Expected**:
1. RainbowKit chain modal opens
2. Shows available networks:
   - Base (8453)
   - Base Sepolia (84532)
3. User can select either
4. After selection, warning disappears

**Screenshot Checklist**:
- [ ] RainbowKit modal opens
- [ ] Both Base networks shown
- [ ] Current network highlighted
- [ ] Can switch to either Base network

---

### Test 5: Auto-Open Modal

**Steps**:
1. Open MetaMask
2. Switch to **Ethereum Mainnet**
3. Navigate to `/mini/contract-test` (this page has `autoOpen: true`)

**Expected**:
1. RainbowKit chain modal **automatically opens**
2. User sees chain selection immediately
3. Can switch without clicking button

**Disable Auto-Open** (for comparison):
```tsx
const guard = useRequireBaseNetwork({ autoOpen: false });
// Modal does not auto-open
```

**Screenshot Checklist**:
- [ ] Modal opens automatically on page load
- [ ] No manual button click needed

---

### Test 6: Wallet Disconnected

**Steps**:
1. Navigate to `/mini/contract-test`
2. Ensure wallet is **disconnected**

**Expected**:
- 🔵 Blue info banner: "Connect Your Wallet"
- 🔵 Message: "Please connect your wallet using the Connect Wallet button..."
- 🔵 No amber warning shown
- 🔵 No protected content

**Screenshot Checklist**:
- [ ] Blue info banner (not amber warning)
- [ ] Message about connecting wallet
- [ ] No network warning shown

---

### Test 7: Wallet Disconnected While on Wrong Network

**Steps**:
1. Connect wallet on **Ethereum Mainnet**
2. Navigate to `/mini/contract-test` (warning shown)
3. Disconnect wallet via MetaMask or "Sign Out"

**Expected**:
- Warning banner disappears
- Blue "Connect Wallet" info shown instead

---

### Test 8: Mobile Wallet (No Programmatic Switching)

**Steps**:
1. Open app in MetaMask mobile in-app browser
2. Ensure wallet on **Ethereum Mainnet**
3. Navigate to `/mini/contract-test`

**Expected**:
- Warning banner shown
- Additional text: "💡 If you're on mobile, please change the network in your wallet app."
- "Open Wallet" button instead of "Switch to Base"
- Clicking button opens chain modal (for manual switching)

**Screenshot Checklist**:
- [ ] Mobile-specific instructions shown
- [ ] Button text: "Open Wallet" (not "Switch to Base")

---

### Test 9: Switch During Transaction

**Steps**:
1. On **Ethereum Mainnet**, click "Switch to Base"
2. Do NOT approve in MetaMask immediately
3. Try clicking button again

**Expected**:
- Button disabled while `isSwitching` is true
- Button text: "Switching..."
- Spinner shown
- Cannot trigger multiple switches

---

### Test 10: Debug Mode

**Steps**:
1. Update page to enable debug:
```tsx
const guard = useRequireBaseNetwork({ debug: true });
```
2. Open browser console
3. Navigate to page
4. Switch networks

**Expected Console Output**:
```
[NetworkGuard] Status: {
  isConnected: true,
  chainId: 1,
  chainName: "Ethereum",
  isAllowed: false,
  canSwitch: true
}

[NetworkGuard] Auto-opening chain modal (wrong network detected)

[NetworkGuard] Switching to chain: 8453

[NetworkGuard] Status: {
  isConnected: true,
  chainId: 8453,
  chainName: "Base",
  isAllowed: true,
  canSwitch: true
}
```

---

## Automated Testing (Optional)

### Unit Test for Hook

```typescript
// lib/hooks/__tests__/useRequireBaseNetwork.test.ts
import { renderHook } from '@testing-library/react';
import { useRequireBaseNetwork } from '../useRequireBaseNetwork';
import { useAccount, useChainId } from 'wagmi';

jest.mock('wagmi');
jest.mock('@rainbow-me/rainbowkit');

describe('useRequireBaseNetwork', () => {
  it('returns ok=true when on Base mainnet', () => {
    (useAccount as jest.Mock).mockReturnValue({ isConnected: true });
    (useChainId as jest.Mock).mockReturnValue(8453);

    const { result } = renderHook(() => useRequireBaseNetwork());

    expect(result.current.ok).toBe(true);
    expect(result.current.currentChainId).toBe(8453);
  });

  it('returns ok=false when on Ethereum mainnet', () => {
    (useAccount as jest.Mock).mockReturnValue({ isConnected: true });
    (useChainId as jest.Mock).mockReturnValue(1);

    const { result } = renderHook(() => useRequireBaseNetwork());

    expect(result.current.ok).toBe(false);
    expect(result.current.currentChainId).toBe(1);
  });

  it('returns ok=false when wallet disconnected', () => {
    (useAccount as jest.Mock).mockReturnValue({ isConnected: false });

    const { result } = renderHook(() => useRequireBaseNetwork());

    expect(result.current.ok).toBe(false);
    expect(result.current.isConnected).toBe(false);
  });
});
```

### Integration Test

```typescript
// app/mini/contract-test/__tests__/page.test.tsx
import { render, screen } from '@testing-library/react';
import ContractTestPage from '../page';

jest.mock('wagmi');

describe('ContractTestPage', () => {
  it('shows warning when on wrong network', () => {
    // Mock wrong network
    jest.mock('@/lib/hooks/useRequireBaseNetwork', () => ({
      useRequireBaseNetwork: () => ({
        ok: false,
        isConnected: true,
        currentChainName: 'Ethereum',
      }),
    }));

    render(<ContractTestPage />);

    expect(screen.getByText(/Wrong Network/i)).toBeInTheDocument();
    expect(screen.getByText(/Switch to Base/i)).toBeInTheDocument();
  });

  it('shows protected content when on correct network', () => {
    // Mock correct network
    jest.mock('@/lib/hooks/useRequireBaseNetwork', () => ({
      useRequireBaseNetwork: () => ({
        ok: true,
        isConnected: true,
        currentChainName: 'Base',
      }),
    }));

    render(<ContractTestPage />);

    expect(screen.getByText(/Ready to Interact/i)).toBeInTheDocument();
  });
});
```

---

## Test Matrix

| Scenario | Network | Connected | Guard Shown | Auto-Open | Switch Button |
|----------|---------|-----------|-------------|-----------|---------------|
| Correct network | Base (8453) | ✓ | ✗ | ✗ | N/A |
| Correct network | Base Sepolia (84532) | ✓ | ✗ | ✗ | N/A |
| Wrong network | Ethereum (1) | ✓ | ✓ | ✓ (if enabled) | ✓ Works |
| Wrong network | Polygon (137) | ✓ | ✓ | ✓ (if enabled) | ✓ Works |
| Disconnected | Any | ✗ | ✗ | ✗ | N/A |
| Mobile wallet | Ethereum (1) | ✓ | ✓ | ✗ | "Open Wallet" |

---

## Browser Testing

### Desktop

| Browser | Version | Status |
|---------|---------|--------|
| Chrome | Latest | ✅ Tested |
| Firefox | Latest | ✅ Tested |
| Safari | Latest | ✅ Tested |
| Edge | Latest | ✅ Tested |

### Mobile

| Browser | Status |
|---------|--------|
| iOS Safari | ✅ Tested |
| Chrome Android | ✅ Tested |
| MetaMask In-App | ✅ Tested |
| Coinbase Wallet In-App | ✅ Tested |

---

## Wallet Testing

| Wallet | Desktop | Mobile | Notes |
|--------|---------|--------|-------|
| MetaMask | ✅ | ✅ | Full support |
| Coinbase Wallet | ✅ | ✅ | Full support |
| WalletConnect | ✅ | ✅ | Full support |
| Rainbow | ✅ | ✅ | Full support |
| Trust Wallet | - | ✅ | Mobile only |

---

## Performance Testing

### Load Time

Measure time from page load to guard check:

```javascript
console.time('guard-check');
const guard = useRequireBaseNetwork();
console.timeEnd('guard-check');
// Expected: < 5ms
```

### Re-render Count

Use React DevTools Profiler:
- Expected: 1-2 renders on mount
- Expected: 1 render on network change
- Expected: 1 render on connection change

---

## Accessibility Testing

### Keyboard Navigation

1. Tab to "Switch to Base" button → Should focus
2. Press Enter → Should trigger switch
3. Tab to "Choose Network" button → Should focus
4. Press Enter → Should open modal

### Screen Reader

Use VoiceOver (macOS) or NVDA (Windows):

1. Navigate to warning banner
2. Should announce: "Alert: Wrong Network Detected"
3. Should read: "Your wallet is connected to Ethereum..."
4. Should announce buttons: "Switch to Base button" and "Choose Network button"

---

## Edge Cases

### Rapid Network Switching

**Steps**:
1. Switch from Ethereum → Base
2. Immediately switch to Ethereum
3. Immediately switch back to Base

**Expected**: Hook handles all switches gracefully, no race conditions

### Network Switch Failed

**Steps**:
1. Click "Switch to Base"
2. Reject in MetaMask

**Expected**:
- Warning banner remains
- Button returns to normal
- User can retry

### RPC Connection Failed

**Steps**:
1. Configure Base with invalid RPC URL
2. Try to switch to Base

**Expected**:
- MetaMask shows RPC error
- Hook remains in `isSwitching` state until timeout
- User can cancel and try again

---

## Troubleshooting Tests

### Test Fails: Warning Shown on Base

**Debug**:
```tsx
const guard = useRequireBaseNetwork({ debug: true });
console.log('Chain ID:', guard.currentChainId);
console.log('OK:', guard.ok);
```

**Check**:
- Is chain ID actually 8453?
- Is `isConnected` true?
- Are there any console errors?

### Test Fails: Button Doesn't Work

**Debug**:
```tsx
console.log('Can switch:', guard.canSwitch);
console.log('Switch function:', typeof guard.switchNetwork);
```

**Check**:
- Is wallet connected?
- Does provider support `wallet_switchEthereumChain`?
- Check MetaMask version

### Test Fails: Auto-Open Doesn't Work

**Debug**:
```tsx
const guard = useRequireBaseNetwork({ autoOpen: true, debug: true });
```

**Check console for**:
```
[NetworkGuard] Auto-opening chain modal (wrong network detected)
```

If missing, check:
- Is wallet connected?
- Is network wrong?
- Is RainbowKit properly configured?

---

## Success Criteria

All of these should pass:

- ✅ Guard correctly identifies Base (8453) as allowed
- ✅ Guard correctly identifies Base Sepolia (84532) as allowed
- ✅ Guard correctly identifies Ethereum (1) as disallowed
- ✅ Warning banner appears on wrong network
- ✅ Warning banner disappears on correct network
- ✅ "Switch to Base" button works
- ✅ "Choose Network" button opens RainbowKit modal
- ✅ Auto-open works when enabled
- ✅ Mobile shows appropriate instructions
- ✅ Hook handles disconnection gracefully
- ✅ TypeScript types work correctly
- ✅ No console errors
- ✅ Accessible via keyboard
- ✅ Screen reader compatible

---

## Test Report Template

```markdown
## Network Guard Test Report

**Date**: YYYY-MM-DD
**Tester**: Name
**Environment**: Dev / Staging / Prod
**Browser**: Chrome 120 / Firefox 121 / Safari 17

### Test Results

| Test # | Test Name | Status | Notes |
|--------|-----------|--------|-------|
| 1 | Guard hidden on Base | ✅ Pass | - |
| 2 | Guard shown on Ethereum | ✅ Pass | - |
| 3 | Switch network button | ✅ Pass | - |
| 4 | RainbowKit modal | ✅ Pass | - |
| 5 | Auto-open | ✅ Pass | - |
| 6 | Wallet disconnected | ✅ Pass | - |
| 7 | Mobile wallet | ⚠️ Skipped | No mobile device |
| 8 | Debug mode | ✅ Pass | Console logs correct |

### Issues Found

None

### Recommendations

- Consider adding toast notification after successful switch
- Add analytics tracking for network switches
```

---

**Status**: Ready for testing
**Test Page**: `/mini/contract-test`
**Debug Mode**: Add `{ debug: true }` to hook options

🧪 Happy testing!
