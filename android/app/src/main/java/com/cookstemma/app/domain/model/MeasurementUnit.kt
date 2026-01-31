package com.cookstemma.app.domain.model

import com.cookstemma.app.R
import java.text.DecimalFormat
import kotlin.math.truncate

/**
 * User's preferred measurement system for displaying recipe ingredients.
 */
enum class MeasurementPreference(val displayNameRes: Int, val descriptionRes: Int) {
    ORIGINAL(R.string.units_original, R.string.units_original_description),
    METRIC(R.string.units_metric, R.string.units_metric_description),
    US(R.string.units_us, R.string.units_us_description)
}

/**
 * Measurement units for recipe ingredients.
 */
enum class MeasurementUnit(val code: String) {
    // Volume - Metric
    ML("ML"),
    LITER("L"),

    // Volume - US
    TSP("TSP"),
    TBSP("TBSP"),
    CUP("CUP"),
    FL_OZ("FL_OZ"),
    PINT("PINT"),
    QUART("QUART"),

    // Weight - Metric
    GRAM("G"),
    KG("KG"),

    // Weight - US
    OZ("OZ"),
    LB("LB"),

    // Non-convertible
    PIECE("PIECE"),
    PINCH("PINCH"),
    DASH("DASH"),
    TO_TASTE("TO_TASTE"),
    CLOVE("CLOVE"),
    BUNCH("BUNCH"),
    CAN("CAN"),
    PACKAGE("PACKAGE");

    val displayName: String
        get() = when (this) {
            ML -> "ml"
            LITER -> "L"
            TSP -> "tsp"
            TBSP -> "tbsp"
            CUP -> "cup"
            FL_OZ -> "fl oz"
            PINT -> "pt"
            QUART -> "qt"
            GRAM -> "g"
            KG -> "kg"
            OZ -> "oz"
            LB -> "lb"
            PIECE -> "piece"
            PINCH -> "pinch"
            DASH -> "dash"
            TO_TASTE -> "to taste"
            CLOVE -> "clove"
            BUNCH -> "bunch"
            CAN -> "can"
            PACKAGE -> "pkg"
        }

    val isVolumeUnit: Boolean
        get() = this in listOf(ML, LITER, TSP, TBSP, CUP, FL_OZ, PINT, QUART)

    val isWeightUnit: Boolean
        get() = this in listOf(GRAM, KG, OZ, LB)

    val isConvertible: Boolean
        get() = this !in listOf(PIECE, PINCH, DASH, TO_TASTE, CLOVE, BUNCH, CAN, PACKAGE)

    val isMetric: Boolean
        get() = this in listOf(ML, LITER, GRAM, KG)

    val isUS: Boolean
        get() = this in listOf(TSP, TBSP, CUP, FL_OZ, PINT, QUART, OZ, LB)

    companion object {
        fun fromCode(code: String?): MeasurementUnit? =
            entries.find { it.code == code }
    }
}

/**
 * Result of a measurement conversion.
 */
data class ConversionResult(
    val quantity: Double,
    val unit: MeasurementUnit,
    val displayString: String
)

/**
 * Converts measurements between unit systems (Original, Metric, US).
 */
object MeasurementConverter {
    // Conversion factors to base units (ML for volume, G for weight)
    private val volumeToML = mapOf(
        MeasurementUnit.ML to 1.0,
        MeasurementUnit.LITER to 1000.0,
        MeasurementUnit.TSP to 5.0,
        MeasurementUnit.TBSP to 15.0,
        MeasurementUnit.CUP to 240.0,
        MeasurementUnit.FL_OZ to 30.0,
        MeasurementUnit.PINT to 473.0,
        MeasurementUnit.QUART to 946.0
    )

    private val weightToG = mapOf(
        MeasurementUnit.GRAM to 1.0,
        MeasurementUnit.KG to 1000.0,
        MeasurementUnit.OZ to 28.35,
        MeasurementUnit.LB to 453.59
    )

    /**
     * Convert a measurement to the user's preferred unit system.
     */
    fun convert(
        quantity: Double?,
        unitString: String?,
        preference: MeasurementPreference
    ): ConversionResult? {
        if (quantity == null || unitString == null) return null

        val unit = MeasurementUnit.fromCode(unitString) ?: MeasurementUnit.PIECE

        // If original, just return as-is
        if (preference == MeasurementPreference.ORIGINAL) {
            return ConversionResult(
                quantity = smartRound(quantity),
                unit = unit,
                displayString = formatQuantity(smartRound(quantity), unit)
            )
        }

        // Non-convertible units stay as-is
        if (!unit.isConvertible) {
            return ConversionResult(
                quantity = smartRound(quantity),
                unit = unit,
                displayString = formatQuantity(smartRound(quantity), unit)
            )
        }

        val targetUnit = getTargetUnit(unit, preference)

        // If already in target unit system, return normalized
        if (unit == targetUnit) {
            val (normalizedQty, normalizedUnit) = normalizeUnit(quantity, unit)
            return ConversionResult(
                quantity = normalizedQty,
                unit = normalizedUnit,
                displayString = formatQuantity(normalizedQty, normalizedUnit)
            )
        }

        // Perform conversion
        val convertedQuantity: Double = when {
            unit.isVolumeUnit && targetUnit.isVolumeUnit -> {
                // Convert through ML as base
                val inML = quantity * (volumeToML[unit] ?: 1.0)
                inML / (volumeToML[targetUnit] ?: 1.0)
            }
            unit.isWeightUnit && targetUnit.isWeightUnit -> {
                // Convert through G as base
                val inG = quantity * (weightToG[unit] ?: 1.0)
                inG / (weightToG[targetUnit] ?: 1.0)
            }
            else -> {
                // Cannot convert between volume and weight
                return ConversionResult(
                    quantity = smartRound(quantity),
                    unit = unit,
                    displayString = formatQuantity(smartRound(quantity), unit)
                )
            }
        }

        // Normalize to better unit if needed (e.g., 1000ml -> 1L)
        val (normalizedQty, normalizedUnit) = normalizeUnit(convertedQuantity, targetUnit)

        return ConversionResult(
            quantity = normalizedQty,
            unit = normalizedUnit,
            displayString = formatQuantity(normalizedQty, normalizedUnit)
        )
    }

    private fun getTargetUnit(
        sourceUnit: MeasurementUnit,
        preference: MeasurementPreference
    ): MeasurementUnit {
        if (preference == MeasurementPreference.ORIGINAL) {
            return sourceUnit
        }

        if (!sourceUnit.isConvertible) {
            return sourceUnit
        }

        val targetIsMetric = preference == MeasurementPreference.METRIC

        return when {
            sourceUnit.isVolumeUnit -> if (targetIsMetric) MeasurementUnit.ML else MeasurementUnit.CUP
            sourceUnit.isWeightUnit -> if (targetIsMetric) MeasurementUnit.GRAM else MeasurementUnit.OZ
            else -> sourceUnit
        }
    }

    /**
     * Round to reasonable precision based on value.
     */
    private fun smartRound(value: Double): Double {
        return when {
            value >= 100 -> value.roundToDecimal(0)
            value >= 10 -> value.roundToDecimal(1)
            value >= 1 -> value.roundToDecimal(2)
            else -> value.roundToDecimal(3) // For very small values, show more precision
        }
    }

    private fun Double.roundToDecimal(decimals: Int): Double {
        var multiplier = 1.0
        repeat(decimals) { multiplier *= 10 }
        return kotlin.math.round(this * multiplier) / multiplier
    }

    /**
     * Convert and potentially upgrade unit for better readability.
     * e.g., 1000ml -> 1L, 1000g -> 1kg
     */
    private fun normalizeUnit(
        quantity: Double,
        unit: MeasurementUnit
    ): Pair<Double, MeasurementUnit> {
        // Upgrade ML to L if >= 1000ml
        if (unit == MeasurementUnit.ML && quantity >= 1000) {
            return smartRound(quantity / 1000) to MeasurementUnit.LITER
        }

        // Upgrade G to KG if >= 1000g
        if (unit == MeasurementUnit.GRAM && quantity >= 1000) {
            return smartRound(quantity / 1000) to MeasurementUnit.KG
        }

        // Upgrade OZ to LB if >= 16oz
        if (unit == MeasurementUnit.OZ && quantity >= 16) {
            return smartRound(quantity / 16) to MeasurementUnit.LB
        }

        // Upgrade CUP to QUART if >= 4 cups
        if (unit == MeasurementUnit.CUP && quantity >= 4) {
            return smartRound(quantity / 4) to MeasurementUnit.QUART
        }

        return smartRound(quantity) to unit
    }

    private fun formatQuantity(quantity: Double, unit: MeasurementUnit): String {
        // Handle "to taste" specially - no quantity
        if (unit == MeasurementUnit.TO_TASTE) {
            return unit.displayName
        }

        // Format quantity - remove trailing zeros
        val formattedQty = when {
            quantity == truncate(quantity) -> quantity.toLong().toString()
            quantity < 1 -> {
                DecimalFormat("0.##").format(quantity)
            }
            else -> {
                DecimalFormat("0.#").format(quantity)
            }
        }

        return "$formattedQty ${unit.displayName}"
    }
}
