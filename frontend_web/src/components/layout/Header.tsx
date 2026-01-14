'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { siteConfig } from '@/config/site';
import { useAuth } from '@/contexts/AuthContext';

export function Header() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const pathname = usePathname();
  const router = useRouter();
  const { user, isAuthenticated, isLoading, signOut } = useAuth();
  const userMenuRef = useRef<HTMLDivElement>(null);

  // Close mobile menu on route change
  useEffect(() => {
    setIsMenuOpen(false);
  }, [pathname]);

  // Prevent body scroll when menu is open
  useEffect(() => {
    if (isMenuOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isMenuOpen]);

  // Close user menu on click outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setIsUserMenuOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      router.push(`/search?q=${encodeURIComponent(searchQuery.trim())}`);
      setSearchQuery('');
    }
  };

  const navLinks = [
    { href: '/recipes', label: 'Recipes' },
    { href: '/logs', label: 'Cooking Logs' },
    { href: '/search', label: 'Search' },
  ];

  return (
    <>
      <header className="sticky top-0 z-50 bg-[var(--surface)] border-b border-[var(--border)]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <Link href="/" className="flex items-center gap-2">
              <span className="text-2xl">🍳</span>
              <span className="font-bold text-xl text-[var(--primary)]">
                {siteConfig.name}
              </span>
            </Link>

            {/* Desktop Navigation */}
            <nav className="hidden md:flex items-center gap-6">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`transition-colors ${
                    pathname === link.href
                      ? 'text-[var(--primary)] font-medium'
                      : 'text-[var(--text-secondary)] hover:text-[var(--primary)]'
                  }`}
                >
                  {link.label}
                </Link>
              ))}

              {/* Desktop Search */}
              <form onSubmit={handleSearch} className="relative">
                <input
                  type="search"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Quick search..."
                  className="w-40 lg:w-48 px-3 py-1.5 pl-9 text-sm bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] focus:w-56 lg:focus:w-64 transition-all"
                />
                <svg
                  className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-[var(--text-secondary)]"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                  />
                </svg>
              </form>

              {/* Auth Section */}
              {!isLoading && (
                <>
                  {isAuthenticated ? (
                    <div className="relative" ref={userMenuRef}>
                      <button
                        onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
                        className="flex items-center gap-2 px-3 py-1.5 rounded-lg hover:bg-[var(--background)] transition-colors"
                      >
                        <div className="w-8 h-8 bg-[var(--primary-light)] rounded-full flex items-center justify-center">
                          <span className="text-[var(--primary)] font-medium text-sm">
                            {user?.username?.charAt(0).toUpperCase() || 'U'}
                          </span>
                        </div>
                        <svg
                          className={`w-4 h-4 text-[var(--text-secondary)] transition-transform ${isUserMenuOpen ? 'rotate-180' : ''}`}
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                        </svg>
                      </button>

                      {/* User Dropdown Menu */}
                      {isUserMenuOpen && (
                        <div className="absolute right-0 mt-2 w-48 bg-[var(--surface)] border border-[var(--border)] rounded-xl shadow-lg py-2 z-50">
                          <div className="px-4 py-2 border-b border-[var(--border)]">
                            <p className="text-sm font-medium text-[var(--text-primary)] truncate">
                              {user?.username}
                            </p>
                          </div>
                          <Link
                            href={`/users/${user?.publicId}`}
                            className="block px-4 py-2 text-sm text-[var(--text-primary)] hover:bg-[var(--background)]"
                            onClick={() => setIsUserMenuOpen(false)}
                          >
                            My Profile
                          </Link>
                          <Link
                            href="/recipes/create"
                            className="block px-4 py-2 text-sm text-[var(--text-primary)] hover:bg-[var(--background)]"
                            onClick={() => setIsUserMenuOpen(false)}
                          >
                            Create Recipe
                          </Link>
                          <Link
                            href="/logs/create"
                            className="block px-4 py-2 text-sm text-[var(--text-primary)] hover:bg-[var(--background)]"
                            onClick={() => setIsUserMenuOpen(false)}
                          >
                            New Cooking Log
                          </Link>
                          <div className="border-t border-[var(--border)] mt-2 pt-2">
                            <button
                              onClick={() => {
                                setIsUserMenuOpen(false);
                                signOut();
                              }}
                              className="w-full text-left px-4 py-2 text-sm text-[var(--error)] hover:bg-[var(--background)]"
                            >
                              Sign Out
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  ) : (
                    <Link
                      href="/login"
                      className="px-4 py-2 bg-[var(--primary)] text-white rounded-lg font-medium hover:bg-[var(--primary-dark)] transition-colors"
                    >
                      Sign In
                    </Link>
                  )}
                </>
              )}
            </nav>

            {/* Mobile menu button */}
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="md:hidden p-2 text-[var(--text-secondary)] hover:text-[var(--primary)]"
              aria-label={isMenuOpen ? 'Close menu' : 'Open menu'}
              aria-expanded={isMenuOpen}
            >
              {isMenuOpen ? (
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              ) : (
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                </svg>
              )}
            </button>
          </div>
        </div>
      </header>

      {/* Mobile Menu Overlay */}
      {isMenuOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 md:hidden"
          onClick={() => setIsMenuOpen(false)}
        />
      )}

      {/* Mobile Menu Panel */}
      <div
        className={`fixed top-16 right-0 bottom-0 z-50 w-72 bg-[var(--surface)] border-l border-[var(--border)] transform transition-transform duration-300 ease-in-out md:hidden ${
          isMenuOpen ? 'translate-x-0' : 'translate-x-full'
        }`}
      >
        <div className="p-4">
          {/* Mobile Search */}
          <form onSubmit={handleSearch} className="mb-6">
            <div className="relative">
              <input
                type="search"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search recipes..."
                className="w-full px-4 py-2.5 pl-10 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
              />
              <svg
                className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-[var(--text-secondary)]"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
            </div>
          </form>

          {/* Mobile Auth Section */}
          {!isLoading && (
            <div className="mb-6">
              {isAuthenticated ? (
                <div className="flex items-center gap-3 px-4 py-3 bg-[var(--background)] rounded-lg">
                  <div className="w-10 h-10 bg-[var(--primary-light)] rounded-full flex items-center justify-center">
                    <span className="text-[var(--primary)] font-medium">
                      {user?.username?.charAt(0).toUpperCase() || 'U'}
                    </span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-[var(--text-primary)] truncate">
                      {user?.username}
                    </p>
                    <p className="text-xs text-[var(--text-secondary)]">Signed in</p>
                  </div>
                </div>
              ) : (
                <Link
                  href="/login"
                  className="block w-full text-center px-4 py-3 bg-[var(--primary)] text-white rounded-lg font-medium hover:bg-[var(--primary-dark)] transition-colors"
                >
                  Sign In
                </Link>
              )}
            </div>
          )}

          {/* Mobile Nav Links */}
          <nav className="space-y-1">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={`block px-4 py-3 rounded-lg transition-colors ${
                  pathname === link.href
                    ? 'bg-[var(--primary-light)] text-[var(--primary)] font-medium'
                    : 'text-[var(--text-primary)] hover:bg-[var(--background)]'
                }`}
              >
                {link.label}
              </Link>
            ))}

            {/* Authenticated User Actions */}
            {isAuthenticated && (
              <>
                <Link
                  href={`/users/${user?.publicId}`}
                  className="block px-4 py-3 rounded-lg text-[var(--text-primary)] hover:bg-[var(--background)]"
                >
                  My Profile
                </Link>
                <Link
                  href="/recipes/create"
                  className="block px-4 py-3 rounded-lg text-[var(--text-primary)] hover:bg-[var(--background)]"
                >
                  Create Recipe
                </Link>
                <Link
                  href="/logs/create"
                  className="block px-4 py-3 rounded-lg text-[var(--text-primary)] hover:bg-[var(--background)]"
                >
                  New Cooking Log
                </Link>
              </>
            )}
          </nav>

          {/* Divider */}
          <div className="my-6 border-t border-[var(--border)]" />

          {/* Additional Links */}
          <nav className="space-y-1">
            <Link
              href="/terms"
              className="block px-4 py-2 text-sm text-[var(--text-secondary)] hover:text-[var(--primary)]"
            >
              Terms of Service
            </Link>
            <Link
              href="/privacy"
              className="block px-4 py-2 text-sm text-[var(--text-secondary)] hover:text-[var(--primary)]"
            >
              Privacy Policy
            </Link>
          </nav>

          {/* Sign Out Button */}
          {isAuthenticated && (
            <>
              <div className="my-6 border-t border-[var(--border)]" />
              <button
                onClick={() => {
                  setIsMenuOpen(false);
                  signOut();
                }}
                className="w-full px-4 py-3 text-left text-[var(--error)] hover:bg-[var(--background)] rounded-lg transition-colors"
              >
                Sign Out
              </button>
            </>
          )}
        </div>
      </div>
    </>
  );
}
