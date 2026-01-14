import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Routes that require authentication
const protectedRoutes = [
  '/profile',
  '/recipes/create',
  '/recipes/edit',
  '/logs/create',
  '/logs/edit',
  '/settings',
];

// Check if the path matches any protected route
function isProtectedRoute(pathname: string): boolean {
  return protectedRoutes.some(
    (route) => pathname === route || pathname.startsWith(`${route}/`)
  );
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Check if route requires authentication
  if (isProtectedRoute(pathname)) {
    const accessToken = request.cookies.get('access_token');

    // If no access token, redirect to login with return URL
    if (!accessToken) {
      const loginUrl = new URL('/login', request.url);
      loginUrl.searchParams.set('redirect', pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  // Already authenticated users visiting login page
  if (pathname === '/login') {
    const accessToken = request.cookies.get('access_token');
    if (accessToken) {
      const redirectUrl = request.nextUrl.searchParams.get('redirect') || '/';
      return NextResponse.redirect(new URL(redirectUrl, request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder files
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\..*|_next).*)',
  ],
};
