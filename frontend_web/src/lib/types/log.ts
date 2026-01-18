import type { RecipeSummary } from './recipe';
import type { HashtagDto, ImageResponseDto } from './common';

/**
 * Star rating (1-5)
 * Replaces the old Outcome type (SUCCESS/PARTIAL/FAILED)
 */
export type Rating = 1 | 2 | 3 | 4 | 5;

/**
 * Log post summary for list/card views
 */
export interface LogPostSummary {
  publicId: string;
  title: string;
  rating: number | null; // 1-5 star rating
  thumbnailUrl: string | null;
  creatorPublicId: string | null;
  userName: string | null;
  foodName: string | null;
  hashtags: string[];
  isVariant: boolean | null;
}

/**
 * Full log post detail response
 */
export interface LogPostDetail {
  publicId: string;
  title: string;
  content: string;
  rating: number | null; // 1-5 star rating
  images: ImageResponseDto[];
  linkedRecipe: RecipeSummary | null;
  createdAt: string; // ISO date string
  hashtags: HashtagDto[];
  isSavedByCurrentUser: boolean | null;
  creatorPublicId: string | null;
  userName: string | null;
  titleTranslations: Record<string, string> | null;
  contentTranslations: Record<string, string> | null;
}

/**
 * Recent activity for home feed
 */
export interface RecentActivity {
  logPublicId: string;
  rating: number | null; // 1-5 star rating
  thumbnailUrl: string | null;
  userName: string | null;
  recipeTitle: string;
  recipePublicId: string;
  foodName: string;
  createdAt: string; // ISO date string
  hashtags: string[];
}

/**
 * Rating display configuration
 * Star color based on rating value
 */
export function getRatingColor(rating: number): string {
  if (rating >= 4) return 'var(--success)';
  if (rating >= 3) return 'var(--diff-modified)';
  return 'var(--error)';
}

/**
 * Log update request
 * Used by PUT /api/v1/log_posts/{publicId}
 */
export interface UpdateLogRequest {
  content: string;
  rating: Rating;
  hashtags?: string[];
  // Note: images are read-only after creation
}

/**
 * Log create request
 * Used by POST /api/v1/log_posts
 */
export interface CreateLogRequest {
  recipePublicId: string;
  title?: string;
  content: string;
  rating: Rating;
  imagePublicIds: string[];
  hashtags?: string[];
}
