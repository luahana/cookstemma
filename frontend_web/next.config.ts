import type { NextConfig } from "next";

const isDev = process.env.NODE_ENV === 'development';

const nextConfig: NextConfig = {
  images: {
    // Allow private/localhost images in development
    dangerouslyAllowSVG: true,
    remotePatterns: [
      {
        // Local development MinIO
        protocol: 'http',
        hostname: '10.0.2.2',
        port: '9000',
        pathname: '/pairing-planet-local/**',
      },
      {
        // Local development MinIO (localhost)
        protocol: 'http',
        hostname: 'localhost',
        port: '9000',
        pathname: '/pairing-planet-local/**',
      },
      {
        // Local development MinIO (127.0.0.1)
        protocol: 'http',
        hostname: '127.0.0.1',
        port: '9000',
        pathname: '/pairing-planet-local/**',
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
    ],
    // Disable image optimization for local development (allows private IPs)
    unoptimized: isDev,
  },
};

export default nextConfig;
