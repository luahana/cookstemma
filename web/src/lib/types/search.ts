import type { RecipeSummary } from './recipe';
import type { LogPostSummary } from './log';

/**
 * Search result content types
 */
export type SearchResultType = 'RECIPE' | 'LOG' | 'HASHTAG';

/**
 * Contributor preview for hashtag results
 */
export interface ContributorPreview {
  publicId: string;
  username: string;
  avatarUrl: string | null;
}

/**
 * Rich hashtag search result with preview data
 */
export interface HashtagSearchResult {
  publicId: string;
  name: string;
  recipeCount: number;
  logCount: number;
  sampleThumbnails: string[];
  topContributors: ContributorPreview[];
}

/**
 * Polymorphic search result item
 */
export interface SearchResultItem {
  type: SearchResultType;
  relevanceScore: number;
  data: RecipeSummary | LogPostSummary | HashtagSearchResult;
}

/**
 * Counts for each search result type (for filter chips)
 */
export interface SearchCounts {
  recipes: number;
  logs: number;
  hashtags: number;
  total: number;
}

/**
 * Unified search response
 */
export interface UnifiedSearchResponse {
  content: SearchResultItem[];
  counts: SearchCounts;
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  hasNext: boolean;
}

/**
 * Search type filter values
 */
export type SearchTypeFilter = 'all' | 'recipes' | 'logs' | 'hashtags';

/**
 * Search parameters
 */
export interface UnifiedSearchParams {
  q: string;
  type?: SearchTypeFilter;
  page?: number;
  size?: number;
}

/**
 * Type guards for search result items
 */
export function isRecipeResult(
  item: SearchResultItem,
): item is SearchResultItem & { data: RecipeSummary } {
  return item.type === 'RECIPE';
}

export function isLogResult(
  item: SearchResultItem,
): item is SearchResultItem & { data: LogPostSummary } {
  return item.type === 'LOG';
}

export function isHashtagResult(
  item: SearchResultItem,
): item is SearchResultItem & { data: HashtagSearchResult } {
  return item.type === 'HASHTAG';
}
