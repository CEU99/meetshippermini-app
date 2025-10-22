'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { apiClient } from '@/lib/api-client';
import { Avatar } from '@/components/shared/Avatar';

export interface UserProfile {
  fid: number;
  username: string;
  display_name?: string;
  avatar_url?: string;
  bio?: string;
  user_code?: string;
}

interface UserLookupProps {
  label: string;
  value: UserProfile | null;
  onChange: (user: UserProfile | null) => void;
  onManualFidChange?: (fid: string) => void; // For manual FID input binding
  currentUserFid?: number;
  excludeFid?: number; // Exclude this FID from being selected (e.g., prevent duplicate A/B)
  disabled?: boolean;
  slot?: 'a' | 'b'; // Which slot this is for (used when navigating to Explore Users)
}

export function UserLookup({
  label,
  value,
  onChange,
  onManualFidChange,
  currentUserFid,
  excludeFid,
  disabled = false,
  slot,
}: UserLookupProps) {
  const router = useRouter();
  const [userInput, setUserInput] = useState('');
  const [lookingUpUser, setLookingUpUser] = useState(false);
  const [error, setError] = useState('');
  const [manualMode, setManualMode] = useState(false);

  const lookupUser = async (fidInput?: string) => {
    const inputToLookup = fidInput || userInput;

    if (!inputToLookup.trim()) {
      setError('Please enter a User ID (FID)');
      return;
    }

    setLookingUpUser(true);
    setError('');

    try {
      const fidMatch = inputToLookup.match(/^\d+$/);
      if (!fidMatch) {
        setError('Please enter a valid numeric FID');
        setLookingUpUser(false);
        return;
      }

      const fid = parseInt(inputToLookup);

      // Check if trying to match with themselves
      if (currentUserFid && fid === currentUserFid) {
        setError('You cannot select yourself');
        setLookingUpUser(false);
        return;
      }

      // Check if trying to select the excluded FID
      if (excludeFid && fid === excludeFid) {
        setError('This user is already selected for the other position');
        setLookingUpUser(false);
        return;
      }

      const data = await apiClient.get<UserProfile>(`/api/users/${fid}`);
      onChange(data);
      setUserInput('');
      setManualMode(false);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error('Error looking up user:', error);
      setError(errorMessage || 'User not found. Please check the FID and try again.');
    } finally {
      setLookingUpUser(false);
    }
  };

  const handleManualFidChange = (fid: string) => {
    setUserInput(fid);
    if (onManualFidChange) {
      onManualFidChange(fid);
    }
  };

  const handleEnterManualMode = () => {
    setManualMode(true);
    onChange(null);
    setUserInput('');
    setError('');
  };

  const handleExitManualMode = () => {
    setManualMode(false);
    setUserInput('');
    setError('');
  };

  return (
    <div className="mb-6">
      <label className="block text-sm font-medium text-gray-700 mb-2">
        {label} <span className="text-red-600">*</span>
      </label>

      {!value ? (
        <div className="space-y-3">
          <div className="flex gap-2">
            <input
              type="text"
              value={userInput}
              onChange={(e) => handleManualFidChange(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  lookupUser();
                }
              }}
              placeholder="e.g., 12345"
              className="flex-1 px-4 py-2 border border-gray-300 rounded-md focus:ring-purple-500 focus:border-purple-500 text-gray-900 placeholder:text-gray-400"
              disabled={lookingUpUser || disabled}
            />
            <button
              type="button"
              onClick={() => lookupUser()}
              disabled={lookingUpUser || !userInput.trim() || disabled}
              className="px-6 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:bg-gray-300 disabled:cursor-not-allowed font-medium transition-colors"
            >
              {lookingUpUser ? 'Looking up...' : 'Lookup'}
            </button>
          </div>

          {/* Find User button - Navigate to Users */}
          <button
            type="button"
            onClick={() => router.push('/users')}
            disabled={disabled}
            className="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 font-medium text-sm disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
          >
            <svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
            Find User
          </button>

          <p className="text-sm text-gray-500">
            Enter a Farcaster ID (FID) like &quot;12345&quot; or browse users
          </p>
          {error && (
            <div className="flex items-start gap-2 p-3 bg-red-50 border border-red-200 rounded-md">
              <svg className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
              </svg>
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}
        </div>
      ) : (
        <div className="space-y-3">
          <div className="flex items-center justify-between p-4 border-2 border-purple-200 rounded-md bg-purple-50">
            <div className="flex items-center space-x-3">
              <Avatar
                src={value.avatar_url}
                alt={value.display_name || value.username}
                size={48}
              />
              <div>
                <p className="font-medium text-gray-900">
                  {value.display_name || value.username}
                </p>
                <p className="text-sm text-gray-600">@{value.username}</p>
                {value.bio && (
                  <p className="text-xs text-gray-500 mt-1 line-clamp-2 max-w-md">
                    {value.bio}
                  </p>
                )}
              </div>
            </div>
            <button
              type="button"
              onClick={() => {
                if (slot) {
                  // Navigate to Users page with slot parameter
                  router.push(`/users?slot=${slot.toUpperCase()}`);
                } else {
                  // Fallback: Navigate to Users without slot
                  router.push('/users');
                }
              }}
              disabled={disabled}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 font-medium text-sm disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
            >
              Change
            </button>
          </div>

          {/* Manual FID Entry Button */}
          <button
            type="button"
            onClick={handleEnterManualMode}
            disabled={disabled}
            className="w-full px-4 py-2 border-2 border-gray-300 rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 font-medium text-sm flex items-center justify-center disabled:bg-gray-100 disabled:cursor-not-allowed transition-colors"
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
                d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
              />
            </svg>
            Manual USER ID (FID)
          </button>
        </div>
      )}
    </div>
  );
}
