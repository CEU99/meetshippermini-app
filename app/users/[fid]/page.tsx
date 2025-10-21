'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import { Navigation } from '@/components/shared/Navigation';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';
import { getTraitColor, type Trait } from '@/lib/constants/traits';
import { Avatar } from '@/components/shared/Avatar';

interface UserProfile {
  fid: number;
  username: string;
  display_name?: string;
  avatar_url?: string;
  bio?: string;
  user_code?: string;
  traits?: string[];
  created_at?: string;
  updated_at?: string;
}

export default function UserProfilePage() {
  const router = useRouter();
  const params = useParams();
  const fid = params.fid as string;
  const { isAuthenticated, loading: authLoading } = useFarcasterAuth();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, authLoading, router]);

  // Fetch user profile
  useEffect(() => {
    if (isAuthenticated && fid) {
      fetchProfile();
    }
  }, [isAuthenticated, fid]);

  const fetchProfile = async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await apiClient.get<UserProfile>(`/api/users/${fid}`);
      setProfile(data);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      console.error('Error fetching user profile:', err);
      setError(errorMessage || 'Failed to load user profile');
    } finally {
      setLoading(false);
    }
  };

  // Loading state
  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading profile...</p>
        </div>
      </div>
    );
  }

  // Error state
  if (error || !profile) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Navigation />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="bg-red-50 border border-red-200 rounded-lg p-6">
            <h2 className="text-lg font-semibold text-red-800 mb-2">Error Loading Profile</h2>
            <p className="text-red-600">{error || 'User not found'}</p>
            <Link
              href="/users"
              className="mt-4 inline-flex items-center text-sm text-red-600 hover:text-red-800 underline"
            >
              ← Back to Users
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Back button */}
        <Link
          href="/users"
          className="inline-flex items-center text-sm text-purple-600 hover:text-purple-800 mb-6"
        >
          <svg
            className="w-4 h-4 mr-1"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M10 19l-7-7m0 0l7-7m-7 7h18"
            />
          </svg>
          Back to Users
        </Link>

        {/* Profile Card */}
        <div className="bg-white rounded-lg shadow-md p-8">
          <div className="flex items-start space-x-6">
            {/* Avatar */}
            <div className="flex-shrink-0">
              <Avatar
                src={profile.avatar_url}
                alt={profile.display_name || profile.username}
                size={120}
              />
            </div>

            {/* Profile Info */}
            <div className="flex-1">
              <h1 className="text-3xl font-bold text-gray-900 mb-2">
                {profile.display_name || profile.username}
              </h1>
              <p className="text-xl text-gray-600 mb-4">@{profile.username}</p>

              {/* Bio */}
              {profile.bio && (
                <div className="mb-6">
                  <p className="text-gray-700 leading-relaxed">{profile.bio}</p>
                </div>
              )}

              {/* Traits */}
              {profile.traits && profile.traits.length > 0 && (
                <div className="mb-6">
                  <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
                    Personal Traits
                  </h3>
                  <div className="flex flex-wrap gap-2">
                    {profile.traits.map((trait) => (
                      <span
                        key={trait}
                        className={`px-4 py-2 rounded-lg text-sm font-medium border ${getTraitColor(
                          trait as Trait
                        )}`}
                      >
                        {trait}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* User Details Grid */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                <div className="bg-gray-50 rounded-lg p-4">
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">
                    Farcaster ID
                  </p>
                  <p className="text-lg font-mono text-gray-900">{profile.fid}</p>
                </div>

                {profile.user_code && (
                  <div className="bg-gradient-to-r from-purple-50 to-blue-50 rounded-lg p-4 border border-purple-200">
                    <p className="text-xs font-semibold text-purple-700 uppercase tracking-wider mb-1">
                      User Code
                    </p>
                    <p className="text-lg font-mono font-bold text-purple-900">
                      {profile.user_code}
                    </p>
                  </div>
                )}

                {profile.created_at && (
                  <div className="bg-gray-50 rounded-lg p-4">
                    <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">
                      Member Since
                    </p>
                    <p className="text-lg text-gray-900">
                      {new Date(profile.created_at).toLocaleDateString('en-US', {
                        month: 'short',
                        year: 'numeric',
                      })}
                    </p>
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div className="flex flex-wrap gap-3">
                <Link
                  href={`/mini/create?targetFid=${profile.fid}`}
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500"
                >
                  <svg
                    className="w-4 h-4 mr-2"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M12 4v16m8-8H4"
                    />
                  </svg>
                  Create Match
                </Link>

                <a
                  href={`https://warpcast.com/${profile.username}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500"
                >
                  <svg
                    className="w-4 h-4 mr-2"
                    fill="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path d="M12 2L2 7v10c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7l-10-5z" />
                  </svg>
                  View on Warpcast
                </a>
              </div>
            </div>
          </div>
        </div>

        {/* Additional Info */}
        <div className="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
          <p className="text-sm text-blue-800">
            <strong>Note:</strong> This is a basic profile view. More features like match history,
            mutual connections, and messaging will be added in future updates.
          </p>
        </div>
      </div>
    </div>
  );
}
