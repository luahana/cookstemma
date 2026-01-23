import Link from 'next/link';
import Image from 'next/image';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Page Not Found',
  description: 'The page you are looking for could not be found.',
};

export default function NotFound() {
  return (
    <div className="min-h-[60vh] flex items-center justify-center px-4">
      <div className="text-center max-w-md">
        {/* Logo */}
        <div className="flex flex-col items-center mb-8">
          <Image
            src="/logo-icon.svg"
            alt="Cookstemma"
            width={64}
            height={64}
            className="w-16 h-16 mb-3"
            unoptimized
          />
          <span className="text-xl font-bold text-[var(--text-logo)]">
            Cookstemma
          </span>
        </div>

        {/* Error Code - subtle gray */}
        <h1 className="text-8xl font-bold text-[var(--border)] mb-4">404</h1>

        {/* Message */}
        <h2 className="text-2xl font-semibold text-[var(--text-primary)] mb-2">
          Page Not Found
        </h2>
        <p className="text-[var(--text-secondary)] mb-8">
          The page you&apos;re looking for doesn&apos;t exist or has been moved.
        </p>

        {/* Actions */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Link
            href="/"
            className="px-6 py-3 bg-[var(--primary)] text-white font-medium rounded-xl hover:bg-[var(--primary-dark)] transition-colors"
          >
            Go Home
          </Link>
          <Link
            href="/recipes"
            className="px-6 py-3 bg-[var(--background)] text-[var(--text-primary)] font-medium rounded-xl border border-[var(--border)] hover:border-[var(--primary)] transition-colors"
          >
            Browse Recipes
          </Link>
        </div>

        {/* Search Suggestion */}
        <div className="mt-10 pt-8 border-t border-[var(--border)]">
          <p className="text-sm text-[var(--text-secondary)] mb-4">
            Looking for something specific?
          </p>
          <Link
            href="/search"
            className="inline-flex items-center gap-2 text-[var(--primary)] hover:underline"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
            Try searching
          </Link>
        </div>
      </div>
    </div>
  );
}
