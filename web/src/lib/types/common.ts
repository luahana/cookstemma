/**
 * Image response from API
 */
export interface ImageResponseDto {
  imagePublicId: string;
  imageUrl: string;
}

/**
 * Image upload response
 */
export interface ImageUploadResponse {
  imagePublicId: string;
  imageUrl: string;
}

/**
 * Image type for upload
 */
export type ImageType = 'LOG_POST' | 'COVER' | 'STEP';

/**
 * Hashtag data
 */
export interface HashtagDto {
  publicId: string;
  name: string;
}

/**
 * Hashtag with counts
 */
export interface HashtagCounts {
  exists: boolean;
  normalizedName: string;
  recipeCount: number;
  logPostCount: number;
}

/**
 * Content item with hashtags (unified feed of recipes and logs)
 */
export interface HashtaggedContentItem {
  type: 'recipe' | 'log';
  publicId: string;
  title: string;
  thumbnailUrl: string | null;
  creatorPublicId: string | null;
  userName: string | null;
  hashtags: string[];
  foodName?: string;        // For recipes
  cookingStyle?: string;    // For recipes
  rating?: number;          // For logs (1-5)
  recipeTitle?: string;     // For logs (linked recipe title)
  isPrivate: boolean;
}
