import createMiddleware from 'next-intl/middleware';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { routing } from './i18n/routing';

// Create the next-intl middleware
const intlMiddleware = createMiddleware(routing);

// Routes that require authentication (without locale prefix)
const protectedRoutes = [
  '/profile',
  '/recipes/create',
  '/recipes/edit',
  '/logs/create',
  '/logs/edit',
  '/settings',
  '/saved',
  '/admin',
];

// Check if the path (without locale) matches any protected route
function isProtectedRoute(pathWithoutLocale: string): boolean {
  return protectedRoutes.some(
    (route) => pathWithoutLocale === route || pathWithoutLocale.startsWith(`${route}/`)
  );
}

// Extract the path without locale prefix
function getPathWithoutLocale(pathname: string): string {
  const localePattern = new RegExp(`^/(${routing.locales.join('|')})`);
  return pathname.replace(localePattern, '') || '/';
}

// Get locale from pathname
function getLocaleFromPath(pathname: string): string | null {
  const match = pathname.match(new RegExp(`^/(${routing.locales.join('|')})`));
  return match ? match[1] : null;
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // First, run the intl middleware to handle locale routing
  const response = intlMiddleware(request);

  // Get the locale (either from path or will be added by intlMiddleware)
  const locale = getLocaleFromPath(pathname) || routing.defaultLocale;
  const pathWithoutLocale = getPathWithoutLocale(pathname);

  // Check if route requires authentication
  if (isProtectedRoute(pathWithoutLocale)) {
    const accessToken = request.cookies.get('access_token');

    // If no access token, redirect to login with return URL
    if (!accessToken) {
      const loginUrl = new URL(`/${locale}/login`, request.url);
      loginUrl.searchParams.set('redirect', pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  // Note: We don't redirect authenticated users away from /login in middleware
  // because we can't validate the token here. The login page handles this
  // client-side by checking auth status and redirecting if authenticated.

  return response;
}

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder files with extensions
     * - monitoring (Sentry tunnel route)
     */
    '/((?!api|_next|_vercel|monitoring|.*\\..*).*)',
  ],
};
