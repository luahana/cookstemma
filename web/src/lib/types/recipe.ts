import type { LogPostSummary } from './log';
import type { HashtagDto, ImageResponseDto } from './common';

/**
 * Recipe summary for list/card views.
 * All string fields (title, description, foodName, rootTitle) are pre-localized
 * by the backend based on the Accept-Language header.
 */
export interface RecipeSummary {
  publicId: string;
  foodName: string; // Localized food name
  foodMasterPublicId: string;
  title: string; // Localized title
  description: string; // Localized description
  cookingStyle: string;
  creatorPublicId: string | null;
  userName: string | null;
  thumbnail: string | null;
  variantCount: number;
  logCount: number;
  parentPublicId: string | null;
  rootPublicId: string | null;
  rootTitle: string | null; // Localized root title
  servings: number;
  cookingTimeRange: string;
  hashtags: string[];
  isPrivate: boolean; // Whether this recipe is private (only visible to creator)
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
 * Recipe ingredient.
 * The name field is pre-localized by the backend.
 */
export interface IngredientDto {
  name: string; // Localized ingredient name
  quantity: number | null; // Numeric quantity
  unit: MeasurementUnit | null; // Standardized unit
  type: IngredientType;
}

/**
 * Recipe step.
 * The description field is pre-localized by the backend.
 */
export interface StepDto {
  stepNumber: number;
  description: string; // Localized step description
  imagePublicId: string | null;
  imageUrl: string | null;
}

/**
 * Full recipe detail response.
 * All string fields (title, description, foodName) are pre-localized
 * by the backend based on the Accept-Language header.
 */
export interface RecipeDetail {
  publicId: string;
  title: string; // Localized title
  description: string; // Localized description
  cookingStyle: string;
  foodName: string; // Localized food name
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
  isPrivate: boolean; // Whether this recipe is private (only visible to creator)
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
 * Cooking time range enum values (matches backend CookingTimeRange.java)
 * Maps backend enum values to translation keys in the 'filters' namespace
 */
export const COOKING_TIME_TRANSLATION_KEYS: Record<string, string> = {
  UNDER_15_MIN: 'timeUnder15',
  MIN_15_TO_30: 'time15to30',
  MIN_30_TO_60: 'time30to60',
  HOUR_1_TO_2: 'time1to2hours',
  OVER_2_HOURS: 'timeOver2hours',
};

export type CookingTimeRange = keyof typeof COOKING_TIME_TRANSLATION_KEYS;

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
  isPrivate?: boolean; // Whether this recipe is private
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
  isPrivate?: boolean; // Whether this recipe is private
  // Variant fields
  parentPublicId?: string | null;
  rootPublicId?: string | null;
  changeCategory?: string | null;
  changeDiff?: Record<string, unknown> | null;
  changeReason?: string | null;
}
