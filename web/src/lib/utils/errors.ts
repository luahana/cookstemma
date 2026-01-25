import { ApiError } from '@/lib/api/client';

/**
 * Map backend error codes to translation keys
 * Backend codes are defined in GlobalExceptionHandler.java
 */
const ERROR_CODE_MAP: Record<string, string> = {
  AUTH_REQUIRED: 'errors.sessionExpired',
  VALIDATION_ERROR: 'errors.validationError',
  INVALID_INPUT: 'errors.validationError',
  ACCESS_DENIED: 'errors.forbidden',
  FILE_TOO_LARGE: 'errors.fileTooLarge',
  SERVER_ERROR: 'errors.serverError',
  TYPE_MISMATCH: 'errors.validationError',
  MISSING_PARAMETER: 'errors.validationError',
};

/**
 * Get the translation key for an error
 * Uses error code if available, falls back to HTTP status
 */
export function getErrorTranslationKey(error: unknown): string {
  if (error instanceof ApiError) {
    // First try to map by error code
    if (error.code && ERROR_CODE_MAP[error.code]) {
      return ERROR_CODE_MAP[error.code];
    }
    // Fallback based on HTTP status code
    if (error.status === 401) return 'errors.sessionExpired';
    if (error.status === 403) return 'errors.forbidden';
    if (error.status === 404) return 'errors.notFound';
    if (error.status === 413) return 'errors.fileTooLarge';
    if (error.status === 429) return 'errors.rateLimited';
    if (error.status >= 500) return 'errors.serverError';
  }

  // Check for network errors
  if (isNetworkError(error)) {
    return 'errors.networkError';
  }

  return 'errors.unknownError';
}

/**
 * Check if error is a network/connection error
 */
export function isNetworkError(error: unknown): boolean {
  return error instanceof TypeError && error.message === 'Failed to fetch';
}

/**
 * Get a user-friendly error message from an error
 * Returns the backend message if available, otherwise the raw message
 */
export function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    return error.message;
  }
  if (error instanceof Error) {
    return error.message;
  }
  return 'An unexpected error occurred';
}
