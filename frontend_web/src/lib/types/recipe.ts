import type { LogPostSummary } from './log';
import type { HashtagDto, ImageResponseDto } from './common';

/**
 * Recipe summary for list/card views
 */
export interface RecipeSummary {
  publicId: string;
  foodName: string;
  foodMasterPublicId: string;
  title: string;
  description: string;
  cookingStyle: string;
  creatorPublicId: string | null;
  userName: string | null;
  thumbnail: string | null;
  variantCount: number;
  logCount: number;
  parentPublicId: string | null;
  rootPublicId: string | null;
  rootTitle: string | null;
  servings: number;
  cookingTimeRange: string;
  hashtags: string[];
  titleTranslations?: Record<string, string> | null;
  descriptionTranslations?: Record<string, string> | null;
}

/**
 * Ingredient types (matches backend IngredientType.java)
 */
export type IngredientType = 'MAIN' | 'SECONDARY' | 'SEASONING';

/**
 * Measurement units (matches backend MeasurementUnit.java)
 */
export type MeasurementUnit =
  | 'ML'
  | 'L'
  | 'TSP'
  | 'TBSP'
  | 'CUP'
  | 'FL_OZ'
  | 'PINT'
  | 'QUART'
  | 'G'
  | 'KG'
  | 'OZ'
  | 'LB'
  | 'PIECE'
  | 'PINCH'
  | 'DASH'
  | 'TO_TASTE'
  | 'CLOVE'
  | 'BUNCH'
  | 'CAN'
  | 'PACKAGE';

/**
 * Recipe ingredient
 */
export interface IngredientDto {
  name: string;
  quantity: number | null; // Numeric quantity
  unit: MeasurementUnit | null; // Standardized unit
  type: IngredientType;
  nameTranslations?: Record<string, string> | null; // Translations by locale (optional, populated by backend)
}

/**
 * Recipe step
 */
export interface StepDto {
  stepNumber: number;
  description: string;
  imagePublicId: string | null;
  imageUrl: string | null;
  descriptionTranslations?: Record<string, string> | null; // Translations by locale (optional, populated by backend)
}

/**
 * Full recipe detail response
 */
export interface RecipeDetail {
  publicId: string;
  title: string;
  description: string;
  cookingStyle: string;
  foodName: string;
  foodMasterPublicId: string;
  creatorPublicId: string | null;
  userName: string | null;
  changeCategory: string | null;
  rootInfo: RecipeSummary | null;
  parentInfo: RecipeSummary | null;
  ingredients: IngredientDto[];
  steps: StepDto[];
  images: ImageResponseDto[];
  variants: RecipeSummary[];
  logs: LogPostSummary[];
  hashtags: HashtagDto[];
  isSavedByCurrentUser: boolean | null;
  changeDiff: Record<string, unknown> | null;
  changeCategories: string[] | null;
  changeReason: string | null;
  servings: number;
  cookingTimeRange: string;
  titleTranslations: Record<string, string> | null;
  descriptionTranslations: Record<string, string> | null;
}

/**
 * Trending tree for home page
 */
export interface TrendingTree {
  rootRecipeId: string;
  title: string;
  foodName: string;
  cookingStyle: string;
  thumbnail: string | null;
  variantCount: number;
  logCount: number;
  latestChangeSummary: string | null;
  userName: string | null;
  creatorPublicId: string | null;
}

/**
 * Cooking time range enum values
 */
export const COOKING_TIME_RANGES = {
  MIN_0_TO_15: '0-15 min',
  MIN_15_TO_30: '15-30 min',
  MIN_30_TO_60: '30-60 min',
  MIN_60_TO_120: '1-2 hours',
  MIN_120_PLUS: '2+ hours',
} as const;

export type CookingTimeRange = keyof typeof COOKING_TIME_RANGES;

/**
 * Recipe modifiable check response
 * Returned by GET /api/v1/recipes/{publicId}/modifiable
 */
export interface RecipeModifiable {
  canModify: boolean;
  isOwner: boolean;
  hasVariants: boolean;
  hasLogs: boolean;
  variantCount: number;
  logCount: number;
  reason: string | null; // Error message when blocked
}

/**
 * Recipe update request
 * Used by PUT /api/v1/recipes/{publicId}
 */
export interface UpdateRecipeRequest {
  title: string;
  description?: string;
  cookingStyle?: string;
  ingredients: IngredientDto[];
  steps: Array<{
    stepNumber: number;
    description: string;
    imagePublicId?: string | null;
  }>;
  imagePublicIds: string[];
  hashtags?: string[];
  servings?: number;
  cookingTimeRange?: string;
}

/**
 * Recipe create request
 * Used by POST /api/v1/recipes
 */
export interface CreateRecipeRequest {
  title: string;
  description?: string;
  cookingStyle?: string;
  newFoodName?: string; // Required for new recipes, null for variants
  food1MasterPublicId?: string | null;
  ingredients: IngredientDto[];
  steps: Array<{
    stepNumber: number;
    description: string;
    imagePublicId?: string | null;
  }>;
  imagePublicIds: string[];
  hashtags?: string[];
  servings?: number;
  cookingTimeRange?: string;
  // Variant fields
  parentPublicId?: string | null;
  rootPublicId?: string | null;
  changeCategory?: string | null;
  changeDiff?: Record<string, unknown> | null;
  changeReason?: string | null;
}
