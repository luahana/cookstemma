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
export async function getHashtagCounts(name: string): Promise<HashtagCounts> {
  return apiFetch<HashtagCounts>(`/hashtags/${encodeURIComponent(name)}/counts`, {
    next: { revalidate: 300 },
  });
}

/**
 * Get recipes by hashtag
 */
export async function getRecipesByHashtag(
  name: string,
  params: PaginationParams = {},
): Promise<UnifiedPageResponse<RecipeSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<UnifiedPageResponse<RecipeSummary>>(
    `/hashtags/${encodeURIComponent(name)}/recipes${queryString}`,
    {
      next: { revalidate: 60 },
    },
  );
}

/**
 * Get log posts by hashtag
 */
export async function getLogsByHashtag(
  name: string,
  params: PaginationParams = {},
): Promise<UnifiedPageResponse<LogPostSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<UnifiedPageResponse<LogPostSummary>>(
    `/hashtags/${encodeURIComponent(name)}/log_posts${queryString}`,
    {
      next: { revalidate: 60 },
    },
  );
}

/**
 * Get unified feed of all content (recipes and logs) with hashtags
 */
export async function getHashtaggedFeed(
  params: PaginationParams = {},
): Promise<UnifiedPageResponse<HashtaggedContentItem>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<UnifiedPageResponse<HashtaggedContentItem>>(
    `/hashtags/feed${queryString}`,
    {
      next: { revalidate: 60 },
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
