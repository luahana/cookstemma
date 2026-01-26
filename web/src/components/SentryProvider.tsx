'use client';

import { useEffect } from 'react';
import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN = process.env.NEXT_PUBLIC_SENTRY_DSN;

// Initialize Sentry on the client side
if (typeof window !== 'undefined' && SENTRY_DSN && !Sentry.getClient()) {
  Sentry.init({
    dsn: SENTRY_DSN,
    environment: process.env.NEXT_PUBLIC_SENTRY_ENVIRONMENT || 'development',
    tracesSampleRate: parseFloat(process.env.NEXT_PUBLIC_SENTRY_TRACES_SAMPLE_RATE || '0.1'),
    replaysSessionSampleRate: 0,
    replaysOnErrorSampleRate: 0,
  });
}

export function SentryProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    // Log initialization status for debugging
    if (process.env.NODE_ENV === 'development') {
      console.log('[Sentry] Client:', !!Sentry.getClient(), 'DSN:', !!SENTRY_DSN);
    }
  }, []);

  return <>{children}</>;
}
