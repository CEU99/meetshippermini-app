/**
 * Matching Service
 * Core business logic for automatic and manual matching
 */

import { getServerSupabase, User } from '@/lib/supabase';
import { Trait } from '@/lib/constants/traits';

// Configuration constants
export const MATCHING_CONFIG = {
  MIN_SCORE_THRESHOLD: 0.50,
  MAX_PROPOSALS_PER_USER: 3,
  COOLDOWN_DAYS: 7,
  TRAIT_WEIGHT: 0.6,
  BIO_WEIGHT: 0.4,
  AUTO_MATCH_INTERVAL_HOURS: 3,
} as const;

export interface MatchCandidate {
  fid: number;
  username: string;
  display_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  traits: Trait[];
}

export interface MatchScore {
  userA: MatchCandidate;
  userB: MatchCandidate;
  traitSimilarity: number;
  bioSimilarity: number;
  overallScore: number;
  sharedTraits: Trait[];
  bioKeywords: string[];
}

export interface MatchRationale {
  traitOverlap: Trait[];
  bioKeywords: string[];
  score: number;
  traitSimilarity: number;
  bioSimilarity: number;
}

/**
 * Calculate Jaccard similarity between two sets
 */
function jaccardSimilarity<T>(setA: Set<T>, setB: Set<T>): number {
  const intersection = new Set([...setA].filter(x => setB.has(x)));
  const union = new Set([...setA, ...setB]);

  if (union.size === 0) return 0;
  return intersection.size / union.size;
}

/**
 * Calculate trait similarity between two users
 */
export function calculateTraitSimilarity(
  traitsA: Trait[],
  traitsB: Trait[]
): { similarity: number; shared: Trait[] } {
  const setA = new Set(traitsA);
  const setB = new Set(traitsB);

  const shared = [...setA].filter(t => setB.has(t)) as Trait[];
  const similarity = jaccardSimilarity(setA, setB);

  return { similarity, shared };
}

/**
 * Extract keywords from bio (simple tokenization)
 */
function extractKeywords(text: string): Set<string> {
  if (!text) return new Set();

  // Remove special characters, convert to lowercase, split by spaces
  const words = text
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .split(/\s+/)
    .filter(word => word.length > 3); // Only words longer than 3 chars

  // Common stop words to filter out
  const stopWords = new Set([
    'about', 'after', 'also', 'been', 'before', 'being', 'between',
    'both', 'could', 'during', 'each', 'from', 'have', 'here',
    'into', 'more', 'most', 'over', 'some', 'such', 'than',
    'that', 'their', 'them', 'then', 'there', 'these', 'they',
    'this', 'through', 'very', 'want', 'what', 'when', 'where',
    'which', 'while', 'will', 'with', 'would', 'your'
  ]);

  return new Set(words.filter(w => !stopWords.has(w)));
}

/**
 * Calculate bio similarity using keyword overlap
 */
export function calculateBioSimilarity(
  bioA: string | null,
  bioB: string | null
): { similarity: number; keywords: string[] } {
  if (!bioA || !bioB) {
    return { similarity: 0, keywords: [] };
  }

  const keywordsA = extractKeywords(bioA);
  const keywordsB = extractKeywords(bioB);

  const commonKeywords = [...keywordsA].filter(k => keywordsB.has(k));
  const similarity = jaccardSimilarity(keywordsA, keywordsB);

  return { similarity, keywords: commonKeywords };
}

/**
 * Calculate overall match score between two users
 */
export function calculateMatchScore(
  userA: MatchCandidate,
  userB: MatchCandidate
): MatchScore {
  const { similarity: traitSim, shared: sharedTraits } = calculateTraitSimilarity(
    userA.traits,
    userB.traits
  );

  const { similarity: bioSim, keywords: bioKeywords } = calculateBioSimilarity(
    userA.bio,
    userB.bio
  );

  const overallScore =
    MATCHING_CONFIG.TRAIT_WEIGHT * traitSim +
    MATCHING_CONFIG.BIO_WEIGHT * bioSim;

  return {
    userA,
    userB,
    traitSimilarity: traitSim,
    bioSimilarity: bioSim,
    overallScore: Math.round(overallScore * 1000) / 1000,
    sharedTraits,
    bioKeywords,
  };
}

/**
 * Check if two users are in cooldown period
 */
export async function isInCooldown(fidA: number, fidB: number): Promise<boolean> {
  const supabase = getServerSupabase();

  const { data, error } = await supabase.rpc('check_match_cooldown', {
    fid_a: fidA,
    fid_b: fidB,
  });

  if (error) {
    console.error('Error checking cooldown:', error);
    return false;
  }

  return data === true;
}

/**
 * Check if users already have an open/pending match
 * Only blocks on truly "open" statuses that need action within last 24 hours
 * 'accepted' is considered complete and doesn't block new proposals
 * 'declined' and 'cancelled' are handled by cooldown system
 */
export async function hasActiveMatch(fidA: number, fidB: number): Promise<boolean> {
  const supabase = getServerSupabase();

  // Only check for truly open/pending statuses within last 24 hours
  const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  const { data, error } = await supabase
    .from('matches')
    .select('id')
    .or(`and(user_a_fid.eq.${fidA},user_b_fid.eq.${fidB}),and(user_a_fid.eq.${fidB},user_b_fid.eq.${fidA})`)
    .in('status', ['proposed', 'accepted_by_a', 'accepted_by_b']) // ✅ Removed 'accepted'
    .gte('created_at', twentyFourHoursAgo) // ✅ Added 24h time constraint
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error('Error checking active match:', error);
    return false;
  }

  return !!data;
}

/**
 * Get count of pending proposals for a user today
 */
export async function getPendingProposalCount(fid: number): Promise<number> {
  const supabase = getServerSupabase();

  const { count, error } = await supabase
    .from('matches')
    .select('*', { count: 'exact', head: true })
    .or(`user_a_fid.eq.${fid},user_b_fid.eq.${fid}`)
    .in('status', ['proposed', 'accepted_by_a', 'accepted_by_b'])
    .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

  if (error) {
    console.error('Error counting proposals:', error);
    return 0;
  }

  return count || 0;
}

/**
 * Get all matchable users (users with bio and traits)
 */
export async function getMatchableUsers(): Promise<MatchCandidate[]> {
  const supabase = getServerSupabase();

  const { data, error } = await supabase.rpc('get_matchable_users');

  if (error) {
    console.error('Error fetching matchable users:', error);
    return [];
  }

  return (data || []).map((u: any) => ({
    fid: u.fid,
    username: u.username,
    display_name: u.display_name,
    avatar_url: u.avatar_url,
    bio: u.bio,
    traits: Array.isArray(u.traits) ? u.traits : JSON.parse(u.traits || '[]'),
  }));
}

/**
 * Find best matches for a given user
 */
export async function findBestMatches(
  user: MatchCandidate,
  candidates: MatchCandidate[],
  limit: number = MATCHING_CONFIG.MAX_PROPOSALS_PER_USER
): Promise<MatchScore[]> {
  const scores: MatchScore[] = [];

  for (const candidate of candidates) {
    // Skip self
    if (candidate.fid === user.fid) continue;

    // Check cooldown
    const inCooldown = await isInCooldown(user.fid, candidate.fid);
    if (inCooldown) continue;

    // Check active match
    const activeMatch = await hasActiveMatch(user.fid, candidate.fid);
    if (activeMatch) continue;

    // Calculate score
    const score = calculateMatchScore(user, candidate);

    // Only include if above threshold
    if (score.overallScore >= MATCHING_CONFIG.MIN_SCORE_THRESHOLD) {
      scores.push(score);
    }
  }

  // Sort by score descending and take top N
  return scores
    .sort((a, b) => b.overallScore - a.overallScore)
    .slice(0, limit);
}

/**
 * Create a match proposal
 */
export async function createMatchProposal(
  matchScore: MatchScore,
  createdBy: string = 'system'
): Promise<{ success: boolean; matchId?: string; error?: string }> {
  const supabase = getServerSupabase();

  // Check if user has too many pending proposals
  const countA = await getPendingProposalCount(matchScore.userA.fid);
  const countB = await getPendingProposalCount(matchScore.userB.fid);

  if (countA >= MATCHING_CONFIG.MAX_PROPOSALS_PER_USER) {
    return {
      success: false,
      error: `User ${matchScore.userA.username} has too many pending proposals`,
    };
  }

  if (countB >= MATCHING_CONFIG.MAX_PROPOSALS_PER_USER) {
    return {
      success: false,
      error: `User ${matchScore.userB.username} has too many pending proposals`,
    };
  }

  const rationale: MatchRationale = {
    traitOverlap: matchScore.sharedTraits,
    bioKeywords: matchScore.bioKeywords,
    score: matchScore.overallScore,
    traitSimilarity: matchScore.traitSimilarity,
    bioSimilarity: matchScore.bioSimilarity,
  };

  const { data, error } = await supabase
    .from('matches')
    .insert({
      user_a_fid: matchScore.userA.fid,
      user_b_fid: matchScore.userB.fid,
      created_by_fid: matchScore.userA.fid, // System matches use userA as creator
      created_by: createdBy,
      status: 'proposed',
      rationale,
      a_accepted: false,
      b_accepted: false,
    })
    .select('id')
    .single();

  if (error) {
    console.error('Error creating match proposal:', error);
    return { success: false, error: error.message };
  }

  return { success: true, matchId: data.id };
}

/**
 * Generate a match rationale message for display
 */
export function generateRationaleMessage(rationale: MatchRationale): string {
  const parts: string[] = [];

  if (rationale.traitOverlap.length > 0) {
    const traitList = rationale.traitOverlap.slice(0, 4).join(', ');
    const remaining = rationale.traitOverlap.length - 4;
    parts.push(
      `You share ${rationale.traitOverlap.length} common trait${rationale.traitOverlap.length > 1 ? 's' : ''} (${traitList}${remaining > 0 ? `, +${remaining} more` : ''})`
    );
  }

  if (rationale.bioKeywords.length > 0) {
    const keywords = rationale.bioKeywords.slice(0, 3).join(', ');
    parts.push(`Both mention: ${keywords}`);
  }

  const percentage = Math.round(rationale.score * 100);
  parts.push(`Match score: ${percentage}%`);

  return parts.join('. ');
}
