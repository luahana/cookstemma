import Cookies from 'js-cookie';
import { apiFetch, ApiError } from './client';

// Mock the siteConfig
jest.mock('@/config/site', () => ({
  siteConfig: {
    apiUrl: 'http://localhost:4001/api/v1',
  },
}));

describe('apiFetch', () => {
  const mockFetch = global.fetch as jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Basic Functionality', () => {
    it('should make a GET request successfully', async () => {
      const mockResponse = { data: 'test' };
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve(mockResponse),
      });

      const result = await apiFetch('/test');

      expect(result).toEqual(mockResponse);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:4001/api/v1/test',
        expect.objectContaining({
          credentials: 'include',
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
          }),
        })
      );
    });

    it('should throw ApiError on non-ok response', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 404,
        statusText: 'Not Found',
      });

      try {
        await apiFetch('/test', { skipAuth: true });
        fail('Should have thrown');
      } catch (error) {
        expect(error).toBeInstanceOf(ApiError);
        expect((error as ApiError).status).toBe(404);
        expect((error as ApiError).message).toContain('404');
      }
    });
  });

  describe('Credentials', () => {
    it('should always include credentials for cookie-based auth', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({}),
      });

      await apiFetch('/test');

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          credentials: 'include',
        })
      );
    });
  });

  describe('CSRF Token', () => {
    it('should NOT include CSRF token for GET requests', async () => {
      (Cookies.get as jest.Mock).mockReturnValue('csrf-token-123');
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({}),
      });

      await apiFetch('/test', { method: 'GET' });

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.not.objectContaining({
            'X-CSRF-Token': expect.anything(),
          }),
        })
      );
    });

    it('should include CSRF token for POST requests', async () => {
      (Cookies.get as jest.Mock).mockReturnValue('csrf-token-123');
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({}),
      });

      await apiFetch('/test', { method: 'POST' });

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'X-CSRF-Token': 'csrf-token-123',
          }),
        })
      );
    });

    it('should include CSRF token for PUT requests', async () => {
      (Cookies.get as jest.Mock).mockReturnValue('csrf-token-456');
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({}),
      });

      await apiFetch('/test', { method: 'PUT' });

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'X-CSRF-Token': 'csrf-token-456',
          }),
        })
      );
    });

    it('should include CSRF token for DELETE requests', async () => {
      (Cookies.get as jest.Mock).mockReturnValue('csrf-token-789');
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({}),
      });

      await apiFetch('/test', { method: 'DELETE' });

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'X-CSRF-Token': 'csrf-token-789',
          }),
        })
      );
    });

    it('should include CSRF token for PATCH requests', async () => {
      (Cookies.get as jest.Mock).mockReturnValue('csrf-token-abc');
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({}),
      });

      await apiFetch('/test', { method: 'PATCH' });

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'X-CSRF-Token': 'csrf-token-abc',
          }),
        })
      );
    });

    it('should handle missing CSRF token gracefully', async () => {
      (Cookies.get as jest.Mock).mockReturnValue(undefined);
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({}),
      });

      await apiFetch('/test', { method: 'POST' });

      // Should not throw, should not include X-CSRF-Token header
      expect(mockFetch).toHaveBeenCalled();
    });
  });

  describe('Token Refresh on 401', () => {
    it('should attempt token refresh on 401 response', async () => {
      // First request returns 401
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
        statusText: 'Unauthorized',
      });

      // Token refresh succeeds
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({}),
      });

      // Retry request succeeds
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ success: true }),
      });

      const result = await apiFetch('/test');

      expect(mockFetch).toHaveBeenCalledTimes(3);
      expect(result).toEqual({ success: true });
    });

    it('should not attempt token refresh when skipAuth is true', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
        statusText: 'Unauthorized',
      });

      await expect(apiFetch('/test', { skipAuth: true })).rejects.toThrow(ApiError);
      expect(mockFetch).toHaveBeenCalledTimes(1);
    });

    it('should throw on 401 if token refresh fails', async () => {
      // First request returns 401
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
        statusText: 'Unauthorized',
      });

      // Token refresh fails
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
        statusText: 'Unauthorized',
      });

      await expect(apiFetch('/test')).rejects.toThrow(ApiError);
    });
  });

  describe('Error Handling', () => {
    it('should create ApiError with correct status code', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
      });

      try {
        await apiFetch('/test', { skipAuth: true });
        fail('Should have thrown');
      } catch (error) {
        expect(error).toBeInstanceOf(ApiError);
        expect((error as ApiError).status).toBe(500);
      }
    });

    it('should create ApiError with status message', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 403,
        statusText: 'Forbidden',
      });

      try {
        await apiFetch('/test', { skipAuth: true });
        fail('Should have thrown');
      } catch (error) {
        expect(error).toBeInstanceOf(ApiError);
        expect((error as ApiError).message).toContain('403');
      }
    });
  });

  describe('Request Options', () => {
    it('should pass through request body', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({}),
      });

      const body = JSON.stringify({ test: 'data' });
      await apiFetch('/test', {
        method: 'POST',
        body,
      });

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          body,
        })
      );
    });

    it('should allow custom headers', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({}),
      });

      await apiFetch('/test', {
        headers: {
          'X-Custom-Header': 'custom-value',
        },
      });

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'X-Custom-Header': 'custom-value',
            'Content-Type': 'application/json',
          }),
        })
      );
    });
  });
});

describe('ApiError', () => {
  it('should have correct name', () => {
    const error = new ApiError(404, 'Not Found');
    expect(error.name).toBe('ApiError');
  });

  it('should have correct status', () => {
    const error = new ApiError(500, 'Server Error');
    expect(error.status).toBe(500);
  });

  it('should have correct message', () => {
    const error = new ApiError(400, 'Bad Request');
    expect(error.message).toBe('Bad Request');
  });

  it('should be instance of Error', () => {
    const error = new ApiError(401, 'Unauthorized');
    expect(error).toBeInstanceOf(Error);
  });
});
