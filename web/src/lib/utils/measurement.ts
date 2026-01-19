import type { MeasurementUnit } from '@/lib/types/recipe';
import type { MeasurementPreference } from '@/lib/types/user';

/**
 * Conversion factors to base units (ML for volume, G for weight)
 */
const VOLUME_TO_ML: Record<string, number> = {
  ML: 1,
  L: 1000,
  TSP: 5,
  TBSP: 15,
  CUP: 240,
  FL_OZ: 30,
  PINT: 473,
  QUART: 946,
};

const WEIGHT_TO_G: Record<string, number> = {
  G: 1,
  KG: 1000,
  OZ: 28.35,
  LB: 453.59,
};

/**
 * Units that cannot be converted (count, descriptive)
 */
const NON_CONVERTIBLE_UNITS: MeasurementUnit[] = [
  'PIECE',
  'PINCH',
  'DASH',
  'TO_TASTE',
  'CLOVE',
  'BUNCH',
  'CAN',
  'PACKAGE',
];

/**
 * Mapping from MeasurementUnit enum to i18n translation key
 */
export const UNIT_TRANSLATION_KEYS: Record<MeasurementUnit, string> = {
  ML: 'ml',
  L: 'l',
  TSP: 'tsp',
  TBSP: 'tbsp',
  CUP: 'cup',
  FL_OZ: 'flOz',
  PINT: 'pint',
  QUART: 'quart',
  G: 'g',
  KG: 'kg',
  OZ: 'oz',
  LB: 'lb',
  PIECE: 'piece',
  PINCH: 'pinch',
  DASH: 'dash',
  TO_TASTE: 'toTaste',
  CLOVE: 'clove',
  BUNCH: 'bunch',
  CAN: 'can',
  PACKAGE: 'package',
};

/**
 * Check if unit is a volume unit
 */
function isVolumeUnit(unit: MeasurementUnit): boolean {
  return unit in VOLUME_TO_ML;
}

/**
 * Check if unit is a weight unit
 */
function isWeightUnit(unit: MeasurementUnit): boolean {
  return unit in WEIGHT_TO_G;
}

/**
 * Check if unit is metric
 */
function isMetricUnit(unit: MeasurementUnit): boolean {
  return ['ML', 'L', 'G', 'KG'].includes(unit);
}

/**
 * Check if unit is US/Imperial
 */
function isUSUnit(unit: MeasurementUnit): boolean {
  return ['TSP', 'TBSP', 'CUP', 'FL_OZ', 'PINT', 'QUART', 'OZ', 'LB'].includes(unit);
}

/**
 * Get target unit based on source unit and preference
 */
function getTargetUnit(
  sourceUnit: MeasurementUnit,
  preference: MeasurementPreference
): MeasurementUnit {
  if (preference === 'ORIGINAL') {
    return sourceUnit;
  }

  if (NON_CONVERTIBLE_UNITS.includes(sourceUnit)) {
    return sourceUnit;
  }

  const targetIsMetric = preference === 'METRIC';

  if (isVolumeUnit(sourceUnit)) {
    if (targetIsMetric) {
      // Convert to ML (or L for large amounts, handled in conversion)
      return 'ML';
    } else {
      // Convert to CUP for US
      return 'CUP';
    }
  }

  if (isWeightUnit(sourceUnit)) {
    if (targetIsMetric) {
      // Convert to G (or KG for large amounts, handled in conversion)
      return 'G';
    } else {
      // Convert to OZ for US
      return 'OZ';
    }
  }

  return sourceUnit;
}

/**
 * Round to reasonable precision based on value
 */
function smartRound(value: number): number {
  if (value >= 100) {
    return Math.round(value);
  } else if (value >= 10) {
    return Math.round(value * 10) / 10;
  } else if (value >= 1) {
    return Math.round(value * 100) / 100;
  } else {
    // For very small values, show more precision
    return Math.round(value * 1000) / 1000;
  }
}

/**
 * Convert and potentially upgrade unit for better readability
 * e.g., 1000ml -> 1L, 1000g -> 1kg
 */
function normalizeUnit(
  quantity: number,
  unit: MeasurementUnit
): { quantity: number; unit: MeasurementUnit } {
  // Upgrade ML to L if >= 1000ml
  if (unit === 'ML' && quantity >= 1000) {
    return { quantity: smartRound(quantity / 1000), unit: 'L' };
  }

  // Upgrade G to KG if >= 1000g
  if (unit === 'G' && quantity >= 1000) {
    return { quantity: smartRound(quantity / 1000), unit: 'KG' };
  }

  // Upgrade OZ to LB if >= 16oz
  if (unit === 'OZ' && quantity >= 16) {
    return { quantity: smartRound(quantity / 16), unit: 'LB' };
  }

  // Upgrade CUP to QUART if >= 4 cups
  if (unit === 'CUP' && quantity >= 4) {
    return { quantity: smartRound(quantity / 4), unit: 'QUART' };
  }

  return { quantity: smartRound(quantity), unit };
}

export interface ConversionResult {
  quantity: number;
  unit: MeasurementUnit;
  translationKey: string;
}

/**
 * Convert a measurement to the user's preferred unit system
 */
export function convertMeasurement(
  quantity: number | null,
  unit: MeasurementUnit | null,
  preference: MeasurementPreference
): ConversionResult | null {
  if (quantity === null || unit === null) {
    return null;
  }

  // If original, just return as-is
  if (preference === 'ORIGINAL') {
    return {
      quantity: smartRound(quantity),
      unit,
      translationKey: UNIT_TRANSLATION_KEYS[unit],
    };
  }

  // Non-convertible units stay as-is
  if (NON_CONVERTIBLE_UNITS.includes(unit)) {
    return {
      quantity: smartRound(quantity),
      unit,
      translationKey: UNIT_TRANSLATION_KEYS[unit],
    };
  }

  const targetUnit = getTargetUnit(unit, preference);

  // If already in target unit system, return as-is
  if (unit === targetUnit) {
    const normalized = normalizeUnit(quantity, unit);
    return {
      ...normalized,
      translationKey: UNIT_TRANSLATION_KEYS[normalized.unit],
    };
  }

  let convertedQuantity: number;

  if (isVolumeUnit(unit) && isVolumeUnit(targetUnit)) {
    // Convert through ML as base
    const inML = quantity * VOLUME_TO_ML[unit];
    convertedQuantity = inML / VOLUME_TO_ML[targetUnit];
  } else if (isWeightUnit(unit) && isWeightUnit(targetUnit)) {
    // Convert through G as base
    const inG = quantity * WEIGHT_TO_G[unit];
    convertedQuantity = inG / WEIGHT_TO_G[targetUnit];
  } else {
    // Cannot convert between volume and weight
    return {
      quantity: smartRound(quantity),
      unit,
      translationKey: UNIT_TRANSLATION_KEYS[unit],
    };
  }

  // Normalize to better unit if needed (e.g., 1000ml -> 1L)
  const normalized = normalizeUnit(convertedQuantity, targetUnit);

  return {
    ...normalized,
    translationKey: UNIT_TRANSLATION_KEYS[normalized.unit],
  };
}

/**
 * Format a measurement for display
 * @param result - The conversion result containing quantity, unit, and translationKey
 * @param t - Translator function that takes a translation key and returns the localized string
 */
export function formatMeasurement(
  result: ConversionResult | null,
  t: (key: string) => string
): string {
  if (!result) {
    return '';
  }

  const { quantity, translationKey } = result;
  const label = t(translationKey);

  // Handle "to taste" specially - no quantity
  if (result.unit === 'TO_TASTE') {
    return label;
  }

  // Format quantity - remove trailing zeros
  const formattedQty = quantity % 1 === 0 ? quantity.toString() : quantity.toFixed(2).replace(/\.?0+$/, '');

  return `${formattedQty} ${label}`;
}

/**
 * localStorage key for measurement preference (matches Header.tsx)
 */
export const MEASUREMENT_STORAGE_KEY = 'userMeasurement';

/**
 * Get measurement preference from localStorage
 */
export function getMeasurementPreference(): MeasurementPreference {
  if (typeof window === 'undefined') {
    return 'ORIGINAL';
  }

  const stored = localStorage.getItem(MEASUREMENT_STORAGE_KEY);
  if (stored === 'METRIC' || stored === 'US' || stored === 'ORIGINAL') {
    return stored;
  }

  return 'ORIGINAL';
}

/**
 * Dispatch custom event for measurement preference change (for same-tab updates)
 */
export function dispatchMeasurementChange(preference: MeasurementPreference): void {
  if (typeof window === 'undefined') return;

  console.log('[measurement] Dispatching event with preference:', preference);
  const event = new CustomEvent('measurementPreferenceChange', {
    detail: { preference },
  });
  window.dispatchEvent(event);
  console.log('[measurement] Event dispatched');
}
