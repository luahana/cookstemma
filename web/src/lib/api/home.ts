import { apiFetch } from './client';
import type { HomeFeedResponse } from '@/lib/types';

/**
 * Get home feed data (recent activity, recipes, trending trees)
 * @param locale - Optional locale for Accept-Language header (SSR)
 */
export async function getHomeFeed(locale?: string): Promise<HomeFeedResponse> {
  return apiFetch<HomeFeedResponse>('/home', {
    next: { revalidate: 60 }, // Cache for 1 minute
    locale,
  });
}
