/**
 * Cooking style utilities for displaying culinary locale
 */

/**
 * Get flag image URL for a country code using flagcdn.com
 */
export function getFlagImageUrl(countryCode: string, size: number = 24): string {
  if (countryCode === 'international') {
    // Use a globe icon for international
    return `https://flagcdn.com/w${size}/un.png`;
  }
  return `https://flagcdn.com/w${size}/${countryCode.toLowerCase()}.png`;
}

// Country code to display name mapping
const COUNTRY_NAMES: Record<string, string> = {
  KR: 'Korean',
  JP: 'Japanese',
  CN: 'Chinese',
  US: 'American',
  FR: 'French',
  DE: 'German',
  ES: 'Spanish',
  IT: 'Italian',
  BR: 'Brazilian',
  RU: 'Russian',
  GR: 'Greek',
  TH: 'Thai',
  VN: 'Vietnamese',
  IN: 'Indian',
  SA: 'Middle Eastern',
  TR: 'Turkish',
  NL: 'Dutch',
  PL: 'Polish',
  SE: 'Swedish',
  DK: 'Danish',
  FI: 'Finnish',
  NO: 'Norwegian',
  ID: 'Indonesian',
  MY: 'Malaysian',
  MX: 'Mexican',
  TW: 'Taiwanese',
  GB: 'British',
  AU: 'Australian',
  CA: 'Canadian',
  international: 'International',
};

// Legacy code mapping (e.g., "ko-KR" -> "KR")
const LEGACY_CODE_MAP: Record<string, string> = {
  'ko-KR': 'KR',
  'en-US': 'US',
  'ja-JP': 'JP',
  'zh-CN': 'CN',
  'it-IT': 'IT',
  'es-MX': 'MX',
  'th-TH': 'TH',
  'hi-IN': 'IN',
  'fr-FR': 'FR',
};

/**
 * Normalize a culinary locale code to a standard 2-letter country code
 */
export function normalizeLocaleCode(code: string | null | undefined): string {
  if (!code || code === 'international') return 'international';

  // Check if it's a legacy code
  if (LEGACY_CODE_MAP[code]) {
    return LEGACY_CODE_MAP[code];
  }

  // If already a 2-letter code, return as-is (uppercase)
  if (code.length === 2) {
    return code.toUpperCase();
  }

  // Try to extract country code from locale string (e.g., "ko_KR" -> "KR")
  const parts = code.replace('-', '_').split('_');
  for (const part of parts.reverse()) {
    if (part.length === 2 && part === part.toUpperCase()) {
      return part;
    }
  }

  return 'international';
}

/**
 * Get display name for a culinary locale code
 */
export function getCookingStyleName(code: string | null | undefined): string {
  const normalized = normalizeLocaleCode(code);
  return COUNTRY_NAMES[normalized] || 'International';
}

/**
 * Get cooking style display data including flag image URL and name
 */
export function getCookingStyleDisplay(code: string | null | undefined): {
  flagUrl: string;
  name: string;
  countryCode: string;
} {
  const normalized = normalizeLocaleCode(code);
  return {
    flagUrl: getFlagImageUrl(normalized, 40),
    name: getCookingStyleName(code),
    countryCode: normalized,
  };
}

/**
 * Get default culinary locale based on browser locale
 */
export function getDefaultCulinaryLocale(): string {
  if (typeof navigator === 'undefined') return 'US';

  const browserLocale = navigator.language || 'en-US';
  const normalized = normalizeLocaleCode(browserLocale);

  // If we got a valid country code, use it
  if (normalized !== 'international' && COUNTRY_NAMES[normalized]) {
    return normalized;
  }

  // Language to default country mapping
  const languageToCountry: Record<string, string> = {
    ko: 'KR',
    ja: 'JP',
    zh: 'CN',
    en: 'US',
    fr: 'FR',
    de: 'DE',
    es: 'ES',
    it: 'IT',
    pt: 'BR',
    ru: 'RU',
    th: 'TH',
    vi: 'VN',
    hi: 'IN',
    ar: 'SA',
    tr: 'TR',
  };

  const lang = browserLocale.split('-')[0].toLowerCase();
  return languageToCountry[lang] || 'US';
}
