import type { Metadata } from 'next';
import { Suspense } from 'react';
import {
  Geist,
  Geist_Mono,
  Noto_Sans_Arabic,
  Noto_Sans_SC,
  Noto_Sans_JP,
  Noto_Sans_KR,
  Noto_Sans_Thai,
  Noto_Sans,
} from 'next/font/google';
import { NextIntlClientProvider } from 'next-intl';
import { getMessages, setRequestLocale } from 'next-intl/server';
import { notFound } from 'next/navigation';
import { routing, type Locale, isRtlLocale } from '@/i18n/routing';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { LocaleSync } from '@/components/common/LocaleSync';
import { SiteJsonLd } from '@/components/seo/SiteJsonLd';
import { AuthProvider } from '@/contexts/AuthContext';
import { ThemeProvider } from '@/contexts/ThemeContext';
import { SentryProvider } from '@/components/SentryProvider';
import { NavigationProgressProvider } from '@/contexts/NavigationProgressContext';
import { NavigationProgress } from '@/components/common/NavigationProgress';
import { themeScript } from '@/lib/theme/script';
import { siteConfig } from '@/config/site';
import '../globals.css';

// Latin script font (English, Spanish, German, French, Portuguese, Italian, Polish, Turkish, Dutch, Swedish, Indonesian, Vietnamese)
const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
});

// Noto Sans for extended Latin and Cyrillic (Russian)
const notoSans = Noto_Sans({
  variable: '--font-noto-sans',
  subsets: ['latin', 'latin-ext', 'cyrillic', 'cyrillic-ext', 'vietnamese', 'greek'],
  weight: ['400', '500', '600', '700'],
});

// Arabic and Persian
const notoSansArabic = Noto_Sans_Arabic({
  variable: '--font-noto-arabic',
  subsets: ['arabic'],
  weight: ['400', '500', '600', '700'],
});

// Chinese Simplified
const notoSansSC = Noto_Sans_SC({
  variable: '--font-noto-sc',
  subsets: ['latin'],
  weight: ['400', '500', '700'],
});

// Japanese
const notoSansJP = Noto_Sans_JP({
  variable: '--font-noto-jp',
  subsets: ['latin'],
  weight: ['400', '500', '700'],
});

// Korean
const notoSansKR = Noto_Sans_KR({
  variable: '--font-noto-kr',
  subsets: ['latin'],
  weight: ['400', '500', '700'],
});

// Thai
const notoSansThai = Noto_Sans_Thai({
  variable: '--font-noto-thai',
  subsets: ['latin', 'thai'],
  weight: ['400', '500', '600', '700'],
});

export function generateStaticParams() {
  return routing.locales.map((locale) => ({ locale }));
}

/**
 * Map locale codes to OpenGraph locale format (e.g., "en" → "en_US")
 */
function getOpenGraphLocale(locale: string): string {
  const ogLocaleMap: Record<string, string> = {
    en: 'en_US',
    ko: 'ko_KR',
    ja: 'ja_JP',
    zh: 'zh_CN',
    de: 'de_DE',
    fr: 'fr_FR',
    es: 'es_ES',
    pt: 'pt_BR',
    it: 'it_IT',
    ar: 'ar_SA',
    ru: 'ru_RU',
    id: 'id_ID',
    vi: 'vi_VN',
    hi: 'hi_IN',
    th: 'th_TH',
    pl: 'pl_PL',
    tr: 'tr_TR',
    nl: 'nl_NL',
    sv: 'sv_SE',
    fa: 'fa_IR',
  };
  return ogLocaleMap[locale] || 'en_US';
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale: localeParam } = await params;
  const locale = localeParam as Locale;
  const baseUrl = siteConfig.url;

  // Generate alternates for all locales
  const languages: Record<string, string> = {};
  routing.locales.forEach((loc) => {
    languages[loc] = `${baseUrl}/${loc}`;
  });
  languages['x-default'] = `${baseUrl}/en`;

  return {
    title: {
      default: siteConfig.name,
      template: `%s | ${siteConfig.name}`,
    },
    description: siteConfig.description,
    metadataBase: new URL(siteConfig.url),
    alternates: {
      canonical: `${baseUrl}/${locale}`,
      languages,
    },
    openGraph: {
      type: 'website',
      locale: getOpenGraphLocale(locale),
      url: siteConfig.url,
      siteName: siteConfig.name,
      title: siteConfig.name,
      description: siteConfig.description,
      images: [
        {
          url: siteConfig.ogImage,
          width: 1200,
          height: 630,
          alt: siteConfig.name,
        },
      ],
    },
    twitter: {
      card: 'summary_large_image',
      title: siteConfig.name,
      description: siteConfig.description,
      images: [siteConfig.ogImage],
    },
    robots: {
      index: true,
      follow: true,
    },
  };
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale: localeParam } = await params;

  // Validate locale
  if (!routing.locales.includes(localeParam as Locale)) {
    notFound();
  }

  const locale = localeParam as Locale;

  // Enable static rendering
  setRequestLocale(locale);

  const messages = await getMessages();
  const isRTL = isRtlLocale(locale);

  // Combine all font variables
  const fontVariables = [
    geistSans.variable,
    geistMono.variable,
    notoSans.variable,
    notoSansArabic.variable,
    notoSansSC.variable,
    notoSansJP.variable,
    notoSansKR.variable,
    notoSansThai.variable,
  ].join(' ');

  return (
    <html lang={locale} dir={isRTL ? 'rtl' : 'ltr'} suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{ __html: themeScript }}
          suppressHydrationWarning
        />
        <SiteJsonLd />
      </head>
      <body
        className={`${fontVariables} antialiased min-h-screen flex flex-col`}
      >
        <SentryProvider>
          <ThemeProvider>
            <NextIntlClientProvider messages={messages}>
              <AuthProvider>
              <NavigationProgressProvider>
                <Suspense fallback={null}>
                  <NavigationProgress />
                </Suspense>
                <LocaleSync />
                <Header />
                <main className="flex-1">{children}</main>
                <Footer />
              </NavigationProgressProvider>
              </AuthProvider>
            </NextIntlClientProvider>
          </ThemeProvider>
        </SentryProvider>
      </body>
    </html>
  );
}
