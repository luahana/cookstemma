package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.enums.MeasurementPreference;
import com.pairingplanet.pairing_planet.domain.enums.MeasurementUnit;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;

/**
 * Service for converting between measurement units.
 * Only supports same-type conversions (volume ↔ volume, weight ↔ weight).
 * Does NOT support volume ↔ weight conversion (requires ingredient density).
 */
@Service
public class MeasurementConversionService {

    // Volume conversions to ML (base unit)
    private static final Map<MeasurementUnit, Double> VOLUME_TO_ML = Map.of(
            MeasurementUnit.ML, 1.0,
            MeasurementUnit.L, 1000.0,
            MeasurementUnit.TSP, 5.0,
            MeasurementUnit.TBSP, 15.0,
            MeasurementUnit.CUP, 240.0,
            MeasurementUnit.FL_OZ, 30.0,
            MeasurementUnit.PINT, 473.0,
            MeasurementUnit.QUART, 946.0
    );

    // Weight conversions to G (base unit)
    private static final Map<MeasurementUnit, Double> WEIGHT_TO_G = Map.of(
            MeasurementUnit.G, 1.0,
            MeasurementUnit.KG, 1000.0,
            MeasurementUnit.OZ, 28.35,
            MeasurementUnit.LB, 453.59
    );

    /**
     * Convert a quantity from one unit to another.
     * Only same-type conversions are supported.
     *
     * @param quantity The quantity to convert
     * @param fromUnit The source unit
     * @param toUnit The target unit
     * @return The converted quantity, or null if conversion is not possible
     */
    public Double convert(Double quantity, MeasurementUnit fromUnit, MeasurementUnit toUnit) {
        if (quantity == null || fromUnit == null || toUnit == null) {
            return null;
        }

        if (fromUnit == toUnit) {
            return quantity;
        }

        // Volume conversion
        if (fromUnit.isVolume() && toUnit.isVolume()) {
            Double mlValue = quantity * VOLUME_TO_ML.get(fromUnit);
            return round(mlValue / VOLUME_TO_ML.get(toUnit));
        }

        // Weight conversion
        if (fromUnit.isWeight() && toUnit.isWeight()) {
            Double gValue = quantity * WEIGHT_TO_G.get(fromUnit);
            return round(gValue / WEIGHT_TO_G.get(toUnit));
        }

        // Cannot convert between different types (volume ↔ weight)
        return null;
    }

    /**
     * Get the target unit for a given unit and preference.
     * Returns the appropriate metric or US unit based on preference.
     *
     * @param sourceUnit The original unit
     * @param preference The user's measurement preference
     * @return The target unit to convert to, or the source unit if no conversion needed
     */
    public MeasurementUnit getTargetUnit(MeasurementUnit sourceUnit, MeasurementPreference preference) {
        if (sourceUnit == null || preference == null || preference == MeasurementPreference.ORIGINAL) {
            return sourceUnit;
        }

        if (sourceUnit.isCountOrOther()) {
            return sourceUnit; // No conversion for count/other units
        }

        if (preference == MeasurementPreference.METRIC) {
            return getMetricEquivalent(sourceUnit);
        } else if (preference == MeasurementPreference.US) {
            return getUSEquivalent(sourceUnit);
        }

        return sourceUnit;
    }

    /**
     * Convert quantity and unit based on user preference.
     *
     * @param quantity The original quantity
     * @param unit The original unit
     * @param preference The user's measurement preference
     * @return A ConversionResult with the converted quantity and unit
     */
    public ConversionResult convertForPreference(Double quantity, MeasurementUnit unit, MeasurementPreference preference) {
        if (quantity == null || unit == null || preference == MeasurementPreference.ORIGINAL) {
            return new ConversionResult(quantity, unit);
        }

        MeasurementUnit targetUnit = getTargetUnit(unit, preference);
        if (targetUnit == unit) {
            return new ConversionResult(quantity, unit);
        }

        Double convertedQuantity = convert(quantity, unit, targetUnit);
        return new ConversionResult(convertedQuantity, targetUnit);
    }

    private MeasurementUnit getMetricEquivalent(MeasurementUnit unit) {
        if (unit.isVolume()) {
            return MeasurementUnit.ML; // Default to ML for volume
        } else if (unit.isWeight()) {
            return MeasurementUnit.G; // Default to G for weight
        }
        return unit;
    }

    private MeasurementUnit getUSEquivalent(MeasurementUnit unit) {
        if (unit.isVolume()) {
            // For metric volume, convert to cups (most common US volume)
            if (unit == MeasurementUnit.ML || unit == MeasurementUnit.L) {
                return MeasurementUnit.CUP;
            }
            return unit; // Already US unit
        } else if (unit.isWeight()) {
            // For metric weight, convert to oz
            if (unit == MeasurementUnit.G || unit == MeasurementUnit.KG) {
                return MeasurementUnit.OZ;
            }
            return unit; // Already US unit
        }
        return unit;
    }

    private Double round(Double value) {
        if (value == null) {
            return null;
        }
        return BigDecimal.valueOf(value)
                .setScale(2, RoundingMode.HALF_UP)
                .doubleValue();
    }

    /**
     * Result of a unit conversion.
     */
    public record ConversionResult(Double quantity, MeasurementUnit unit) {
        public boolean isConverted() {
            return quantity != null && unit != null;
        }
    }
}
