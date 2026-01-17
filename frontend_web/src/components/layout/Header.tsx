'use client';

import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname, useRouter } from 'next/navigation';
import { siteConfig } from '@/config/site';
import { useAuth } from '@/contexts/AuthContext';
import { updateUserProfile } from '@/lib/api/users';
import { dispatchMeasurementChange } from '@/lib/utils/measurement';
import type { MeasurementPreference } from '@/lib/types';

const LOCALE_OPTIONS = [
  { value: 'ko-KR', label: '한국어' },
  { value: 'en-US', label: 'English' },
  { value: 'ja-JP', label: '日本語' },
  { value: 'zh-CN', label: '简体中文' },
  { value: 'zh-TW', label: '繁體中文' },
  { value: 'es-ES', label: 'Español' },
  { value: 'fr-FR', label: 'Français' },
  { value: 'de-DE', label: 'Deutsch' },
  { value: 'it-IT', label: 'Italiano' },
  { value: 'pt-BR', label: 'Português' },
  { value: 'vi-VN', label: 'Tiếng Việt' },
];

const MEASUREMENT_OPTIONS = [
  { value: 'ORIGINAL', label: 'Original' },
  { value: 'METRIC', label: 'Metric' },
  { value: 'US', label: 'US' },
];

export function Header() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const [isLocaleMenuOpen, setIsLocaleMenuOpen] = useState(false);
  const [isMeasurementMenuOpen, setIsMeasurementMenuOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [currentLocale, setCurrentLocale] = useState('en-US');
  const [currentMeasurement, setCurrentMeasurement] = useState<MeasurementPreference>('ORIGINAL');
  const pathname = usePathname();
  const router = useRouter();
  const { user, isAuthenticated, isLoading, isAdmin, signOut } = useAuth();
  const userMenuRef = useRef<HTMLDivElement>(null);
  const localeMenuRef = useRef<HTMLDivElement>(null);
  const measurementMenuRef = useRef<HTMLDivElement>(null);

  // Close mobile menu on route change
  const prevPathnameRef = useRef(pathname);
  useEffect(() => {
    if (prevPathnameRef.current !== pathname) {
      prevPathnameRef.current = pathname;
      // Use requestAnimationFrame to avoid synchronous setState warning
      requestAnimationFrame(() => setIsMenuOpen(false));
    }
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

  // Close menus on click outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setIsUserMenuOpen(false);
      }
      if (localeMenuRef.current && !localeMenuRef.current.contains(event.target as Node)) {
        setIsLocaleMenuOpen(false);
      }
      if (measurementMenuRef.current && !measurementMenuRef.current.contains(event.target as Node)) {
        setIsMeasurementMenuOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Load preferences from localStorage on mount
  useEffect(() => {
    const savedLocale = localStorage.getItem('userLocale');
    const savedMeasurement = localStorage.getItem('userMeasurement');
    // Use queueMicrotask to avoid synchronous setState warning in effect
    queueMicrotask(() => {
      if (savedLocale) setCurrentLocale(savedLocale);
      if (savedMeasurement) setCurrentMeasurement(savedMeasurement as MeasurementPreference);
    });
  }, []);

  // Handle locale change
  const handleLocaleChange = async (newLocale: string) => {
    setCurrentLocale(newLocale);
    localStorage.setItem('userLocale', newLocale);
    setIsLocaleMenuOpen(false);

    // Update backend if logged in
    if (isAuthenticated) {
      try {
        await updateUserProfile({ locale: newLocale });
      } catch (error) {
        console.error('Failed to update locale:', error);
      }
    }
  };

  // Handle measurement change
  const handleMeasurementChange = async (newMeasurement: MeasurementPreference) => {
    console.log('[Header] Measurement change:', newMeasurement);
    setCurrentMeasurement(newMeasurement);
    localStorage.setItem('userMeasurement', newMeasurement);
    setIsMeasurementMenuOpen(false);

    // Dispatch custom event for same-tab updates (e.g., ingredient conversion)
    console.log('[Header] Dispatching measurementPreferenceChange event');
    dispatchMeasurementChange(newMeasurement);

    // Update backend if logged in
    if (isAuthenticated) {
      try {
        await updateUserProfile({ measurementPreference: newMeasurement });
      } catch (error) {
        console.error('Failed to update measurement preference:', error);
      }
    }
  };

  const currentLocaleOption = LOCALE_OPTIONS.find(opt => opt.value === currentLocale) || LOCALE_OPTIONS[1];
  const currentMeasurementOption = MEASUREMENT_OPTIONS.find(opt => opt.value === currentMeasurement) || MEASUREMENT_OPTIONS[0];

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
              <Image
                src="/logo-icon.svg"
                alt={siteConfig.name}
                width={32}
                height={32}
                className="w-8 h-8"
              />
              <span className="font-bold text-xl text-[var(--text-logo)]">
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

              {/* Language Selector */}
              <div className="relative" ref={localeMenuRef}>
                <button
                  onClick={() => {
                    setIsLocaleMenuOpen(!isLocaleMenuOpen);
                    setIsMeasurementMenuOpen(false);
                    setIsUserMenuOpen(false);
                  }}
                  className="flex items-center gap-1 px-2 py-1.5 text-sm rounded-lg hover:bg-[var(--background)] transition-colors text-[var(--text-secondary)]"
                  title="Language"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
                  </svg>
                  <span className="text-xs">{currentLocaleOption.label}</span>
                  <svg
                    className={`w-3 h-3 transition-transform ${isLocaleMenuOpen ? 'rotate-180' : ''}`}
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                {isLocaleMenuOpen && (
                  <div className="absolute right-0 mt-2 w-36 bg-[var(--surface)] border border-[var(--border)] rounded-xl shadow-lg py-1 z-50 max-h-64 overflow-y-auto">
                    {LOCALE_OPTIONS.map((opt) => (
                      <button
                        key={opt.value}
                        onClick={() => handleLocaleChange(opt.value)}
                        className={`w-full text-left px-3 py-2 text-sm hover:bg-[var(--background)] ${
                          opt.value === currentLocale ? 'bg-[var(--primary-light)] text-[var(--primary)]' : 'text-[var(--text-primary)]'
                        }`}
                      >
                        {opt.label}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Measurement Selector */}
              <div className="relative" ref={measurementMenuRef}>
                <button
                  onClick={() => {
                    setIsMeasurementMenuOpen(!isMeasurementMenuOpen);
                    setIsLocaleMenuOpen(false);
                    setIsUserMenuOpen(false);
                  }}
                  className="flex items-center gap-1 px-2 py-1.5 text-sm rounded-lg hover:bg-[var(--background)] transition-colors text-[var(--text-secondary)]"
                  title="Measurement Units"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3" />
                  </svg>
                  <span className="text-xs">{currentMeasurementOption.label}</span>
                  <svg
                    className={`w-3 h-3 transition-transform ${isMeasurementMenuOpen ? 'rotate-180' : ''}`}
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                {isMeasurementMenuOpen && (
                  <div className="absolute right-0 mt-2 w-28 bg-[var(--surface)] border border-[var(--border)] rounded-xl shadow-lg py-1 z-50">
                    {MEASUREMENT_OPTIONS.map((opt) => (
                      <button
                        key={opt.value}
                        onClick={() => handleMeasurementChange(opt.value as MeasurementPreference)}
                        className={`w-full text-left px-3 py-2 text-sm hover:bg-[var(--background)] ${
                          opt.value === currentMeasurement ? 'bg-[var(--primary-light)] text-[var(--primary)]' : 'text-[var(--text-primary)]'
                        }`}
                      >
                        {opt.label}
                      </button>
                    ))}
                  </div>
                )}
              </div>

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
                            href="/saved"
                            className="block px-4 py-2 text-sm text-[var(--text-primary)] hover:bg-[var(--background)]"
                            onClick={() => setIsUserMenuOpen(false)}
                          >
                            Saved
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
                          {isAdmin && (
                            <Link
                              href="/admin"
                              className="block px-4 py-2 text-sm text-[var(--primary)] font-medium hover:bg-[var(--background)]"
                              onClick={() => setIsUserMenuOpen(false)}
                            >
                              Admin Dashboard
                            </Link>
                          )}
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
                  href="/saved"
                  className="block px-4 py-3 rounded-lg text-[var(--text-primary)] hover:bg-[var(--background)]"
                >
                  Saved
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
                {isAdmin && (
                  <Link
                    href="/admin"
                    className="block px-4 py-3 rounded-lg text-[var(--primary)] font-medium hover:bg-[var(--background)]"
                  >
                    Admin Dashboard
                  </Link>
                )}
              </>
            )}
          </nav>

          {/* Divider */}
          <div className="my-6 border-t border-[var(--border)]" />

          {/* Mobile Settings */}
          <div className="space-y-4 px-4">
            <p className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
              Settings
            </p>

            {/* Language Select */}
            <div>
              <label className="block text-sm text-[var(--text-primary)] mb-2">
                Language
              </label>
              <select
                value={currentLocale}
                onChange={(e) => handleLocaleChange(e.target.value)}
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm focus:outline-none focus:border-[var(--primary)]"
              >
                {LOCALE_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>

            {/* Measurement Select */}
            <div>
              <label className="block text-sm text-[var(--text-primary)] mb-2">
                Measurement Units
              </label>
              <select
                value={currentMeasurement}
                onChange={(e) => handleMeasurementChange(e.target.value as MeasurementPreference)}
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm focus:outline-none focus:border-[var(--primary)]"
              >
                {MEASUREMENT_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

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
