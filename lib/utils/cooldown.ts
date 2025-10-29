/**
 * Cooldown System Utilities
 * Shared logic for handling match cooldowns across the app
 */

export interface CooldownInfo {
  remainingDays: number;
  remainingHours: number;
  expiresAt: string;
}

export interface CooldownApiResponse {
  error: string;
  cooldownExpiry?: string;
  hoursRemaining?: number;
  daysRemaining?: number;
}

/**
 * Check if an API error response contains cooldown information
 */
export function isCooldownError(error: any): boolean {
  return !!(
    error?.data?.cooldownExpiry ||
    error?.data?.hoursRemaining ||
    error?.data?.daysRemaining
  );
}

/**
 * Extract cooldown info from API error response
 */
export function extractCooldownInfo(error: any): CooldownInfo | null {
  if (!isCooldownError(error)) {
    return null;
  }

  const { cooldownExpiry, hoursRemaining, daysRemaining } = error.data;

  if (!cooldownExpiry || hoursRemaining === undefined || daysRemaining === undefined) {
    return null;
  }

  return {
    expiresAt: cooldownExpiry,
    remainingHours: hoursRemaining,
    remainingDays: daysRemaining,
  };
}

/**
 * Format cooldown error message for display
 */
export function formatCooldownMessage(cooldownInfo: CooldownInfo): string {
  const { remainingHours, remainingDays } = cooldownInfo;

  if (remainingHours <= 24) {
    return `⏳ Cooldown active: Please wait ${remainingHours} hour${
      remainingHours !== 1 ? 's' : ''
    } before requesting again.`;
  }

  return `⏳ Cooldown active: Please wait ${remainingDays} day${
    remainingDays !== 1 ? 's' : ''
  } (${remainingHours} hours) before requesting again.`;
}

/**
 * Format cooldown expiry date for display
 */
export function formatCooldownExpiry(expiresAt: string): string {
  return new Date(expiresAt).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

/**
 * Calculate cooldown info from expiry timestamp (client-side calculation)
 */
export function calculateCooldownFromExpiry(expiresAt: string): CooldownInfo {
  const expiry = new Date(expiresAt);
  const now = new Date();
  const msRemaining = expiry.getTime() - now.getTime();
  const hoursRemaining = Math.ceil(msRemaining / (1000 * 60 * 60));
  const daysRemaining = Math.ceil(hoursRemaining / 24);

  return {
    expiresAt,
    remainingHours: Math.max(0, hoursRemaining),
    remainingDays: Math.max(0, daysRemaining),
  };
}
