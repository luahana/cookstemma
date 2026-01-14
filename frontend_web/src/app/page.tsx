import Link from 'next/link';
import Image from 'next/image';
import { getHomeFeed } from '@/lib/api/home';
import { getRecipes } from '@/lib/api/recipes';
import { RecipeGrid } from '@/components/recipe/RecipeGrid';
import { AppDownloadCTA } from '@/components/common/AppDownloadCTA';
import { PopularHashtags } from '@/components/common/PopularHashtags';
import { OutcomeBadge } from '@/components/log/OutcomeBadge';
import { getImageUrl } from '@/lib/utils/image';

export default async function Home() {
  let homeFeed;
  let featuredRecipes;

  try {
    [homeFeed, featuredRecipes] = await Promise.all([
      getHomeFeed(),
      getRecipes({ size: 6, sort: 'trending' }),
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
              Your Recipes, <span className="text-[var(--primary)]">Evolved</span>
            </h1>
            <p className="text-lg sm:text-xl text-[var(--text-secondary)] max-w-2xl mx-auto mb-10">
              Share your recipes, create variations, and track your cooking journey.
              Join a community of home cooks discovering new flavors together.
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
                Featured Recipes
              </h2>
              <Link
                href="/recipes"
                className="text-[var(--primary)] hover:underline font-medium"
              >
                View all
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
                Recent Cooking Activity
              </h2>
              <Link
                href="/logs"
                className="text-[var(--primary)] hover:underline font-medium"
              >
                View all
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
                        <OutcomeBadge outcome={activity.outcome} size="sm" />
                      </div>
                      <p className="font-medium text-[var(--text-primary)] truncate">
                        {activity.recipeTitle}
                      </p>
                      <p className="text-sm text-[var(--text-secondary)]">
                        by {activity.creatorName || 'Anonymous'}
                      </p>
                      <p className="text-xs text-[var(--text-secondary)] mt-1">
                        {activity.foodName}
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
            Why Pairing Planet?
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-[var(--surface)] p-6 rounded-2xl shadow-sm border border-[var(--border)]">
              <div className="w-12 h-12 bg-[var(--primary-light)] rounded-xl flex items-center justify-center mb-4">
                <svg className="w-6 h-6 text-[var(--primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-[var(--text-primary)] mb-2">Share Recipes</h3>
              <p className="text-[var(--text-secondary)]">
                Create and share your favorite recipes with photos and step-by-step instructions.
              </p>
            </div>
            <div className="bg-[var(--surface)] p-6 rounded-2xl shadow-sm border border-[var(--border)]">
              <div className="w-12 h-12 bg-[var(--primary-light)] rounded-xl flex items-center justify-center mb-4">
                <svg className="w-6 h-6 text-[var(--primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-[var(--text-primary)] mb-2">Create Variations</h3>
              <p className="text-[var(--text-secondary)]">
                Put your own spin on recipes and see how dishes evolve across the community.
              </p>
            </div>
            <div className="bg-[var(--surface)] p-6 rounded-2xl shadow-sm border border-[var(--border)]">
              <div className="w-12 h-12 bg-[var(--primary-light)] rounded-xl flex items-center justify-center mb-4">
                <svg className="w-6 h-6 text-[var(--primary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-[var(--text-primary)] mb-2">Track Your Cooking</h3>
              <p className="text-[var(--text-secondary)]">
                Log your cooking sessions, note what worked, and improve over time.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-16 bg-[var(--primary)]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-2xl sm:text-3xl font-bold text-white mb-4">
            Start Your Cooking Journey
          </h2>
          <p className="text-white/80 mb-8 max-w-2xl mx-auto">
            Download the app and join thousands of home cooks sharing their culinary adventures.
          </p>
          <div className="flex justify-center gap-4">
            <Link
              href="/recipes"
              className="px-6 py-3 bg-white text-[var(--primary)] font-semibold rounded-xl hover:bg-gray-100 transition-colors"
            >
              Browse Recipes
            </Link>
            <Link
              href="/search"
              className="px-6 py-3 bg-[var(--primary-dark)] text-white font-semibold rounded-xl hover:bg-[var(--secondary)] transition-colors"
            >
              Search
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
