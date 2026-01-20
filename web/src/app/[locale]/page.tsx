import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
import { getTranslations } from 'next-intl/server';
import { getHomeFeed } from '@/lib/api/home';
import { getRecipes } from '@/lib/api/recipes';
import { RecipeGrid } from '@/components/recipe/RecipeGrid';
import { AppDownloadCTA } from '@/components/common/AppDownloadCTA';
import { PopularHashtags } from '@/components/common/PopularHashtags';
import { StarRating } from '@/components/log/StarRating';
import { getImageUrl } from '@/lib/utils/image';
import { siteConfig } from '@/config/site';

interface Props {
  params: Promise<{ locale: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'home' });

  return {
    title: t('metaTitle'),
    description: t('metaDescription'),
    alternates: {
      canonical: `${siteConfig.url}/${locale}`,
    },
  };
}

export default async function Home({ params }: Props) {
  const { locale } = await params;
  const t = await getTranslations('home');
  const tCommon = await getTranslations('common');
  let homeFeed;
  let featuredRecipes;

  try {
    [homeFeed, featuredRecipes] = await Promise.all([
      getHomeFeed(locale),
      getRecipes({ size: 6, sort: 'trending', contentLocale: locale }),
    ]);
  } catch {
    // If API fails, show minimal page
    homeFeed = null;
    featuredRecipes = null;
  }

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="bg-gradient-to-b from-[var(--highlight-bg)] to-[var(--background)] py-16 sm:py-24">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-[var(--text-primary)] mb-6">
              {t.rich('heroTitle', {
                highlight: (chunks) => <span className="text-[#E67E22]">{chunks}</span>,
              })}
            </h1>
            <p className="text-lg sm:text-xl text-[var(--text-secondary)] max-w-2xl mx-auto mb-10">
              {t('heroSubtitle')}
            </p>

            <AppDownloadCTA />
          </div>
        </div>
      </section>

      {/* Featured Recipes */}
      {featuredRecipes && featuredRecipes.content.length > 0 && (
        <section className="py-16 bg-[var(--background)]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between mb-8">
              <h2 className="text-2xl sm:text-3xl font-bold text-[var(--text-primary)]">
                {t('featuredRecipes')}
              </h2>
              <Link
                href="/recipes"
                className="text-[var(--primary)] hover:underline font-medium"
              >
                {tCommon('viewAll')}
              </Link>
            </div>
            <RecipeGrid recipes={featuredRecipes.content} />
          </div>
        </section>
      )}

      {/* Popular Hashtags */}
      <section className="py-12 bg-[var(--surface)]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <PopularHashtags limit={10} />
        </div>
      </section>

      {/* Recent Activity */}
      {homeFeed && homeFeed.recentActivity.length > 0 && (
        <section className="py-16 bg-[var(--surface)]">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between mb-8">
              <h2 className="text-2xl sm:text-3xl font-bold text-[var(--text-primary)]">
                {t('recentCookingLogs')}
              </h2>
              <Link
                href="/logs"
                className="text-[var(--primary)] hover:underline font-medium"
              >
                {tCommon('viewAll')}
              </Link>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {homeFeed.recentActivity.slice(0, 6).map((activity) => (
                <Link
                  key={activity.logPublicId}
                  href={`/logs/${activity.logPublicId}`}
                  className="bg-[var(--background)] rounded-xl p-4 hover:shadow-md transition-shadow border border-[var(--border)]"
                >
                  <div className="flex gap-4">
                    {getImageUrl(activity.thumbnailUrl) && (
                      <div className="relative w-20 h-20 rounded-lg overflow-hidden flex-shrink-0">
                        <Image
                          src={getImageUrl(activity.thumbnailUrl)!}
                          alt={activity.recipeTitle}
                          fill
                          className="object-cover"
                          sizes="80px"
                        />
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        {activity.rating && <StarRating rating={activity.rating} size="sm" />}
                        <span className="text-sm font-medium text-[var(--primary)]">{activity.foodName}</span>
                      </div>
                      <p className="font-medium text-[var(--text-primary)] truncate">
                        {activity.recipeTitle}
                      </p>
                      <p className="text-sm text-[var(--text-secondary)]">
                        {tCommon('by')} {activity.userName || tCommon('anonymous')}
                      </p>
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* Features */}
      <section className="py-16 bg-[var(--background)]">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
          <h2 className="text-2xl sm:text-3xl font-bold text-[var(--text-primary)] text-center mb-12">
            {t('whyCookstemma')}
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-[var(--surface)] p-6 rounded-2xl shadow-sm border border-[var(--border)]">
              <div className="w-12 h-12 bg-[var(--primary-light)] rounded-xl flex items-center justify-center mb-4">
                <svg className="w-6 h-6 text-[var(--primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-[var(--text-primary)] mb-2">{t('shareRecipes')}</h3>
              <p className="text-[var(--text-secondary)]">
                {t('shareRecipesDesc')}
              </p>
            </div>
            <div className="bg-[var(--surface)] p-6 rounded-2xl shadow-sm border border-[var(--border)]">
              <div className="w-12 h-12 bg-[var(--primary-light)] rounded-xl flex items-center justify-center mb-4">
                <svg className="w-6 h-6 text-[var(--primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-[var(--text-primary)] mb-2">{t('createVariations')}</h3>
              <p className="text-[var(--text-secondary)]">
                {t('createVariationsDesc')}
              </p>
            </div>
            <div className="bg-[var(--surface)] p-6 rounded-2xl shadow-sm border border-[var(--border)]">
              <div className="w-12 h-12 bg-[var(--primary-light)] rounded-xl flex items-center justify-center mb-4">
                <svg className="w-6 h-6 text-[var(--primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-[var(--text-primary)] mb-2">{t('trackCooking')}</h3>
              <p className="text-[var(--text-secondary)]">
                {t('trackCookingDesc')}
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-16 bg-[var(--secondary)] dark:bg-[#2D2D2D]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-2xl sm:text-3xl font-bold text-white mb-4">
            {t('startJourney')}
          </h2>
          <p className="text-white/80 mb-8 max-w-2xl mx-auto">
            {t('startJourneyDesc')}
          </p>
          <div className="flex justify-center gap-4">
            <Link
              href="/recipes"
              className="px-6 py-3 bg-white !text-gray-800 font-semibold rounded-xl hover:bg-gray-200 hover:scale-105 transition-all"
            >
              {t('browseRecipes')}
            </Link>
            <Link
              href="/search"
              className="px-6 py-3 bg-[var(--primary)] dark:bg-[var(--secondary)] font-semibold rounded-xl hover:bg-[var(--primary-dark)] dark:hover:bg-[#6D4C41] hover:scale-105 transition-all"
            >
              <span className="text-white">{tCommon('search')}</span>
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
