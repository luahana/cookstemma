import Link from 'next/link';
import { siteConfig } from '@/config/site';

export function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-[var(--surface)] border-t border-[var(--border)] mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="col-span-1 md:col-span-2">
            <Link href="/" className="flex items-center gap-2 mb-4">
              <span className="text-2xl">🍳</span>
              <span className="font-bold text-xl text-[var(--primary)]">
                {siteConfig.name}
              </span>
            </Link>
            <p className="text-[var(--text-secondary)] text-sm max-w-md">
              {siteConfig.description}
            </p>
          </div>

          {/* Explore */}
          <div>
            <h3 className="font-semibold text-[var(--text-primary)] mb-4">
              Explore
            </h3>
            <ul className="space-y-2">
              <li>
                <Link
                  href="/recipes"
                  className="text-[var(--text-secondary)] text-sm hover:text-[var(--primary)] transition-colors"
                >
                  Recipes
                </Link>
              </li>
              <li>
                <Link
                  href="/logs"
                  className="text-[var(--text-secondary)] text-sm hover:text-[var(--primary)] transition-colors"
                >
                  Cooking Logs
                </Link>
              </li>
              <li>
                <Link
                  href="/search"
                  className="text-[var(--text-secondary)] text-sm hover:text-[var(--primary)] transition-colors"
                >
                  Search
                </Link>
              </li>
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h3 className="font-semibold text-[var(--text-primary)] mb-4">
              Legal
            </h3>
            <ul className="space-y-2">
              <li>
                <Link
                  href={siteConfig.links.terms}
                  className="text-[var(--text-secondary)] text-sm hover:text-[var(--primary)] transition-colors"
                >
                  Terms of Service
                </Link>
              </li>
              <li>
                <Link
                  href={siteConfig.links.privacy}
                  className="text-[var(--text-secondary)] text-sm hover:text-[var(--primary)] transition-colors"
                >
                  Privacy Policy
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="mt-12 pt-8 border-t border-[var(--border)]">
          <p className="text-[var(--text-secondary)] text-sm text-center">
            &copy; {currentYear} {siteConfig.name}. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
