'use client';

import { useEffect } from 'react';
import { useLocale } from 'next-intl';
import { useRouter, usePathname } from '@/i18n/navigation';
import { routing, type Locale } from '@/i18n/routing';

/**
 * LocaleSync component handles syncing the user's locale preference
 * across browser navigation (back/forward buttons).
 *
 * Problem: When user changes language and navigates back, the browser
 * restores the old URL with the old locale.
 *
 * Solution: Store locale preference in localStorage and redirect to
 * the preferred locale on page load when it differs from the URL locale.
 */
export function LocaleSync() {
  const currentLocale = useLocale() as Locale;
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    const savedLocale = localStorage.getItem('userLocale') as Locale | null;

    // If user has a saved preference that differs from current URL locale
    if (
      savedLocale &&
      routing.locales.includes(savedLocale) &&
      savedLocale !== currentLocale
    ) {
      // Redirect to preferred locale
      router.replace(pathname, { locale: savedLocale });
    }
  }, [currentLocale, pathname, router]);

  return null;
}
