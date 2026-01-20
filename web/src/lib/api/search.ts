import { apiFetch, buildQueryString } from './client';
import type { UnifiedSearchResponse, UnifiedSearchParams } from '@/lib/types';

/**
 * Unified search across recipes, logs, and hashtags
 */
export async function unifiedSearch(
  params: UnifiedSearchParams & { locale?: string },
): Promise<UnifiedSearchResponse> {
  const queryString = buildQueryString({
    q: params.q,
    type: params.type ?? 'all',
    page: params.page ?? 0,
    size: params.size ?? 20,
  });

  return apiFetch<UnifiedSearchResponse>(`/search${queryString}`, {
    next: { revalidate: 60 }, // Cache for 1 minute
    locale: params.locale,
  });
}
