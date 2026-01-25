import { getLogs } from './logs';

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

describe('getLogs', () => {
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
    it('should pass sort parameter to buildQueryString when provided', async () => {
      await getLogs({ sort: 'popular' });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'popular',
        })
      );
    });

    it('should pass trending sort parameter', async () => {
      await getLogs({ sort: 'trending' });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'trending',
        })
      );
    });

    it('should pass recent sort parameter', async () => {
      await getLogs({ sort: 'recent' });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'recent',
        })
      );
    });

    it('should not pass sort parameter when not provided', async () => {
      await getLogs({});

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: undefined,
        })
      );
    });

    it('should combine sort with rating filter', async () => {
      await getLogs({ sort: 'popular', minRating: 4 });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'popular',
          minRating: 4,
        })
      );
    });

    it('should combine sort with pagination', async () => {
      await getLogs({ sort: 'trending', page: 2, size: 10 });

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          sort: 'trending',
          page: 2,
          size: 10,
        })
      );
    });
  });

  describe('default parameters', () => {
    it('should use default page 0 and size 20', async () => {
      await getLogs({});

      expect(mockBuildQueryString).toHaveBeenCalledWith(
        expect.objectContaining({
          page: 0,
          size: 20,
        })
      );
    });
  });
});
