'use client';

import { useState, useRef, useEffect, useMemo } from 'react';
import Image from 'next/image';
import { useTranslations } from 'next-intl';

export interface CookingStyleOption {
  value: string;
  label: string;
}

// List of all cooking style country codes
export const COOKING_STYLE_CODES = [
  'international',
  'AF', 'AL', 'DZ', 'AD', 'AO', 'AG', 'AR', 'AM', 'AU', 'AT', 'AZ',
  'BS', 'BH', 'BD', 'BB', 'BY', 'BE', 'BZ', 'BJ', 'BT', 'BO', 'BA', 'BW', 'BR', 'BN', 'BG', 'BF', 'BI',
  'CV', 'KH', 'CM', 'CA', 'CF', 'TD', 'CL', 'CN', 'CO', 'KM', 'CG', 'CR', 'HR', 'CU', 'CY', 'CZ',
  'DK', 'DJ', 'DM', 'DO',
  'EC', 'EG', 'SV', 'GQ', 'ER', 'EE', 'SZ', 'ET',
  'FJ', 'FI', 'FR',
  'GA', 'GM', 'GE', 'DE', 'GH', 'GR', 'GD', 'GT', 'GN', 'GW', 'GY',
  'HT', 'HN', 'HU',
  'IS', 'IN', 'ID', 'IR', 'IQ', 'IE', 'IL', 'IT', 'CI',
  'JM', 'JP', 'JO',
  'KZ', 'KE', 'KI', 'KW', 'KG',
  'LA', 'LV', 'LB', 'LS', 'LR', 'LY', 'LI', 'LT', 'LU',
  'MG', 'MW', 'MY', 'MV', 'ML', 'MT', 'MH', 'MR', 'MU', 'MX', 'FM', 'MD', 'MC', 'MN', 'ME', 'MA', 'MZ', 'MM',
  'NA', 'NR', 'NP', 'NL', 'NZ', 'NI', 'NE', 'NG', 'KP', 'MK', 'NO',
  'OM',
  'PK', 'PW', 'PS', 'PA', 'PG', 'PY', 'PE', 'PH', 'PL', 'PT',
  'QA',
  'RO', 'RU', 'RW',
  'KN', 'LC', 'VC', 'WS', 'SM', 'ST', 'SA', 'SN', 'RS', 'SC', 'SL', 'SG', 'SK', 'SI', 'SB', 'SO', 'ZA', 'KR', 'SS', 'ES', 'LK', 'SD', 'SR', 'SE', 'CH', 'SY',
  'TW', 'TJ', 'TZ', 'TH', 'TL', 'TG', 'TO', 'TT', 'TN', 'TR', 'TM', 'TV',
  'UG', 'UA', 'AE', 'GB', 'US', 'UY', 'UZ',
  'VU', 'VA', 'VE', 'VN',
  'YE',
  'ZM', 'ZW',
] as const;

export type CookingStyleCode = typeof COOKING_STYLE_CODES[number];

/**
 * Hook to get translated cooking style options
 */
export function useCookingStyleOptions(): CookingStyleOption[] {
  const t = useTranslations('cookingStyles');

  return useMemo(() =>
    COOKING_STYLE_CODES.map((code) => ({
      value: code,
      label: t(code),
    })),
    [t]
  );
}

/**
 * Hook to get translated cooking style filter options (includes "All Styles")
 */
export function useCookingStyleFilterOptions(): CookingStyleOption[] {
  const t = useTranslations('cookingStyles');

  return useMemo(() => [
    { value: 'any', label: t('allStyles') },
    ...COOKING_STYLE_CODES.map((code) => ({
      value: code,
      label: t(code),
    })),
  ], [t]);
}

interface CookingStyleSelectProps {
  value: string;
  onChange: (value: string) => void;
  options: CookingStyleOption[];
  placeholder?: string;
  className?: string;
}

function getFlagUrl(code: string): string {
  if (code === 'any' || code === 'international') {
    return 'https://flagcdn.com/w40/un.png';
  }
  return `https://flagcdn.com/w40/${code.toLowerCase()}.png`;
}

export function CookingStyleSelect({
  value,
  onChange,
  options,
  placeholder = 'Select...',
  className = '',
}: CookingStyleSelectProps) {
  const t = useTranslations('common');
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const containerRef = useRef<HTMLDivElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  const selectedOption = options.find((opt) => opt.value === value);

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
        setSearch('');
      }
    }

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Focus search input when dropdown opens
  useEffect(() => {
    if (isOpen && searchInputRef.current) {
      searchInputRef.current.focus();
    }
  }, [isOpen]);

  const filteredOptions = search
    ? options.filter((opt) =>
        opt.label.toLowerCase().includes(search.toLowerCase())
      )
    : options;

  const handleSelect = (optionValue: string) => {
    onChange(optionValue);
    setIsOpen(false);
    setSearch('');
  };

  return (
    <div ref={containerRef} className={`relative ${className}`}>
      {/* Selected value button */}
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg focus:outline-none focus:border-[var(--primary)] flex items-center justify-between gap-2 text-sm"
      >
        <span className="flex items-center gap-2 min-w-0">
          {selectedOption && (
            <>
              <Image
                src={getFlagUrl(selectedOption.value)}
                alt=""
                width={20}
                height={15}
                className="rounded-sm flex-shrink-0"
                unoptimized
              />
              <span className="truncate">{selectedOption.label}</span>
            </>
          )}
          {!selectedOption && (
            <span className="text-[var(--text-secondary)]">{placeholder}</span>
          )}
        </span>
        <svg
          className={`w-4 h-4 text-[var(--text-secondary)] transition-transform flex-shrink-0 ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {/* Dropdown */}
      {isOpen && (
        <div className="absolute z-50 mt-1 w-full bg-[var(--surface)] border border-[var(--border)] rounded-lg shadow-lg overflow-hidden">
          {/* Search input */}
          <div className="p-2 border-b border-[var(--border)]">
            <input
              ref={searchInputRef}
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={t('searchPlaceholder')}
              className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-md text-sm focus:outline-none focus:border-[var(--primary)]"
            />
          </div>

          {/* Options list */}
          <div className="max-h-60 overflow-y-auto">
            {filteredOptions.length === 0 ? (
              <div className="px-3 py-2 text-sm text-[var(--text-secondary)]">
                {t('noResults')}
              </div>
            ) : (
              filteredOptions.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => handleSelect(option.value)}
                  className={`w-full px-3 py-2 flex items-center gap-2 text-sm hover:bg-[var(--highlight-bg)] transition-colors text-left ${
                    option.value === value ? 'bg-[var(--primary-light)]/20' : ''
                  }`}
                >
                  <Image
                    src={getFlagUrl(option.value)}
                    alt=""
                    width={20}
                    height={15}
                    className="rounded-sm flex-shrink-0"
                    unoptimized
                  />
                  <span className="truncate">{option.label}</span>
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}

