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
 * Get popular hashtags with their counts
 */
export async function getPopularHashtags(limit: number = 10): Promise<(HashtagDto & { totalCount: number })[]> {
  const hashtags = await getHashtags();

  // Fetch counts for all hashtags in parallel
  const hashtagsWithCounts = await Promise.all(
    hashtags.slice(0, Math.min(hashtags.length, 20)).map(async (hashtag) => {
      try {
        const counts = await getHashtagCounts(hashtag.name);
        return {
          ...hashtag,
          totalCount: counts.recipeCount + counts.logPostCount,
        };
      } catch {
        return {
          ...hashtag,
          totalCount: 0,
        };
      }
    }),
  );

  // Sort by total count and return top N
  return hashtagsWithCounts
    .sort((a, b) => b.totalCount - a.totalCount)
    .slice(0, limit);
}
