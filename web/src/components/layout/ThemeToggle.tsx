'use client';

import { useTheme, type Theme } from '@/contexts/ThemeContext';
import { useTranslations } from 'next-intl';
import { useState, useRef, useEffect } from 'react';

const THEME_OPTIONS: { value: Theme; labelKey: string }[] = [
  { value: 'light', labelKey: 'lightMode' },
  { value: 'dark', labelKey: 'darkMode' },
  { value: 'system', labelKey: 'systemMode' },
];

interface ThemeToggleProps {
  onMenuToggle?: (isOpen: boolean) => void;
}

export function ThemeToggle({ onMenuToggle }: ThemeToggleProps) {
  const { theme, setTheme } = useTheme();
  const t = useTranslations('nav');
  const [isOpen, setIsOpen] = useState(false);
  const [mounted, setMounted] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  // Prevent hydration mismatch by only rendering theme-specific content after mount
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- Intentional: one-time mount flag for SSR hydration
    setMounted(true);
  }, []);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleToggle = () => {
    const newState = !isOpen;
    setIsOpen(newState);
    onMenuToggle?.(newState);
  };

  const handleSelect = (newTheme: Theme) => {
    setTheme(newTheme);
    setIsOpen(false);
    onMenuToggle?.(false);
  };

  return (
    <div className="relative" ref={menuRef}>
      <button
        onClick={handleToggle}
        className="p-2 rounded-lg hover:bg-[var(--background)] transition-colors text-[var(--text-secondary)]"
        title={t('theme')}
        aria-expanded={isOpen}
        aria-haspopup="true"
      >
        {!mounted ? (
          <SystemIcon className="w-5 h-5" />
        ) : theme === 'dark' ? (
          <MoonIcon className="w-5 h-5" />
        ) : theme === 'light' ? (
          <SunIcon className="w-5 h-5" />
        ) : (
          <SystemIcon className="w-5 h-5" />
        )}
      </button>

      {isOpen && (
        <div className="absolute end-0 mt-2 w-28 bg-[var(--surface)] border border-[var(--border)] rounded-xl shadow-lg py-1 z-50">
          {THEME_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              onClick={() => handleSelect(opt.value)}
              className={`w-full text-start px-3 py-2 text-sm hover:bg-[var(--background)] flex items-center gap-2 ${
                opt.value === theme
                  ? 'bg-[var(--primary-light)] text-[var(--primary)]'
                  : 'text-[var(--text-primary)]'
              }`}
            >
              {opt.value === 'light' && <SunIcon className="w-4 h-4" />}
              {opt.value === 'dark' && <MoonIcon className="w-4 h-4" />}
              {opt.value === 'system' && <SystemIcon className="w-4 h-4" />}
              {t(opt.labelKey)}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function SunIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
      />
    </svg>
  );
}

function MoonIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
      />
    </svg>
  );
}

function SystemIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
      />
    </svg>
  );
}
