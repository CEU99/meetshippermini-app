/**
 * Achievement System Constants
 *
 * Defines all available achievements, their point values,
 * and wave progression for the UI.
 */

export const POINTS_PER_LEVEL = 100;
export const MAX_LEVEL = 20;
export const MAX_POINTS = MAX_LEVEL * POINTS_PER_LEVEL; // 2000

export type AchievementCode =
  | 'bio_done'
  | 'traits_done'
  | 'sent_5'
  | 'sent_10'
  | 'sent_20'
  | 'sent_30'
  | 'joined_1'
  | 'joined_5'
  | 'joined_10'
  | 'joined_40';

export interface Achievement {
  code: AchievementCode;
  title: string;
  description: string;
  points: number;
  wave: number; // 1, 2, 3, or 4
  icon: string; // Emoji icon
  howToEarn: string;
}

/**
 * All available achievements in the system
 */
export const ACHIEVEMENTS: Record<AchievementCode, Achievement> = {
  // Wave 1: Profile Setup (200 points total = Level 2)
  bio_done: {
    code: 'bio_done',
    title: 'Bio Master',
    description: 'Fill out your bio',
    points: 50,
    wave: 1,
    icon: '📝',
    howToEarn: 'Add a bio to your profile in Edit Profile',
  },
  traits_done: {
    code: 'traits_done',
    title: 'Trait Hunter',
    description: 'Select your personal traits',
    points: 50,
    wave: 1,
    icon: '⭐',
    howToEarn: 'Select at least 5 personal traits in Edit Profile',
  },
  sent_5: {
    code: 'sent_5',
    title: 'First Connections',
    description: 'Send 5 match requests',
    points: 100,
    wave: 1,
    icon: '🤝',
    howToEarn: 'Send match requests to 5 unique users',
  },

  // Wave 2: Active Networker (300 points total = Level 5)
  sent_10: {
    code: 'sent_10',
    title: 'Connector',
    description: 'Send 10 match requests',
    points: 100,
    wave: 2,
    icon: '🔗',
    howToEarn: 'Send match requests to 10 unique users',
  },
  sent_20: {
    code: 'sent_20',
    title: 'Network Builder',
    description: 'Send 20 match requests',
    points: 100,
    wave: 2,
    icon: '🌐',
    howToEarn: 'Send match requests to 20 unique users',
  },
  sent_30: {
    code: 'sent_30',
    title: 'Super Connector',
    description: 'Send 30 match requests',
    points: 100,
    wave: 2,
    icon: '🚀',
    howToEarn: 'Send match requests to 30 unique users',
  },

  // Wave 3: Meeting Achievements (1200 points total = Level 17)
  joined_1: {
    code: 'joined_1',
    title: 'First Meeting',
    description: 'Complete your first meeting',
    points: 400,
    wave: 3,
    icon: '🎯',
    howToEarn: 'Join and complete 1 meeting',
  },
  joined_5: {
    code: 'joined_5',
    title: 'Meeting Regular',
    description: 'Complete 5 meetings',
    points: 400,
    wave: 3,
    icon: '🏆',
    howToEarn: 'Join and complete 5 meetings',
  },
  joined_10: {
    code: 'joined_10',
    title: 'Meeting Pro',
    description: 'Complete 10 meetings',
    points: 400,
    wave: 3,
    icon: '💎',
    howToEarn: 'Join and complete 10 meetings',
  },

  // Wave 4: Final Achievement (400 points = Level 20 MAX)
  joined_40: {
    code: 'joined_40',
    title: 'Legendary Networker',
    description: 'Complete 40 meetings',
    points: 400,
    wave: 4,
    icon: '👑',
    howToEarn: 'Join and complete 40 meetings',
  },
};

/**
 * Get achievements organized by wave
 */
export function getAchievementsByWave(wave: number): Achievement[] {
  return Object.values(ACHIEVEMENTS).filter((a) => a.wave === wave);
}

/**
 * Get all achievements in display order (wave 1 → 4)
 */
export function getAllAchievementsInOrder(): Achievement[] {
  return Object.values(ACHIEVEMENTS).sort((a, b) => {
    if (a.wave !== b.wave) return a.wave - b.wave;
    return a.points - b.points;
  });
}

/**
 * Calculate level from total points
 */
export function calculateLevel(points: number): number {
  return Math.min(Math.floor(points / POINTS_PER_LEVEL), MAX_LEVEL);
}

/**
 * Calculate progress within current level (0-100)
 */
export function calculateLevelProgress(points: number): number {
  if (points >= MAX_POINTS) return 100;
  return points % POINTS_PER_LEVEL;
}

/**
 * Get achievement by code
 */
export function getAchievement(code: AchievementCode): Achievement | undefined {
  return ACHIEVEMENTS[code];
}

/**
 * Check if achievement is earned
 */
export function isAchievementEarned(
  code: AchievementCode,
  earnedAchievements: { code: string }[]
): boolean {
  return earnedAchievements.some((a) => a.code === code);
}

/**
 * Get which wave the user has unlocked
 * Wave unlocks when ALL previous wave achievements are complete
 */
export function getUnlockedWave(earnedAchievements: { code: string }[]): number {
  const earnedCodes = new Set(earnedAchievements.map((a) => a.code));

  // Wave 1 is always unlocked
  const wave1 = getAchievementsByWave(1);
  const wave1Complete = wave1.every((a) => earnedCodes.has(a.code));

  if (!wave1Complete) return 1;

  // Check wave 2
  const wave2 = getAchievementsByWave(2);
  const wave2Complete = wave2.every((a) => earnedCodes.has(a.code));

  if (!wave2Complete) return 2;

  // Check wave 3
  const wave3 = getAchievementsByWave(3);
  const wave3Complete = wave3.every((a) => earnedCodes.has(a.code));

  if (!wave3Complete) return 3;

  // All waves complete or working on wave 4
  return 4;
}

/**
 * Get visible achievements for the current user state
 * Only shows achievements from unlocked waves
 */
export function getVisibleAchievements(
  earnedAchievements: { code: string }[]
): Achievement[] {
  const unlockedWave = getUnlockedWave(earnedAchievements);
  const earnedCodes = new Set(earnedAchievements.map((a) => a.code));

  const visible: Achievement[] = [];

  // Add all earned achievements
  for (const achievement of getAllAchievementsInOrder()) {
    if (earnedCodes.has(achievement.code)) {
      visible.push(achievement);
    }
  }

  // Add locked achievements from current unlocked wave
  for (const achievement of getAllAchievementsInOrder()) {
    if (achievement.wave === unlockedWave && !earnedCodes.has(achievement.code)) {
      visible.push(achievement);
    }
  }

  return visible;
}

/**
 * Format points with commas (e.g., 1,250)
 */
export function formatPoints(points: number): string {
  return points.toLocaleString();
}

/**
 * Get level label
 */
export function getLevelLabel(level: number): string {
  if (level >= MAX_LEVEL) return 'Max Level';
  return `Level ${level}`;
}

/**
 * Get progress percentage (0-100)
 */
export function getProgressPercentage(levelProgress: number): number {
  return Math.round((levelProgress / POINTS_PER_LEVEL) * 100);
}
