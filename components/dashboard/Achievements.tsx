'use client';

import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';
import {
  getAllAchievementsInOrder,
  getUnlockedWave,
  isAchievementEarned,
  type Achievement,
} from '@/lib/constants/achievements';
import { AchievementCard } from './AchievementCard';

interface EarnedAchievement {
  code: string;
  title: string;
  description: string;
  points: number;
  icon: string;
  awarded_at: string;
  wave: number;
}

interface AchievementsResponse {
  achievements: EarnedAchievement[];
  total_earned: number;
  total_available: number;
}

export function Achievements() {
  const [earnedAchievements, setEarnedAchievements] = useState<EarnedAchievement[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    fetchAchievements();

    // Listen for achievement/profile updates
    const handleUpdate = () => {
      console.log('[Achievements] Update detected, refreshing...');
      fetchAchievements();
    };

    window.addEventListener('achievement-awarded', handleUpdate);
    window.addEventListener('profile-updated', handleUpdate);

    return () => {
      window.removeEventListener('achievement-awarded', handleUpdate);
      window.removeEventListener('profile-updated', handleUpdate);
    };
  }, []);

  const fetchAchievements = async () => {
    try {
      setError(false);
      const data = await apiClient.get<AchievementsResponse>('/api/achievements/me');
      setEarnedAchievements(data.achievements || []);
    } catch (err) {
      console.error('[Achievements] Error fetching achievements:', err);
      setError(true);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-pink-50/60 rounded-2xl border border-white/60 shadow-lg p-8">
        <h2 className="text-xl font-bold bg-gradient-to-r from-gray-900 via-purple-900 to-pink-900 bg-clip-text text-transparent mb-6">Achievements</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="h-56 bg-gradient-to-br from-gray-100/70 to-gray-50/70 rounded-2xl animate-pulse backdrop-blur-sm"
            ></div>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return null; // Silently fail - don't break the dashboard
  }

  // Get all achievements in order
  const allAchievements = getAllAchievementsInOrder();

  // Determine unlocked wave
  const unlockedWave = getUnlockedWave(earnedAchievements);

  // Group achievements by wave
  const wave1 = allAchievements.filter((a) => a.wave === 1);
  const wave2 = allAchievements.filter((a) => a.wave === 2);
  const wave3 = allAchievements.filter((a) => a.wave === 3);
  const wave4 = allAchievements.filter((a) => a.wave === 4);

  // Determine which achievements to display
  const visibleAchievements: Achievement[] = [];

  // Always show Wave 1
  visibleAchievements.push(...wave1);

  // Show Wave 2 if Wave 1 is complete
  if (unlockedWave >= 2) {
    visibleAchievements.push(...wave2);
  }

  // Show Wave 3 if Wave 2 is complete
  if (unlockedWave >= 3) {
    visibleAchievements.push(...wave3);
  }

  // Show Wave 4 if Wave 3 is complete
  if (unlockedWave >= 4) {
    visibleAchievements.push(...wave4);
  }

  // Determine which are earned/locked
  const achievementStates = visibleAchievements.map((achievement) => ({
    achievement,
    earned: isAchievementEarned(achievement.code, earnedAchievements),
    locked: achievement.wave > unlockedWave,
  }));

  return (
    <div className="backdrop-blur-xl bg-gradient-to-br from-white/80 via-purple-50/60 to-pink-50/60 rounded-2xl border border-white/60 shadow-lg hover:shadow-2xl transition-all duration-300 p-8">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-bold bg-gradient-to-r from-gray-900 via-purple-900 to-pink-900 bg-clip-text text-transparent">
          Achievements
        </h2>
        <span className="px-3 py-1.5 rounded-xl text-sm font-semibold bg-white/70 backdrop-blur-sm border border-purple-200/60 text-purple-700">
          {earnedAchievements.length} / {allAchievements.length} earned
        </span>
      </div>

      {/* Wave Progress Indicator */}
      <div className="mb-6 flex items-center gap-3">
        {[1, 2, 3, 4].map((wave) => (
          <div
            key={wave}
            className={`flex-1 h-3 rounded-full transition-all duration-500 ${
              wave < unlockedWave
                ? 'bg-gradient-to-r from-emerald-400 to-green-500 shadow-sm'
                : wave === unlockedWave
                ? 'bg-gradient-to-r from-purple-400 to-purple-600 shadow-md animate-pulse'
                : 'bg-gradient-to-r from-gray-200 to-gray-300'
            }`}
          />
        ))}
      </div>

      <p className="text-sm font-medium text-gray-700 mb-6 px-4 py-3 bg-white/60 backdrop-blur-sm rounded-xl border border-purple-100/60">
        {unlockedWave === 1 && '🎯 Complete Wave 1 to unlock Wave 2 achievements'}
        {unlockedWave === 2 && '⚡ Complete Wave 2 to unlock Wave 3 achievements'}
        {unlockedWave === 3 && '🚀 Complete Wave 3 to unlock the final achievement'}
        {unlockedWave === 4 && '🎉 All waves unlocked! Complete the final challenge.'}
      </p>

      {/* Achievement Grid - 3 per row on desktop */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {achievementStates.map(({ achievement, earned, locked }) => (
          <AchievementCard
            key={achievement.code}
            achievement={achievement}
            earned={earned}
            locked={locked}
          />
        ))}
      </div>

      {/* Empty State */}
      {visibleAchievements.length === 0 && (
        <div className="text-center py-12 px-4 bg-white/50 backdrop-blur-sm rounded-xl border border-gray-200/60">
          <p className="text-gray-600 font-medium">No achievements available yet. Complete actions to earn achievements!</p>
        </div>
      )}
    </div>
  );
}
