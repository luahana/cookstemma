import { apiFetch, buildQueryString } from './client';
import type {
  RecipeSummary,
  RecipeDetail,
  RecipeModifiable,
  CreateRecipeRequest,
  UpdateRecipeRequest,
  UnifiedPageResponse,
  PaginationParams,
} from '@/lib/types';

/**
 * Cooking time filter values matching backend CookingTimeRange enum
 */
export type CookingTimeFilter =
  | 'UNDER_15_MIN'
  | 'MIN_15_TO_30'
  | 'MIN_30_TO_60'
  | 'HOUR_1_TO_2'
  | 'OVER_2_HOURS';

interface RecipeSearchParams extends PaginationParams {
  q?: string;
  locale?: string; // Cooking style filter (e.g., korean, japanese)
  onlyRoot?: boolean;
  typeFilter?: 'original' | 'variants';
  sort?: 'recent' | 'popular' | 'mostForked' | 'trending';
  cookingTime?: CookingTimeFilter[];
  minServings?: number;
  maxServings?: number;
  contentLocale?: string; // Accept-Language header for content translation (SSR)
}

/**
 * Get paginated list of recipes with optional search/filter
 */
export async function getRecipes(
  params: RecipeSearchParams = {},
): Promise<UnifiedPageResponse<RecipeSummary>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
    q: params.q,
    locale: params.locale,
    onlyRoot: params.onlyRoot,
    typeFilter: params.typeFilter,
    sort: params.sort,
    cookingTime: params.cookingTime?.join(','),
    minServings: params.minServings,
    maxServings: params.maxServings,
  });

  return apiFetch<UnifiedPageResponse<RecipeSummary>>(`/recipes${queryString}`, {
    next: { revalidate: 60 }, // Cache for 1 minute
    locale: params.contentLocale, // Pass to Accept-Language header for SSR
  });
}

/**
 * Get recipe detail by publicId
 */
export async function getRecipeDetail(publicId: string): Promise<RecipeDetail> {
  return apiFetch<RecipeDetail>(`/recipes/${publicId}`, {
    next: { revalidate: 300 }, // Cache for 5 minutes
  });
}

/**
 * Get all recipe IDs for sitemap generation
 */
export async function getAllRecipeIds(): Promise<string[]> {
  const result = await apiFetch<UnifiedPageResponse<RecipeSummary>>(
    '/recipes?page=0&size=1000',
    {
      next: { revalidate: 3600 }, // Cache for 1 hour
    },
  );
  return result.content.map((r) => r.publicId);
}

/**
 * Check if a recipe can be modified (edit/delete)
 * Returns modifiable status with reason if blocked
 */
export async function getRecipeModifiable(
  publicId: string,
): Promise<RecipeModifiable> {
  return apiFetch<RecipeModifiable>(`/recipes/${publicId}/modifiable`, {
    cache: 'no-store', // Always fetch fresh
  });
}

/**
 * Update an existing recipe
 * Requires ownership and no variants/logs
 */
export async function updateRecipe(
  publicId: string,
  data: UpdateRecipeRequest,
): Promise<RecipeDetail> {
  return apiFetch<RecipeDetail>(`/recipes/${publicId}`, {
    method: 'PUT',
    body: JSON.stringify(data),
    cache: 'no-store',
  });
}

/**
 * Delete a recipe (soft delete)
 * Requires ownership and no variants/logs
 */
export async function deleteRecipe(publicId: string): Promise<void> {
  await apiFetch<void>(`/recipes/${publicId}`, {
    method: 'DELETE',
    cache: 'no-store',
  });
}

/**
 * Create a new recipe
 * Requires authentication
 */
export async function createRecipe(data: CreateRecipeRequest): Promise<RecipeDetail> {
  return apiFetch<RecipeDetail>('/recipes', {
    method: 'POST',
    body: JSON.stringify(data),
    cache: 'no-store',
  });
}
