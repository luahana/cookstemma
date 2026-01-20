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

export function useNavigationProgress() {
  const context = useContext(NavigationProgressContext);
  if (!context) {
    throw new Error('useNavigationProgress must be used within NavigationProgressProvider');
  }
  return context;
}
