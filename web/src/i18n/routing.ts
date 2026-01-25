import { defineRouting } from 'next-intl/routing';

export const routing = defineRouting({
  // 20 supported languages
  locales: [
    'en',  // English
    'zh',  // Chinese (Simplified)
    'es',  // Spanish
    'ja',  // Japanese
    'de',  // German
    'fr',  // French
    'pt',  // Portuguese
    'ko',  // Korean
    'it',  // Italian
    'ar',  // Arabic
    'ru',  // Russian
    'id',  // Indonesian
    'vi',  // Vietnamese
    'hi',  // Hindi
    'th',  // Thai
    'pl',  // Polish
    'tr',  // Turkish
    'nl',  // Dutch
    'sv',  // Swedish
    'fa',  // Persian (Farsi)
  ],
  defaultLocale: 'en',
  localePrefix: 'always'
});

export type Locale = (typeof routing.locales)[number];

// RTL languages
export const rtlLocales: Locale[] = ['ar', 'fa'];

export function isRtlLocale(locale: Locale): boolean {
  return rtlLocales.includes(locale);
}
