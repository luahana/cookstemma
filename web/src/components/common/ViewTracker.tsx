'use client';

import { useEffect, useRef } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { recordRecipeView, recordLogView } from '@/lib/api/history';
import { addToViewHistory } from '@/lib/utils/viewHistory';

interface ViewTrackerProps {
  publicId: string;
  type: 'recipe' | 'log';
  title: string; // Pre-localized title from backend
  thumbnail: string | null;
  foodName: string | null;
  rating?: number | null;
}

/**
 * Component that tracks views when mounted.
 * Saves to localStorage for display and to backend for permanent storage.
 */
export function ViewTracker({
  publicId,
  type,
  title,
  thumbnail,
  foodName,
  rating,
}: ViewTrackerProps) {
  const { isAuthenticated, isLoading } = useAuth();
  const hasTrackedLocal = useRef(false);
  const hasTrackedBackend = useRef(false);

  // Save to localStorage immediately (works for all users)
  useEffect(() => {
    if (hasTrackedLocal.current) return;
    hasTrackedLocal.current = true;

    addToViewHistory({
      type,
      publicId,
      title,
      thumbnail,
      foodName,
      rating,
    });
  }, [type, publicId, title, thumbnail, foodName, rating]);

  // Save to backend after auth is determined (only for authenticated users)
  useEffect(() => {
    if (isLoading || hasTrackedBackend.current) return;

    if (isAuthenticated) {
      hasTrackedBackend.current = true;
      if (type === 'recipe') {
        recordRecipeView(publicId);
      } else {
        recordLogView(publicId);
      }
    }
  }, [isLoading, isAuthenticated, publicId, type]);

  return null;
}
