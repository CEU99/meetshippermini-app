'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import Image from 'next/image';
import { useAccount } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAttestationStatus } from '@/lib/hooks/useAttestationStatus';
import { useState } from 'react';

export function Navigation() {
  const pathname = usePathname();
  const { user, signOut } = useFarcasterAuth();
  const { address, isConnected } = useAccount();
  const { isVerified, isLoading: isCheckingVerification } = useAttestationStatus();
  const [showVerifiedTooltip, setShowVerifiedTooltip] = useState(false);
  const [showWalletTooltip, setShowWalletTooltip] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const navItems = [
    { href: '/dashboard', label: 'Dashboard' },
    { href: '/mini/create', label: 'Create Match' },
    { href: '/mini/suggest', label: 'Suggest Match' },
    { href: '/mini/inbox', label: 'Inbox' },
    { href: '/users', label: 'Explore Users' },
  ];

  // Format wallet address to compact form
  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  return (
    <nav className="backdrop-blur-xl bg-white/80 border-b border-white/60 shadow-lg sticky top-0 z-50 animate-fade-in">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Left: Logo */}
          <div className="flex items-center gap-8">
            <Link href="/dashboard" className="flex items-center group">
              <span className="text-xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent transition-all duration-300 group-hover:from-purple-700 group-hover:to-blue-700 group-hover:scale-105">
                Meet Shipper
              </span>
            </Link>

            {/* Desktop Navigation Links - Hidden on mobile */}
            <div className="hidden lg:flex items-center gap-2">
              {navItems.map((item) => {
                const isActive = pathname === item.href;
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`relative px-4 py-2 text-sm font-medium rounded-lg transition-all duration-300 ${
                      isActive
                        ? 'text-purple-600'
                        : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50/50 hover:scale-105'
                    }`}
                  >
                    {item.label}
                    {isActive && (
                      <span className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-12 h-0.5 bg-gradient-to-r from-purple-600 via-purple-500 to-blue-600 rounded-full animate-slide-in"></span>
                    )}
                  </Link>
                );
              })}
            </div>
          </div>

          {/* Right: Profile Section */}
          <div className="flex items-center gap-3">
            {user && (
              <>
                {/* User Profile - Desktop only */}
                <div className="hidden lg:flex items-center gap-2.5 px-3 py-1.5 rounded-lg backdrop-blur-sm bg-white/50 border border-purple-100/60 hover:bg-purple-50/50 hover:border-purple-200/60 transition-all duration-300 cursor-pointer">
                  {user.pfpUrl && (
                    <Image
                      src={user.pfpUrl}
                      alt={user.username}
                      width={28}
                      height={28}
                      className="rounded-full ring-2 ring-purple-200/50 hover:ring-purple-300/70 transition-all duration-300"
                    />
                  )}
                  <span className="text-sm font-medium text-gray-700 hover:text-purple-600 transition-colors duration-300">
                    @{user.username}
                  </span>
                </div>

                {/* Verified Badge - Smaller and more elegant */}
                <div className="relative hidden lg:block">
                  {isVerified ? (
                    <div
                      className="group relative inline-flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-medium rounded-lg backdrop-blur-sm bg-emerald-50/70 text-emerald-700 border border-emerald-200/60 cursor-default hover:bg-emerald-100/70 hover:border-emerald-300/60 transition-all duration-300"
                      onMouseEnter={() => setShowVerifiedTooltip(true)}
                      onMouseLeave={() => setShowVerifiedTooltip(false)}
                    >
                      <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"/>
                      </svg>
                      <span>Verified</span>

                      {/* Tooltip */}
                      {showVerifiedTooltip && (
                        <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 backdrop-blur-xl bg-gray-900/95 text-white text-xs rounded-lg whitespace-nowrap shadow-xl z-50 animate-tooltip-in">
                          Verified On-Chain
                          <div className="absolute top-full left-1/2 transform -translate-x-1/2 -mt-1">
                            <div className="border-[5px] border-transparent border-t-gray-900"></div>
                          </div>
                        </div>
                      )}
                    </div>
                  ) : (
                    <Link
                      href="/mini/contract-test"
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg backdrop-blur-sm bg-gradient-to-r from-purple-500/90 to-blue-500/90 text-white border border-purple-300/40 hover:from-purple-600 hover:to-blue-600 hover:scale-105 hover:shadow-lg transition-all duration-300"
                    >
                      <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                      </svg>
                      <span>Verify</span>
                    </Link>
                  )}
                </div>

                {/* Wallet Address Badge - Smaller and elegant with tooltip */}
                {isConnected && address && (
                  <div
                    className="relative hidden lg:flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-mono text-gray-600 backdrop-blur-sm bg-blue-50/60 rounded-lg border border-blue-200/60 hover:border-blue-300/60 hover:bg-blue-100/60 transition-all duration-300 cursor-pointer"
                    onMouseEnter={() => setShowWalletTooltip(true)}
                    onMouseLeave={() => setShowWalletTooltip(false)}
                  >
                    <svg className="w-3 h-3 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
                    </svg>
                    <span>{formatAddress(address)}</span>

                    {/* Tooltip */}
                    {showWalletTooltip && (
                      <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 backdrop-blur-xl bg-gray-900/95 text-white text-xs rounded-lg whitespace-nowrap shadow-xl z-50 animate-tooltip-in">
                        Wallet Connected
                        <div className="absolute top-full left-1/2 transform -translate-x-1/2 -mt-1">
                          <div className="border-[5px] border-transparent border-t-gray-900"></div>
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* Connect Wallet Button - Refined */}
                <div className="hidden lg:block">
                  <ConnectButton.Custom>
                    {({
                      account,
                      chain,
                      openAccountModal,
                      openChainModal,
                      openConnectModal,
                      mounted,
                    }) => {
                      const ready = mounted;
                      const connected = ready && account && chain;

                      return (
                        <div
                          {...(!ready && {
                            'aria-hidden': true,
                            style: {
                              opacity: 0,
                              pointerEvents: 'none',
                              userSelect: 'none',
                            },
                          })}
                        >
                          {(() => {
                            if (!connected) {
                              return (
                                <button
                                  onClick={openConnectModal}
                                  type="button"
                                  className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg backdrop-blur-sm bg-gray-100/70 text-gray-700 hover:bg-gray-200/70 hover:scale-105 transition-all duration-300 border border-gray-200/60"
                                >
                                  <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"/>
                                  </svg>
                                  Connect
                                </button>
                              );
                            }

                            if (chain.unsupported) {
                              return (
                                <button
                                  onClick={openChainModal}
                                  type="button"
                                  className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg backdrop-blur-sm bg-red-100/70 text-red-700 hover:bg-red-200/70 hover:scale-105 transition-all duration-300 border border-red-200/60"
                                >
                                  <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                    <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd"/>
                                  </svg>
                                  Wrong Network
                                </button>
                              );
                            }

                            return (
                              <button
                                onClick={openAccountModal}
                                type="button"
                                className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg backdrop-blur-sm bg-blue-50/70 text-blue-700 hover:bg-blue-100/70 hover:scale-105 transition-all duration-300 border border-blue-200/60"
                              >
                                {chain.hasIcon && (
                                  <div
                                    className="w-3 h-3 rounded-full overflow-hidden"
                                    style={{
                                      background: chain.iconBackground,
                                    }}
                                  >
                                    {chain.iconUrl && (
                                      <img
                                        alt={chain.name ?? 'Chain icon'}
                                        src={chain.iconUrl}
                                        className="w-3 h-3"
                                      />
                                    )}
                                  </div>
                                )}
                                {chain.name}
                              </button>
                            );
                          })()}
                        </div>
                      );
                    }}
                  </ConnectButton.Custom>
                </div>

                {/* Sign Out Button - Refined */}
                <button
                  onClick={signOut}
                  className="hidden lg:inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg text-gray-600 backdrop-blur-sm bg-white/50 hover:bg-gray-100/70 hover:scale-105 transition-all duration-300 border border-gray-200/60"
                >
                  <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                  </svg>
                  Sign Out
                </button>

                {/* Mobile Menu Button (Hamburger) */}
                <button
                  onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                  className="lg:hidden inline-flex items-center justify-center p-2 rounded-lg text-gray-600 hover:text-purple-600 hover:bg-gray-100 transition-all duration-300"
                  aria-label="Toggle menu"
                >
                  {mobileMenuOpen ? (
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                  ) : (
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16"/>
                    </svg>
                  )}
                </button>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Mobile Slide-out Menu */}
      {mobileMenuOpen && (
        <>
          {/* Backdrop */}
          <div
            className="fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden animate-fade-in"
            onClick={() => setMobileMenuOpen(false)}
          ></div>

          {/* Menu Panel */}
          <div className="fixed top-16 right-0 bottom-0 w-80 backdrop-blur-xl bg-white/95 shadow-2xl z-50 lg:hidden animate-slide-in-right overflow-y-auto border-l border-white/60">
            <div className="p-6 space-y-6">
              {/* User Profile Section */}
              {user && (
                <div className="flex items-center gap-3 pb-6 border-b border-purple-100/60">
                  {user.pfpUrl && (
                    <Image
                      src={user.pfpUrl}
                      alt={user.username}
                      width={48}
                      height={48}
                      className="rounded-full ring-2 ring-purple-200/50"
                    />
                  )}
                  <div>
                    <p className="text-sm font-semibold text-gray-900">@{user.username}</p>
                    <p className="text-xs text-gray-500">Farcaster User</p>
                  </div>
                </div>
              )}

              {/* Navigation Links */}
              <div className="space-y-2">
                <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3">Navigation</p>
                {navItems.map((item) => {
                  const isActive = pathname === item.href;
                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      onClick={() => setMobileMenuOpen(false)}
                      className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-300 ${
                        isActive
                          ? 'text-purple-600 backdrop-blur-sm bg-purple-50/70 border border-purple-200/60'
                          : 'text-gray-700 hover:text-purple-600 hover:bg-gray-50/50'
                      }`}
                    >
                      {item.label}
                      {isActive && (
                        <span className="ml-auto w-2 h-2 bg-gradient-to-r from-purple-600 to-blue-600 rounded-full"></span>
                      )}
                    </Link>
                  );
                })}
              </div>

              {/* Wallet Section */}
              <div className="space-y-3 pt-4 border-t border-purple-100/60">
                <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3">Wallet</p>

                {/* Verified Badge */}
                {isVerified ? (
                  <div className="flex items-center gap-2 px-3 py-2.5 rounded-lg backdrop-blur-sm bg-emerald-50/70 border border-emerald-200/60">
                    <svg className="w-4 h-4 text-emerald-600" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"/>
                    </svg>
                    <span className="text-sm font-medium text-emerald-700">Verified On-Chain</span>
                  </div>
                ) : (
                  <Link
                    href="/mini/contract-test"
                    onClick={() => setMobileMenuOpen(false)}
                    className="flex items-center gap-2 px-3 py-2.5 rounded-lg text-sm font-medium text-white backdrop-blur-sm bg-gradient-to-r from-purple-500/90 to-blue-500/90 border border-purple-300/40 hover:from-purple-600 hover:to-blue-600 transition-all duration-300"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                    </svg>
                    <span>Verify Wallet</span>
                  </Link>
                )}

                {/* Wallet Address */}
                {isConnected && address && (
                  <div className="flex items-center gap-2 px-3 py-2.5 rounded-lg backdrop-blur-sm bg-blue-50/60 border border-blue-200/60">
                    <svg className="w-4 h-4 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
                    </svg>
                    <span className="text-xs font-mono text-gray-600">{formatAddress(address)}</span>
                  </div>
                )}

                {/* Connect Wallet Button */}
                <div className="pt-2">
                  <ConnectButton.Custom>
                    {({
                      account,
                      chain,
                      openAccountModal,
                      openChainModal,
                      openConnectModal,
                      mounted,
                    }) => {
                      const ready = mounted;
                      const connected = ready && account && chain;

                      if (!ready) return null;

                      if (!connected) {
                        return (
                          <button
                            onClick={openConnectModal}
                            type="button"
                            className="w-full flex items-center justify-center gap-2 px-3 py-2.5 rounded-lg text-sm font-medium backdrop-blur-sm bg-gray-100/70 text-gray-700 hover:bg-gray-200/70 transition-all duration-300 border border-gray-200/60"
                          >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"/>
                            </svg>
                            Connect Wallet
                          </button>
                        );
                      }

                      if (chain.unsupported) {
                        return (
                          <button
                            onClick={openChainModal}
                            type="button"
                            className="w-full flex items-center justify-center gap-2 px-3 py-2.5 rounded-lg text-sm font-medium backdrop-blur-sm bg-red-100/70 text-red-700 hover:bg-red-200/70 transition-all duration-300 border border-red-200/60"
                          >
                            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd"/>
                            </svg>
                            Switch Network
                          </button>
                        );
                      }

                      return (
                        <button
                          onClick={openAccountModal}
                          type="button"
                          className="w-full flex items-center justify-center gap-2 px-3 py-2.5 rounded-lg text-sm font-medium backdrop-blur-sm bg-blue-50/70 text-blue-700 hover:bg-blue-100/70 transition-all duration-300 border border-blue-200/60"
                        >
                          {chain.hasIcon && (
                            <div
                              className="w-4 h-4 rounded-full overflow-hidden"
                              style={{
                                background: chain.iconBackground,
                              }}
                            >
                              {chain.iconUrl && (
                                <img
                                  alt={chain.name ?? 'Chain icon'}
                                  src={chain.iconUrl}
                                  className="w-4 h-4"
                                />
                              )}
                            </div>
                          )}
                          {chain.name}
                        </button>
                      );
                    }}
                  </ConnectButton.Custom>
                </div>
              </div>

              {/* Sign Out Button */}
              <div className="pt-4 border-t border-purple-100/60">
                <button
                  onClick={() => {
                    signOut();
                    setMobileMenuOpen(false);
                  }}
                  className="w-full flex items-center justify-center gap-2 px-3 py-2.5 rounded-lg text-sm font-medium text-red-600 backdrop-blur-sm bg-red-50/70 hover:bg-red-100/70 transition-all duration-300 border border-red-200/60"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                  </svg>
                  Sign Out
                </button>
              </div>
            </div>
          </div>
        </>
      )}
    </nav>
  );
}
