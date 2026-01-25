import type { NextConfig } from "next";
import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin('./src/i18n/request.ts');

const isDev = process.env.NODE_ENV === 'development';

// Sentry integration - enabled when DSN is set in environment
// Errors are only sent in staging/production (DSN empty in dev)
let withSentryConfig: ((config: NextConfig, options: object) => NextConfig) | null = null;
try {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  withSentryConfig = require("@sentry/nextjs").withSentryConfig;
} catch {
  // Sentry not installed - will run without it
}

const nextConfig: NextConfig = {
  // Enable standalone output for Docker deployment
  output: 'standalone',

  // Fix COOP header for Firebase popup authentication
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'Cross-Origin-Opener-Policy',
            value: 'same-origin-allow-popups',
          },
        ],
      },
    ];
  },

  images: {
    // Prefer WebP/AVIF for modern browsers, Next.js handles fallback
    formats: ['image/webp', 'image/avif'],
    // Allow private/localhost images in development
    dangerouslyAllowSVG: true,
    remotePatterns: [
      {
        // Local development MinIO
        protocol: 'http',
        hostname: '10.0.2.2',
        port: '9000',
        pathname: '/cookstemma-local/**',
      },
      {
        // Local development MinIO (localhost)
        protocol: 'http',
        hostname: 'localhost',
        port: '9000',
        pathname: '/cookstemma-local/**',
      },
      {
        // Local development MinIO (127.0.0.1)
        protocol: 'http',
        hostname: '127.0.0.1',
        port: '9000',
        pathname: '/cookstemma-local/**',
      },
      {
        // Production S3/CloudFront - update with actual domain
        protocol: 'https',
        hostname: '*.amazonaws.com',
      },
      {
        // Production CloudFront CDN - update with actual domain
        protocol: 'https',
        hostname: '*.cloudfront.net',
      },
      {
        // Google profile images (OAuth login)
        protocol: 'https',
        hostname: 'lh3.googleusercontent.com',
      },
      {
        // Flag images CDN
        protocol: 'https',
        hostname: 'flagcdn.com',
      },
    ],
    // Disable image optimization for local development (allows private IPs)
    unoptimized: isDev,
  },
};

// Sentry configuration - only active when SENTRY_AUTH_TOKEN is set
const sentryWebpackPluginOptions = {
  // Organization and project from environment
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  authToken: process.env.SENTRY_AUTH_TOKEN,

  // Only upload source maps in CI when auth token is available
  silent: !process.env.SENTRY_AUTH_TOKEN,

  // Hide source maps from client bundles
  hideSourceMaps: true,

  // Upload source maps for better stack traces
  widenClientFileUpload: true,

  // Route Sentry events through app to bypass ad blockers
  tunnelRoute: "/monitoring",

  // Disable Sentry in development (no DSN)
  disableServerWebpackPlugin: !process.env.NEXT_PUBLIC_SENTRY_DSN,
  disableClientWebpackPlugin: !process.env.NEXT_PUBLIC_SENTRY_DSN,
};

// Wrap config with next-intl and optionally Sentry
const configWithIntl = withNextIntl(nextConfig);

export default withSentryConfig
  ? withSentryConfig(configWithIntl, sentryWebpackPluginOptions)
  : configWithIntl;
