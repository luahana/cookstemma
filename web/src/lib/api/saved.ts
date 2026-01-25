import { apiFetch, buildQueryString } from './client';
import type { RecipeSummary, LogPostSummary, UnifiedPageResponse, PaginationParams } from '@/lib/types';

interface SavedStatusResponse {
  isSaved: boolean;
}

/**
 * Check if a recipe is saved by the current user
 */
export async function checkRecipeSaved(publicId: string): Promise<boolean> {
  const response = await apiFetch<SavedStatusResponse>(`/recipes/${publicId}/saved`, {
    cache: 'no-store',
  });
  return response.isSaved;
}

/**
 * Check if a log is saved by the current user
 */
export async function checkLogSaved(publicId: string): Promise<boolean> {
  const response = await apiFetch<SavedStatusResponse>(`/log_posts/${publicId}/saved`, {
    cache: 'no-store',
  });
  return response.isSaved;
}

/**
 * Save a recipe (bookmark)
 */
export async function saveRecipe(publicId: string): Promise<void> {
  await apiFetch<void>(`/recipes/${publicId}/save`, {
    method: 'POST',
    cache: 'no-store',
  });
}

/**
 * Unsave a recipe (remove bookmark)
 */
export async function unsaveRecipe(publicId: string): Promise<void> {
  await apiFetch<void>(`/recipes/${publicId}/save`, {
    method: 'DELETE',
    cache: 'no-store',
  });
}

/**
 * Get saved recipes with pagination
 */
export async function getSavedRecipes(
  params: PaginationParams = {}
): Promise<UnifiedPageResponse<RecipeSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<UnifiedPageResponse<RecipeSummary>>(`/recipes/saved${queryString}`, {
    cache: 'no-store',
  });
}

/**
 * Save a log post (bookmark)
 */
export async function saveLog(publicId: string): Promise<void> {
  await apiFetch<void>(`/log_posts/${publicId}/save`, {
    method: 'POST',
    cache: 'no-store',
  });
}

/**
 * Unsave a log post (remove bookmark)
 */
export async function unsaveLog(publicId: string): Promise<void> {
  await apiFetch<void>(`/log_posts/${publicId}/save`, {
    method: 'DELETE',
    cache: 'no-store',
  });
}

/**
 * Get saved log posts with pagination
 */
export async function getSavedLogs(
  params: PaginationParams = {}
): Promise<UnifiedPageResponse<LogPostSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<UnifiedPageResponse<LogPostSummary>>(`/log_posts/saved${queryString}`, {
    cache: 'no-store',
  });
}
