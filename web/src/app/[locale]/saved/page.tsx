'use client';

import { useState, useEffect, useCallback } from 'react';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { getSavedRecipes, getSavedLogs } from '@/lib/api/saved';
import { RecipeCard } from '@/components/recipe/RecipeCard';
import { LogCard } from '@/components/log/LogCard';
import { Pagination } from '@/components/common/Pagination';
import { LoadingSpinner } from '@/components/common/LoadingSpinner';
import type { RecipeSummary, LogPostSummary, UnifiedPageResponse } from '@/lib/types';

type TabType = 'recipes' | 'logs';

export default function SavedPage() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const router = useRouter();
  const t = useTranslations('saved');

  const [activeTab, setActiveTab] = useState<TabType>('recipes');
  const [recipes, setRecipes] = useState<UnifiedPageResponse<RecipeSummary> | null>(null);
  const [logs, setLogs] = useState<UnifiedPageResponse<LogPostSummary> | null>(null);
  const [currentPage, setCurrentPage] = useState(0);
  const [isLoading, setIsLoading] = useState(false);

  const loadData = useCallback(async () => {
    if (!isAuthenticated) return;

    setIsLoading(true);
    try {
      if (activeTab === 'recipes') {
        const data = await getSavedRecipes({ page: currentPage, size: 12 });
        setRecipes(data);
      } else {
        const data = await getSavedLogs({ page: currentPage, size: 12 });
        setLogs(data);
      }
    } catch (error) {
      console.error('Failed to load saved content:', error);
    } finally {
      setIsLoading(false);
    }
  }, [isAuthenticated, activeTab, currentPage]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  useEffect(() => {
    // Reset page when tab changes
    setCurrentPage(0);
  }, [activeTab]);

  // Redirect to login if not authenticated
  useEffect(() => {
    if (!authLoading && !isAuthenticated) {
      router.push('/');
    }
  }, [authLoading, isAuthenticated, router]);

  if (authLoading) {
    return <LoadingSpinner />;
  }

  if (!isAuthenticated) {
    return null;
  }

  const currentData = activeTab === 'recipes' ? recipes : logs;
  const totalPages = currentData?.totalPages ?? 0;

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Page header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-[var(--text-primary)]">{t('title')}</h1>
        <p className="text-[var(--text-secondary)] mt-2">
          {t('subtitle')}
        </p>
      </div>

      {/* Tabs */}
      <div className="border-b border-[var(--border)] mb-6">
        <nav className="flex gap-8" aria-label="Tabs">
          <button
            onClick={() => setActiveTab('recipes')}
            className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'recipes'
                ? 'border-[var(--primary)] text-[var(--primary)]'
                : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:border-[var(--border)]'
            }`}
          >
            {t('recipesTab')}
            {recipes?.totalElements !== null && recipes?.totalElements !== undefined && (
              <span className="ml-2 py-0.5 px-2 bg-[var(--background)] text-[var(--text-secondary)] text-xs rounded-full">
                {recipes.totalElements}
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveTab('logs')}
            className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'logs'
                ? 'border-[var(--primary)] text-[var(--primary)]'
                : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:border-[var(--border)]'
            }`}
          >
            {t('logsTab')}
            {logs?.totalElements !== null && logs?.totalElements !== undefined && (
              <span className="ml-2 py-0.5 px-2 bg-[var(--background)] text-[var(--text-secondary)] text-xs rounded-full">
                {logs.totalElements}
              </span>
            )}
          </button>
        </nav>
      </div>

      {/* Content */}
      {isLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="bg-[var(--surface)] rounded-2xl shadow-sm border border-[var(--border)] overflow-hidden animate-pulse">
              <div className="aspect-[4/3] bg-[var(--border)]"></div>
              <div className="p-4">
                <div className="h-4 bg-[var(--border)] rounded w-1/4 mb-2"></div>
                <div className="h-5 bg-[var(--border)] rounded w-3/4 mb-2"></div>
                <div className="h-4 bg-[var(--border)] rounded w-full"></div>
              </div>
            </div>
          ))}
        </div>
      ) : activeTab === 'recipes' ? (
        <>
          {recipes?.content.length === 0 ? (
            <div className="text-center py-12">
              <svg
                className="w-16 h-16 mx-auto text-[var(--text-secondary)] opacity-50"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={1.5}
                  d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
                />
              </svg>
              <h3 className="mt-4 text-lg font-medium text-[var(--text-primary)]">
                {t('noSavedRecipes')}
              </h3>
              <p className="mt-2 text-[var(--text-secondary)]">
                {t('startBrowsing')}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {recipes?.content.map((recipe) => (
                <RecipeCard key={recipe.publicId} recipe={recipe} isSaved={true} />
              ))}
            </div>
          )}
        </>
      ) : (
        <>
          {logs?.content.length === 0 ? (
            <div className="text-center py-12">
              <svg
                className="w-16 h-16 mx-auto text-[var(--text-secondary)] opacity-50"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={1.5}
                  d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
                />
              </svg>
              <h3 className="mt-4 text-lg font-medium text-[var(--text-primary)]">
                {t('noSavedLogs')}
              </h3>
              <p className="mt-2 text-[var(--text-secondary)]">
                {t('startBrowsing')}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {logs?.content.map((log) => (
                <LogCard key={log.publicId} log={log} isSaved={true} />
              ))}
            </div>
          )}
        </>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="mt-8">
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            baseUrl={`/saved?tab=${activeTab}`}
            onPageChange={(page) => setCurrentPage(page)}
          />
        </div>
      )}
    </div>
  );
}
