'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { apiClient } from '@/lib/api-client';
import {
  getAllAchievementsInOrder,
  getUnlockedWave,
  isAchievementEarned,
  type Achievement,
} from '@/lib/constants/achievements';

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

export default function AchievementsSummary() {
  const [earnedAchievements, setEarnedAchievements] = useState<EarnedAchievement[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    fetchAchievements();

    const handleUpdate = () => {
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
      console.error('[AchievementsSummary] Error fetching achievements:', err);
      setError(true);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="backdrop-blur-xl bg-gradient-to-br from-green-50/80 via-emerald-50/80 to-teal-50/80 rounded-2xl border border-green-200/60 shadow-lg p-6 h-full">
        <div className="text-center mb-4">
          <h3 className="text-sm font-bold text-green-700 uppercase tracking-wider flex items-center justify-center gap-2">
            <span>🏅</span> Achievements Summary
          </h3>
          <p className="text-xs text-green-600 mt-1">Complete more actions to unlock new waves</p>
        </div>
        <div className="flex items-center justify-center gap-3 py-8">
          <div className="w-5 h-5 border-2 border-green-400 border-t-transparent rounded-full animate-spin" />
          <span className="text-sm text-gray-600 font-medium">Loading achievements...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="backdrop-blur-xl bg-gradient-to-br from-green-50/80 via-emerald-50/80 to-teal-50/80 rounded-2xl border border-green-200/60 shadow-lg p-6 h-full">
        <div className="text-center mb-4">
          <h3 className="text-sm font-bold text-green-700 uppercase tracking-wider flex items-center justify-center gap-2">
            <span>🏅</span> Achievements Summary
          </h3>
        </div>
        <div className="backdrop-blur-xl bg-red-50/60 rounded-xl border border-red-200/60 p-4">
          <p className="text-xs text-red-700 font-medium text-center">Failed to load achievements</p>
        </div>
      </div>
    );
  }

  const allAchievements = getAllAchievementsInOrder();
  const unlockedWave = getUnlockedWave(earnedAchievements);

  // Get first 6 visible achievements for compact display
  const wave1 = allAchievements.filter((a) => a.wave === 1);
  const wave2 = allAchievements.filter((a) => a.wave === 2);
  const wave3 = allAchievements.filter((a) => a.wave === 3);

  const visibleAchievements: Achievement[] = [];
  visibleAchievements.push(...wave1);
  if (unlockedWave >= 2) {
    visibleAchievements.push(...wave2);
  }
  if (unlockedWave >= 3) {
    visibleAchievements.push(...wave3.slice(0, 1));
  }

  // Limit to first 6 for compact view
  const displayAchievements = visibleAchievements.slice(0, 6);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      className="backdrop-blur-xl bg-gradient-to-br from-green-50/80 via-emerald-50/80 to-teal-50/80 rounded-2xl border border-green-200/60 shadow-lg hover:shadow-xl transition-all duration-300 p-6 h-full"
    >
      {/* Header */}
      <div className="text-center mb-4">
        <div className="flex items-center justify-center gap-2 mb-1">
          <h3 className="text-sm font-bold text-green-700 uppercase tracking-wider flex items-center gap-2">
            <span>🏅</span> Achievements Summary
          </h3>
          <span className="px-2 py-0.5 rounded-lg text-xs font-semibold bg-white/70 backdrop-blur-sm border border-green-200/60 text-green-700">
            {earnedAchievements.length} / {allAchievements.length}
          </span>
        </div>
        <p className="text-xs text-green-600">Complete more actions to unlock new waves</p>
      </div>

      {/* Wave Progress Indicator */}
      <div className="mb-4 flex items-center gap-2">
        {[1, 2, 3, 4].map((wave) => (
          <div
            key={wave}
            className={`flex-1 h-2 rounded-full transition-all duration-500 ${
              wave < unlockedWave
                ? 'bg-gradient-to-r from-emerald-400 to-green-500 shadow-sm'
                : wave === unlockedWave
                ? 'bg-gradient-to-r from-green-400 to-green-600 shadow-md animate-pulse'
                : 'bg-gradient-to-r from-gray-200 to-gray-300'
            }`}
          />
        ))}
      </div>

      {/* Compact Achievement Grid - 3x2 */}
      <div className="grid grid-cols-3 gap-2 mb-3">
        {displayAchievements.map((achievement, index) => {
          const earned = isAchievementEarned(achievement.code, earnedAchievements);
          return (
            <motion.div
              key={achievement.code}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.3, delay: index * 0.05 }}
              className={`relative rounded-xl p-2.5 transition-all duration-200 group ${
                earned
                  ? 'bg-gradient-to-br from-emerald-50/90 to-green-50/90 border-2 border-emerald-300/60 shadow-sm hover:shadow-md'
                  : 'bg-gradient-to-br from-white/70 to-green-50/50 border border-green-200/40 shadow-sm hover:shadow-md'
              }`}
            >
              {/* Icon */}
              <div className="text-2xl text-center mb-1 group-hover:scale-110 transition-transform duration-300">
                {achievement.icon}
              </div>

              {/* Points */}
              <div className="text-center mb-1">
                <p
                  className={`text-xs font-bold ${
                    earned ? 'text-emerald-700' : 'text-gray-600'
                  }`}
                >
                  +{achievement.points}
                </p>
              </div>

              {/* Description */}
              <div className="text-center px-1">
                <p
                  className={`text-[9px] leading-tight ${
                    earned ? 'text-emerald-600/80' : 'text-gray-500/80'
                  }`}
                >
                  {achievement.description}
                </p>
              </div>

              {/* Earned Badge */}
              {earned && (
                <div className="absolute -top-1 -right-1 w-4 h-4 bg-emerald-500 rounded-full flex items-center justify-center">
                  <svg className="w-2.5 h-2.5 text-white" fill="currentColor" viewBox="0 0 20 20">
                    <path
                      fillRule="evenodd"
                      d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                      clipRule="evenodd"
                    />
                  </svg>
                </div>
              )}
            </motion.div>
          );
        })}
      </div>

      {/* Current Wave Status */}
      <div className="pt-3 border-t border-green-200/40">
        <p className="text-xs text-center text-green-600/80 font-medium">
          {unlockedWave === 1 && '🎯 Complete Wave 1 to unlock more'}
          {unlockedWave === 2 && '⚡ Wave 2 in progress'}
          {unlockedWave === 3 && '🚀 Wave 3 unlocked!'}
          {unlockedWave === 4 && '🎉 Final wave unlocked!'}
        </p>
      </div>
    </motion.div>
  );
}
