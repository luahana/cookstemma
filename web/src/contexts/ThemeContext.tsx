'use client';

import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  useMemo,
  ReactNode,
} from 'react';

export type Theme = 'light' | 'dark' | 'system';
export type ResolvedTheme = 'light' | 'dark';

interface ThemeContextType {
  theme: Theme;
  resolvedTheme: ResolvedTheme;
  setTheme: (theme: Theme) => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

const STORAGE_KEY = 'theme';

function getSystemTheme(): ResolvedTheme {
  if (typeof window === 'undefined') return 'light';
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function getStoredTheme(): Theme {
  if (typeof window === 'undefined') return 'system';
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored === 'light' || stored === 'dark' || stored === 'system') {
    return stored;
  }
  return 'system';
}

const darkThemeVars = {
  '--primary': '#F39C12',
  '--primary-light': '#5D4037',
  '--primary-dark': '#E67E22',
  '--secondary': '#8D6E63',
  '--success': '#2ECC71',
  '--error': '#E74C3C',
  '--rating': '#F1C40F',
  '--hashtag': '#66BB6A',
  '--background': '#121212',
  '--surface': '#1E1E1E',
  '--text-primary': '#E8E8E8',
  '--text-secondary': '#A0A0A0',
  '--text-logo': '#F5F5F5',
  '--border': '#333333',
  '--highlight-bg': '#2D2D2D',
  '--diff-added': '#2ECC71',
  '--diff-added-bg': '#1A3A2A',
  '--diff-removed': '#E74C3C',
  '--diff-removed-bg': '#3A1A1A',
  '--diff-modified': '#F39C12',
  '--diff-modified-bg': '#3A2A1A',
};

const lightThemeVars = {
  '--primary': '#E67E22',
  '--primary-light': '#FFE0B2',
  '--primary-dark': '#D35400',
  '--secondary': '#5D4037',
  '--success': '#27AE60',
  '--error': '#D63031',
  '--rating': '#F1C40F',
  '--hashtag': '#4CAF50',
  '--background': '#F9F9F9',
  '--surface': '#FFFFFF',
  '--text-primary': '#2D3436',
  '--text-secondary': '#636E72',
  '--text-logo': '#494F57',
  '--border': '#DFE6E9',
  '--highlight-bg': '#FFF3E0',
  '--diff-added': '#27AE60',
  '--diff-added-bg': '#E8F5E9',
  '--diff-removed': '#E74C3C',
  '--diff-removed-bg': '#FFEBEE',
  '--diff-modified': '#F39C12',
  '--diff-modified-bg': '#FFF3E0',
};

function applyTheme(theme: ResolvedTheme) {
  const root = document.documentElement;
  const vars = theme === 'dark' ? darkThemeVars : lightThemeVars;

  if (theme === 'dark') {
    root.classList.add('dark');
    root.style.colorScheme = 'dark';
  } else {
    root.classList.remove('dark');
    root.style.colorScheme = 'light';
  }

  Object.entries(vars).forEach(([key, value]) => {
    root.style.setProperty(key, value);
  });
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  // Use lazy initialization to read from localStorage
  const [theme, setThemeState] = useState<Theme>(getStoredTheme);
  const [systemTheme, setSystemTheme] = useState<ResolvedTheme>(getSystemTheme);

  // Derive resolvedTheme from theme and systemTheme
  const resolvedTheme = useMemo<ResolvedTheme>(() => {
    return theme === 'system' ? systemTheme : theme;
  }, [theme, systemTheme]);

  // Apply theme to DOM when resolvedTheme changes
  useEffect(() => {
    applyTheme(resolvedTheme);
  }, [resolvedTheme]);

  // Listen for system preference changes
  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

    const handleChange = (e: MediaQueryListEvent) => {
      setSystemTheme(e.matches ? 'dark' : 'light');
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, []);

  const setTheme = useCallback((newTheme: Theme) => {
    setThemeState(newTheme);
    localStorage.setItem(STORAGE_KEY, newTheme);
  }, []);

  return (
    <ThemeContext.Provider value={{ theme, resolvedTheme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}
