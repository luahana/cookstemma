/**
 * Get the API URL based on execution context.
 * - Server-side (SSR): Uses INTERNAL_API_URL for direct container-to-container communication
 * - Client-side (browser): Uses NEXT_PUBLIC_API_URL for public access through ALB
 *
 * This allows IP-restricted ALB while still enabling SSR API calls.
 */
export function getApiUrl(): string {
  const isServer = typeof window === 'undefined';

  if (isServer) {
    // Server-side: prefer internal URL for direct communication (bypasses ALB IP restrictions)
    return process.env.INTERNAL_API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1';
  }

  // Client-side: use public URL (browser makes requests directly)
  return process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1';
}

export const siteConfig = {
  name: 'Cookstemma',
  description: 'Log every recipe you try, learn from each attempt, and become a better cook',
  url: process.env.NEXT_PUBLIC_SITE_URL || 'https://cookstemma.com',
  /** @deprecated Use getApiUrl() for dynamic context-aware URL */
  apiUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1',
  ogImage: '/images/og-default.png',
  links: {
    appStore: '#', // TODO: Add real App Store link
    playStore: '#', // TODO: Add real Play Store link
    terms: '/terms',
    privacy: '/privacy',
  },
};
