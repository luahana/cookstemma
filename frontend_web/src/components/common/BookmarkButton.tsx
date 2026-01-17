'use client';

import { useState, useCallback, MouseEvent } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { saveRecipe, unsaveRecipe, saveLog, unsaveLog } from '@/lib/api/saved';

interface BookmarkButtonProps {
  publicId: string;
  type: 'recipe' | 'log';
  initialSaved?: boolean;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
  onSaveChange?: (isSaved: boolean) => void;
}

export function BookmarkButton({
  publicId,
  type,
  initialSaved = false,
  size = 'md',
  className = '',
  onSaveChange,
}: BookmarkButtonProps) {
  const { isAuthenticated } = useAuth();
  const [isSaved, setIsSaved] = useState(initialSaved);
  const [isLoading, setIsLoading] = useState(false);

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

      if (!isAuthenticated || isLoading) return;

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
    [isAuthenticated, isLoading, isSaved, publicId, type, onSaveChange]
  );

  // Don't render if not authenticated
  if (!isAuthenticated) {
    return null;
  }

  return (
    <button
      onClick={handleClick}
      disabled={isLoading}
      className={`
        ${sizeClasses[size]}
        flex items-center justify-center rounded-full
        bg-white/90 backdrop-blur-sm shadow-sm
        hover:bg-white hover:shadow-md
        transition-all duration-200
        disabled:opacity-50 disabled:cursor-not-allowed
        ${className}
      `}
      aria-label={isSaved ? 'Remove bookmark' : 'Add bookmark'}
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
