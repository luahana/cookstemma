export type SuggestionStatus = 'PENDING' | 'APPROVED' | 'REJECTED';
export type UserRole = 'USER' | 'ADMIN' | 'CREATOR' | 'BOT';
export type AccountStatus = 'ACTIVE' | 'BANNED' | 'DELETED';

export interface AdminUser {
  publicId: string;
  username: string;
  email: string;
  role: UserRole;
  status: AccountStatus;
  createdAt: string;
  lastLoginAt: string | null;
}

export interface UserSuggestedFood {
  publicId: string;
  suggestedName: string;
  localeCode: string;
  status: SuggestionStatus;
  userPublicId: string;
  username: string;
  masterFoodPublicId: string | null;
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
  userPublicId: string | null;
  username: string | null;
  autocompleteItemPublicId: string | null;
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
