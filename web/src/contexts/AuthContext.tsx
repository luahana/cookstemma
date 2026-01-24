'use client';

import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  ReactNode,
} from 'react';
import {
  signInWithPopup,
  signOut as firebaseSignOut,
  type AuthProvider as FirebaseAuthProvider,
} from 'firebase/auth';
import Cookies from 'js-cookie';
import { auth, googleProvider, appleProvider, isFirebaseConfigured } from '@/lib/firebase/config';
import type { SocialProvider } from '@/lib/firebase/providers';
import { getApiUrl } from '@/config/site';
import { MEASUREMENT_STORAGE_KEY } from '@/lib/utils/measurement';

export type UserRole = 'USER' | 'ADMIN' | 'CREATOR' | 'BOT';

interface User {
  publicId: string;
  username: string;
  role: UserRole;
}

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  isAdmin: boolean;
  signIn: (provider: SocialProvider) => Promise<void>;
  signOut: () => Promise<void>;
  refreshSession: () => Promise<boolean>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// No-op: Sentry user context disabled until @sentry/nextjs supports Next.js 16
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function setSentryUser(_user: User | null) {
  // No-op
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Check auth status on mount
  useEffect(() => {
    checkAuthStatus();
  }, []);

  const checkAuthStatus = async () => {
    console.log('[Auth] Checking auth status...');
    try {
      const response = await fetch(`${getApiUrl()}/users/me`, {
        credentials: 'include',
      });

      console.log('[Auth] /users/me response:', response.status);

      if (response.ok) {
        const data = await response.json();
        // /users/me returns MyProfileResponseDto which wraps user in a 'user' property
        // UserDto uses 'id' field (not 'publicId') for the user's public identifier
        const userData = data.user;
        console.log('[Auth] User authenticated:', userData.username, 'role:', userData.role);
        const newUser = { publicId: userData.id, username: userData.username, role: userData.role || 'USER' };
        setUser(newUser);
        setSentryUser(newUser);

        // Sync user's measurement preference to localStorage
        if (userData.measurementPreference) {
          localStorage.setItem(MEASUREMENT_STORAGE_KEY, userData.measurementPreference);
        }
      } else {
        console.log('[Auth] Not authenticated, clearing stale cookies via logout endpoint');
        // Call logout endpoint to clear HttpOnly cookies
        await fetch(`${getApiUrl()}/auth/web/logout`, {
          method: 'POST',
          credentials: 'include',
        }).catch(() => {}); // Ignore errors
        setUser(null);
        setSentryUser(null);
      }
    } catch (error) {
      console.error('[Auth] Error checking auth status:', error);
      // Call logout endpoint to clear HttpOnly cookies
      await fetch(`${getApiUrl()}/auth/web/logout`, {
        method: 'POST',
        credentials: 'include',
      }).catch(() => {}); // Ignore errors
      setUser(null);
      setSentryUser(null);
    } finally {
      setIsLoading(false);
    }
  };

  const getAuthProvider = (provider: SocialProvider): FirebaseAuthProvider => {
    switch (provider) {
      case 'google':
        if (!googleProvider) throw new Error('Google provider not initialized');
        return googleProvider;
      case 'apple':
        if (!appleProvider) throw new Error('Apple provider not initialized');
        return appleProvider;
      default:
        throw new Error(`Unknown provider: ${provider}`);
    }
  };

  const fetchCsrfToken = async () => {
    await fetch(`${getApiUrl()}/auth/web/csrf-token`, {
      credentials: 'include',
    });
  };

  const signIn = useCallback(async (provider: SocialProvider) => {
    if (!isFirebaseConfigured || !auth) {
      throw new Error('Firebase is not configured. Please set up Firebase environment variables.');
    }

    console.log('[Auth] Starting sign in with', provider);
    setIsLoading(true);

    try {
      // 1. Get Firebase provider
      const authProvider = getAuthProvider(provider);

      // 2. Sign in with Firebase popup
      console.log('[Auth] Opening Firebase popup...');
      const result = await signInWithPopup(auth, authProvider);
      console.log('[Auth] Firebase sign in successful');

      // 3. Get Firebase ID token
      const idToken = await result.user.getIdToken();
      console.log('[Auth] Got Firebase ID token');

      // 4. Get CSRF token first
      await fetchCsrfToken();
      console.log('[Auth] Got CSRF token');

      // 5. Exchange Firebase token for app tokens (sets cookies)
      const response = await fetch(`${getApiUrl()}/auth/web/social-login`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Cookies.get('csrf_token') || '',
        },
        body: JSON.stringify({
          idToken,
          locale: navigator.language,
        }),
      });

      console.log('[Auth] social-login response:', response.status);

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || 'Login failed');
      }

      const userData = await response.json();
      console.log('[Auth] Login successful, user:', userData.username, 'role:', userData.role);
      const newUser = { publicId: userData.userPublicId, username: userData.username, role: userData.role || 'USER' };
      setUser(newUser);
      setSentryUser(newUser);
    } catch (error) {
      console.error('[Auth] Sign in error:', error);
      throw error;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const signOut = useCallback(async () => {
    try {
      // Clear backend session
      await fetch(`${getApiUrl()}/auth/web/logout`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'X-CSRF-Token': Cookies.get('csrf_token') || '',
        },
      });

      // Sign out from Firebase (if available)
      if (auth) {
        await firebaseSignOut(auth);
      }

      setUser(null);
      setSentryUser(null);
    } catch (error) {
      console.error('Sign out error:', error);
      // Still clear local state even if server call fails
      setUser(null);
      setSentryUser(null);
    }
  }, []);

  const refreshSession = useCallback(async (): Promise<boolean> => {
    try {
      const response = await fetch(`${getApiUrl()}/auth/web/reissue`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'X-CSRF-Token': Cookies.get('csrf_token') || '',
        },
      });

      if (response.ok) {
        const userData = await response.json();
        const newUser = { publicId: userData.userPublicId, username: userData.username, role: userData.role || 'USER' };
        setUser(newUser);
        setSentryUser(newUser);
        return true;
      }

      setUser(null);
      setSentryUser(null);
      return false;
    } catch {
      setUser(null);
      setSentryUser(null);
      return false;
    }
  }, []);

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user,
        isAdmin: user?.role === 'ADMIN',
        signIn,
        signOut,
        refreshSession,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
