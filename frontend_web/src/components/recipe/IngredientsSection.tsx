'use client';

import { useState, useEffect } from 'react';
import type { IngredientDto, IngredientType } from '@/lib/types/recipe';
import type { MeasurementPreference } from '@/lib/types/user';
import {
  convertMeasurement,
  formatMeasurement,
  getMeasurementPreference,
  MEASUREMENT_STORAGE_KEY,
} from '@/lib/utils/measurement';

interface IngredientsSectionProps {
  ingredients: IngredientDto[];
}

const INGREDIENT_TYPE_LABELS: Record<IngredientType, string> = {
  MAIN: 'Main Ingredients',
  SECONDARY: 'Additional Ingredients',
  SEASONING: 'Sauce & Seasoning',
};

const INGREDIENT_TYPE_ORDER: IngredientType[] = ['MAIN', 'SECONDARY', 'SEASONING'];

export function IngredientsSection({ ingredients }: IngredientsSectionProps) {
  const [preference, setPreference] = useState<MeasurementPreference>('ORIGINAL');

  // Debug: log ingredients structure on mount
  useEffect(() => {
    console.log('[IngredientsSection] Ingredients data:', ingredients.map(ing => ({
      name: ing.name,
      quantity: ing.quantity,
      unit: ing.unit,
    })));
  }, [ingredients]);

  useEffect(() => {
    // Get initial preference - use queueMicrotask to avoid synchronous setState warning
    const initialPref = getMeasurementPreference();
    console.log('[IngredientsSection] Initial preference:', initialPref);
    queueMicrotask(() => setPreference(initialPref));

    // Listen for storage changes (when user changes preference in header from another tab)
    const handleStorageChange = (e: StorageEvent) => {
      if (e.key === MEASUREMENT_STORAGE_KEY && e.newValue) {
        if (e.newValue === 'METRIC' || e.newValue === 'US' || e.newValue === 'ORIGINAL') {
          console.log('[IngredientsSection] Storage event - new preference:', e.newValue);
          setPreference(e.newValue);
        }
      }
    };

    // Also listen for custom event (for same-tab updates)
    const handleCustomEvent = (e: CustomEvent<{ preference: MeasurementPreference }>) => {
      console.log('[IngredientsSection] Custom event - new preference:', e.detail.preference);
      setPreference(e.detail.preference);
    };

    window.addEventListener('storage', handleStorageChange);
    window.addEventListener(
      'measurementPreferenceChange',
      handleCustomEvent as EventListener
    );

    return () => {
      window.removeEventListener('storage', handleStorageChange);
      window.removeEventListener(
        'measurementPreferenceChange',
        handleCustomEvent as EventListener
      );
    };
  }, []);

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
      return formatMeasurement(converted);
    }

    return '';
  };

  // Check if any ingredients have structured data
  const hasStructuredData = ingredients.some(ing => ing.quantity !== null && ing.unit !== null);

  return (
    <section className="mb-8">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-bold text-[var(--text-primary)]">
          Ingredients
        </h2>
        {hasStructuredData && preference !== 'ORIGINAL' && (
          <span className="text-xs text-[var(--text-secondary)] bg-[var(--background)] px-2 py-1 rounded">
            Showing in {preference === 'METRIC' ? 'metric' : 'US'} units
          </span>
        )}
      </div>
      <div className="bg-[var(--surface)] border border-[var(--border)] rounded-xl p-6">
        {INGREDIENT_TYPE_ORDER.filter((type) => ingredientsByType[type]?.length > 0).map(
          (type) => (
            <div key={type} className="mb-4 last:mb-0">
              <h3 className="font-medium text-[var(--text-primary)] mb-2">
                {INGREDIENT_TYPE_LABELS[type]}
              </h3>
              <ul className="space-y-2">
                {ingredientsByType[type].map((ing, idx) => {
                  const amount = formatIngredientAmount(ing);
                  return (
                    <li
                      key={idx}
                      className="flex items-center gap-2 text-[var(--text-secondary)]"
                    >
                      <span className="w-2 h-2 bg-[var(--primary)] rounded-full flex-shrink-0" />
                      <span>
                        {amount && (
                          <span className="font-medium text-[var(--text-primary)]">
                            {amount}{' '}
                          </span>
                        )}
                        {ing.name}
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
