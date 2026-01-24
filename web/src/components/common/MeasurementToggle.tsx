'use client';

import { useTranslations } from 'next-intl';
import type { MeasurementPreference } from '@/lib/types/user';

const MEASUREMENT_OPTIONS: { value: MeasurementPreference; labelKey: string }[] = [
  { value: 'ORIGINAL', labelKey: 'original' },
  { value: 'METRIC', labelKey: 'metric' },
  { value: 'US', labelKey: 'us' },
];

interface MeasurementToggleProps {
  value: MeasurementPreference;
  onChange: (value: MeasurementPreference) => void;
  className?: string;
}

export function MeasurementToggle({ value, onChange, className = '' }: MeasurementToggleProps) {
  const t = useTranslations('measurement');

  return (
    <div
      className={`inline-flex rounded-lg bg-[var(--surface)] p-1 border border-[var(--border)] ${className}`}
      role="radiogroup"
      aria-label={t('units')}
    >
      {MEASUREMENT_OPTIONS.map((option) => {
        const isSelected = value === option.value;
        return (
          <button
            key={option.value}
            type="button"
            role="radio"
            aria-checked={isSelected}
            onClick={() => onChange(option.value)}
            className={`
              px-2 py-1 text-xs sm:px-3 sm:py-1.5 sm:text-sm
              rounded-md font-medium transition-colors
              focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] focus-visible:ring-offset-1
              ${isSelected
                ? 'bg-[var(--primary)] text-white'
                : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--background)]'
              }
            `}
          >
            {t(option.labelKey)}
          </button>
        );
      })}
    </div>
  );
}
