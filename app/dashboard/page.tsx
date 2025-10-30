'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import { Navigation } from '@/components/shared/Navigation';
import Image from 'next/image';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';
import { getTraitColor, type Trait } from '@/lib/constants/traits';
import { LevelProgress } from '@/components/dashboard/LevelProgress';
import { useAttestationStatus } from '@/lib/hooks/useAttestationStatus';
import VerifiedInsights from '@/components/dashboard/VerifiedInsights';
import GrowthDashboard from '@/components/dashboard/GrowthDashboard';
import PointLeaderboard from '@/components/dashboard/PointLeaderboard';
import InboxOverview from '@/components/dashboard/InboxOverview';
import AchievementsSummary from '@/components/dashboard/AchievementsSummary';

interface MatchStats {
  total: number;
  pending: number;
  accepted: number;
  asCreator: number;
}

interface ProfileData {
  bio: string;
  traits: string[];
}

export default function Dashboard() {
  const router = useRouter();
  const { user, isAuthenticated, loading } = useFarcasterAuth();
  const { isVerified, isLoading: isCheckingVerification } = useAttestationStatus();
  const [stats, setStats] = useState<MatchStats>({
    total: 0,
    pending: 0,
    accepted: 0,
    asCreator: 0,
  });
  const [profile, setProfile] = useState<ProfileData>({ bio: '', traits: [] });
  const [loadingStats, setLoadingStats] = useState(true);
  const [loadingProfile, setLoadingProfile] = useState(true);
  const [showVerifiedTooltip, setShowVerifiedTooltip] = useState(false);

  useEffect(() => {
    if (!loading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, loading, router]);

  useEffect(() => {
    if (isAuthenticated) {
      fetchStats();
      fetchProfile();
    }
  }, [isAuthenticated]);

  // Refetch profile when page becomes visible (e.g., returning from edit page)
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (!document.hidden && isAuthenticated) {
        console.log('[Dashboard] Page visible, refreshing profile...');
        fetchProfile();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    // Also refetch when window regains focus
    const handleFocus = () => {
      if (isAuthenticated) {
        console.log('[Dashboard] Window focused, refreshing profile...');
        fetchProfile();
      }
    };

    window.addEventListener('focus', handleFocus);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('focus', handleFocus);
    };
  }, [isAuthenticated]);

  // Refetch profile on route change (e.g., navigating back from edit page)
  useEffect(() => {
    if (isAuthenticated) {
      console.log('[Dashboard] Route mounted/changed, refreshing profile...');
      fetchProfile();
    }
  }, [router, isAuthenticated]);

  // Listen for profile-updated events from Edit Profile page
  useEffect(() => {
    const handleProfileUpdate = (event: CustomEvent) => {
      console.log('[Dashboard] Profile update event received, updating state...');
      if (event.detail && isAuthenticated) {
        // Update profile state directly from the event
        setProfile({
          bio: event.detail.bio || '',
          traits: event.detail.traits || [],
        });
        console.log('[Dashboard] Profile state updated:', event.detail);
      }
    };

    window.addEventListener('profile-updated', handleProfileUpdate as EventListener);

    return () => {
      window.removeEventListener('profile-updated', handleProfileUpdate as EventListener);
    };
  }, [isAuthenticated]);

  const fetchStats = async () => {
    try {
      const data = await apiClient.get<{ matches: Array<{ status: string; created_by_fid: number }> }>('/api/matches');

      if (data.matches) {
        const matches = data.matches;
        const stats: MatchStats = {
          total: matches.length,
          pending: matches.filter((m) => m.status === 'pending').length,
          accepted: matches.filter((m) => m.status === 'accepted').length,
          asCreator: matches.filter((m) => m.created_by_fid === user?.fid)
            .length,
        };
        setStats(stats);
      }
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoadingStats(false);
    }
  };

  const fetchProfile = async () => {
    try {
      const data = await apiClient.get<ProfileData>('/api/profile');
      setProfile({
        bio: data.bio || '',
        traits: data.traits || [],
      });
    } catch (error) {
      console.error('Error fetching profile:', error);
      // Silently fail - display nothing if profile data unavailable
      setProfile({ bio: '', traits: [] });
    } finally {
      setLoadingProfile(false);
    }
  };

  if (loading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />

      {/* Animated Banner */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-6">
        <div className="flex justify-end">
          <a
            href="https://www.meetshipper.com/frame"
            target="_blank"
            rel="noopener noreferrer"
            className="
              inline-block
              backdrop-blur-xl
              bg-gradient-to-r from-white/80 via-purple-50/70 to-purple-100/60
              rounded-xl
              shadow-lg
              hover:shadow-2xl
              px-6 py-3
              transition-all duration-300
              hover:scale-105
              hover:from-white/90 hover:via-purple-100/80 hover:to-purple-200/70
              border border-purple-200/40
              animate-fade-slide-up
              group
            "
          >
            <p className="text-sm sm:text-base md:text-lg font-bold text-center bg-gradient-to-r from-purple-700 via-purple-600 to-blue-600 bg-clip-text text-transparent group-hover:from-purple-800 group-hover:via-purple-700 group-hover:to-blue-700 transition-all duration-300">
              MeetShipper — Discover the Miniapp
            </p>
          </a>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Profile Header and Leaderboard Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Profile Header - Takes 2 columns on large screens */}
          <div className="lg:col-span-2">
            <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-blue-50/60 rounded-2xl border border-white/60 shadow-lg hover:shadow-2xl transition-all duration-300 p-8 h-full">
          <div className="flex items-start justify-between mb-4">
            <div className="flex items-start space-x-6 flex-1">
              {user.pfpUrl && (
                <div className="relative group">
                  <div className="absolute inset-0 bg-gradient-to-br from-purple-400 to-blue-400 rounded-full blur opacity-20 group-hover:opacity-40 transition-opacity duration-300"></div>
                  <Image
                    src={user.pfpUrl}
                    alt={user.username}
                    width={96}
                    height={96}
                    className="rounded-full relative z-10 ring-4 ring-white/50"
                  />
                </div>
              )}
              <div className="flex-1">
                <div className="flex items-center gap-3 flex-wrap">
                  <h1 className="text-3xl font-bold bg-gradient-to-r from-gray-900 via-purple-900 to-blue-900 bg-clip-text text-transparent">
                    {user.displayName}
                  </h1>
                  <Link
                    href="/profile/edit"
                    className="px-4 py-2 text-sm bg-white/70 hover:bg-white backdrop-blur-sm text-gray-700 hover:text-purple-700 rounded-xl border border-purple-200/40 hover:border-purple-300 transition-all duration-200 font-medium shadow-sm hover:shadow-md"
                  >
                    Edit Profile
                  </Link>
                </div>
                <div className="flex items-center gap-2 mt-1">
                  <p className="text-lg text-gray-600">@{user.username}</p>

                  {/* Verification Badge */}
                  {!isCheckingVerification && (
                    <div className="relative inline-block">
                      {isVerified ? (
                        <div
                          className="inline-flex items-center px-3 py-1.5 text-xs font-semibold rounded-xl bg-gradient-to-r from-emerald-50 to-green-50 text-emerald-700 border border-emerald-200/60 cursor-help hover:shadow-md transition-all duration-200 backdrop-blur-sm"
                          onMouseEnter={() => setShowVerifiedTooltip(true)}
                          onMouseLeave={() => setShowVerifiedTooltip(false)}
                        >
                          <span className="mr-1.5">✅</span> Verified On-Chain

                          {/* Tooltip */}
                          {showVerifiedTooltip && (
                            <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 bg-gray-900/95 backdrop-blur-sm text-white text-xs rounded-lg whitespace-nowrap shadow-xl z-50 animate-fade-in">
                              Your Farcaster username is verified on-chain
                              <div className="absolute top-full left-1/2 transform -translate-x-1/2 -mt-1">
                                <div className="border-[5px] border-transparent border-t-gray-900"></div>
                              </div>
                            </div>
                          )}
                        </div>
                      ) : (
                        <div className="inline-flex items-center px-3 py-1.5 text-xs font-medium rounded-xl bg-white/70 backdrop-blur-sm text-gray-600 border border-gray-200/60">
                          <span className="mr-1.5">⚪</span> Not Verified
                        </div>
                      )}
                    </div>
                  )}

                  {/* Loading state for verification check */}
                  {isCheckingVerification && (
                    <div className="inline-flex items-center px-3 py-1.5 text-xs font-medium rounded-xl bg-white/70 backdrop-blur-sm text-gray-500 border border-gray-200/60">
                      <svg className="animate-spin h-3.5 w-3.5 mr-1.5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Checking...
                    </div>
                  )}
                </div>

                {/* Bio - from fetched profile data */}
                {!loadingProfile && profile.bio && (
                  <p className="mt-3 text-gray-700 max-w-2xl break-words line-clamp-3 leading-relaxed">{profile.bio}</p>
                )}

                {/* Loading state for profile */}
                {loadingProfile && (
                  <div className="mt-3 h-6 bg-gradient-to-r from-gray-100 to-gray-50 rounded-lg animate-pulse w-64"></div>
                )}

                {/* Trait Cards - from fetched profile data */}
                {!loadingProfile && profile.traits && profile.traits.length > 0 && (
                  <div className="mt-4">
                    <p className="text-xs font-bold text-gray-600 uppercase tracking-wider mb-2.5">
                      Personal Traits
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {profile.traits.map((trait) => (
                        <span
                          key={trait}
                          className={`px-3 py-1.5 rounded-xl text-xs font-semibold border backdrop-blur-sm ${getTraitColor(
                            trait as Trait
                          )}`}
                        >
                          {trait}
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                {/* Loading state for traits */}
                {loadingProfile && (
                  <div className="mt-4">
                    <div className="h-4 bg-gradient-to-r from-gray-100 to-gray-50 rounded-lg animate-pulse w-32 mb-2.5"></div>
                    <div className="flex flex-wrap gap-2">
                      {[1, 2, 3, 4, 5].map((i) => (
                        <div
                          key={i}
                          className="h-8 w-20 bg-gradient-to-r from-gray-100 to-gray-50 rounded-xl animate-pulse"
                        ></div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Level Progress Bar */}
                <LevelProgress />
              </div>
            </div>

            {/* User Code Badge */}
            {user.userCode ? (
              <div className="backdrop-blur-xl bg-gradient-to-br from-purple-100/80 to-blue-100/80 rounded-2xl p-5 border border-purple-200/60 shadow-lg hover:shadow-xl transition-all duration-300">
                <div className="text-center">
                  <p className="text-xs font-bold text-purple-700 uppercase tracking-wider mb-2">
                    User ID
                  </p>
                  <p className="text-2xl font-bold bg-gradient-to-r from-purple-700 to-blue-700 bg-clip-text text-transparent font-mono tracking-widest">
                    {user.userCode}
                  </p>
                  <p className="text-xs text-purple-600 mt-2">
                    10-digit unique code
                  </p>
                </div>
              </div>
            ) : (
              <div className="backdrop-blur-xl bg-gradient-to-br from-yellow-50/80 to-orange-50/80 rounded-2xl p-5 border border-yellow-200/60 shadow-lg">
                <div className="text-center">
                  <p className="text-xs font-bold text-yellow-700 uppercase tracking-wider mb-2">
                    User ID
                  </p>
                  <p className="text-sm text-yellow-700 font-bold">
                    Migration Required
                  </p>
                  <p className="text-xs text-yellow-600 mt-2">
                    Run SQL migration in Supabase
                  </p>
                </div>
              </div>
            )}
          </div>
            </div>
          </div>

          {/* Point Leaderboard - Takes 1 column on large screens */}
          <div className="lg:col-span-1">
            <PointLeaderboard />
          </div>
        </div>

        {/* Inbox Overview and Achievements Summary Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* Inbox Overview - Left side */}
          <div>
            <InboxOverview stats={stats} loading={loadingStats} />
          </div>

          {/* Achievements Summary - Right side */}
          <div>
            <AchievementsSummary />
          </div>
        </div>

        {/* Verification Prompt - Show if user is not verified */}
        {!isCheckingVerification && !isVerified && (
          <div className="mb-8 bg-gradient-to-r from-purple-50 via-blue-50 to-green-50 border-2 border-purple-200 rounded-xl p-6 shadow-lg animate-fade-in">
            <div className="flex items-start gap-4">
              <div className="flex-shrink-0 w-12 h-12 bg-gradient-to-br from-purple-600 to-blue-600 rounded-lg flex items-center justify-center">
                <svg
                  className="w-6 h-6 text-white"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                  />
                </svg>
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold text-gray-900 mb-2">
                  Complete Your Verification
                </h3>
                <p className="text-gray-700 mb-4">
                  You're logged in with Farcaster, but you haven't created an on-chain attestation yet.
                  Complete the verification process to appear in the verified users analytics and unlock all features.
                </p>
                <div className="bg-white rounded-lg p-4 mb-4">
                  <p className="text-sm font-semibold text-gray-700 mb-2">What is verification?</p>
                  <ul className="text-sm text-gray-600 space-y-1 list-disc list-inside">
                    <li>Links your Farcaster account to your wallet on-chain</li>
                    <li>Creates an EAS attestation proving your identity</li>
                    <li>Makes you appear in the verified users dashboard</li>
                    <li>Takes about 2 minutes to complete</li>
                  </ul>
                </div>
                <Link
                  href="/mini/contract-test"
                  className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white font-semibold rounded-lg hover:from-purple-700 hover:to-blue-700 hover:scale-105 hover:shadow-xl transition-all duration-300"
                >
                  <svg
                    className="w-5 h-5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M13 10V3L4 14h7v7l9-11h-7z"
                    />
                  </svg>
                  Start Verification Now
                </Link>
              </div>
            </div>
          </div>
        )}

        {/* Analytics Section */}
        <div className="mb-8 space-y-6">
          <VerifiedInsights />
          <GrowthDashboard />
        </div>

        {/* Quick Actions */}
        <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-blue-50/60 to-purple-50/60 rounded-2xl border border-white/60 shadow-lg hover:shadow-2xl transition-all duration-300 p-8">
          <h2 className="text-xl font-bold bg-gradient-to-r from-gray-900 via-blue-900 to-purple-900 bg-clip-text text-transparent mb-6">
            Quick Actions
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <Link
              href="/mini/create"
              className="group flex items-center p-5 backdrop-blur-xl bg-gradient-to-br from-purple-50/80 to-violet-50/80 rounded-2xl border border-purple-200/60 shadow-lg hover:shadow-2xl transition-all duration-300 hover:-translate-y-1"
            >
              <div className="w-14 h-14 bg-gradient-to-br from-purple-100 to-violet-100 rounded-xl flex items-center justify-center mr-4 transition-transform duration-300 group-hover:scale-110 shadow-sm">
                <svg
                  className="w-7 h-7 text-purple-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2.5}
                    d="M12 4v16m8-8H4"
                  />
                </svg>
              </div>
              <div>
                <h3 className="font-bold text-gray-900 mb-1">
                  Create New Match
                </h3>
                <p className="text-sm text-gray-600">
                  Introduce two friends from your network
                </p>
              </div>
            </Link>

            <Link
              href="/mini/suggest"
              className="group flex items-center p-5 backdrop-blur-xl bg-gradient-to-br from-emerald-50/80 to-green-50/80 rounded-2xl border border-emerald-200/60 shadow-lg hover:shadow-2xl transition-all duration-300 hover:-translate-y-1"
            >
              <div className="w-14 h-14 bg-gradient-to-br from-emerald-100 to-green-100 rounded-xl flex items-center justify-center mr-4 transition-transform duration-300 group-hover:scale-110 shadow-sm">
                <svg
                  className="w-7 h-7 text-emerald-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2.5}
                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                  />
                </svg>
              </div>
              <div>
                <h3 className="font-bold text-gray-900 mb-1">Suggest Match</h3>
                <p className="text-sm text-gray-600">
                  Connect two people from your network
                </p>
              </div>
            </Link>

            <Link
              href="/mini/inbox"
              className="group flex items-center p-5 backdrop-blur-xl bg-gradient-to-br from-blue-50/80 to-cyan-50/80 rounded-2xl border border-blue-200/60 shadow-lg hover:shadow-2xl transition-all duration-300 hover:-translate-y-1"
            >
              <div className="w-14 h-14 bg-gradient-to-br from-blue-100 to-cyan-100 rounded-xl flex items-center justify-center mr-4 transition-transform duration-300 group-hover:scale-110 shadow-sm">
                <svg
                  className="w-7 h-7 text-blue-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2.5}
                    d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
                  />
                </svg>
              </div>
              <div>
                <h3 className="font-bold text-gray-900 mb-1">View Inbox</h3>
                <p className="text-sm text-gray-600">
                  Check your matches and messages
                </p>
              </div>
            </Link>
          </div>
        </div>

        {/* Welcome Message */}
        {stats.total === 0 && !loadingStats && (
          <div className="mt-8 bg-gradient-to-r from-purple-50 to-blue-50 rounded-lg p-8 text-center">
            <h3 className="text-2xl font-bold text-gray-900 mb-2">
              Welcome to Meet Shipper!
            </h3>
            <p className="text-gray-600 mb-6">
              You haven&apos;t created any matches yet. Get started by introducing
              two friends from your Farcaster network.
            </p>
            <Link
              href="/mini/create"
              className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500"
            >
              Create Your First Match
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
