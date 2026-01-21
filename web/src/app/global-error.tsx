'use client';

import * as Sentry from '@sentry/nextjs';
import { useEffect } from 'react';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    Sentry.captureException(error);
    console.error('[Global Error]', error);
  }, [error]);

  return (
    <html>
      <body>
        <div className="min-h-screen flex items-center justify-center px-4 bg-[#F9F9F9]">
          <div className="text-center max-w-md">
            {/* Logo */}
            <div className="flex flex-col items-center mb-8">
              {/* eslint-disable-next-line @next/next/no-img-element -- global-error cannot use next/image */}
              <img
                src="/logo-icon.svg"
                alt="Cookstemma"
                width={64}
                height={64}
                className="w-16 h-16 mb-3"
              />
              <span className="text-xl font-bold text-[#494F57]">
                Cookstemma
              </span>
            </div>

            {/* Error indicator - subtle gray */}
            <h1 className="text-8xl font-bold text-[#DFE6E9] mb-4">Oops!</h1>

            {/* Message */}
            <h2 className="text-2xl font-semibold text-[#2D3436] mb-2">
              Something went wrong
            </h2>
            <p className="text-[#636E72] mb-8">
              We encountered an unexpected error. Our team has been notified.
            </p>

            {/* Error digest for support */}
            {error.digest && (
              <p className="text-sm text-[#636E72] mb-4 font-mono bg-[#F1F1F1] px-3 py-1 rounded inline-block">
                Error ID: {error.digest}
              </p>
            )}

            {/* Actions */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center mt-6">
              <button
                onClick={reset}
                className="px-6 py-3 bg-[#E67E22] text-white font-medium rounded-xl hover:bg-[#D35400] transition-colors"
              >
                Try Again
              </button>
              {/* eslint-disable-next-line @next/next/no-html-link-for-pages -- global-error needs hard navigation */}
              <a
                href="/"
                className="px-6 py-3 bg-white text-[#2D3436] font-medium rounded-xl border border-[#DFE6E9] hover:border-[#E67E22] transition-colors"
              >
                Go Home
              </a>
            </div>
          </div>
        </div>
      </body>
    </html>
  );
}
