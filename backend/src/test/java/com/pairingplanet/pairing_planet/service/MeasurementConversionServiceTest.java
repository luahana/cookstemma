package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.enums.MeasurementPreference;
import com.pairingplanet.pairing_planet.domain.enums.MeasurementUnit;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

class MeasurementConversionServiceTest {

    private MeasurementConversionService service;

    @BeforeEach
    void setUp() {
        service = new MeasurementConversionService();
    }

    @Nested
    @DisplayName("Volume Conversions")
    class VolumeConversions {

        @Test
        @DisplayName("Should convert cups to ml")
        void cupsToMl() {
            Double result = service.convert(1.0, MeasurementUnit.CUP, MeasurementUnit.ML);
            assertThat(result).isEqualTo(240.0);
        }

        @Test
        @DisplayName("Should convert ml to cups")
        void mlToCups() {
            Double result = service.convert(240.0, MeasurementUnit.ML, MeasurementUnit.CUP);
            assertThat(result).isEqualTo(1.0);
        }

        @Test
        @DisplayName("Should convert tablespoons to ml")
        void tbspToMl() {
            Double result = service.convert(2.0, MeasurementUnit.TBSP, MeasurementUnit.ML);
            assertThat(result).isEqualTo(30.0);
        }

        @Test
        @DisplayName("Should convert teaspoons to tablespoons")
        void tspToTbsp() {
            Double result = service.convert(3.0, MeasurementUnit.TSP, MeasurementUnit.TBSP);
            assertThat(result).isEqualTo(1.0);
        }

        @Test
        @DisplayName("Should convert liters to ml")
        void litersToMl() {
            Double result = service.convert(1.0, MeasurementUnit.L, MeasurementUnit.ML);
            assertThat(result).isEqualTo(1000.0);
        }

        @Test
        @DisplayName("Should convert cups to liters")
        void cupsToLiters() {
            Double result = service.convert(4.0, MeasurementUnit.CUP, MeasurementUnit.L);
            assertThat(result).isCloseTo(0.96, within(0.01));
        }
    }

    @Nested
    @DisplayName("Weight Conversions")
    class WeightConversions {

        @Test
        @DisplayName("Should convert ounces to grams")
        void ozToGrams() {
            Double result = service.convert(1.0, MeasurementUnit.OZ, MeasurementUnit.G);
            assertThat(result).isCloseTo(28.35, within(0.01));
        }

        @Test
        @DisplayName("Should convert grams to ounces")
        void gramsToOz() {
            Double result = service.convert(100.0, MeasurementUnit.G, MeasurementUnit.OZ);
            assertThat(result).isCloseTo(3.53, within(0.01));
        }

        @Test
        @DisplayName("Should convert pounds to grams")
        void lbToGrams() {
            Double result = service.convert(1.0, MeasurementUnit.LB, MeasurementUnit.G);
            assertThat(result).isCloseTo(453.59, within(0.01));
        }

        @Test
        @DisplayName("Should convert kilograms to grams")
        void kgToGrams() {
            Double result = service.convert(1.0, MeasurementUnit.KG, MeasurementUnit.G);
            assertThat(result).isEqualTo(1000.0);
        }

        @Test
        @DisplayName("Should convert grams to kilograms")
        void gramsToKg() {
            Double result = service.convert(500.0, MeasurementUnit.G, MeasurementUnit.KG);
            assertThat(result).isEqualTo(0.5);
        }
    }

    @Nested
    @DisplayName("Same Unit Conversion")
    class SameUnitConversion {

        @Test
        @DisplayName("Should return same value for same unit")
        void sameUnit() {
            Double result = service.convert(5.0, MeasurementUnit.CUP, MeasurementUnit.CUP);
            assertThat(result).isEqualTo(5.0);
        }
    }

    @Nested
    @DisplayName("Cross-Type Conversion (Should Fail)")
    class CrossTypeConversion {

        @Test
        @DisplayName("Should return null for volume to weight conversion")
        void volumeToWeight() {
            Double result = service.convert(1.0, MeasurementUnit.CUP, MeasurementUnit.G);
            assertThat(result).isNull();
        }

        @Test
        @DisplayName("Should return null for weight to volume conversion")
        void weightToVolume() {
            Double result = service.convert(100.0, MeasurementUnit.G, MeasurementUnit.ML);
            assertThat(result).isNull();
        }
    }

    @Nested
    @DisplayName("Null Input Handling")
    class NullInputs {

        @Test
        @DisplayName("Should return null for null quantity")
        void nullQuantity() {
            Double result = service.convert(null, MeasurementUnit.CUP, MeasurementUnit.ML);
            assertThat(result).isNull();
        }

        @Test
        @DisplayName("Should return null for null from unit")
        void nullFromUnit() {
            Double result = service.convert(1.0, null, MeasurementUnit.ML);
            assertThat(result).isNull();
        }

        @Test
        @DisplayName("Should return null for null to unit")
        void nullToUnit() {
            Double result = service.convert(1.0, MeasurementUnit.CUP, null);
            assertThat(result).isNull();
        }
    }

    @Nested
    @DisplayName("Count/Other Units (No Conversion)")
    class CountUnits {

        @Test
        @DisplayName("PIECE should be identified as count unit")
        void pieceIsCount() {
            assertThat(MeasurementUnit.PIECE.isCountOrOther()).isTrue();
            assertThat(MeasurementUnit.PIECE.isVolume()).isFalse();
            assertThat(MeasurementUnit.PIECE.isWeight()).isFalse();
        }

        @Test
        @DisplayName("PINCH should be identified as count unit")
        void pinchIsCount() {
            assertThat(MeasurementUnit.PINCH.isCountOrOther()).isTrue();
        }
    }

    @Nested
    @DisplayName("Preference-Based Conversion")
    class PreferenceConversion {

        @Test
        @DisplayName("Should convert to metric when preference is METRIC")
        void metricPreference() {
            var result = service.convertForPreference(1.0, MeasurementUnit.CUP, MeasurementPreference.METRIC);

            assertThat(result.unit()).isEqualTo(MeasurementUnit.ML);
            assertThat(result.quantity()).isEqualTo(240.0);
        }

        @Test
        @DisplayName("Should convert to US when preference is US")
        void usPreference() {
            var result = service.convertForPreference(240.0, MeasurementUnit.ML, MeasurementPreference.US);

            assertThat(result.unit()).isEqualTo(MeasurementUnit.CUP);
            assertThat(result.quantity()).isEqualTo(1.0);
        }

        @Test
        @DisplayName("Should keep original when preference is ORIGINAL")
        void originalPreference() {
            var result = service.convertForPreference(2.0, MeasurementUnit.CUP, MeasurementPreference.ORIGINAL);

            assertThat(result.unit()).isEqualTo(MeasurementUnit.CUP);
            assertThat(result.quantity()).isEqualTo(2.0);
        }

        @Test
        @DisplayName("Should not convert count units regardless of preference")
        void countUnitsNotConverted() {
            var result = service.convertForPreference(3.0, MeasurementUnit.PIECE, MeasurementPreference.METRIC);

            assertThat(result.unit()).isEqualTo(MeasurementUnit.PIECE);
            assertThat(result.quantity()).isEqualTo(3.0);
        }

        @Test
        @DisplayName("Should convert weight to metric grams")
        void weightToMetric() {
            var result = service.convertForPreference(4.0, MeasurementUnit.OZ, MeasurementPreference.METRIC);

            assertThat(result.unit()).isEqualTo(MeasurementUnit.G);
            assertThat(result.quantity()).isCloseTo(113.4, within(0.1));
        }

        @Test
        @DisplayName("Should convert weight to US ounces")
        void weightToUS() {
            var result = service.convertForPreference(100.0, MeasurementUnit.G, MeasurementPreference.US);

            assertThat(result.unit()).isEqualTo(MeasurementUnit.OZ);
            assertThat(result.quantity()).isCloseTo(3.53, within(0.01));
        }
    }

    @Nested
    @DisplayName("Target Unit Determination")
    class TargetUnitTests {

        @Test
        @DisplayName("Should return ML for volume metric preference")
        void volumeMetric() {
            MeasurementUnit result = service.getTargetUnit(MeasurementUnit.CUP, MeasurementPreference.METRIC);
            assertThat(result).isEqualTo(MeasurementUnit.ML);
        }

        @Test
        @DisplayName("Should return G for weight metric preference")
        void weightMetric() {
            MeasurementUnit result = service.getTargetUnit(MeasurementUnit.OZ, MeasurementPreference.METRIC);
            assertThat(result).isEqualTo(MeasurementUnit.G);
        }

        @Test
        @DisplayName("Should return CUP for volume US preference from metric")
        void volumeUSFromMetric() {
            MeasurementUnit result = service.getTargetUnit(MeasurementUnit.ML, MeasurementPreference.US);
            assertThat(result).isEqualTo(MeasurementUnit.CUP);
        }

        @Test
        @DisplayName("Should return OZ for weight US preference from metric")
        void weightUSFromMetric() {
            MeasurementUnit result = service.getTargetUnit(MeasurementUnit.G, MeasurementPreference.US);
            assertThat(result).isEqualTo(MeasurementUnit.OZ);
        }

        @Test
        @DisplayName("Should keep US units when preference is US")
        void keepUSUnits() {
            MeasurementUnit result = service.getTargetUnit(MeasurementUnit.CUP, MeasurementPreference.US);
            assertThat(result).isEqualTo(MeasurementUnit.CUP);
        }

        @Test
        @DisplayName("Should return original unit for ORIGINAL preference")
        void originalPreference() {
            MeasurementUnit result = service.getTargetUnit(MeasurementUnit.TBSP, MeasurementPreference.ORIGINAL);
            assertThat(result).isEqualTo(MeasurementUnit.TBSP);
        }

        @Test
        @DisplayName("Should return source unit for count/other types")
        void countTypes() {
            MeasurementUnit result = service.getTargetUnit(MeasurementUnit.PIECE, MeasurementPreference.METRIC);
            assertThat(result).isEqualTo(MeasurementUnit.PIECE);
        }
    }
}
