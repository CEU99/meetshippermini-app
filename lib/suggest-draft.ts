/**
 * Suggest Match Draft State Management
 * Uses sessionStorage to persist draft state across page navigation
 */

export interface SuggestDraftUser {
  fid: number;
  username: string;
  displayName?: string;
  pfpUrl?: string;
  bio?: string;
}

export interface SuggestDraft {
  a?: SuggestDraftUser;
  b?: SuggestDraftUser;
  farcasterA?: SuggestDraftUser;
  farcasterB?: SuggestDraftUser;
}

const STORAGE_KEY = 'suggestDraft';

/**
 * Get the current suggest draft from sessionStorage
 */
export function getSuggestDraft(): SuggestDraft {
  if (typeof window === 'undefined') {
    return {};
  }

  try {
    const stored = sessionStorage.getItem(STORAGE_KEY);
    if (!stored) return {};
    return JSON.parse(stored) as SuggestDraft;
  } catch (err) {
    console.error('[suggest-draft] Error reading draft:', err);
    return {};
  }
}

/**
 * Save suggest draft to sessionStorage
 */
export function setSuggestDraft(draft: SuggestDraft): void {
  if (typeof window === 'undefined') return;

  try {
    if (!draft.a && !draft.b && !draft.farcasterA && !draft.farcasterB) {
      // If all empty, just clear storage
      sessionStorage.removeItem(STORAGE_KEY);
    } else {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(draft));
    }
  } catch (err) {
    console.error('[suggest-draft] Error saving draft:', err);
  }
}

/**
 * Clear suggest draft from sessionStorage
 */
export function clearSuggestDraft(): void {
  if (typeof window === 'undefined') return;

  try {
    sessionStorage.removeItem(STORAGE_KEY);
  } catch (err) {
    console.error('[suggest-draft] Error clearing draft:', err);
  }
}

/**
 * Check if a FID is already selected in the draft
 */
export function isFidInDraft(fid: number): { isSelected: boolean; slot?: 'a' | 'b' } {
  const draft = getSuggestDraft();

  if (draft.a?.fid === fid) {
    return { isSelected: true, slot: 'a' };
  }

  if (draft.b?.fid === fid) {
    return { isSelected: true, slot: 'b' };
  }

  return { isSelected: false };
}

/**
 * Set User A in the draft
 */
export function setDraftUserA(user: SuggestDraftUser | undefined): void {
  const draft = getSuggestDraft();
  draft.a = user;
  setSuggestDraft(draft);
}

/**
 * Set User B in the draft
 */
export function setDraftUserB(user: SuggestDraftUser | undefined): void {
  const draft = getSuggestDraft();
  draft.b = user;
  setSuggestDraft(draft);
}

/**
 * Set Farcaster User A in the draft
 */
export function setDraftFarcasterUserA(user: SuggestDraftUser | undefined): void {
  const draft = getSuggestDraft();
  draft.farcasterA = user;
  setSuggestDraft(draft);
}

/**
 * Set Farcaster User B in the draft
 */
export function setDraftFarcasterUserB(user: SuggestDraftUser | undefined): void {
  const draft = getSuggestDraft();
  draft.farcasterB = user;
  setSuggestDraft(draft);
}
