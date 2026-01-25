export type SuggestionStatus = 'PENDING' | 'APPROVED' | 'REJECTED';
export type UserRole = 'USER' | 'ADMIN' | 'CREATOR' | 'BOT';
export type AccountStatus = 'ACTIVE' | 'BANNED' | 'DELETED';

export interface AdminUser {
  publicId: string;
  username: string;
  email: string;
  role: UserRole;
  status: AccountStatus;
  locale: string | null;
  createdAt: string;
  lastLoginAt: string | null;
}

export interface UserSuggestedFood {
  publicId: string;
  suggestedName: string;
  localeCode: string;
  status: SuggestionStatus;
  rejectionReason: string | null;
  userPublicId: string;
  username: string;
  masterFoodPublicId: string | null;
  masterFoodNameKo: string | null;
  masterFoodNameEn: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface SuggestedFoodFilter {
  suggestedName?: string;
  localeCode?: string;
  status?: SuggestionStatus;
  username?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
  empty: boolean;
}

export type IngredientType = 'MAIN' | 'SECONDARY' | 'SEASONING';

export interface UserSuggestedIngredient {
  publicId: string;
  suggestedName: string;
  ingredientType: IngredientType;
  localeCode: string;
  status: SuggestionStatus;
  rejectionReason: string | null;
  userPublicId: string | null;
  username: string | null;
  autocompleteItemPublicId: string | null;
  autocompleteItemNameKo: string | null;
  autocompleteItemNameEn: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface SuggestedIngredientFilter {
  suggestedName?: string;
  ingredientType?: IngredientType;
  localeCode?: string;
  status?: SuggestionStatus;
  username?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export type TranslationStatus = 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED';

export interface UntranslatedRecipe {
  publicId: string;
  title: string;
  cookingStyle: string;
  translationStatus: TranslationStatus | null;
  lastError: string | null;
  translatedLocaleCount: number;
  totalLocaleCount: number;
  creatorUsername: string;
  createdAt: string;
}

export interface UntranslatedRecipeFilter {
  title?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface UntranslatedLog {
  publicId: string;
  content: string;
  translationStatus: TranslationStatus | null;
  lastError: string | null;
  translatedLocaleCount: number;
  totalLocaleCount: number;
  creatorUsername: string;
  createdAt: string;
}

export interface UntranslatedLogFilter {
  content?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface FoodMasterAdmin {
  publicId: string;
  name: Record<string, string>;
  categoryName: Record<string, string> | null;
  description: Record<string, string>;
  searchKeywords: Record<string, string> | null;
  foodScore: number;
  isVerified: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface FoodMasterAdminFilter {
  name?: string;
  isVerified?: boolean;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}
