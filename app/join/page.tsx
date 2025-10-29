'use client';

import { Suspense, useEffect, useState } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import Image from 'next/image';

function JoinPageContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const ref = searchParams?.get('ref');

  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);

    // Store referral in localStorage if present
    if (ref) {
      console.log('[Join] Storing referral:', ref);
      localStorage.setItem('meetshipper_referral', ref);
      localStorage.setItem('meetshipper_referral_timestamp', Date.now().toString());
    }
  }, [ref]);

  const handleJoinClick = () => {
    const baseUrl = process.env.NEXT_PUBLIC_BASE_URL ||
                   process.env.NEXT_PUBLIC_APP_URL ||
                   'https://www.meetshipper.com';

    // Redirect to homepage
    window.location.href = baseUrl;
  };

  const getReferralInfo = () => {
    if (!ref) return null;

    if (ref.startsWith('match-')) {
      return {
        type: 'match',
        icon: '🤝',
        text: 'You were invited to a match!',
        description: 'Someone thinks you should connect with another member.',
      };
    } else if (ref.startsWith('suggestion-')) {
      return {
        type: 'suggestion',
        icon: '💡',
        text: 'You received a match suggestion!',
        description: 'Someone suggested you as a great connection.',
      };
    } else {
      return {
        type: 'referral',
        icon: '✨',
        text: 'You were invited to MeetShipper!',
        description: 'Join to see your invitation.',
      };
    }
  };

  const referralInfo = getReferralInfo();

  if (!mounted) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 to-blue-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-blue-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-2xl mx-auto">
        <div className="bg-white rounded-2xl shadow-xl overflow-hidden">
          {/* Header */}
          <div className="bg-gradient-to-r from-purple-600 to-blue-600 px-8 py-12 text-white text-center">
            <div className="text-6xl mb-4">🚀</div>
            <h1 className="text-4xl font-bold mb-3">Join MeetShipper</h1>
            <p className="text-purple-100 text-lg">
              Connect with amazing people on Farcaster
            </p>
          </div>

          {/* Content */}
          <div className="p-8">
            {/* Referral Info */}
            {referralInfo && (
              <div className="mb-8 p-6 bg-gradient-to-r from-purple-50 to-blue-50 rounded-lg border-2 border-purple-200">
                <div className="text-center">
                  <div className="text-5xl mb-3">{referralInfo.icon}</div>
                  <h2 className="text-xl font-bold text-gray-900 mb-2">
                    {referralInfo.text}
                  </h2>
                  <p className="text-gray-600">
                    {referralInfo.description}
                  </p>
                </div>
              </div>
            )}

            {/* Main Content */}
            <div className="text-center mb-8">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">
                Get Started in 3 Easy Steps
              </h2>

              <div className="space-y-4 text-left max-w-md mx-auto mb-8">
                <div className="flex items-start gap-4 p-4 bg-gray-50 rounded-lg">
                  <div className="flex-shrink-0 w-8 h-8 bg-purple-600 text-white rounded-full flex items-center justify-center font-bold">
                    1
                  </div>
                  <div>
                    <h3 className="font-semibold text-gray-900">Visit MeetShipper</h3>
                    <p className="text-sm text-gray-600">Click the button below to go to our homepage</p>
                  </div>
                </div>

                <div className="flex items-start gap-4 p-4 bg-gray-50 rounded-lg">
                  <div className="flex-shrink-0 w-8 h-8 bg-purple-600 text-white rounded-full flex items-center justify-center font-bold">
                    2
                  </div>
                  <div>
                    <h3 className="font-semibold text-gray-900">Sign In with Farcaster</h3>
                    <p className="text-sm text-gray-600">Connect your Farcaster account securely</p>
                  </div>
                </div>

                <div className="flex items-start gap-4 p-4 bg-gray-50 rounded-lg">
                  <div className="flex-shrink-0 w-8 h-8 bg-purple-600 text-white rounded-full flex items-center justify-center font-bold">
                    3
                  </div>
                  <div>
                    <h3 className="font-semibold text-gray-900">Start Connecting</h3>
                    <p className="text-sm text-gray-600">Accept or decline your invitation and explore matches</p>
                  </div>
                </div>
              </div>

              {/* Primary CTA Button */}
              <button
                onClick={handleJoinClick}
                className="w-full max-w-md bg-gradient-to-r from-purple-600 to-blue-600 text-white px-8 py-4 rounded-lg font-bold text-lg hover:from-purple-700 hover:to-blue-700 transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
              >
                Go to MeetShipper.com
              </button>

              <p className="mt-4 text-sm text-gray-500">
                Scan the QR code or click above to get started
              </p>
            </div>

            {/* QR Code Section */}
            <div className="border-t border-gray-200 pt-8">
              <div className="text-center">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  Scan QR Code to Join
                </h3>
                <div className="flex justify-center mb-4">
                  <div className="bg-white p-6 rounded-lg shadow-md border-2 border-gray-200">
                    {/* QR Code placeholder - You can replace this with an actual QR code generator */}
                    <div className="w-48 h-48 bg-gradient-to-br from-purple-100 to-blue-100 rounded-lg flex items-center justify-center">
                      <div className="text-center">
                        <div className="text-4xl mb-2">📱</div>
                        <p className="text-sm font-medium text-gray-700">QR Code</p>
                        <p className="text-xs text-gray-500 mt-1">www.meetshipper.com</p>
                      </div>
                    </div>
                  </div>
                </div>
                <p className="text-sm text-gray-600">
                  Open your camera app and point it at the QR code
                </p>
              </div>
            </div>

            {/* Features */}
            <div className="mt-8 pt-8 border-t border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900 mb-4 text-center">
                Why Join MeetShipper?
              </h3>
              <div className="grid md:grid-cols-3 gap-4">
                <div className="text-center p-4">
                  <div className="text-3xl mb-2">🎯</div>
                  <h4 className="font-semibold text-gray-900 mb-1">Smart Matching</h4>
                  <p className="text-sm text-gray-600">AI-powered connections based on your interests</p>
                </div>
                <div className="text-center p-4">
                  <div className="text-3xl mb-2">🔒</div>
                  <h4 className="font-semibold text-gray-900 mb-1">Privacy First</h4>
                  <p className="text-sm text-gray-600">Your data stays secure and private</p>
                </div>
                <div className="text-center p-4">
                  <div className="text-3xl mb-2">⚡</div>
                  <h4 className="font-semibold text-gray-900 mb-1">Easy to Use</h4>
                  <p className="text-sm text-gray-600">Simple, intuitive interface for everyone</p>
                </div>
              </div>
            </div>

            {/* Debug Info (only in development) */}
            {process.env.NODE_ENV === 'development' && ref && (
              <div className="mt-8 p-4 bg-gray-100 rounded-lg">
                <p className="text-xs text-gray-600 font-mono">
                  <strong>Debug:</strong> Referral stored: {ref}
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Back Button */}
        <div className="mt-6 text-center">
          <button
            onClick={() => router.back()}
            className="text-purple-600 hover:text-purple-700 font-medium"
          >
            ← Go Back
          </button>
        </div>
      </div>
    </div>
  );
}

export default function JoinPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-gradient-to-br from-purple-50 to-blue-50 flex items-center justify-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
        </div>
      }
    >
      <JoinPageContent />
    </Suspense>
  );
}
