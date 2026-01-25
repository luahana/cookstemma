'use client';

import { useState, useEffect } from 'react';
import { useTranslations } from 'next-intl';
import type { IngredientDto, IngredientType } from '@/lib/types/recipe';
import type { MeasurementPreference } from '@/lib/types/user';
import {
  convertMeasurement,
  formatMeasurement,
  getMeasurementPreference,
} from '@/lib/utils/measurement';
import { MeasurementToggle } from '@/components/common/MeasurementToggle';

// Languages where ingredient name comes BEFORE quantity (e.g., "쌀 400g" not "400g 쌀")
// Based on natural language patterns in recipes
const NAME_FIRST_LOCALES = ['ko', 'ja', 'zh', 'vi', 'th'];

function isNameFirstLocale(locale: string): boolean {
  // Extract language code (e.g., 'ko' from 'ko-KR')
  const lang = locale.split('-')[0].toLowerCase();
  return NAME_FIRST_LOCALES.includes(lang);
}

interface IngredientsSectionProps {
  ingredients: IngredientDto[];
  locale: string;
}

const INGREDIENT_CATEGORIES: {
  type: IngredientType;
  labelKey: 'categoryMain' | 'categorySecondary' | 'categorySeasoning';
  icon: string;
  color: string;
  bgColor: string;
  borderColor: string;
  bulletColor: string;
}[] = [
  {
    type: 'MAIN',
    labelKey: 'categoryMain',
    icon: '🍲',
    color: 'var(--primary)',
    bgColor: 'var(--primary-light)',
    borderColor: 'var(--primary)',
    bulletColor: 'var(--primary)',
  },
  {
    type: 'SECONDARY',
    labelKey: 'categorySecondary',
    icon: '🥕',
    color: 'var(--success)',
    bgColor: '#E8F5E9',
    borderColor: 'var(--success)',
    bulletColor: 'var(--success)',
  },
  {
    type: 'SEASONING',
    labelKey: 'categorySeasoning',
    icon: '🧂',
    color: 'var(--secondary)',
    bgColor: '#EFEBE9',
    borderColor: 'var(--secondary)',
    bulletColor: 'var(--secondary)',
  },
];

export function IngredientsSection({ ingredients, locale }: IngredientsSectionProps) {
  const t = useTranslations('recipes');
  const tIngredients = useTranslations('ingredients');
  const tUnits = useTranslations('units');
  const [preference, setPreference] = useState<MeasurementPreference>('ORIGINAL');

  // Initialize preference from user's saved setting (default for this page view only)
  useEffect(() => {
    const initialPref = getMeasurementPreference();
    queueMicrotask(() => setPreference(initialPref));
  }, []);

  // Handle toggle change - local state only (no persistence)
  const handleToggleChange = (newPreference: MeasurementPreference) => {
    setPreference(newPreference);
  };

  // Group ingredients by type
  const ingredientsByType = ingredients.reduce(
    (acc, ing) => {
      const type = ing.type || 'MAIN';
      if (!acc[type]) acc[type] = [];
      acc[type].push(ing);
      return acc;
    },
    {} as Record<IngredientType, IngredientDto[]>
  );

  // Format ingredient amount for display
  const formatIngredientAmount = (ing: IngredientDto): string => {
    // If we have structured quantity + unit, use conversion
    if (ing.quantity !== null && ing.unit !== null) {
      const converted = convertMeasurement(ing.quantity, ing.unit, preference);
      return formatMeasurement(converted, tUnits);
    }

    return '';
  };

  // Check if any ingredients have structured data
  const hasStructuredData = ingredients.some(ing => ing.quantity !== null && ing.unit !== null);

  return (
    <section className="mb-8">
      <div className="flex items-center justify-between mb-4 gap-4">
        <h2 className="text-2xl font-bold text-[var(--text-primary)]">
          {t('ingredients')}
        </h2>
        {hasStructuredData && (
          <MeasurementToggle
            value={preference}
            onChange={handleToggleChange}
          />
        )}
      </div>
      <div className="space-y-4">
        {INGREDIENT_CATEGORIES.filter((cat) => ingredientsByType[cat.type]?.length > 0).map(
          (category) => (
            <div
              key={category.type}
              className="rounded-xl p-4 border-2"
              style={{
                borderColor: category.borderColor,
                backgroundColor: `color-mix(in srgb, ${category.bgColor} 30%, transparent)`,
              }}
            >
              <div className="flex items-center gap-2 mb-3">
                <span className="text-lg">{category.icon}</span>
                <h3
                  className="font-semibold"
                  style={{ color: category.color }}
                >
                  {tIngredients(category.labelKey)}
                </h3>
                <span
                  className="text-xs font-medium px-2 py-0.5 rounded-full ml-auto"
                  style={{ backgroundColor: category.bgColor, color: category.color }}
                >
                  {ingredientsByType[category.type].length}
                </span>
              </div>
              <ul className="space-y-2">
                {ingredientsByType[category.type].map((ing, idx) => {
                  const amount = formatIngredientAmount(ing);
                  // Ingredient name is pre-localized by the backend based on Accept-Language header
                  const name = ing.name;
                  const nameFirst = isNameFirstLocale(locale);

                  return (
                    <li
                      key={idx}
                      className="flex items-center gap-2 text-[var(--text-secondary)]"
                    >
                      <span
                        className="w-2 h-2 rounded-full flex-shrink-0"
                        style={{ backgroundColor: category.bulletColor }}
                      />
                      <span>
                        {nameFirst ? (
                          // Name first: "쌀 400g" (Korean, Japanese, Chinese, Vietnamese, Thai)
                          <>
                            {name}
                            {amount && (
                              <span className="font-medium text-[var(--text-primary)]">
                                {' '}{amount}
                              </span>
                            )}
                          </>
                        ) : (
                          // Quantity first: "400g rice" (English, European languages, etc.)
                          <>
                            {amount && (
                              <span className="font-medium text-[var(--text-primary)]">
                                {amount}{' '}
                              </span>
                            )}
                            {name}
                          </>
                        )}
                      </span>
                    </li>
                  );
                })}
              </ul>
            </div>
          )
        )}
      </div>
    </section>
  );
}
