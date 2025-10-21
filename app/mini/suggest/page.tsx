'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Navigation } from '@/components/shared/Navigation';
import { apiClient } from '@/lib/api-client';

export default function SuggestMatchPage() {
  const router = useRouter();
  const [userAFid, setUserAFid] = useState('');
  const [userBFid, setUserBFid] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const userAFidNum = parseInt(userAFid);
      const userBFidNum = parseInt(userBFid);

      if (isNaN(userAFidNum) || isNaN(userBFidNum)) {
        setError('Please enter valid numeric FIDs');
        setLoading(false);
        return;
      }

      const response = await apiClient.post('/api/matches/suggestions', {
        userAFid: userAFidNum,
        userBFid: userBFidNum,
        message: message.trim(),
      });

      if (response.success) {
        // Success! Redirect to dashboard
        router.push('/dashboard?suggestion=created');
      }
    } catch (err: any) {
      console.error('Error creating suggestion:', err);
      setError(err.message || 'Failed to create match suggestion');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />

      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            Create a match suggestion between two users
          </h1>
          <p className="text-gray-600">
            Suggest a potential connection between two people in your network
          </p>
        </div>

        {/* How it works */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
          <h2 className="text-lg font-semibold text-blue-900 mb-3 flex items-center">
            <svg
              className="w-5 h-5 mr-2"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fillRule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                clipRule="evenodd"
              />
            </svg>
            How it works
          </h2>
          <p className="text-blue-800 text-sm">
            You can suggest a match between two users along with an introduction
            message. Each of them can accept or decline. If both accept, they
            will earn points and automatically receive a link to a shared chat
            room.
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow p-6">
          {/* User A FID */}
          <div className="mb-6">
            <label
              htmlFor="userAFid"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              User A FID <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              id="userAFid"
              value={userAFid}
              onChange={(e) => setUserAFid(e.target.value)}
              placeholder="Enter User A's Farcaster ID"
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            />
            <p className="text-sm text-gray-500 mt-1">
              The numeric Farcaster ID of the first person
            </p>
          </div>

          {/* User B FID */}
          <div className="mb-6">
            <label
              htmlFor="userBFid"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              User B FID <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              id="userBFid"
              value={userBFid}
              onChange={(e) => setUserBFid(e.target.value)}
              placeholder="Enter User B's Farcaster ID"
              required
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            />
            <p className="text-sm text-gray-500 mt-1">
              The numeric Farcaster ID of the second person
            </p>
          </div>

          {/* Message */}
          <div className="mb-6">
            <label
              htmlFor="message"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Why are you suggesting this match between these two users?{' '}
              <span className="text-red-500">*</span>
            </label>
            <textarea
              id="message"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Explain why you think these two people should connect..."
              required
              rows={5}
              maxLength={500}
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-purple-500 focus:border-transparent resize-none"
            />
            <p className="text-sm text-gray-500 mt-1">
              {message.length}/500 characters
            </p>
          </div>

          {/* Error Display */}
          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
              <p className="text-sm text-red-800">{error}</p>
            </div>
          )}

          {/* What happens next */}
          <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 mb-6">
            <h3 className="text-sm font-semibold text-gray-900 mb-2">
              What happens next:
            </h3>
            <ul className="text-sm text-gray-700 space-y-1 list-disc list-inside">
              <li>
                Both users will receive your match suggestion and message in
                their inbox
              </li>
              <li>Each of them can accept or decline the suggestion</li>
              <li>
                If accepted: Both users will earn points and receive an
                automatic chat room link
              </li>
              <li>
                If declined: You'll be notified (7-day cooldown applies)
              </li>
            </ul>
          </div>

          {/* Buttons */}
          <div className="flex items-center gap-4">
            <button
              type="button"
              onClick={() => router.back()}
              className="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading || !userAFid || !userBFid || !message.trim()}
              className="flex-1 px-6 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
            >
              {loading ? 'Creating Suggestion...' : 'Create Match Suggestion'}
            </button>
          </div>
        </form>

        {/* Privacy Notice */}
        <div className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-sm text-yellow-800">
            <strong>Privacy Notice:</strong> Your identity as the suggester will
            be kept private. The participants will only see your message, not
            your name or FID.
          </p>
        </div>
      </div>
    </div>
  );
}
