'use client';

import { useState, useCallback, useEffect, MouseEvent } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import {
  saveRecipe,
  unsaveRecipe,
  saveLog,
  unsaveLog,
  checkRecipeSaved,
  checkLogSaved,
} from '@/lib/api/saved';

interface BookmarkButtonProps {
  publicId: string;
  type: 'recipe' | 'log';
  initialSaved?: boolean;
  size?: 'sm' | 'md' | 'lg';
  variant?: 'overlay' | 'inline';
  className?: string;
  onSaveChange?: (isSaved: boolean) => void;
}

export function BookmarkButton({
  publicId,
  type,
  initialSaved = false,
  size = 'md',
  variant = 'overlay',
  className = '',
  onSaveChange,
}: BookmarkButtonProps) {
  const t = useTranslations('bookmark');
  const router = useRouter();
  const { isAuthenticated } = useAuth();
  const [isSaved, setIsSaved] = useState(initialSaved);
  const [isLoading, setIsLoading] = useState(false);

  // Fetch saved status on mount when authenticated
  useEffect(() => {
    if (!isAuthenticated) return;

    const fetchSavedStatus = async () => {
      try {
        const saved = type === 'recipe'
          ? await checkRecipeSaved(publicId)
          : await checkLogSaved(publicId);
        setIsSaved(saved);
      } catch (error) {
        console.error('Failed to fetch saved status:', error);
      }
    };

    fetchSavedStatus();
  }, [isAuthenticated, publicId, type]);

  const sizeClasses = {
    sm: 'w-8 h-8',
    md: 'w-10 h-10',
    lg: 'w-12 h-12',
  };

  const iconSizeClasses = {
    sm: 'w-4 h-4',
    md: 'w-5 h-5',
    lg: 'w-6 h-6',
  };

  const handleClick = useCallback(
    async (e: MouseEvent) => {
      e.preventDefault();
      e.stopPropagation();

      if (!isAuthenticated) {
        const currentPath = window.location.pathname;
        router.push(`/login?redirect=${encodeURIComponent(currentPath)}`);
        return;
      }

      if (isLoading) return;

      setIsLoading(true);
      try {
        if (isSaved) {
          if (type === 'recipe') {
            await unsaveRecipe(publicId);
          } else {
            await unsaveLog(publicId);
          }
          setIsSaved(false);
          onSaveChange?.(false);
        } else {
          if (type === 'recipe') {
            await saveRecipe(publicId);
          } else {
            await saveLog(publicId);
          }
          setIsSaved(true);
          onSaveChange?.(true);
        }
      } catch (error) {
        console.error('Failed to toggle bookmark:', error);
      } finally {
        setIsLoading(false);
      }
    },
    [isAuthenticated, isLoading, isSaved, publicId, type, onSaveChange, router]
  );

  const variantClasses = {
    overlay: 'bg-white/90 backdrop-blur-sm shadow-sm hover:bg-white hover:shadow-md',
    inline: 'bg-transparent hover:bg-[var(--highlight-bg)]',
  };

  return (
    <button
      onClick={handleClick}
      disabled={isLoading}
      className={`
        ${sizeClasses[size]}
        flex items-center justify-center rounded-full
        ${variantClasses[variant]}
        transition-all duration-200
        disabled:opacity-50 disabled:cursor-not-allowed
        ${className}
      `}
      aria-label={isSaved ? t('remove') : t('add')}
    >
      <svg
        className={`${iconSizeClasses[size]} transition-colors duration-200 ${
          isSaved ? 'text-[var(--primary)] fill-current' : 'text-[var(--text-secondary)]'
        }`}
        fill={isSaved ? 'currentColor' : 'none'}
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
        />
      </svg>
    </button>
  );
}
