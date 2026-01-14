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

interface RecipeSearchParams extends PaginationParams {
  q?: string;
  locale?: string;
  onlyRoot?: boolean;
  typeFilter?: 'original' | 'variants';
  sort?: 'recent' | 'mostForked' | 'trending';
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
  });

  return apiFetch<UnifiedPageResponse<RecipeSummary>>(`/recipes${queryString}`, {
    next: { revalidate: 60 }, // Cache for 1 minute
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
