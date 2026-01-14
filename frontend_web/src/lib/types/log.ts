import type { RecipeSummary } from './recipe';
import type { HashtagDto, ImageResponseDto } from './common';

/**
 * Cooking outcome types
 */
export type Outcome = 'SUCCESS' | 'PARTIAL' | 'FAILED';

/**
 * Log post summary for list/card views
 */
export interface LogPostSummary {
  publicId: string;
  title: string;
  outcome: Outcome;
  thumbnailUrl: string | null;
  creatorPublicId: string | null;
  creatorName: string | null;
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
  outcome: Outcome;
  images: ImageResponseDto[];
  linkedRecipe: RecipeSummary | null;
  createdAt: string; // ISO date string
  hashtags: HashtagDto[];
  isSavedByCurrentUser: boolean | null;
  creatorPublicId: string | null;
  creatorName: string | null;
}

/**
 * Recent activity for home feed
 */
export interface RecentActivity {
  logPublicId: string;
  outcome: Outcome;
  thumbnailUrl: string | null;
  creatorName: string | null;
  recipeTitle: string;
  recipePublicId: string;
  foodName: string;
  createdAt: string; // ISO date string
  hashtags: string[];
}

/**
 * Outcome display labels and colors
 */
export const OUTCOME_CONFIG = {
  SUCCESS: {
    label: 'Success',
    color: 'var(--success)',
    bgColor: 'var(--diff-added-bg)',
  },
  PARTIAL: {
    label: 'Partial',
    color: 'var(--diff-modified)',
    bgColor: 'var(--diff-modified-bg)',
  },
  FAILED: {
    label: 'Failed',
    color: 'var(--error)',
    bgColor: 'var(--diff-removed-bg)',
  },
} as const;

/**
 * Log update request
 * Used by PUT /api/v1/log_posts/{publicId}
 */
export interface UpdateLogRequest {
  content: string;
  outcome: Outcome;
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
  outcome: Outcome;
  imagePublicIds: string[];
  hashtags?: string[];
}
