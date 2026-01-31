package com.cookstemma.app.domain.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class MeasurementConverterTest {

    @Test
    fun `convert returns null when quantity is null`() {
        val result = MeasurementConverter.convert(null, "ML", MeasurementPreference.METRIC)
        assertNull(result)
    }

    @Test
    fun `convert returns null when unitString is null`() {
        val result = MeasurementConverter.convert(100.0, null, MeasurementPreference.METRIC)
        assertNull(result)
    }

    @Test
    fun `convert returns original value when preference is ORIGINAL`() {
        val result = MeasurementConverter.convert(250.0, "ML", MeasurementPreference.ORIGINAL)

        assertNotNull(result)
        assertEquals(250.0, result!!.quantity, 0.01)
        assertEquals(MeasurementUnit.ML, result.unit)
        assertEquals("250 ml", result.displayString)
    }

    @Test
    fun `convert non-convertible unit returns original regardless of preference`() {
        val result = MeasurementConverter.convert(2.0, "PIECE", MeasurementPreference.METRIC)

        assertNotNull(result)
        assertEquals(2.0, result!!.quantity, 0.01)
        assertEquals(MeasurementUnit.PIECE, result.unit)
        assertEquals("2 piece", result.displayString)
    }

    @Test
    fun `convert ML to US returns cups`() {
        // 240 ml = 1 cup
        val result = MeasurementConverter.convert(240.0, "ML", MeasurementPreference.US)

        assertNotNull(result)
        assertEquals(1.0, result!!.quantity, 0.01)
        assertEquals(MeasurementUnit.CUP, result.unit)
        assertEquals("1 cup", result.displayString)
    }

    @Test
    fun `convert cups to metric returns ml`() {
        // 1 cup = 240 ml
        val result = MeasurementConverter.convert(1.0, "CUP", MeasurementPreference.METRIC)

        assertNotNull(result)
        assertEquals(240.0, result!!.quantity, 0.01)
        assertEquals(MeasurementUnit.ML, result.unit)
        assertEquals("240 ml", result.displayString)
    }

    @Test
    fun `convert grams to US returns oz`() {
        // 28.35g = 1 oz
        val result = MeasurementConverter.convert(28.35, "G", MeasurementPreference.US)

        assertNotNull(result)
        assertEquals(1.0, result!!.quantity, 0.01)
        assertEquals(MeasurementUnit.OZ, result.unit)
    }

    @Test
    fun `convert oz to metric returns grams`() {
        // 1 oz = 28.35g
        val result = MeasurementConverter.convert(1.0, "OZ", MeasurementPreference.METRIC)

        assertNotNull(result)
        assertEquals(28.35, result!!.quantity, 0.1)
        assertEquals(MeasurementUnit.GRAM, result.unit)
    }

    @Test
    fun `normalizes ml to liters when at least 1000`() {
        val result = MeasurementConverter.convert(4.0, "CUP", MeasurementPreference.METRIC)

        assertNotNull(result)
        // 4 cups = 960ml, not quite 1L
        assertEquals(MeasurementUnit.ML, result!!.unit)

        // 5 cups = 1200ml -> should normalize to L
        val result2 = MeasurementConverter.convert(5.0, "CUP", MeasurementPreference.METRIC)
        assertNotNull(result2)
        assertEquals(MeasurementUnit.LITER, result2!!.unit)
        assertEquals(1.2, result2.quantity, 0.01)
    }

    @Test
    fun `normalizes grams to kg when at least 1000`() {
        // 36 oz = 1020.6g -> normalizes to ~1.02 kg
        val result = MeasurementConverter.convert(36.0, "OZ", MeasurementPreference.METRIC)

        assertNotNull(result)
        assertEquals(MeasurementUnit.KG, result!!.unit)
        assertEquals(1.0, result.quantity, 0.1)
    }

    @Test
    fun `normalizes oz to lb when at least 16`() {
        // 500g = 17.64 oz -> normalizes to ~1.1 lb
        val result = MeasurementConverter.convert(500.0, "G", MeasurementPreference.US)

        assertNotNull(result)
        assertEquals(MeasurementUnit.LB, result!!.unit)
        assertEquals(1.1, result.quantity, 0.1)
    }

    @Test
    fun `normalizes cups to quarts when at least 4`() {
        val result = MeasurementConverter.convert(960.0, "ML", MeasurementPreference.US)

        assertNotNull(result)
        // 960ml = 4 cups = 1 quart
        assertEquals(MeasurementUnit.QUART, result!!.unit)
        assertEquals(1.0, result.quantity, 0.01)
    }

    @Test
    fun `formatQuantity handles TO_TASTE unit`() {
        val result = MeasurementConverter.convert(1.0, "TO_TASTE", MeasurementPreference.ORIGINAL)

        assertNotNull(result)
        assertEquals("to taste", result!!.displayString)
    }

    @Test
    fun `formatQuantity removes trailing zeros`() {
        val result = MeasurementConverter.convert(2.0, "CUP", MeasurementPreference.ORIGINAL)

        assertNotNull(result)
        assertEquals("2 cup", result!!.displayString)
    }

    @Test
    fun `smartRound rounds appropriately based on value size`() {
        // Large values round to whole numbers
        val large = MeasurementConverter.convert(125.0, "ML", MeasurementPreference.ORIGINAL)
        assertEquals(125.0, large!!.quantity, 0.01)

        // Medium values round to 1 decimal
        val medium = MeasurementConverter.convert(12.5, "ML", MeasurementPreference.ORIGINAL)
        assertEquals(12.5, medium!!.quantity, 0.01)

        // Small values round to 2 decimals
        val small = MeasurementConverter.convert(1.25, "ML", MeasurementPreference.ORIGINAL)
        assertEquals(1.25, small!!.quantity, 0.01)
    }

    @Test
    fun `MeasurementUnit fromCode returns correct unit`() {
        assertEquals(MeasurementUnit.ML, MeasurementUnit.fromCode("ML"))
        assertEquals(MeasurementUnit.CUP, MeasurementUnit.fromCode("CUP"))
        assertEquals(MeasurementUnit.GRAM, MeasurementUnit.fromCode("G"))
        assertNull(MeasurementUnit.fromCode("INVALID"))
    }

    @Test
    fun `MeasurementUnit properties are correct`() {
        // Volume units
        assertEquals(true, MeasurementUnit.ML.isVolumeUnit)
        assertEquals(true, MeasurementUnit.CUP.isVolumeUnit)
        assertEquals(false, MeasurementUnit.GRAM.isVolumeUnit)

        // Weight units
        assertEquals(true, MeasurementUnit.GRAM.isWeightUnit)
        assertEquals(true, MeasurementUnit.OZ.isWeightUnit)
        assertEquals(false, MeasurementUnit.ML.isWeightUnit)

        // Metric units
        assertEquals(true, MeasurementUnit.ML.isMetric)
        assertEquals(true, MeasurementUnit.GRAM.isMetric)
        assertEquals(false, MeasurementUnit.CUP.isMetric)

        // US units
        assertEquals(true, MeasurementUnit.CUP.isUS)
        assertEquals(true, MeasurementUnit.OZ.isUS)
        assertEquals(false, MeasurementUnit.ML.isUS)

        // Convertible units
        assertEquals(true, MeasurementUnit.ML.isConvertible)
        assertEquals(false, MeasurementUnit.PIECE.isConvertible)
        assertEquals(false, MeasurementUnit.TO_TASTE.isConvertible)
    }
}
