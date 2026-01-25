package com.cookstemma.cookstemma.domain.enums;

/**
 * Cooking time ranges for recipes.
 * Uses approximate ranges since cooking time varies by skill level.
 */
public enum CookingTimeRange {
    UNDER_15_MIN,    // Quick snacks, salads
    MIN_15_TO_30,    // Fast weeknight meals
    MIN_30_TO_60,    // Standard home cooking (default)
    HOUR_1_TO_2,     // Elaborate dishes
    OVER_2_HOURS     // Slow roasts, fermented dishes
}
