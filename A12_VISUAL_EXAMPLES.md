# A12: Verified Identity Integration - Visual Examples

## Dashboard Badge Examples

### Verified User

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  [Profile Pic]   Alice Johnson                         │
│                  @alice  [✅ Verified On-Chain]         │
│                          [green badge]                  │
│                                                         │
│                  Software engineer passionate about     │
│                  decentralization and web3              │
│                                                         │
│                  Personal Traits:                       │
│                  [Developer] [Creative] [Introvert]     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Hover State**:
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  [Profile Pic]   Alice Johnson                         │
│                  @alice  [✅ Verified On-Chain]         │
│                          │                              │
│                          ▼                              │
│                  ┌─────────────────────────┐           │
│                  │ Your Farcaster username │           │
│                  │ is verified on-chain    │           │
│                  └─────────────────────────┘           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Not Verified User

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  [Profile Pic]   Bob Smith                             │
│                  @bob  [⚪ Not Verified]                 │
│                        [gray badge]                     │
│                                                         │
│                  Web developer and designer             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Loading State

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  [Profile Pic]   Charlie Brown                         │
│                  @charlie  [🔄 Checking...]             │
│                            [gray badge with spinner]    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Navigation Bar Examples

### Desktop View - Not Verified

```
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│ [Meet Shipper]  Dashboard | Create | Inbox | Explore          │
│                                                                │
│         [@alice] [Verify Wallet] [0x39F...bF04] [Base] [Sign] │
│                  [purple→blue]                                 │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Desktop View - Verified

```
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│ [Meet Shipper]  Dashboard | Create | Inbox | Explore          │
│                                                                │
│         [@alice] [✓ Verified] [0x39F...bF04] [Base] [Sign]    │
│                  [green badge]                                 │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Desktop View - Verified with Tooltip

```
┌────────────────────────────────────────────────────────────────┐
│                 ┌──────────────────────────┐                   │
│                 │ Your Farcaster username  │                   │
│                 │ is verified on-chain     │                   │
│                 └────────────┬─────────────┘                   │
│                              ▼                                 │
│ [Meet Shipper]  Dashboard | Create | Inbox | Explore          │
│                                                                │
│         [@alice] [✓ Verified] [0x39F...bF04] [Base] [Sign]    │
│                  [green badge]                                 │
│                   (hovered)                                    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## Mobile Menu Examples

### Not Verified

```
┌────────────────────────────┐
│ [Meet Shipper]   [Sign]   │
├────────────────────────────┤
│ ☰ Menu                     │
│                            │
│ ┌────────────────────────┐│
│ │ Dashboard              ││
│ │ Create Match           ││
│ │ Suggest Match          ││
│ │ Inbox                  ││
│ │ Explore Users          ││
│ │                        ││
│ │ [Verify Wallet]        ││
│ │ [purple→blue gradient] ││
│ └────────────────────────┘│
│                            │
└────────────────────────────┘
```

### Verified

```
┌────────────────────────────┐
│ [Meet Shipper]   [Sign]   │
├────────────────────────────┤
│ ☰ Menu                     │
│                            │
│ ┌────────────────────────┐│
│ │ Dashboard              ││
│ │ Create Match           ││
│ │ Suggest Match          ││
│ │ Inbox                  ││
│ │ Explore Users          ││
│ │                        ││
│ │ [✓ Verified]           ││
│ │ [green badge]          ││
│ └────────────────────────┘│
│                            │
└────────────────────────────┘
```

---

## Color Reference

### Verified Badge

```
┌─────────────────────────┐
│ ✅ Verified On-Chain    │  ← Text: #15803d (green-700)
└─────────────────────────┘
 ↑
 Background: #f0fdf4 (green-50)
 Border: #bbf7d0 (green-200)
```

### Not Verified Badge

```
┌─────────────────────────┐
│ ⚪ Not Verified         │  ← Text: #4b5563 (gray-600)
└─────────────────────────┘
 ↑
 Background: #f3f4f6 (gray-100)
 Border: #e5e7eb (gray-200)
```

### Verify Wallet Button (Active)

```
┌─────────────────────────┐
│ Verify Wallet           │  ← Text: #ffffff (white)
└─────────────────────────┘
 ↑
 Gradient: #9333ea → #2563eb (purple-600 → blue-600)
 Hover: #7e22ce → #1d4ed8 (purple-700 → blue-700)
```

### Tooltip

```
╔═══════════════════════════╗
║ Your Farcaster username   ║  ← Text: #ffffff (white)
║ is verified on-chain      ║
╚═════════════╦═════════════╝
              ▼
         [Badge]
 ↑
 Background: #111827 (gray-900)
```

---

## Badge Size Comparison

```
Dashboard Badge:
[✅ Verified On-Chain]
 ↑
 Height: auto (text-xs with py-0.5)
 Padding: px-2 py-0.5 (8px x 2px)
 Font: 12px

Navbar Badge:
[✓ Verified]
 ↑
 Height: h-8 (32px)
 Padding: px-3 (12px horizontal)
 Font: 12px
```

---

## State Transitions

### User Completes Verification

```
BEFORE (Dashboard):
@alice  [⚪ Not Verified]

↓ User completes verification at /mini/contract-test

AFTER (Dashboard):
@alice  [✅ Verified On-Chain]
```

```
BEFORE (Navbar):
[Verify Wallet]  ← Purple-blue gradient, clickable

↓ User completes verification

AFTER (Navbar):
[✓ Verified]  ← Green badge, not clickable
```

---

## Interactive States

### Dashboard Badge

```
State 1: Default (Verified)
┌──────────────────────┐
│ ✅ Verified On-Chain │
└──────────────────────┘

State 2: Hover
┌──────────────────────┐
│ ✅ Verified On-Chain │  ← Tooltip appears above
└──────────────────────┘
   (cursor: help)

State 3: Not Verified
┌──────────────────────┐
│ ⚪ Not Verified      │
└──────────────────────┘
   (no hover effect)
```

### Navbar Button/Badge

```
State 1: Not Verified (Hoverable)
┌──────────────────┐
│ Verify Wallet    │  ← Darker gradient on hover
└──────────────────┘
   (cursor: pointer)

State 2: Verified (Hoverable)
┌──────────────────┐
│ ✓ Verified       │  ← Tooltip on hover
└──────────────────┘
   (cursor: default)
```

---

## Layout Examples

### Full Dashboard Header - Verified

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  [Profile]  Alice Johnson          [Edit Profile]              │
│  [Image]    @alice  [✅ Verified On-Chain]                      │
│             ─────────────────────────                           │
│             (green badge with tooltip)                          │
│                                                                 │
│             Software engineer passionate about                  │
│             decentralization and web3                           │
│                                                                 │
│             Personal Traits:                                    │
│             [Developer] [Creative] [Introvert] [Builder]        │
│                                                                 │
│             ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                    │
│             Level 3  ●●●●●●●●●●○○○○○○○○○○  50%                  │
│                                                                 │
│                                                 [User Code]     │
│                                                 1234567890      │
└─────────────────────────────────────────────────────────────────┘
```

### Full Dashboard Header - Not Verified

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  [Profile]  Bob Smith              [Edit Profile]              │
│  [Image]    @bob  [⚪ Not Verified]                             │
│             ──────────────────                                  │
│             (gray badge, no tooltip)                            │
│                                                                 │
│             Web developer and designer                          │
│                                                                 │
│             Personal Traits:                                    │
│             [Designer] [Creative] [Extrovert]                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Responsive Breakpoints

### Desktop (≥ 1024px)

```
Navbar:
[Meet Shipper] | Nav Links | [@user] [Verify/✓] [Wallet] [Chain] [Sign]
                             (all visible)

Dashboard:
@username [Badge]
          (visible)
```

### Tablet (768px - 1023px)

```
Navbar:
[Meet Shipper] | Nav Links | [Verify/✓] [Wallet] [Chain] [Sign]
                             (profile hidden, badge visible)

Dashboard:
@username [Badge]
          (visible)
```

### Mobile (< 768px)

```
Navbar:
[Meet Shipper] | [Chain] [Sign]

☰ Menu:
  - Nav Links
  - [Verify/✓]  ← Badge in menu

Dashboard:
@username [Badge]
          (visible)
```

---

## Animation Timeline

```
Tooltip Fade-In:
0ms:    opacity: 0, translateY(-10px)
300ms:  opacity: 1, translateY(0)
        [complete]

Status Change:
0ms:    [Checking...] (gray with spinner)
2000ms: API response received
2001ms: [✅ Verified On-Chain] (green)
        [instant transition]
```

---

## Z-Index Layers

```
Z-Index Stack:

z-50:  Tooltips
       ▲
z-10:  Badges (if needed)
       ▲
z-1:   Base content
```

---

**Version**: A12 - Verified Identity Integration
**Status**: ✅ Complete
**Visual Guide**: Ready for reference
