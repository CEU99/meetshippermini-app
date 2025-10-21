'use client';

import { Achievement } from '@/lib/constants/achievements';

interface AchievementCardProps {
  achievement: Achievement;
  earned: boolean;
  locked: boolean;
}

export function AchievementCard({ achievement, earned, locked }: AchievementCardProps) {
  return (
    <div
      className={`
        rounded-lg p-4 border-2 transition-all duration-300
        ${earned ? 'border-green-500 bg-green-50' : 'border-gray-300 bg-white'}
        ${locked ? 'opacity-50 cursor-not-allowed' : 'hover:shadow-md'}
      `}
    >
      {/* Icon */}
      <div className="text-4xl mb-2 text-center">{achievement.icon}</div>

      {/* Title */}
      <h3 className="font-bold text-gray-900 text-center text-sm mb-1">
        {achievement.title}
      </h3>

      {/* Description */}
      <p className="text-xs text-gray-600 text-center mb-2">
        {achievement.description}
      </p>

      {/* Points */}
      <p className="text-center font-bold text-purple-600 text-sm mb-2">
        +{achievement.points} pts
      </p>

      {/* Status */}
      {earned && (
        <div className="flex items-center justify-center gap-1 text-green-600 text-sm font-medium">
          <svg
            className="w-4 h-4"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fillRule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
              clipRule="evenodd"
            />
          </svg>
          <span>Completed</span>
        </div>
      )}

      {!earned && !locked && (
        <div className="text-xs text-gray-500 text-center mt-2 pt-2 border-t border-gray-200">
          <p className="font-medium text-gray-700 mb-1">How to earn:</p>
          <p>{achievement.howToEarn}</p>
        </div>
      )}

      {locked && (
        <div className="flex items-center justify-center gap-1 text-gray-400 text-sm">
          <svg
            className="w-4 h-4"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fillRule="evenodd"
              d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z"
              clipRule="evenodd"
            />
          </svg>
          <span>Locked</span>
        </div>
      )}
    </div>
  );
}
