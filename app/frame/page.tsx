'use client';

import { useState, useEffect } from 'react';
import { AuthKitProvider, useProfile } from '@farcaster/auth-kit';

// Frame Preview Component
function FramePreview() {
  const { profile, isAuthenticated } = useProfile();
  const [currentStep, setCurrentStep] = useState<'initial' | 'matching' | 'stats'>('initial');
  const [buttonLoading, setButtonLoading] = useState<number | null>(null);
  const [frameUrl, setFrameUrl] = useState('https://meetshipper.com/api/frame');

  // Use relative path - Next.js serves files from public/ at root automatically
  const FRAME_IMAGE = '/cover.png';

  // Update frame URL after component mounts to match current origin
  useEffect(() => {
    setFrameUrl(`${window.location.origin}/api/frame`);
  }, []);

  const handleButtonClick = async (buttonIndex: number) => {
    setButtonLoading(buttonIndex);

    // Simulate frame interaction
    setTimeout(() => {
      if (buttonIndex === 1) {
        setCurrentStep('matching');
      } else if (buttonIndex === 2) {
        setCurrentStep('stats');
      } else if (buttonIndex === 3) {
        // Redirect to contract test page
        window.location.href = `/mini/contract-test${profile?.fid ? `?fid=${profile.fid}` : ''}`;
      }
      setButtonLoading(null);
    }, 500);
  };

  const getButtons = () => {
    switch (currentStep) {
      case 'matching':
        return [
          { label: '🎯 Finding Match...', action: () => setCurrentStep('initial') },
          { label: 'View Profile', action: () => setCurrentStep('stats') },
          { label: 'Open App', action: () => handleButtonClick(3) },
        ];
      case 'stats':
        return [
          { label: '« Back', action: () => setCurrentStep('initial') },
          { label: 'Refresh Stats', action: () => setCurrentStep('stats') },
          { label: 'Open Dashboard', action: () => handleButtonClick(3) },
        ];
      default:
        return [
          { label: 'Start Match', action: () => handleButtonClick(1) },
          { label: 'View Stats', action: () => handleButtonClick(2) },
          { label: 'Verify on Base', action: () => handleButtonClick(3) },
        ];
    }
  };

  const buttons = getButtons();

  return (
    <div className="relative min-h-screen flex flex-col items-center justify-center p-4 bg-gradient-to-br from-purple-600 via-indigo-600 to-blue-600">
      {/* Top-left back link */}
      <a
        href="https://www.meetshipper.com"
        target="_blank"
        rel="noopener noreferrer"
        className="absolute top-6 left-6 text-white/90 text-base font-semibold hover:text-purple-300 transition-colors duration-300 animate-fade-in-left z-10"
      >
        ← Back to MeetShipper Website
      </a>

      {/* Right-center status message */}
      <div className="absolute right-4 md:right-10 top-1/2 transform -translate-y-1/2 text-lg md:text-2xl lg:text-3xl font-semibold drop-shadow-lg animate-floating-fade z-10 max-w-xs md:max-w-sm text-right">
        <span className="bg-gradient-to-r from-purple-300 via-pink-300 to-blue-400 bg-clip-text text-transparent">
          We're currently in development — stay tuned! 🚀
        </span>
      </div>

      <div className="max-w-2xl w-full">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl md:text-5xl font-bold text-white mb-3">
            MeetShipper Frame Preview
          </h1>
          <p className="text-white/90 text-lg">
            Base Mini App • Farcaster Frame
          </p>
          {profile && (
            <div className="mt-4 inline-block px-4 py-2 bg-white/10 backdrop-blur-sm rounded-full text-white">
              Connected as FID: <span className="font-semibold">{profile.fid}</span>
            </div>
          )}
        </div>

        {/* Frame Container */}
        <div className="bg-white rounded-2xl shadow-2xl overflow-hidden">
          {/* Frame Image */}
          <div className="relative aspect-[1.91/1] bg-gray-100">
            <img
              src={FRAME_IMAGE}
              alt="Frame Preview"
              className="w-full h-full object-cover"
              onError={(e) => {
                const target = e.target as HTMLImageElement;
                target.style.display = 'none';
                target.parentElement!.innerHTML = `
                  <div class="w-full h-full flex items-center justify-center bg-gradient-to-br from-purple-500 to-blue-500">
                    <div class="text-center text-white p-8">
                      <h2 class="text-3xl font-bold mb-2">MeetShipper</h2>
                      <p class="text-xl">Find Your Perfect Match on Base</p>
                      <p class="mt-4 text-sm opacity-80">Add your cover image at /public/frame/cover.png</p>
                    </div>
                  </div>
                `;
              }}
            />
          </div>

          {/* Frame Buttons */}
          <div className="p-4 bg-gray-50 border-t border-gray-200">
            <div className="grid grid-cols-3 gap-3">
              {buttons.map((button, idx) => (
                <button
                  key={idx}
                  onClick={button.action}
                  disabled={buttonLoading !== null}
                  className={`
                    px-4 py-3 rounded-lg font-semibold text-sm
                    transition-all duration-200 transform
                    ${
                      buttonLoading === idx + 1
                        ? 'bg-indigo-400 text-white scale-95'
                        : 'bg-indigo-600 hover:bg-indigo-700 text-white hover:scale-105'
                    }
                    disabled:opacity-50 disabled:cursor-not-allowed
                    shadow-md hover:shadow-lg
                  `}
                >
                  {buttonLoading === idx + 1 ? (
                    <span className="flex items-center justify-center">
                      <svg
                        className="animate-spin h-4 w-4 mr-2"
                        xmlns="http://www.w3.org/2000/svg"
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
                      Loading...
                    </span>
                  ) : (
                    button.label
                  )}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Info Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-8">
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-white">
            <h3 className="font-semibold text-lg mb-2">📱 Frame Info</h3>
            <p className="text-sm text-white/80">
              This is a preview of your Farcaster Frame. Share the frame URL in Farcaster to enable
              interactive buttons.
            </p>
            <div className="mt-4 p-3 bg-black/20 rounded-lg">
              <a
                href={frameUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-xs font-mono break-all text-white hover:text-blue-300 hover:underline transition-colors"
              >
                🔗 {frameUrl}
              </a>
            </div>
          </div>

          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-white">
            <h3 className="font-semibold text-lg mb-2">⛓️ Base Chain</h3>
            <p className="text-sm text-white/80">
              This frame is configured for Base L2. Users can verify their identity and create
              attestations on-chain.
            </p>
            <div className="mt-4 flex items-center space-x-2">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
              <span className="text-xs font-semibold">Base Network Ready</span>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-8 text-center text-white/70 text-sm">
          <p>Built with Next.js, Farcaster AuthKit, and EAS on Base</p>
          <p className="mt-2">
            <a href="/mini/contract-test" className="text-white hover:underline font-semibold">
              Go to Contract Test →
            </a>
          </p>
        </div>
      </div>
    </div>
  );
}

// Main Page Component with Auth Provider
export default function FramePage() {
  return (
    <AuthKitProvider>
      <FramePreview />
    </AuthKitProvider>
  );
}