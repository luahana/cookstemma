'use client';

import { useState, useEffect, useRef, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Link } from '@/i18n/navigation';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import { isFirebaseConfigured } from '@/lib/firebase/config';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import type { SocialProvider } from '@/lib/firebase/providers';

function LoginContent() {
  const t = useTranslations('auth');
  const tNav = useTranslations('nav');
  const { signIn, isLoading, isAuthenticated, refreshSession } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [error, setError] = useState<string | null>(null);
  const [signingInWith, setSigningInWith] = useState<SocialProvider | null>(null);
  // Use ref instead of state - refs update synchronously so it's set before useEffect runs
  const justLoggedInRef = useRef(false);

  const redirectUrl = searchParams.get('redirect') || '/';

  // Redirect if already authenticated
  useEffect(() => {
    const handleRedirect = async () => {
      if (isAuthenticated) {
        if (justLoggedInRef.current) {
          // Fresh login - cookies are already set by social-login endpoint
          router.push(redirectUrl);
        } else {
          // Existing session - refresh to ensure access_token cookie is valid
          const refreshed = await refreshSession();
          if (refreshed) {
            router.push(redirectUrl);
          }
          // If refresh failed, isAuthenticated will become false and login form will show
        }
      }
    };
    handleRedirect();
  }, [isAuthenticated, redirectUrl, router, refreshSession]);

  // Show loading while checking auth or redirecting
  if (isLoading || isAuthenticated) {
    return <LoadingSpinner />;
  }

  const handleSignIn = async (provider: SocialProvider) => {
    setError(null);
    setSigningInWith(provider);
    // Set ref BEFORE signIn so it's ready when useEffect runs
    justLoggedInRef.current = true;
    try {
      await signIn(provider);
      // Redirect directly after successful sign-in using full page navigation
      // This bypasses Next.js router to ensure cookies are sent with the request
      console.log('[Login] Sign in successful, redirecting to:', redirectUrl);
      window.location.href = redirectUrl;
    } catch (err) {
      justLoggedInRef.current = false;
      setError('Sign in failed. Please try again.');
      setSigningInWith(null);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[var(--background)] px-4">
      <div className="max-w-md w-full">
        {/* Logo/Brand */}
        <div className="text-center mb-8">
          <Link href="/" className="inline-flex items-center justify-center gap-2">
            <img src="/logo-icon.svg" alt="" className="w-10 h-10" />
            <h1 className="text-3xl font-bold text-[var(--text-logo)]">
              Cookstemma
            </h1>
          </Link>
          <p className="text-[var(--text-secondary)] mt-2">
            {t('signInSubtitle')}
          </p>
        </div>

        {/* Login Card */}
        <div className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-8 shadow-sm">
          <h2 className="text-xl font-semibold text-[var(--text-primary)] text-center mb-6">
            {t('welcomeBack')}
          </h2>

          {!isFirebaseConfigured && (
            <div className="mb-6 p-4 bg-amber-50 border border-amber-200 text-amber-800 rounded-lg text-sm">
              <p className="font-medium mb-1">{t('firebaseNotConfigured')}</p>
              <p className="text-xs">
                {t('firebaseConfigMessage')}
              </p>
              <ul className="text-xs mt-2 space-y-0.5 font-mono">
                <li>NEXT_PUBLIC_FIREBASE_API_KEY</li>
                <li>NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN</li>
                <li>NEXT_PUBLIC_FIREBASE_PROJECT_ID</li>
                <li>NEXT_PUBLIC_FIREBASE_APP_ID</li>
              </ul>
            </div>
          )}

          {error && (
            <div className="mb-6 p-3 bg-[var(--error)]/10 border border-[var(--error)]/20 text-[var(--error)] rounded-lg text-sm text-center">
              {error}
            </div>
          )}

          <div className="space-y-3">
            {/* Google */}
            <button
              onClick={() => handleSignIn('google')}
              disabled={isLoading || !isFirebaseConfigured}
              className="w-full flex items-center justify-center gap-3 px-4 py-3 bg-white dark:bg-black border border-[var(--border)] rounded-xl hover:bg-gray-50 dark:hover:bg-gray-900 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              <span className="text-[var(--text-primary)] font-medium">
                {signingInWith === 'google' ? t('signingIn') : t('continueWithGoogle')}
              </span>
            </button>

            {/* Apple */}
            <button
              onClick={() => handleSignIn('apple')}
              disabled={isLoading || !isFirebaseConfigured}
              className="w-full flex items-center justify-center gap-3 px-4 py-3 bg-white dark:bg-black text-black dark:text-white border border-[var(--border)] rounded-xl hover:bg-gray-50 dark:hover:bg-gray-900 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
              </svg>
              <span className="font-medium">
                {signingInWith === 'apple' ? t('signingIn') : t('continueWithApple')}
              </span>
            </button>
          </div>

          {/* Terms */}
          <p className="mt-6 text-xs text-center text-[var(--text-secondary)]">
            {t('termsAgree')}{' '}
            <Link href="/terms" className="text-[var(--primary)] hover:underline">
              {tNav('termsOfService')}
            </Link>{' '}
            {t('and')}{' '}
            <Link href="/privacy" className="text-[var(--primary)] hover:underline">
              {tNav('privacyPolicy')}
            </Link>
          </p>
        </div>

        {/* Back to home */}
        <div className="text-center mt-6">
          <Link
            href="/"
            className="text-[var(--text-secondary)] hover:text-[var(--primary)] text-sm"
          >
            {t('backToHome')}
          </Link>
        </div>
      </div>
    </div>
  );
}

function LoginFallback() {
  return <LoadingSpinner />;
}

export default function LoginPage() {
  return (
    <Suspense fallback={<LoginFallback />}>
      <LoginContent />
    </Suspense>
  );
}
