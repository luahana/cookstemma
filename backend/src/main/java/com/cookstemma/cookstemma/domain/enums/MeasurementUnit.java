package com.cookstemma.cookstemma.domain.enums;

/**
 * Measurement units for recipe ingredients.
 * Grouped by type (volume/weight/count) for conversion logic.
 */
public enum MeasurementUnit {
    // Volume - Metric
    ML,
    L,

    // Volume - US
    TSP,
    TBSP,
    CUP,
    FL_OZ,
    PINT,
    QUART,

    // Weight - Metric
    G,
    KG,

    // Weight - Imperial
    OZ,
    LB,

    // Count/Other (no conversion)
    PIECE,
    PINCH,
    DASH,
    TO_TASTE,
    CLOVE,
    BUNCH,
    CAN,
    PACKAGE;

    /**
     * Check if this unit is a volume measurement.
     */
    public boolean isVolume() {
        return this == ML || this == L || this == TSP || this == TBSP ||
               this == CUP || this == FL_OZ || this == PINT || this == QUART;
    }

    /**
     * Check if this unit is a weight measurement.
     */
    public boolean isWeight() {
        return this == G || this == KG || this == OZ || this == LB;
    }

    /**
     * Check if this unit is metric.
     */
    public boolean isMetric() {
        return this == ML || this == L || this == G || this == KG;
    }

    /**
     * Check if this unit is US/Imperial.
     */
    public boolean isImperial() {
        return this == TSP || this == TBSP || this == CUP || this == FL_OZ ||
               this == PINT || this == QUART || this == OZ || this == LB;
    }

    /**
     * Check if this unit is countable/uncountable (no conversion possible).
     */
    public boolean isCountOrOther() {
        return !isVolume() && !isWeight();
    }
}
