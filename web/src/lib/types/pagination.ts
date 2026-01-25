/**
 * Unified pagination response supporting both offset-based (web) and cursor-based (mobile) pagination.
 * For web, we use offset-based pagination with page numbers.
 */
export interface UnifiedPageResponse<T> {
  content: T[];
  totalElements: number | null; // Total count (offset pagination only)
  totalPages: number | null; // Total pages (offset pagination only)
  currentPage: number | null; // Current page, 0-indexed (offset pagination only)
  nextCursor: string | null; // Cursor for next page (cursor pagination only)
  hasNext: boolean;
  size: number;
}

/**
 * Parameters for offset-based pagination (web)
 */
export interface PaginationParams {
  page?: number;
  size?: number;
}

/**
 * Parameters for search with pagination
 */
export interface SearchParams extends PaginationParams {
  q?: string;
}
