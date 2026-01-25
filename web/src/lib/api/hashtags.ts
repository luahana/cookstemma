import { apiFetch, buildQueryString } from './client';
import type {
  HashtagDto,
  HashtagCounts,
  HashtaggedContentItem,
  RecipeSummary,
  LogPostSummary,
  UnifiedPageResponse,
  PaginationParams,
} from '@/lib/types';

/**
 * Get all hashtags
 */
export async function getHashtags(): Promise<HashtagDto[]> {
  return apiFetch<HashtagDto[]>('/hashtags', {
    next: { revalidate: 3600 }, // Cache for 1 hour
  });
}

/**
 * Search hashtags by prefix
 */
export async function searchHashtags(query: string): Promise<HashtagDto[]> {
  return apiFetch<HashtagDto[]>(`/hashtags/search?q=${encodeURIComponent(query)}`, {
    next: { revalidate: 60 },
  });
}

/**
 * Get hashtag counts (recipes and logs count)
 */
export async function getHashtagCounts(name: string, locale?: string): Promise<HashtagCounts> {
  return apiFetch<HashtagCounts>(`/hashtags/${encodeURIComponent(name)}/counts`, {
    next: { revalidate: 300 },
    locale,
  });
}

/**
 * Get recipes by hashtag
 */
export async function getRecipesByHashtag(
  name: string,
  params: PaginationParams & { locale?: string } = {},
): Promise<UnifiedPageResponse<RecipeSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<UnifiedPageResponse<RecipeSummary>>(
    `/hashtags/${encodeURIComponent(name)}/recipes${queryString}`,
    {
      next: { revalidate: 60 },
      locale: params.locale,
    },
  );
}

/**
 * Get log posts by hashtag
 */
export async function getLogsByHashtag(
  name: string,
  params: PaginationParams & { locale?: string } = {},
): Promise<UnifiedPageResponse<LogPostSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<UnifiedPageResponse<LogPostSummary>>(
    `/hashtags/${encodeURIComponent(name)}/log_posts${queryString}`,
    {
      next: { revalidate: 60 },
      locale: params.locale,
    },
  );
}

/**
 * Get unified content (recipes and logs) for a specific hashtag
 */
export async function getContentByHashtag(
  name: string,
  params: PaginationParams & { locale?: string } = {},
): Promise<UnifiedPageResponse<HashtaggedContentItem>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<UnifiedPageResponse<HashtaggedContentItem>>(
    `/hashtags/${encodeURIComponent(name)}/content${queryString}`,
    {
      next: { revalidate: 60 },
      locale: params.locale,
    },
  );
}

/**
 * Popular hashtag response type from backend
 */
export interface HashtagWithCount {
  publicId: string;
  name: string;
  recipeCount: number;
  logPostCount: number;
  totalCount: number;
}

/**
 * Get popular hashtags filtered by locale (based on original_language).
 * Returns hashtags that are used on content originally created in the user's language.
 */
export async function getPopularHashtags(
  limit: number = 10,
  locale?: string,
): Promise<HashtagWithCount[]> {
  const queryString = buildQueryString({ limit, locale });
  return apiFetch<HashtagWithCount[]>(`/hashtags/popular${queryString}`, {
    next: { revalidate: 300 },
    locale,
  });
}
