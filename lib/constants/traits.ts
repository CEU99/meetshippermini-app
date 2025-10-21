/**
 * Predefined list of 50 user traits
 * Users can select 5-10 traits to describe themselves
 */

export const AVAILABLE_TRAITS = [
  'Trader',
  'Investor',
  'Airdropper',
  'Alpha-hunter',
  'Drop-sniper',
  'Smart-money',
  'Hodler',
  'Degen',
  'Whale',
  'Reward-hunter',
  'Signal-maker',
  'Chartist',
  'Analyst',
  'Scalper',
  'Swinger',
  'Sniper',
  'Speculator',
  'Visionary',
  'Pioneer',
  'Builder',
  'Beta-chaser',
  'Presale-hunter',
  'Launchpad-scout',
  'Wallet-collector',
  'Social-miner',
  'Staking-warrior',
  'Airfarmer',
  'Trend-catcher',
  'Meme-king',
  'Opportunist',
  'Risk-manager',
  'Growth-focused',
  'Thinker',
  'Tactical-mind',
  'Code-breaker',
  'Candle-wizard',
  'Graph-reader',
  'Market-seer',
  'Earlybird',
  'Silent-strategist',
  'DEX-nomad',
  'CEX-veteran',
  'Wallet-hopper',
  'Rational-ape',
  'Token-seeker',
  'Adaptive-leader',
  'Emotion-proof',
  'Data-driven',
  'Hidden-gem-finder',
  'DeFi-explorer',
] as const;

export type Trait = (typeof AVAILABLE_TRAITS)[number];

export const MIN_TRAITS = 5;
export const MAX_TRAITS = 10;

/**
 * Validate if a trait is in the allowed list
 */
export function isValidTrait(trait: string): trait is Trait {
  return AVAILABLE_TRAITS.includes(trait as Trait);
}

/**
 * Validate traits array
 * @param traits - Array of trait strings to validate
 * @param allowEmpty - If true, allows empty array (for reset operations). Default: false
 */
export function validateTraits(
  traits: string[],
  allowEmpty: boolean = false
): {
  valid: boolean;
  error?: string;
} {
  if (!Array.isArray(traits)) {
    return { valid: false, error: 'Traits must be an array' };
  }

  // Allow empty array if explicitly permitted (for reset operations)
  if (traits.length === 0 && allowEmpty) {
    return { valid: true };
  }

  if (traits.length < MIN_TRAITS) {
    return {
      valid: false,
      error: `You must select at least ${MIN_TRAITS} traits`,
    };
  }

  if (traits.length > MAX_TRAITS) {
    return {
      valid: false,
      error: `You can select at most ${MAX_TRAITS} traits`,
    };
  }

  // Check for duplicates
  const unique = new Set(traits);
  if (unique.size !== traits.length) {
    return { valid: false, error: 'Traits must be unique' };
  }

  // Check all traits are valid
  for (const trait of traits) {
    if (!isValidTrait(trait)) {
      return { valid: false, error: `Invalid trait: ${trait}` };
    }
  }

  return { valid: true };
}

/**
 * Get trait color based on category (for styling)
 */
export function getTraitColor(trait: Trait): string {
  // Trading focused
  if (
    [
      'Trader',
      'Scalper',
      'Swinger',
      'Sniper',
      'Chartist',
      'Candle-wizard',
      'Graph-reader',
    ].includes(trait)
  ) {
    return 'bg-blue-100 text-blue-700 border-blue-200';
  }

  // Investment focused
  if (
    [
      'Investor',
      'Hodler',
      'Whale',
      'Smart-money',
      'Growth-focused',
      'Risk-manager',
    ].includes(trait)
  ) {
    return 'bg-green-100 text-green-700 border-green-200';
  }

  // Airdrop/Reward focused
  if (
    [
      'Airdropper',
      'Drop-sniper',
      'Reward-hunter',
      'Airfarmer',
      'Alpha-hunter',
      'Presale-hunter',
      'Beta-chaser',
    ].includes(trait)
  ) {
    return 'bg-purple-100 text-purple-700 border-purple-200';
  }

  // Analysis/Strategy focused
  if (
    [
      'Analyst',
      'Signal-maker',
      'Market-seer',
      'Data-driven',
      'Thinker',
      'Tactical-mind',
      'Code-breaker',
    ].includes(trait)
  ) {
    return 'bg-yellow-100 text-yellow-700 border-yellow-200';
  }

  // Visionary/Builder focused
  if (
    [
      'Visionary',
      'Pioneer',
      'Builder',
      'Speculator',
      'Earlybird',
      'Hidden-gem-finder',
    ].includes(trait)
  ) {
    return 'bg-pink-100 text-pink-700 border-pink-200';
  }

  // DeFi/Platform focused
  if (
    [
      'DeFi-explorer',
      'DEX-nomad',
      'CEX-veteran',
      'Wallet-hopper',
      'Wallet-collector',
      'Staking-warrior',
    ].includes(trait)
  ) {
    return 'bg-indigo-100 text-indigo-700 border-indigo-200';
  }

  // Community/Social focused
  if (
    ['Social-miner', 'Meme-king', 'Launchpad-scout', 'Trend-catcher'].includes(
      trait
    )
  ) {
    return 'bg-orange-100 text-orange-700 border-orange-200';
  }

  // Personality focused
  if (
    [
      'Degen',
      'Opportunist',
      'Adaptive-leader',
      'Emotion-proof',
      'Rational-ape',
      'Silent-strategist',
      'Token-seeker',
    ].includes(trait)
  ) {
    return 'bg-red-100 text-red-700 border-red-200';
  }

  // Default
  return 'bg-gray-100 text-gray-700 border-gray-200';
}
