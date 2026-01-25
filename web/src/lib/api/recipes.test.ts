import { getRecipes } from './recipes';

// Mock the client module
jest.mock('./client', () => ({
  apiFetch: jest.fn(),
  buildQueryString: jest.fn((params) => {
    const entries = Object.entries(params).filter(([, v]) => v !== undefined);
    if (entries.length === 0) return '';
    return '?' + entries.map(([k, v]) => `${k}=${encodeURIComponent(String(v))}`).join('&');
  }),
}));

import { apiFetch, buildQueryString } from './client';

const mockApiFetch = apiFetch as jest.Mock;
const mockBuildQueryString = buildQueryString as jest.Mock;

describe('getRecipes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockApiFetch.mockResolvedValue({
      content: [],
      totalElements: 0,
      totalPages: 0,
      currentPage: 0,
    });
  });

  describe('sort parameter', () => {
    it('should pass popular sort parameter', async () => {
      await getRecipes({ sort: 'popular' });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'popular',
        })
      );
    });

    it('should pass trending sort parameter', async () => {
      await getRecipes({ sort: 'trending' });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'trending',
        })
      );
    });

    it('should pass mostForked sort parameter', async () => {
      await getRecipes({ sort: 'mostForked' });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'mostForked',
        })
      );
    });

    it('should pass recent sort parameter', async () => {
      await getRecipes({ sort: 'recent' });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'recent',
        })
      );
    });

    it('should not pass sort parameter when not provided', async () => {
      await getRecipes({});

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: undefined,
        })
      );
    });

    it('should combine sort with locale filter', async () => {
      await getRecipes({ sort: 'popular', locale: 'ko-KR' });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'popular',
          locale: 'ko-KR',
        })
      );
    });

    it('should combine sort with typeFilter', async () => {
      await getRecipes({ sort: 'trending', typeFilter: 'original' });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'trending',
          typeFilter: 'original',
        })
      );
    });

    it('should combine sort with pagination', async () => {
      await getRecipes({ sort: 'popular', page: 1, size: 12 });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'popular',
          page: 1,
          size: 12,
        })
      );
    });
  });

  describe('default parameters', () => {
    it('should use default page 0 and size 20', async () => {
      await getRecipes({});

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          page: 0,
          size: 20,
        })
      );
    });
  });
});
