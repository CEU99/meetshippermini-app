'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useFarcasterAuth } from '@/components/providers/FarcasterAuthProvider';
import { Navigation } from '@/components/shared/Navigation';
import { apiClient, ApiError } from '@/lib/api-client';
import {
  AVAILABLE_TRAITS,
  MIN_TRAITS,
  MAX_TRAITS,
  getTraitColor,
  type Trait,
} from '@/lib/constants/traits';

const MAX_BIO_LENGTH = 100;

export default function EditProfile() {
  const router = useRouter();
  const { user, isAuthenticated, loading: authLoading } = useFarcasterAuth();

  // Form state - will be loaded from API
  const [bio, setBio] = useState('');
  const [selectedTraits, setSelectedTraits] = useState<Trait[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  // Redirect if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [isAuthenticated, authLoading, router]);

  // Load existing profile data when user is authenticated
  useEffect(() => {
    if (isAuthenticated && user) {
      loadProfile();
    }
  }, [isAuthenticated, user]);

  const loadProfile = async () => {
    try {
      setLoading(true);
      const data = await apiClient.get<{
        bio: string;
        traits: string[];
      }>('/api/profile');

      setBio(data.bio || '');
      setSelectedTraits((data.traits || []) as Trait[]);
    } catch (err) {
      console.error('Failed to load profile:', err);
      // Don't show error to user - just start with empty form
      setBio('');
      setSelectedTraits([]);
    } finally {
      setLoading(false);
    }
  };

  const toggleTrait = (trait: Trait) => {
    setSelectedTraits((prev) => {
      if (prev.includes(trait)) {
        return prev.filter((t) => t !== trait);
      } else {
        if (prev.length >= MAX_TRAITS) {
          setError(`You can select at most ${MAX_TRAITS} traits`);
          setTimeout(() => setError(null), 3000);
          return prev;
        }
        setError(null);
        return [...prev, trait];
      }
    });
  };

  const handleSave = async () => {
    try {
      setError(null);
      setSuccess(false);

      // Validate traits count
      if (selectedTraits.length < MIN_TRAITS) {
        setError(`Please select at least ${MIN_TRAITS} traits`);
        return;
      }

      if (selectedTraits.length > MAX_TRAITS) {
        setError(`You can select at most ${MAX_TRAITS} traits`);
        return;
      }

      // Validate bio length
      if (bio.length > MAX_BIO_LENGTH) {
        setError(`Bio must be ${MAX_BIO_LENGTH} characters or less`);
        return;
      }

      setSaving(true);

      const response = await apiClient.patch<{
        ok: boolean;
        profile: {
          bio: string;
          traits: string[];
        };
      }>('/api/profile', {
        bio,
        traits: selectedTraits,
      });

      if (response.ok) {
        setSuccess(true);
        console.log('[EditProfile] ✅ Profile updated successfully:', response.profile);

        // Dispatch custom event to notify Dashboard to refresh
        if (typeof window !== 'undefined') {
          window.dispatchEvent(new CustomEvent('profile-updated', {
            detail: response.profile
          }));
        }

        // Redirect to dashboard after short delay
        setTimeout(() => {
          router.push('/dashboard');
        }, 1500);
      }
    } catch (err) {
      console.error('Failed to save profile:', err);

      // Handle specific error types
      if (err instanceof ApiError) {
        if (err.data?.error === 'MIGRATION_REQUIRED') {
          setError(
            '⚠️ Database migration required. Please run the profile migration SQL in Supabase SQL Editor, then try again.'
          );
        } else if (err.data?.error === 'SCHEMA_CACHE_ERROR') {
          setError(
            '⚠️ Schema cache error. Please run: SELECT reload_pgrst_schema(); in Supabase SQL Editor, then try again.'
          );
        } else {
          setError(err.data?.error || err.message || 'Failed to save profile');
        }
      } else {
        setError('Failed to save profile. Please try again.');
      }
    } finally {
      setSaving(false);
    }
  };

  const handleResetBio = async () => {
    try {
      // Confirm before resetting
      if (!window.confirm('Are you sure you want to clear your bio? This will permanently delete your bio text.')) {
        return;
      }

      setError(null);
      setSuccess(false);
      setSaving(true);

      // Update bio to empty string in database
      const response = await apiClient.patch<{
        ok: boolean;
        profile: {
          bio: string;
          traits: string[];
        };
      }>('/api/profile', {
        bio: '',
        traits: selectedTraits,
      });

      if (response.ok) {
        setBio('');
        console.log('[EditProfile] ✅ Bio reset successfully');

        // Dispatch custom event to notify Dashboard
        if (typeof window !== 'undefined') {
          window.dispatchEvent(new CustomEvent('profile-updated', {
            detail: response.profile
          }));
        }

        setSuccess(true);
        setTimeout(() => setSuccess(false), 3000);
      }
    } catch (err) {
      console.error('Failed to reset bio:', err);
      setError('Failed to reset bio. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const handleResetTraits = async () => {
    try {
      // Confirm before resetting
      if (!window.confirm('Are you sure you want to reset all personal traits? This will permanently clear your selected traits.')) {
        return;
      }

      setError(null);
      setSuccess(false);
      setSaving(true);

      // Update traits to empty array in database
      const response = await apiClient.patch<{
        ok: boolean;
        profile: {
          bio: string;
          traits: string[];
        };
      }>('/api/profile', {
        bio,
        traits: [],
      });

      if (response.ok) {
        setSelectedTraits([]);
        console.log('[EditProfile] ✅ Traits reset successfully');

        // Dispatch custom event to notify Dashboard
        if (typeof window !== 'undefined') {
          window.dispatchEvent(new CustomEvent('profile-updated', {
            detail: response.profile
          }));
        }

        setSuccess(true);
        setTimeout(() => setSuccess(false), 3000);
      }
    } catch (err) {
      console.error('Failed to reset traits:', err);
      setError('Failed to reset traits. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  // Show loading for both auth and profile data
  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  const isValid = selectedTraits.length >= MIN_TRAITS && selectedTraits.length <= MAX_TRAITS;

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Edit Profile</h1>
          <p className="mt-2 text-gray-600">
            Update your bio and select traits that describe you
          </p>
        </div>

        {/* Error Message */}
        {error && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-sm text-red-700 whitespace-pre-line">{error}</p>
          </div>
        )}

        {/* Success Message */}
        {success && (
          <div className="mb-6 bg-green-50 border border-green-200 rounded-lg p-4">
            <p className="text-sm text-green-700">
              ✅ Profile updated successfully! Redirecting to dashboard...
            </p>
          </div>
        )}

        {/* Bio Section */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-8">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Bio</h2>
          <textarea
            value={bio}
            onChange={(e) => setBio(e.target.value.slice(0, MAX_BIO_LENGTH))}
            placeholder="Tell us about yourself... (optional)"
            maxLength={MAX_BIO_LENGTH}
            rows={3}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent resize-none text-black placeholder-gray-400"
          />
          <div className="mt-2 flex items-center justify-between">
            <button
              onClick={handleResetBio}
              disabled={saving || bio.length === 0}
              className="px-4 py-2 bg-red-500 text-white rounded-lg font-medium hover:bg-red-600 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors text-sm"
            >
              Reset Bio
            </button>
            <p className="text-sm text-gray-500">
              {bio.length} / {MAX_BIO_LENGTH} characters
            </p>
          </div>
        </div>

        {/* Traits Section */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-8">
          <div className="mb-4">
            <h2 className="text-xl font-bold text-gray-900">
              Personal Traits
            </h2>
            <p className="mt-1 text-sm text-gray-600">
              Select {MIN_TRAITS}-{MAX_TRAITS} traits that best describe you
            </p>
            <p
              className={`mt-1 text-sm font-medium ${
                isValid ? 'text-green-600' : 'text-purple-600'
              }`}
            >
              Selected: {selectedTraits.length} / {MAX_TRAITS}
              {isValid && ' ✓'}
            </p>
          </div>

          {/* Trait Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3">
            {AVAILABLE_TRAITS.map((trait) => {
              const isSelected = selectedTraits.includes(trait);
              const colorClass = getTraitColor(trait);

              return (
                <button
                  key={trait}
                  onClick={() => toggleTrait(trait)}
                  className={`
                    px-3 py-2 rounded-lg border-2 text-sm font-medium
                    transition-all duration-200
                    ${
                      isSelected
                        ? `${colorClass} ring-2 ring-offset-2 ring-purple-500`
                        : 'bg-gray-50 text-gray-700 border-gray-200 hover:border-gray-300 hover:bg-gray-100'
                    }
                  `}
                >
                  {trait}
                </button>
              );
            })}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center justify-between">
          <button
            onClick={() => router.push('/dashboard')}
            className="px-6 py-3 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition-colors"
            disabled={saving}
          >
            Cancel
          </button>
          <div className="flex items-center space-x-3">
            <button
              onClick={handleResetTraits}
              disabled={saving || selectedTraits.length === 0}
              className="px-6 py-3 bg-red-500 text-white rounded-lg font-medium hover:bg-red-600 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
            >
              Reset Personal Traits
            </button>
            <button
              onClick={handleSave}
              disabled={saving || !isValid}
              className="px-6 py-3 bg-purple-600 text-white rounded-lg font-medium hover:bg-purple-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
            >
              {saving ? 'Saving...' : 'Save Profile'}
            </button>
          </div>
        </div>

        {/* Validation hint */}
        {!isValid && selectedTraits.length > 0 && (
          <p className="mt-4 text-center text-sm text-gray-500">
            {selectedTraits.length < MIN_TRAITS
              ? `Select at least ${MIN_TRAITS - selectedTraits.length} more trait${
                  MIN_TRAITS - selectedTraits.length === 1 ? '' : 's'
                }`
              : `Remove ${selectedTraits.length - MAX_TRAITS} trait${
                  selectedTraits.length - MAX_TRAITS === 1 ? '' : 's'
                }`}
          </p>
        )}
      </div>
    </div>
  );
}
