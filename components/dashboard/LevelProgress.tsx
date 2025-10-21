'use client';

import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import { MAX_LEVEL, POINTS_PER_LEVEL } from '@/lib/constants/achievements';

interface LevelData {
  user_fid: number;
  points_total: number;
  level: number;
  level_progress: number;
  is_max_level: boolean;
  updated_at: string;
}

export function LevelProgress() {
  const [levelData, setLevelData] = useState<LevelData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    fetchLevelData();

    // Listen for achievement events to refresh level
    const handleAchievementUpdate = () => {
      console.log('[LevelProgress] Achievement updated, refreshing level...');
      fetchLevelData();
    };

    window.addEventListener('achievement-awarded', handleAchievementUpdate);
    window.addEventListener('profile-updated', handleAchievementUpdate);

    return () => {
      window.removeEventListener('achievement-awarded', handleAchievementUpdate);
      window.removeEventListener('profile-updated', handleAchievementUpdate);
    };
  }, []);

  const fetchLevelData = async () => {
    try {
      setError(false);
      const data = await apiClient.get<LevelData>('/api/level/me');
      setLevelData(data);
    } catch (err) {
      console.error('[LevelProgress] Error fetching level data:', err);
      setError(true);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="mt-4 animate-pulse">
        <div className="h-4 bg-gray-200 rounded w-24 mb-2"></div>
        <div className="h-3 bg-gray-200 rounded-full w-full"></div>
      </div>
    );
  }

  if (error || !levelData) {
    return null; // Silently fail - don't break the dashboard
  }

  const percentage = levelData.is_max_level
    ? 100
    : Math.round((levelData.level_progress / POINTS_PER_LEVEL) * 100);

  return (
    <div className="mt-4">
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <span className="text-sm font-bold text-purple-700">
            {levelData.is_max_level ? 'Max Level' : `Level ${levelData.level}`}
          </span>
          {!levelData.is_max_level && (
            <span className="text-xs text-gray-500">
              {levelData.level_progress}/{POINTS_PER_LEVEL} pts
            </span>
          )}
        </div>
        <span className="text-xs font-medium text-gray-600">
          {levelData.points_total} total pts
        </span>
      </div>

      {/* Progress Bar */}
      <div className="w-full bg-gray-200 rounded-full h-3 overflow-hidden">
        <div
          className={`h-3 rounded-full transition-all duration-500 ease-out ${
            levelData.is_max_level
              ? 'bg-gradient-to-r from-yellow-400 via-yellow-500 to-yellow-600'
              : 'bg-gradient-to-r from-purple-500 to-purple-600'
          }`}
          style={{ width: `${percentage}%` }}
        />
      </div>

      {levelData.is_max_level && (
        <p className="text-xs text-yellow-700 font-medium mt-1 text-center">
          👑 You've reached the maximum level!
        </p>
      )}
    </div>
  );
}
