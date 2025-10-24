# Navigation Bar - Visual Style Guide

## Layout Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                 │
│  [Meet Shipper]    Dashboard  Create  Suggest  Inbox  Explore                  │
│                                                                                 │
│           [@user] [Verify Wallet] [0x39F...bF04] [Base ⚡] [Sign Out]         │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Element Specifications

### 🎨 Logo: "Meet Shipper"

**Position**: Far left
**Style**:
- Font: `text-xl font-bold`
- Color: Gradient from purple-600 to blue-600
- Effect: Text gradient clip
- Hover: Darkens to purple-700/blue-700

**Code**:
```tsx
<span className="text-xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent">
  Meet Shipper
</span>
```

**Visual**:
```
 Meet Shipper
 [purple→blue gradient]
```

---

### 🔗 Navigation Links

**Position**: Center
**Items**: Dashboard | Create Match | Suggest Match | Inbox | Explore Users

**States**:

#### Default State
- Color: `text-gray-600`
- Hover: `text-gray-900` + `bg-gray-50`
- Font: `text-sm font-medium`
- Padding: `px-3 py-1.5`

#### Active State
- Color: `text-purple-600`
- Underline: 2px gradient bar at bottom
- Underline gradient: purple-600 → blue-600

**Visual**:
```
Dashboard  Create Match  Suggest Match  Inbox  Explore Users
   ━━━━
[active link has gradient underline]
```

---

### 👤 User Profile Section

**Position**: Right side (before buttons)
**Visibility**: Hidden on < lg screens

**Components**:
- Profile picture: 24x24px, rounded-full, ring-1 ring-gray-200
- Username: `text-xs font-medium text-gray-600`, prefixed with `@`

**Visual**:
```
[●] @alice
[profile pic] [@username]
```

---

### ✅ Verify Wallet Button (NEW)

**Position**: After profile, before wallet address
**Link**: `/mini/contract-test`

**Style**:
- Background: Gradient `from-purple-600 to-blue-600`
- Text: White, `text-xs font-medium`
- Height: `h-8` (32px)
- Padding: `px-3`
- Shadow: `shadow-sm`
- Hover: Darkens to purple-700/blue-700

**Visual**:
```
┌──────────────────┐
│  Verify Wallet   │
└──────────────────┘
[purple→blue gradient, white text]
```

---

### 💰 Wallet Address Display

**Position**: After Verify Wallet button
**Condition**: Only when wallet connected

**Style**:
- Background: `bg-gray-50`
- Border: `border border-gray-200`
- Text: `text-xs font-mono text-gray-600`
- Height: `h-8` (32px)
- Padding: `px-2.5`

**Format**:
```
0x39F7...bF04
[first 6 chars]...[last 4 chars]
```

**Visual**:
```
┌─────────────────┐
│ 0x39F7...bF04   │
└─────────────────┘
[gray bg, monospace font]
```

---

### 🔌 Connect Wallet Button (Custom Compact)

**Position**: After wallet address
**Type**: RainbowKit Custom Button

#### State 1: Not Connected
**Visual**:
```
┌──────────┐
│ Connect  │
└──────────┘
[gray-100 bg, gray-700 text]
```

#### State 2: Wrong Network
**Visual**:
```
┌─────────────────┐
│ Wrong Network   │
└─────────────────┘
[red-100 bg, red-700 text]
```

#### State 3: Connected (Correct Network)
**Visual**:
```
┌────────────┐
│ ⚡ Base    │
└────────────┘
[green-50 bg, green-700 text, chain icon]
```

**Common Properties**:
- Height: `h-8` (32px)
- Padding: `px-3`
- Font: `text-xs font-medium`
- Border: 1px solid matching color
- Transition: `transition-all duration-200`

---

### 🚪 Sign Out Button

**Position**: Far right
**Style**:
- Background: White
- Border: `border-gray-200`
- Text: `text-xs font-medium text-gray-600`
- Height: `h-8` (32px)
- Padding: `px-3`
- Hover: `bg-gray-50`

**Visual**:
```
┌────────────┐
│ Sign Out   │
└────────────┘
[white bg, gray border, gray text]
```

---

## Complete Desktop Layout

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║  [Meet Shipper]                                                               ║
║  [gradient logo]                                                              ║
║                                                                               ║
║     Dashboard    Create Match    Suggest Match    Inbox    Explore Users     ║
║        ━━━━                                                                   ║
║     [active]     [hover bg]      [default]                                   ║
║                                                                               ║
║                                                                               ║
║  [●] @alice  [Verify Wallet]  [0x39F...bF04]  [⚡ Base]  [Sign Out]          ║
║  [profile]   [gradient btn]   [gray box]     [green]    [white btn]         ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

## Mobile Layout (< md)

```
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║  [Meet Shipper]              [⚡ Base]  [Sign Out]   ║
║  [gradient logo]             [wallet]  [button]      ║
║                                                       ║
╠═══════════════════════════════════════════════════════╣
║  Collapsible Menu:                                    ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │  Dashboard                                      │ ║
║  │  Create Match                                   │ ║
║  │  Suggest Match                                  │ ║
║  │  Inbox                                          │ ║
║  │  Explore Users                                  │ ║
║  │  ┌──────────────────┐                          │ ║
║  │  │  Verify Wallet   │  [gradient button]      │ ║
║  │  └──────────────────┘                          │ ║
║  └─────────────────────────────────────────────────┘ ║
╚═══════════════════════════════════════════════════════╝
```

## Color Palette Reference

### Primary Colors
```css
purple-600: #9333ea
purple-700: #7e22ce
blue-600:   #2563eb
blue-700:   #1d4ed8
```

### Neutral Colors
```css
gray-50:    #f9fafb
gray-100:   #f3f4f6
gray-200:   #e5e7eb
gray-600:   #4b5563
gray-700:   #374151
gray-900:   #111827
```

### State Colors
```css
/* Success (Connected) */
green-50:   #f0fdf4
green-700:  #15803d

/* Warning (Wrong Network) */
red-50:     #fef2f2
red-100:    #fee2e2
red-700:    #b91c1c
```

## Spacing & Sizing

### Heights
- Navbar: `h-14` (56px)
- All buttons: `h-8` (32px)
- Profile picture: `24px x 24px`
- Chain icon: `12px x 12px`

### Spacing
- Between right-side elements: `space-x-2` (8px)
- Between nav links: `space-x-1` (4px)
- Button padding horizontal: `px-3` (12px)
- Button padding vertical: Built-in to `h-8`

### Borders & Shadows
- Navbar border: `border-b border-gray-100`
- Button borders: `border border-gray-200`
- Navbar shadow: `shadow-sm`
- Verify Wallet shadow: `shadow-sm`

## Typography Scale

```
Logo:              text-xl (20px)
Nav Links:         text-sm (14px)
Username:          text-xs (12px)
Button Text:       text-xs (12px)
Wallet Address:    text-xs (12px) + font-mono
```

## Hover & Active States

### Navigation Links
```
Default:  text-gray-600
Hover:    text-gray-900 + bg-gray-50
Active:   text-purple-600 + gradient underline
```

### Buttons
```
Logo:           hover:from-purple-700 hover:to-blue-700
Verify Wallet:  hover:from-purple-700 hover:to-blue-700
Connect:        hover:bg-gray-200
Chain Button:   hover:bg-green-100
Sign Out:       hover:bg-gray-50
```

## Responsive Breakpoints

```css
/* Mobile First */
default:  < 640px   (mobile)
sm:       >= 640px  (small tablets)
md:       >= 768px  (tablets)
lg:       >= 1024px (desktops)
```

### Visibility Rules
- Profile (`@username`): `hidden lg:flex` (only desktop)
- Verify Wallet button: `hidden sm:inline-flex` (tablet+)
- Wallet address: `hidden sm:flex` (tablet+)
- Nav links (center): `hidden md:flex` (desktop+)
- Mobile menu: `md:hidden` (mobile/tablet only)

## Animation Timing

```css
All transitions: transition-all duration-200 (200ms)
Fade-in on load: animation: fadeIn 0.3s ease-out
```

## Accessibility Features

- ✅ Focus rings on all interactive elements (ring-2 ring-purple-500)
- ✅ Semantic HTML (`<nav>`, `<button>`, `<a>`)
- ✅ Alt text on profile images
- ✅ ARIA labels where needed
- ✅ Keyboard navigation support
- ✅ Color contrast > 4.5:1 (WCAG AA)

## Z-Index Layers

```
Navbar:        z-50
Modals:        z-[100]
RainbowKit:    z-[200]
```

---

## Implementation Example

```tsx
// Full right-side section layout
<div className="flex items-center space-x-2">
  {user && (
    <>
      {/* 1. Profile */}
      <div className="hidden lg:flex items-center space-x-2 px-2 py-1 rounded-md">
        <Image src={user.pfpUrl} alt={user.username} width={24} height={24}
               className="rounded-full ring-1 ring-gray-200" />
        <span className="text-xs font-medium text-gray-600">@{user.username}</span>
      </div>

      {/* 2. Verify Wallet */}
      <Link href="/mini/contract-test"
            className="hidden sm:inline-flex items-center px-3 h-8 text-xs font-medium rounded-md
                       bg-gradient-to-r from-purple-600 to-blue-600 text-white
                       hover:from-purple-700 hover:to-blue-700 transition-all duration-200 shadow-sm">
        Verify Wallet
      </Link>

      {/* 3. Wallet Address */}
      {isConnected && address && (
        <div className="hidden sm:flex items-center px-2.5 h-8 text-xs font-mono
                        text-gray-600 bg-gray-50 rounded-md border border-gray-200">
          {formatAddress(address)}
        </div>
      )}

      {/* 4. Connect Wallet */}
      <div className="scale-90">
        <ConnectButton.Custom>
          {/* Custom compact button logic */}
        </ConnectButton.Custom>
      </div>

      {/* 5. Sign Out */}
      <button onClick={signOut}
              className="inline-flex items-center px-3 h-8 text-xs font-medium rounded-md
                         text-gray-600 bg-white hover:bg-gray-50 transition-all duration-200
                         border border-gray-200">
        Sign Out
      </button>
    </>
  )}
</div>
```

---

**Version**: v3.0 - Modern Compact Navigation
**Status**: ✅ Production Ready
**Last Updated**: 2025-01-15
