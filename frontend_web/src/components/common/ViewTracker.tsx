'use client';

import { useEffect, useRef } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { recordRecipeView, recordLogView } from '@/lib/api/history';

interface ViewTrackerProps {
  publicId: string;
  type: 'recipe' | 'log';
}

/**
 * Component that tracks views when mounted.
 * Uses sessionStorage to avoid duplicate tracking within the same session.
 */
export function ViewTracker({ publicId, type }: ViewTrackerProps) {
  const { isAuthenticated } = useAuth();
  const hasTracked = useRef(false);

  useEffect(() => {
    // Only track once per component mount, and only for authenticated users
    if (!isAuthenticated || hasTracked.current) return;

    // Check sessionStorage to avoid duplicate tracking within same session
    const storageKey = `viewed_${type}_${publicId}`;
    if (typeof window !== 'undefined' && sessionStorage.getItem(storageKey)) {
      return;
    }

    hasTracked.current = true;

    // Record the view
    if (type === 'recipe') {
      recordRecipeView(publicId);
    } else {
      recordLogView(publicId);
    }

    // Mark as viewed in sessionStorage
    if (typeof window !== 'undefined') {
      sessionStorage.setItem(storageKey, 'true');
    }
  }, [isAuthenticated, publicId, type]);

  // This component doesn't render anything
  return null;
}
