'use client';

import { useState, useEffect, useRef, useTransition } from 'react';
import Image from 'next/image';
import { useTranslations, useLocale } from 'next-intl';
import { Link, usePathname, useRouter } from '@/i18n/navigation';
import { routing, type Locale } from '@/i18n/routing';
import { siteConfig } from '@/config/site';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme, type Theme } from '@/contexts/ThemeContext';
import { ThemeToggle } from '@/components/layout/ThemeToggle';
import { updateUserProfile } from '@/lib/api/users';
import { dispatchMeasurementChange } from '@/lib/utils/measurement';
import type { MeasurementPreference } from '@/lib/types';

const THEME_OPTIONS: { value: Theme; labelKey: string }[] = [
  { value: 'light', labelKey: 'lightMode' },
  { value: 'dark', labelKey: 'darkMode' },
  { value: 'system', labelKey: 'systemMode' },
];

const LOCALE_OPTIONS: { value: Locale; label: string; dir: 'ltr' | 'rtl' }[] = [
  { value: 'en', label: 'English', dir: 'ltr' },
  { value: 'zh', label: '中文', dir: 'ltr' },
  { value: 'es', label: 'Español', dir: 'ltr' },
  { value: 'ja', label: '日本語', dir: 'ltr' },
  { value: 'de', label: 'Deutsch', dir: 'ltr' },
  { value: 'fr', label: 'Français', dir: 'ltr' },
  { value: 'pt', label: 'Português', dir: 'ltr' },
  { value: 'ko', label: '한국어', dir: 'ltr' },
  { value: 'it', label: 'Italiano', dir: 'ltr' },
  { value: 'ar', label: 'العربية', dir: 'rtl' },
  { value: 'ru', label: 'Русский', dir: 'ltr' },
  { value: 'id', label: 'Bahasa Indonesia', dir: 'ltr' },
  { value: 'vi', label: 'Tiếng Việt', dir: 'ltr' },
  { value: 'hi', label: 'हिन्दी', dir: 'ltr' },
  { value: 'th', label: 'ไทย', dir: 'ltr' },
  { value: 'pl', label: 'Polski', dir: 'ltr' },
  { value: 'tr', label: 'Türkçe', dir: 'ltr' },
  { value: 'nl', label: 'Nederlands', dir: 'ltr' },
  { value: 'sv', label: 'Svenska', dir: 'ltr' },
  { value: 'fa', label: 'فارسی', dir: 'rtl' },
];

const MEASUREMENT_OPTIONS = [
  { value: 'ORIGINAL', labelKey: 'original' },
  { value: 'METRIC', labelKey: 'metric' },
  { value: 'US', labelKey: 'us' },
] as const;

export function Header() {
  const t = useTranslations('nav');
  const tMeasurement = useTranslations('measurement');
  const tCommon = useTranslations('common');
  const locale = useLocale() as Locale;
  const pathname = usePathname();
  const router = useRouter();

  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const [isLocaleMenuOpen, setIsLocaleMenuOpen] = useState(false);
  const [isMeasurementMenuOpen, setIsMeasurementMenuOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [currentMeasurement, setCurrentMeasurement] = useState<MeasurementPreference>('ORIGINAL');
  const { user, isAuthenticated, isLoading, isAdmin, signOut } = useAuth();
  const userMenuRef = useRef<HTMLDivElement>(null);
  const localeMenuRef = useRef<HTMLDivElement>(null);
  const measurementMenuRef = useRef<HTMLDivElement>(null);
  const [isPending, startTransition] = useTransition();

  // Close mobile menu on route change
  const prevPathnameRef = useRef(pathname);
  useEffect(() => {
    if (prevPathnameRef.current !== pathname) {
      prevPathnameRef.current = pathname;
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

  // Load measurement preference from localStorage on mount
  useEffect(() => {
    const savedMeasurement = localStorage.getItem('userMeasurement');
    queueMicrotask(() => {
      if (savedMeasurement) setCurrentMeasurement(savedMeasurement as MeasurementPreference);
    });
  }, []);

  // Handle locale change
  const handleLocaleChange = (newLocale: Locale) => {
    setIsLocaleMenuOpen(false);
    startTransition(() => {
      router.replace(pathname, { locale: newLocale });
    });
  };

  // Handle measurement change
  const handleMeasurementChange = async (newMeasurement: MeasurementPreference) => {
    setCurrentMeasurement(newMeasurement);
    localStorage.setItem('userMeasurement', newMeasurement);
    setIsMeasurementMenuOpen(false);

    dispatchMeasurementChange(newMeasurement);

    if (isAuthenticated) {
      try {
        await updateUserProfile({ measurementPreference: newMeasurement });
      } catch (error) {
        console.error('Failed to update measurement preference:', error);
      }
    }
  };

  const currentLocaleOption = LOCALE_OPTIONS.find(opt => opt.value === locale) || LOCALE_OPTIONS[0];
  const currentMeasurementOption = MEASUREMENT_OPTIONS.find(opt => opt.value === currentMeasurement) || MEASUREMENT_OPTIONS[0];

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      router.push(`/search?q=${encodeURIComponent(searchQuery.trim())}`);
      setSearchQuery('');
    }
  };

  const navLinks = [
    { href: '/recipes', label: t('recipes') },
    { href: '/logs', label: t('cookingLogs') },
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
            <nav className="hidden md:flex items-center gap-4 lg:gap-6">
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

              {/* Search Icon Link */}
              <Link
                href="/search"
                className={`p-2 rounded-lg transition-colors ${
                  pathname === '/search'
                    ? 'text-[var(--primary)] bg-[var(--primary-light)]'
                    : 'text-[var(--text-secondary)] hover:text-[var(--primary)] hover:bg-[var(--background)]'
                }`}
                title={t('search')}
              >
                <svg
                  className="w-5 h-5"
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
              </Link>

              {/* Measurement Selector */}
              <div className="relative" ref={measurementMenuRef}>
                <button
                  onClick={() => {
                    setIsMeasurementMenuOpen(!isMeasurementMenuOpen);
                    setIsLocaleMenuOpen(false);
                    setIsUserMenuOpen(false);
                  }}
                  className="flex items-center gap-1 px-2 py-1.5 text-sm rounded-lg hover:bg-[var(--background)] transition-colors text-[var(--text-secondary)]"
                  title={t('measurementUnits')}
                >
                  <span className="text-xs">{tMeasurement(currentMeasurementOption.labelKey)}</span>
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
                  <div className="absolute end-0 mt-2 w-28 bg-[var(--surface)] border border-[var(--border)] rounded-xl shadow-lg py-1 z-50">
                    {MEASUREMENT_OPTIONS.map((opt) => (
                      <button
                        key={opt.value}
                        onClick={() => handleMeasurementChange(opt.value as MeasurementPreference)}
                        className={`w-full text-start px-3 py-2 text-sm hover:bg-[var(--background)] ${
                          opt.value === currentMeasurement ? 'bg-[var(--primary-light)] text-[var(--primary)]' : 'text-[var(--text-primary)]'
                        }`}
                      >
                        {tMeasurement(opt.labelKey)}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Language Selector */}
              <div className="relative" ref={localeMenuRef}>
                <button
                  onClick={() => {
                    setIsLocaleMenuOpen(!isLocaleMenuOpen);
                    setIsMeasurementMenuOpen(false);
                    setIsUserMenuOpen(false);
                  }}
                  disabled={isPending}
                  className={`flex items-center gap-1 px-2 py-1.5 text-sm rounded-lg hover:bg-[var(--background)] transition-colors text-[var(--text-secondary)] ${isPending ? 'opacity-50 cursor-not-allowed' : ''}`}
                  title={t('language')}
                >
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
                  <div className="absolute end-0 mt-2 w-36 bg-[var(--surface)] border border-[var(--border)] rounded-xl shadow-lg py-1 z-50 max-h-64 overflow-y-auto">
                    {LOCALE_OPTIONS.map((opt) => (
                      <button
                        key={opt.value}
                        onClick={() => handleLocaleChange(opt.value)}
                        disabled={isPending}
                        className={`w-full text-start px-3 py-2 text-sm hover:bg-[var(--background)] ${
                          opt.value === locale ? 'bg-[var(--primary-light)] text-[var(--primary)]' : 'text-[var(--text-primary)]'
                        } ${isPending ? 'opacity-50 cursor-not-allowed' : ''}`}
                      >
                        {opt.label}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Theme Toggle */}
              <ThemeToggle
                onMenuToggle={(isOpen) => {
                  if (isOpen) {
                    setIsLocaleMenuOpen(false);
                    setIsMeasurementMenuOpen(false);
                    setIsUserMenuOpen(false);
                  }
                }}
              />

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
                        <div className="absolute end-0 mt-2 w-48 bg-[var(--surface)] border border-[var(--border)] rounded-xl shadow-lg py-2 z-50">
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
                            {t('myProfile')}
                          </Link>
                          <Link
                            href="/saved"
                            className="block px-4 py-2 text-sm text-[var(--text-primary)] hover:bg-[var(--background)]"
                            onClick={() => setIsUserMenuOpen(false)}
                          >
                            {t('saved')}
                          </Link>
                          <Link
                            href="/recipes/create"
                            className="block px-4 py-2 text-sm text-[var(--text-primary)] hover:bg-[var(--background)]"
                            onClick={() => setIsUserMenuOpen(false)}
                          >
                            {t('createRecipe')}
                          </Link>
                          <Link
                            href="/logs/create"
                            className="block px-4 py-2 text-sm text-[var(--text-primary)] hover:bg-[var(--background)]"
                            onClick={() => setIsUserMenuOpen(false)}
                          >
                            {t('newCookingLog')}
                          </Link>
                          {isAdmin && (
                            <Link
                              href="/admin"
                              className="block px-4 py-2 text-sm text-[var(--primary)] font-medium hover:bg-[var(--background)]"
                              onClick={() => setIsUserMenuOpen(false)}
                            >
                              {t('adminDashboard')}
                            </Link>
                          )}
                          <div className="border-t border-[var(--border)] mt-2 pt-2">
                            <button
                              onClick={() => {
                                setIsUserMenuOpen(false);
                                signOut();
                              }}
                              className="w-full text-start px-4 py-2 text-sm text-[var(--error)] hover:bg-[var(--background)]"
                            >
                              {tCommon('signOut')}
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
                      {tCommon('signIn')}
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
        className={`fixed top-16 end-0 bottom-0 z-50 w-72 bg-[var(--surface)] border-s border-[var(--border)] transform transition-transform duration-300 ease-in-out md:hidden ${
          isMenuOpen ? 'translate-x-0' : 'ltr:translate-x-full rtl:-translate-x-full'
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
                placeholder={t('searchPlaceholder')}
                className="w-full px-4 py-2.5 ps-10 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)]"
              />
              <svg
                className="absolute start-3 top-1/2 -translate-y-1/2 w-5 h-5 text-[var(--text-secondary)]"
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
                    <p className="text-xs text-[var(--text-secondary)]">{tCommon('signedIn')}</p>
                  </div>
                </div>
              ) : (
                <Link
                  href="/login"
                  className="block w-full text-center px-4 py-3 bg-[var(--primary)] text-white rounded-lg font-medium hover:bg-[var(--primary-dark)] transition-colors"
                >
                  {tCommon('signIn')}
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
                  {t('myProfile')}
                </Link>
                <Link
                  href="/saved"
                  className="block px-4 py-3 rounded-lg text-[var(--text-primary)] hover:bg-[var(--background)]"
                >
                  {t('saved')}
                </Link>
                <Link
                  href="/recipes/create"
                  className="block px-4 py-3 rounded-lg text-[var(--text-primary)] hover:bg-[var(--background)]"
                >
                  {t('createRecipe')}
                </Link>
                <Link
                  href="/logs/create"
                  className="block px-4 py-3 rounded-lg text-[var(--text-primary)] hover:bg-[var(--background)]"
                >
                  {t('newCookingLog')}
                </Link>
                {isAdmin && (
                  <Link
                    href="/admin"
                    className="block px-4 py-3 rounded-lg text-[var(--primary)] font-medium hover:bg-[var(--background)]"
                  >
                    {t('adminDashboard')}
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
              {t('settings')}
            </p>

            {/* Measurement Select */}
            <div>
              <label className="block text-sm text-[var(--text-primary)] mb-2">
                {t('measurementUnits')}
              </label>
              <select
                value={currentMeasurement}
                onChange={(e) => handleMeasurementChange(e.target.value as MeasurementPreference)}
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm focus:outline-none focus:border-[var(--primary)]"
              >
                {MEASUREMENT_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {tMeasurement(opt.labelKey)}
                  </option>
                ))}
              </select>
            </div>

            {/* Language Select */}
            <div>
              <label className="block text-sm text-[var(--text-primary)] mb-2">
                {t('language')}
              </label>
              <select
                value={locale}
                onChange={(e) => handleLocaleChange(e.target.value as Locale)}
                disabled={isPending}
                className={`w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm focus:outline-none focus:border-[var(--primary)] ${isPending ? 'opacity-50 cursor-not-allowed' : ''}`}
              >
                {LOCALE_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>

            {/* Theme Select */}
            <MobileThemeSelect />
          </div>

          {/* Divider */}
          <div className="my-6 border-t border-[var(--border)]" />

          {/* Additional Links */}
          <nav className="space-y-1">
            <Link
              href="/terms"
              className="block px-4 py-2 text-sm text-[var(--text-secondary)] hover:text-[var(--primary)]"
            >
              {t('termsOfService')}
            </Link>
            <Link
              href="/privacy"
              className="block px-4 py-2 text-sm text-[var(--text-secondary)] hover:text-[var(--primary)]"
            >
              {t('privacyPolicy')}
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
                className="w-full px-4 py-3 text-start text-[var(--error)] hover:bg-[var(--background)] rounded-lg transition-colors"
              >
                {tCommon('signOut')}
              </button>
            </>
          )}
        </div>
      </div>
    </>
  );
}

function MobileThemeSelect() {
  const t = useTranslations('nav');
  const { theme, setTheme } = useTheme();

  return (
    <div>
      <label className="block text-sm text-[var(--text-primary)] mb-2">
        {t('theme')}
      </label>
      <select
        value={theme}
        onChange={(e) => setTheme(e.target.value as Theme)}
        className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm focus:outline-none focus:border-[var(--primary)]"
      >
        {THEME_OPTIONS.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {t(opt.labelKey)}
          </option>
        ))}
      </select>
    </div>
  );
}
