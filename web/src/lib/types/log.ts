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
  content: string | null; // Cooking notes (for display in recipe detail logs gallery)
  rating: number | null; // 1-5 star rating
  thumbnailUrl: string | null;
  creatorPublicId: string | null;
  userName: string | null;
  foodName: string | null;
  recipeTitle: string | null; // Linked recipe's title
  hashtags: string[];
  isVariant: boolean | null;
  isPrivate: boolean; // Whether this log is private (only visible to creator)
  commentCount: number; // Number of comments on this log
  cookingStyle: string | null; // Cooking style (locale code) from linked recipe
}

/**
 * Full log post detail response.
 * All string fields (title, content) are pre-localized
 * by the backend based on the Accept-Language header.
 */
export interface LogPostDetail {
  publicId: string;
  title: string; // Localized title
  content: string; // Localized content
  rating: number | null; // 1-5 star rating
  images: ImageResponseDto[];
  linkedRecipe: RecipeSummary | null;
  createdAt: string; // ISO date string
  hashtags: HashtagDto[];
  isSavedByCurrentUser: boolean | null;
  creatorPublicId: string | null;
  userName: string | null;
  isPrivate: boolean; // Whether this log is private (only visible to creator)
  commentCount: number; // Number of comments on this log
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
  commentCount: number; // Number of comments on this log
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
  imagePublicIds?: string[];
  isPrivate?: boolean; // Whether this log is private
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
  isPrivate?: boolean; // Whether this log is private
}
