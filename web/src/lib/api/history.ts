import { apiFetch, buildQueryString } from './client';
import type { RecipeSummary, LogPostSummary } from '@/lib/types';

/**
 * Record a recipe view in view history.
 * Called when viewing recipe detail page.
 */
export async function recordRecipeView(publicId: string): Promise<void> {
  try {
    await apiFetch<void>(`/view-history/recipes/${publicId}`, {
      method: 'POST',
      cache: 'no-store',
    });
  } catch (error) {
    // Silently fail - view tracking shouldn't break the app
    console.error('Failed to record recipe view:', error);
  }
}

/**
 * Record a log post view in view history.
 * Called when viewing log detail page.
 */
export async function recordLogView(publicId: string): Promise<void> {
  try {
    await apiFetch<void>(`/view-history/logs/${publicId}`, {
      method: 'POST',
      cache: 'no-store',
    });
  } catch (error) {
    // Silently fail - view tracking shouldn't break the app
    console.error('Failed to record log view:', error);
  }
}

/**
 * Get recently viewed recipes for the current user.
 */
export async function getRecentlyViewedRecipes(limit: number = 10): Promise<RecipeSummary[]> {
  const queryString = buildQueryString({ limit });
  return apiFetch<RecipeSummary[]>(`/view-history/recipes${queryString}`, {
    cache: 'no-store',
  });
}

/**
 * Get recently viewed log posts for the current user.
 */
export async function getRecentlyViewedLogs(limit: number = 10): Promise<LogPostSummary[]> {
  const queryString = buildQueryString({ limit });
  return apiFetch<LogPostSummary[]>(`/view-history/logs${queryString}`, {
    cache: 'no-store',
  });
}

/**
 * Record a search query in search history.
 * Called when performing a search.
 */
export async function recordSearchHistory(query: string): Promise<void> {
  try {
    await apiFetch<void>('/view-history/search', {
      method: 'POST',
      body: JSON.stringify({ query }),
      cache: 'no-store',
    });
  } catch (error) {
    // Silently fail - search tracking shouldn't break the app
    console.error('Failed to record search history:', error);
  }
}
