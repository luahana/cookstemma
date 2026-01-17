'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import { getRecentlyViewedRecipes } from '@/lib/api/history';
import { RecipeGrid } from '@/components/recipe/RecipeGrid';
import type { RecipeSummary } from '@/lib/types';

export function RecentlyViewedSection() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [recipes, setRecipes] = useState<RecipeSummary[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (authLoading) return;

    if (!isAuthenticated) {
      setIsLoading(false);
      return;
    }

    async function fetchRecentlyViewed() {
      try {
        const data = await getRecentlyViewedRecipes(6);
        setRecipes(data);
      } catch (error) {
        console.error('Failed to fetch recently viewed:', error);
      } finally {
        setIsLoading(false);
      }
    }

    fetchRecentlyViewed();
  }, [isAuthenticated, authLoading]);

  // Don't render anything if not authenticated or no recipes
  if (authLoading || isLoading) return null;
  if (!isAuthenticated) return null;
  if (recipes.length === 0) return null;

  return (
    <section className="py-16 bg-[var(--background)]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between mb-8">
          <h2 className="text-2xl sm:text-3xl font-bold text-[var(--text-primary)]">
            Recently Viewed
          </h2>
          <Link
            href="/recipes"
            className="text-[var(--primary)] hover:underline font-medium"
          >
            Browse more
          </Link>
        </div>
        <RecipeGrid recipes={recipes} />
      </div>
    </section>
  );
}
