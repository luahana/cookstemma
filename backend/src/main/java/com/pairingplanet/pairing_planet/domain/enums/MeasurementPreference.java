package com.pairingplanet.pairing_planet.domain.enums;

/**
 * User preference for displaying measurement units.
 */
public enum MeasurementPreference {
    /**
     * Show measurements in metric units (ml, g, kg).
     */
    METRIC,

    /**
     * Show measurements in US units (cups, oz, tbsp).
     */
    US,

    /**
     * Show measurements as the recipe author entered them.
     */
    ORIGINAL
}
