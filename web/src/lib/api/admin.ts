import { apiFetch, buildQueryString } from './client';
import type {
  UserSuggestedFood,
  SuggestedFoodFilter,
  PageResponse,
  SuggestionStatus,
  AdminUser,
  UserRole,
  UserSuggestedIngredient,
  SuggestedIngredientFilter,
  IngredientType,
  UntranslatedRecipe,
  UntranslatedRecipeFilter,
  UntranslatedLog,
  UntranslatedLogFilter,
} from '@/lib/types/admin';

/**
 * Get paginated list of suggested foods with filters
 */
export async function getSuggestedFoods(
  params: SuggestedFoodFilter & { page?: number; size?: number } = {},
): Promise<PageResponse<UserSuggestedFood>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
    suggestedName: params.suggestedName,
    localeCode: params.localeCode,
    status: params.status,
    username: params.username,
    sortBy: params.sortBy ?? 'createdAt',
    sortOrder: params.sortOrder ?? 'desc',
  });

  return apiFetch<PageResponse<UserSuggestedFood>>(
    `/admin/suggested-foods${queryString}`,
  );
}

/**
 * Update the status of a suggested food
 */
export async function updateSuggestedFoodStatus(
  publicId: string,
  status: SuggestionStatus,
): Promise<UserSuggestedFood> {
  return apiFetch<UserSuggestedFood>(
    `/admin/suggested-foods/${publicId}/status`,
    {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    },
  );
}

/**
 * Get paginated list of users with filters
 */
export async function getUsers(
  params: {
    page?: number;
    size?: number;
    username?: string;
    email?: string;
    role?: UserRole;
    sortBy?: string;
    sortOrder?: 'asc' | 'desc';
  } = {},
): Promise<PageResponse<AdminUser>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
    username: params.username,
    email: params.email,
    role: params.role,
    sortBy: params.sortBy ?? 'createdAt',
    sortOrder: params.sortOrder ?? 'desc',
  });

  return apiFetch<PageResponse<AdminUser>>(`/admin/users${queryString}`);
}

/**
 * Update the role of a user
 */
export async function updateUserRole(
  publicId: string,
  role: UserRole,
): Promise<AdminUser> {
  return apiFetch<AdminUser>(`/admin/users/${publicId}/role`, {
    method: 'PATCH',
    body: JSON.stringify({ role }),
  });
}

/**
 * Get paginated list of suggested ingredients with filters
 */
export async function getSuggestedIngredients(
  params: SuggestedIngredientFilter & { page?: number; size?: number } = {},
): Promise<PageResponse<UserSuggestedIngredient>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
    suggestedName: params.suggestedName,
    ingredientType: params.ingredientType,
    localeCode: params.localeCode,
    status: params.status,
    username: params.username,
    sortBy: params.sortBy ?? 'createdAt',
    sortOrder: params.sortOrder ?? 'desc',
  });

  return apiFetch<PageResponse<UserSuggestedIngredient>>(
    `/admin/suggested-ingredients${queryString}`,
  );
}

/**
 * Update the status of a suggested ingredient
 */
export async function updateSuggestedIngredientStatus(
  publicId: string,
  status: SuggestionStatus,
): Promise<UserSuggestedIngredient> {
  return apiFetch<UserSuggestedIngredient>(
    `/admin/suggested-ingredients/${publicId}/status`,
    {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    },
  );
}

/**
 * Get paginated list of untranslated recipes
 */
export async function getUntranslatedRecipes(
  params: UntranslatedRecipeFilter & { page?: number; size?: number } = {},
): Promise<PageResponse<UntranslatedRecipe>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
    title: params.title,
    sortBy: params.sortBy ?? 'createdAt',
    sortOrder: params.sortOrder ?? 'desc',
  });

  return apiFetch<PageResponse<UntranslatedRecipe>>(
    `/admin/untranslated-recipes${queryString}`,
  );
}

/**
 * Trigger re-translation for selected recipes
 */
export async function triggerRecipeRetranslation(
  publicIds: string[],
): Promise<{ message: string; recipesQueued: number }> {
  return apiFetch<{ message: string; recipesQueued: number }>(
    '/admin/untranslated-recipes/retranslate',
    {
      method: 'POST',
      body: JSON.stringify({ publicIds }),
    },
  );
}

/**
 * Get paginated list of untranslated logs
 */
export async function getUntranslatedLogs(
  params: UntranslatedLogFilter & { page?: number; size?: number } = {},
): Promise<PageResponse<UntranslatedLog>> {
  const queryString = buildQueryString({
    page: params.page ?? 0,
    size: params.size ?? 20,
    content: params.content,
    sortBy: params.sortBy ?? 'createdAt',
    sortOrder: params.sortOrder ?? 'desc',
  });

  return apiFetch<PageResponse<UntranslatedLog>>(
    `/admin/untranslated-logs${queryString}`,
  );
}

/**
 * Trigger re-translation for selected logs
 */
export async function triggerLogRetranslation(
  publicIds: string[],
): Promise<{ message: string; logsQueued: number }> {
  return apiFetch<{ message: string; logsQueued: number }>(
    '/admin/untranslated-logs/retranslate',
    {
      method: 'POST',
      body: JSON.stringify({ publicIds }),
    },
  );
}
