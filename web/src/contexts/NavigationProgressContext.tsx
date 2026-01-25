'use client';

import { createContext, useContext, useState, useCallback, useRef, type ReactNode } from 'react';

interface NavigationProgressContextType {
  isLoading: boolean;
  startLoading: () => void;
  stopLoading: () => void;
}

const NavigationProgressContext = createContext<NavigationProgressContextType | null>(null);

export function NavigationProgressProvider({ children }: { children: ReactNode }) {
  const [isLoading, setIsLoading] = useState(false);
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);

  const startLoading = useCallback(() => {
    // Clear any existing timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    setIsLoading(true);

    // Auto-stop after 10 seconds as a safety fallback
    timeoutRef.current = setTimeout(() => {
      setIsLoading(false);
    }, 10000);
  }, []);

  const stopLoading = useCallback(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    setIsLoading(false);
  }, []);

  return (
    <NavigationProgressContext.Provider value={{ isLoading, startLoading, stopLoading }}>
      {children}
    </NavigationProgressContext.Provider>
  );
}

// No-op fallback for when used outside provider (e.g., during static generation)
const noopContext: NavigationProgressContextType = {
  isLoading: false,
  startLoading: () => {},
  stopLoading: () => {},
};

export function useNavigationProgress() {
  const context = useContext(NavigationProgressContext);
  // Return no-op context if used outside provider (safe for static rendering)
  return context ?? noopContext;
}
