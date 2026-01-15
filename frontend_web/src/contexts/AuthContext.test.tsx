import { renderHook, act, waitFor } from '@testing-library/react';
import { ReactNode } from 'react';
import Cookies from 'js-cookie';
import { AuthProvider, useAuth } from './AuthContext';

// Mock firebase/auth
jest.mock('firebase/auth', () => ({
  signInWithPopup: jest.fn(),
  signOut: jest.fn(),
}));

// Mock firebase config
jest.mock('@/lib/firebase/config', () => ({
  auth: {},
  googleProvider: {},
  appleProvider: {},
}));

// Mock firebase providers
jest.mock('@/lib/firebase/providers', () => ({
  naverProvider: {},
  kakaoProvider: {},
}));

// Mock site config
jest.mock('@/config/site', () => ({
  siteConfig: {
    apiUrl: 'http://localhost:4001/api/v1',
  },
}));

const mockFetch = global.fetch as jest.Mock;

const wrapper = ({ children }: { children: ReactNode }) => (
  <AuthProvider>{children}</AuthProvider>
);

describe('AuthContext', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Default: user not authenticated
    mockFetch.mockResolvedValue({
      ok: false,
      status: 401,
    });
  });

  describe('Initial State', () => {
    it('should start with loading state', () => {
      const { result } = renderHook(() => useAuth(), { wrapper });

      // Initially loading
      expect(result.current.isLoading).toBe(true);
      expect(result.current.user).toBeNull();
      expect(result.current.isAuthenticated).toBe(false);
    });

    it('should check auth status on mount', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          user: { publicId: 'user-123', username: 'testuser' },
          recipeCount: 0,
          logCount: 0,
          savedCount: 0,
        }),
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:4001/api/v1/users/me',
        expect.objectContaining({
          credentials: 'include',
        })
      );
    });

    it('should set user when authenticated', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          // UserDto returns 'id' field (not 'publicId') for the user's public identifier
          user: { id: 'user-123', username: 'testuser' },
          recipeCount: 0,
          logCount: 0,
          savedCount: 0,
        }),
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      expect(result.current.user).toEqual({
        publicId: 'user-123',
        username: 'testuser',
      });
      expect(result.current.isAuthenticated).toBe(true);
    });

    it('should set user to null when not authenticated', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      expect(result.current.user).toBeNull();
      expect(result.current.isAuthenticated).toBe(false);
    });
  });

  describe('signOut', () => {
    it('should call logout endpoint', async () => {
      // Initial auth check
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          user: { publicId: 'user-123', username: 'testuser' },
          recipeCount: 0,
          logCount: 0,
          savedCount: 0,
        }),
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isAuthenticated).toBe(true);
      });

      // Mock logout endpoint
      mockFetch.mockResolvedValueOnce({
        ok: true,
      });

      await act(async () => {
        await result.current.signOut();
      });

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:4001/api/v1/auth/web/logout',
        expect.objectContaining({
          method: 'POST',
          credentials: 'include',
          headers: expect.objectContaining({
            'X-CSRF-Token': expect.any(String),
          }),
        })
      );
    });

    it('should clear user state after signOut', async () => {
      // Initial auth check
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          user: { publicId: 'user-123', username: 'testuser' },
          recipeCount: 0,
          logCount: 0,
          savedCount: 0,
        }),
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isAuthenticated).toBe(true);
      });

      // Mock logout endpoint
      mockFetch.mockResolvedValueOnce({
        ok: true,
      });

      await act(async () => {
        await result.current.signOut();
      });

      expect(result.current.user).toBeNull();
      expect(result.current.isAuthenticated).toBe(false);
    });

    it('should clear user state even if logout endpoint fails', async () => {
      // Initial auth check
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          user: { publicId: 'user-123', username: 'testuser' },
          recipeCount: 0,
          logCount: 0,
          savedCount: 0,
        }),
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isAuthenticated).toBe(true);
      });

      // Mock logout endpoint failure
      mockFetch.mockRejectedValueOnce(new Error('Network error'));

      await act(async () => {
        await result.current.signOut();
      });

      // Should still clear user state
      expect(result.current.user).toBeNull();
      expect(result.current.isAuthenticated).toBe(false);
    });
  });

  describe('refreshSession', () => {
    it('should call reissue endpoint', async () => {
      // Initial auth check fails
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      // Mock reissue endpoint
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          userPublicId: 'user-456',
          username: 'refresheduser',
        }),
      });

      let refreshResult: boolean = false;
      await act(async () => {
        refreshResult = await result.current.refreshSession();
      });

      expect(refreshResult).toBe(true);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:4001/api/v1/auth/web/reissue',
        expect.objectContaining({
          method: 'POST',
          credentials: 'include',
        })
      );
    });

    it('should update user state on successful refresh', async () => {
      // Initial auth check fails
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      // Mock reissue endpoint
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          userPublicId: 'user-456',
          username: 'refresheduser',
        }),
      });

      await act(async () => {
        await result.current.refreshSession();
      });

      expect(result.current.user).toEqual({
        publicId: 'user-456',
        username: 'refresheduser',
      });
      expect(result.current.isAuthenticated).toBe(true);
    });

    it('should return false on refresh failure', async () => {
      // Initial auth check fails
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      // Mock reissue endpoint failure
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      let refreshResult: boolean = true;
      await act(async () => {
        refreshResult = await result.current.refreshSession();
      });

      expect(refreshResult).toBe(false);
      expect(result.current.user).toBeNull();
    });

    it('should clear user state on refresh failure', async () => {
      // Initial auth check succeeds
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          user: { publicId: 'user-123', username: 'testuser' },
          recipeCount: 0,
          logCount: 0,
          savedCount: 0,
        }),
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isAuthenticated).toBe(true);
      });

      // Mock reissue endpoint failure
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      await act(async () => {
        await result.current.refreshSession();
      });

      expect(result.current.user).toBeNull();
      expect(result.current.isAuthenticated).toBe(false);
    });
  });

  describe('CSRF Token Usage', () => {
    it('should include CSRF token in signOut request', async () => {
      (Cookies.get as jest.Mock).mockReturnValue('test-csrf-token');

      // Initial auth check
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          user: { publicId: 'user-123', username: 'testuser' },
          recipeCount: 0,
          logCount: 0,
          savedCount: 0,
        }),
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isAuthenticated).toBe(true);
      });

      // Mock logout endpoint
      mockFetch.mockResolvedValueOnce({
        ok: true,
      });

      await act(async () => {
        await result.current.signOut();
      });

      // Find the logout call
      const logoutCall = mockFetch.mock.calls.find(
        (call) => call[0].includes('/logout')
      );

      expect(logoutCall).toBeDefined();
      expect(logoutCall[1].headers['X-CSRF-Token']).toBe('test-csrf-token');
    });

    it('should include CSRF token in refreshSession request', async () => {
      (Cookies.get as jest.Mock).mockReturnValue('test-csrf-token');

      // Initial auth check fails
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      // Mock reissue endpoint
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          userPublicId: 'user-456',
          username: 'refresheduser',
        }),
      });

      await act(async () => {
        await result.current.refreshSession();
      });

      // Find the reissue call
      const reissueCall = mockFetch.mock.calls.find(
        (call) => call[0].includes('/reissue')
      );

      expect(reissueCall).toBeDefined();
      expect(reissueCall[1].headers['X-CSRF-Token']).toBe('test-csrf-token');
    });
  });

  describe('useAuth hook', () => {
    it('should throw error when used outside AuthProvider', () => {
      // Suppress console.error for this test
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

      expect(() => {
        renderHook(() => useAuth());
      }).toThrow('useAuth must be used within AuthProvider');

      consoleSpy.mockRestore();
    });
  });

  describe('Error Handling', () => {
    it('should handle network errors during auth check', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network error'));

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      expect(result.current.user).toBeNull();
      expect(result.current.isAuthenticated).toBe(false);
    });

    it('should handle network errors during refresh', async () => {
      // Initial auth check fails
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      const { result } = renderHook(() => useAuth(), { wrapper });

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      // Mock network error
      mockFetch.mockRejectedValueOnce(new Error('Network error'));

      let refreshResult: boolean = true;
      await act(async () => {
        refreshResult = await result.current.refreshSession();
      });

      expect(refreshResult).toBe(false);
      expect(result.current.user).toBeNull();
    });
  });
});
