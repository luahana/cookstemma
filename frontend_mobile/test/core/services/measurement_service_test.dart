import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/core/services/measurement_service.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/ingredient_dto.dart';

void main() {
  group('MeasurementService', () {
    group('convert', () {
      group('Volume conversions', () {
        test('converts cups to ml', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.cup,
            MeasurementUnit.ml,
          );
          expect(result, 240.0);
        });

        test('converts ml to cups', () {
          final result = MeasurementService.convert(
            240.0,
            MeasurementUnit.ml,
            MeasurementUnit.cup,
          );
          expect(result, 1.0);
        });

        test('converts tbsp to ml', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.tbsp,
            MeasurementUnit.ml,
          );
          expect(result, 15.0);
        });

        test('converts tsp to ml', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.tsp,
            MeasurementUnit.ml,
          );
          expect(result, 5.0);
        });

        test('converts L to ml', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.l,
            MeasurementUnit.ml,
          );
          expect(result, 1000.0);
        });

        test('converts fl oz to ml', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.flOz,
            MeasurementUnit.ml,
          );
          expect(result, 30.0);
        });

        test('converts pint to ml', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.pint,
            MeasurementUnit.ml,
          );
          expect(result, 473.0);
        });

        test('converts quart to ml', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.quart,
            MeasurementUnit.ml,
          );
          expect(result, 946.0);
        });
      });

      group('Weight conversions', () {
        test('converts oz to g', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.oz,
            MeasurementUnit.g,
          );
          expect(result, 28.35);
        });

        test('converts g to oz', () {
          final result = MeasurementService.convert(
            28.35,
            MeasurementUnit.g,
            MeasurementUnit.oz,
          );
          expect(result, 1.0);
        });

        test('converts lb to g', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.lb,
            MeasurementUnit.g,
          );
          expect(result, 453.59);
        });

        test('converts kg to g', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.kg,
            MeasurementUnit.g,
          );
          expect(result, 1000.0);
        });

        test('converts g to kg', () {
          final result = MeasurementService.convert(
            1000.0,
            MeasurementUnit.g,
            MeasurementUnit.kg,
          );
          expect(result, 1.0);
        });
      });

      group('Same unit conversion', () {
        test('returns same quantity when from and to units are the same', () {
          final result = MeasurementService.convert(
            2.5,
            MeasurementUnit.cup,
            MeasurementUnit.cup,
          );
          expect(result, 2.5);
        });
      });

      group('Invalid conversions', () {
        test('returns null for volume to weight conversion', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.cup,
            MeasurementUnit.g,
          );
          expect(result, isNull);
        });

        test('returns null for weight to volume conversion', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.g,
            MeasurementUnit.ml,
          );
          expect(result, isNull);
        });

        test('returns null when quantity is null', () {
          final result = MeasurementService.convert(
            null,
            MeasurementUnit.cup,
            MeasurementUnit.ml,
          );
          expect(result, isNull);
        });

        test('returns null when fromUnit is null', () {
          final result = MeasurementService.convert(
            1.0,
            null,
            MeasurementUnit.ml,
          );
          expect(result, isNull);
        });

        test('returns null when toUnit is null', () {
          final result = MeasurementService.convert(
            1.0,
            MeasurementUnit.cup,
            null,
          );
          expect(result, isNull);
        });
      });

      group('Rounding', () {
        test('rounds to 2 decimal places', () {
          // 1.333... cups = 320 ml / 240 ml per cup
          final result = MeasurementService.convert(
            320.0,
            MeasurementUnit.ml,
            MeasurementUnit.cup,
          );
          expect(result, closeTo(1.33, 0.01));
        });
      });
    });

    group('getTargetUnit', () {
      test('returns source unit for ORIGINAL preference', () {
        final result = MeasurementService.getTargetUnit(
          MeasurementUnit.cup,
          MeasurementPreference.original,
        );
        expect(result, MeasurementUnit.cup);
      });

      test('returns ml for METRIC preference with volume unit', () {
        final result = MeasurementService.getTargetUnit(
          MeasurementUnit.cup,
          MeasurementPreference.metric,
        );
        expect(result, MeasurementUnit.ml);
      });

      test('returns g for METRIC preference with weight unit', () {
        final result = MeasurementService.getTargetUnit(
          MeasurementUnit.oz,
          MeasurementPreference.metric,
        );
        expect(result, MeasurementUnit.g);
      });

      test('returns cup for US preference with ml', () {
        final result = MeasurementService.getTargetUnit(
          MeasurementUnit.ml,
          MeasurementPreference.us,
        );
        expect(result, MeasurementUnit.cup);
      });

      test('returns cup for US preference with L', () {
        final result = MeasurementService.getTargetUnit(
          MeasurementUnit.l,
          MeasurementPreference.us,
        );
        expect(result, MeasurementUnit.cup);
      });

      test('returns oz for US preference with g', () {
        final result = MeasurementService.getTargetUnit(
          MeasurementUnit.g,
          MeasurementPreference.us,
        );
        expect(result, MeasurementUnit.oz);
      });

      test('returns oz for US preference with kg', () {
        final result = MeasurementService.getTargetUnit(
          MeasurementUnit.kg,
          MeasurementPreference.us,
        );
        expect(result, MeasurementUnit.oz);
      });

      test('returns source unit for count units regardless of preference', () {
        final result = MeasurementService.getTargetUnit(
          MeasurementUnit.piece,
          MeasurementPreference.metric,
        );
        expect(result, MeasurementUnit.piece);
      });

      test('returns source unit for pinch regardless of preference', () {
        final result = MeasurementService.getTargetUnit(
          MeasurementUnit.pinch,
          MeasurementPreference.us,
        );
        expect(result, MeasurementUnit.pinch);
      });
    });

    group('convertForPreference', () {
      test('returns original values for ORIGINAL preference', () {
        final result = MeasurementService.convertForPreference(
          2.0,
          MeasurementUnit.cup,
          MeasurementPreference.original,
        );
        expect(result.quantity, 2.0);
        expect(result.unit, MeasurementUnit.cup);
      });

      test('converts cups to ml for METRIC preference', () {
        final result = MeasurementService.convertForPreference(
          2.0,
          MeasurementUnit.cup,
          MeasurementPreference.metric,
        );
        expect(result.quantity, 480.0);
        expect(result.unit, MeasurementUnit.ml);
      });

      test('converts ml to cups for US preference', () {
        final result = MeasurementService.convertForPreference(
          240.0,
          MeasurementUnit.ml,
          MeasurementPreference.us,
        );
        expect(result.quantity, 1.0);
        expect(result.unit, MeasurementUnit.cup);
      });

      test('returns original values when quantity is null', () {
        final result = MeasurementService.convertForPreference(
          null,
          MeasurementUnit.cup,
          MeasurementPreference.metric,
        );
        expect(result.quantity, isNull);
        expect(result.unit, MeasurementUnit.cup);
      });

      test('returns original values when unit is null', () {
        final result = MeasurementService.convertForPreference(
          2.0,
          null,
          MeasurementPreference.metric,
        );
        expect(result.quantity, 2.0);
        expect(result.unit, isNull);
      });
    });

    group('getUnitLabel', () {
      test('returns correct labels for volume units', () {
        expect(MeasurementService.getUnitLabel(MeasurementUnit.ml), 'ml');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.l), 'L');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.tsp), 'tsp');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.tbsp), 'tbsp');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.cup), 'cup');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.flOz), 'fl oz');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.pint), 'pint');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.quart), 'quart');
      });

      test('returns correct labels for weight units', () {
        expect(MeasurementService.getUnitLabel(MeasurementUnit.g), 'g');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.kg), 'kg');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.oz), 'oz');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.lb), 'lb');
      });

      test('returns correct labels for count units', () {
        expect(MeasurementService.getUnitLabel(MeasurementUnit.piece), 'pc');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.pinch), 'pinch');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.dash), 'dash');
        expect(
            MeasurementService.getUnitLabel(MeasurementUnit.toTaste), 'to taste');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.clove), 'clove');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.bunch), 'bunch');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.can), 'can');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.package), 'pkg');
      });
    });

    group('volumeUnits', () {
      test('returns all volume units', () {
        final units = MeasurementService.volumeUnits;
        expect(units, contains(MeasurementUnit.ml));
        expect(units, contains(MeasurementUnit.l));
        expect(units, contains(MeasurementUnit.cup));
        expect(units, contains(MeasurementUnit.tbsp));
        expect(units, contains(MeasurementUnit.tsp));
        expect(units, contains(MeasurementUnit.flOz));
        expect(units, contains(MeasurementUnit.pint));
        expect(units, contains(MeasurementUnit.quart));
      });
    });

    group('weightUnits', () {
      test('returns all weight units', () {
        final units = MeasurementService.weightUnits;
        expect(units, contains(MeasurementUnit.g));
        expect(units, contains(MeasurementUnit.kg));
        expect(units, contains(MeasurementUnit.oz));
        expect(units, contains(MeasurementUnit.lb));
      });
    });

    group('countUnits', () {
      test('returns all count units', () {
        final units = MeasurementService.countUnits;
        expect(units, contains(MeasurementUnit.piece));
        expect(units, contains(MeasurementUnit.pinch));
        expect(units, contains(MeasurementUnit.dash));
        expect(units, contains(MeasurementUnit.toTaste));
        expect(units, contains(MeasurementUnit.clove));
        expect(units, contains(MeasurementUnit.bunch));
        expect(units, contains(MeasurementUnit.can));
        expect(units, contains(MeasurementUnit.package));
      });
    });
  });

  group('ConversionResult', () {
    test('isConverted returns true when both quantity and unit are set', () {
      final result = ConversionResult(
        quantity: 2.0,
        unit: MeasurementUnit.cup,
      );
      expect(result.isConverted, isTrue);
    });

    test('isConverted returns false when quantity is null', () {
      final result = ConversionResult(
        quantity: null,
        unit: MeasurementUnit.cup,
      );
      expect(result.isConverted, isFalse);
    });

    test('isConverted returns false when unit is null', () {
      final result = ConversionResult(
        quantity: 2.0,
        unit: null,
      );
      expect(result.isConverted, isFalse);
    });

    group('format', () {
      test('returns empty string when not converted', () {
        final result = ConversionResult(quantity: null, unit: null);
        expect(result.format(), '');
      });

      test('formats whole number without decimals', () {
        final result = ConversionResult(
          quantity: 2.0,
          unit: MeasurementUnit.cup,
        );
        expect(result.format(), '2 cup');
      });

      test('formats decimal number with appropriate precision', () {
        final result = ConversionResult(
          quantity: 2.5,
          unit: MeasurementUnit.cup,
        );
        expect(result.format(), '2.5 cup');
      });

      test('removes trailing zeros from decimals', () {
        final result = ConversionResult(
          quantity: 2.50,
          unit: MeasurementUnit.g,
        );
        expect(result.format(), '2.5 g');
      });
    });
  });

  // ============================================================
  // HEAVY UNIT TESTS - Comprehensive Conversion Coverage
  // ============================================================

  group('Complete bidirectional volume conversions', () {
    // ml conversions
    group('ml conversions', () {
      test('ml → L', () => expect(MeasurementService.convert(1000.0, MeasurementUnit.ml, MeasurementUnit.l), 1.0));
      test('L → ml', () => expect(MeasurementService.convert(1.0, MeasurementUnit.l, MeasurementUnit.ml), 1000.0));
      test('ml → tsp', () => expect(MeasurementService.convert(5.0, MeasurementUnit.ml, MeasurementUnit.tsp), 1.0));
      test('tsp → ml', () => expect(MeasurementService.convert(1.0, MeasurementUnit.tsp, MeasurementUnit.ml), 5.0));
      test('ml → tbsp', () => expect(MeasurementService.convert(15.0, MeasurementUnit.ml, MeasurementUnit.tbsp), 1.0));
      test('tbsp → ml', () => expect(MeasurementService.convert(1.0, MeasurementUnit.tbsp, MeasurementUnit.ml), 15.0));
      test('ml → cup', () => expect(MeasurementService.convert(240.0, MeasurementUnit.ml, MeasurementUnit.cup), 1.0));
      test('cup → ml', () => expect(MeasurementService.convert(1.0, MeasurementUnit.cup, MeasurementUnit.ml), 240.0));
      test('ml → flOz', () => expect(MeasurementService.convert(30.0, MeasurementUnit.ml, MeasurementUnit.flOz), 1.0));
      test('flOz → ml', () => expect(MeasurementService.convert(1.0, MeasurementUnit.flOz, MeasurementUnit.ml), 30.0));
      test('ml → pint', () => expect(MeasurementService.convert(473.0, MeasurementUnit.ml, MeasurementUnit.pint), 1.0));
      test('pint → ml', () => expect(MeasurementService.convert(1.0, MeasurementUnit.pint, MeasurementUnit.ml), 473.0));
      test('ml → quart', () => expect(MeasurementService.convert(946.0, MeasurementUnit.ml, MeasurementUnit.quart), 1.0));
      test('quart → ml', () => expect(MeasurementService.convert(1.0, MeasurementUnit.quart, MeasurementUnit.ml), 946.0));
    });

    // L conversions (non-ml)
    group('L conversions', () {
      test('L → tsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.l, MeasurementUnit.tsp), 200.0));
      test('tsp → L', () => expect(MeasurementService.convert(200.0, MeasurementUnit.tsp, MeasurementUnit.l), 1.0));
      test('L → tbsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.l, MeasurementUnit.tbsp), closeTo(66.67, 0.01)));
      test('tbsp → L', () => expect(MeasurementService.convert(66.67, MeasurementUnit.tbsp, MeasurementUnit.l), closeTo(1.0, 0.01)));
      test('L → cup', () => expect(MeasurementService.convert(1.0, MeasurementUnit.l, MeasurementUnit.cup), closeTo(4.17, 0.01)));
      test('cup → L', () => expect(MeasurementService.convert(4.17, MeasurementUnit.cup, MeasurementUnit.l), closeTo(1.0, 0.01)));
      test('L → flOz', () => expect(MeasurementService.convert(1.0, MeasurementUnit.l, MeasurementUnit.flOz), closeTo(33.33, 0.01)));
      test('flOz → L', () => expect(MeasurementService.convert(33.33, MeasurementUnit.flOz, MeasurementUnit.l), closeTo(1.0, 0.01)));
      test('L → pint', () => expect(MeasurementService.convert(1.0, MeasurementUnit.l, MeasurementUnit.pint), closeTo(2.11, 0.01)));
      test('pint → L', () => expect(MeasurementService.convert(2.11, MeasurementUnit.pint, MeasurementUnit.l), closeTo(1.0, 0.01)));
      test('L → quart', () => expect(MeasurementService.convert(1.0, MeasurementUnit.l, MeasurementUnit.quart), closeTo(1.06, 0.01)));
      test('quart → L', () => expect(MeasurementService.convert(1.06, MeasurementUnit.quart, MeasurementUnit.l), closeTo(1.0, 0.01)));
    });

    // tsp conversions (non-ml, non-L)
    group('tsp conversions', () {
      test('tsp → tbsp', () => expect(MeasurementService.convert(3.0, MeasurementUnit.tsp, MeasurementUnit.tbsp), 1.0));
      test('tbsp → tsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.tbsp, MeasurementUnit.tsp), 3.0));
      test('tsp → cup', () => expect(MeasurementService.convert(48.0, MeasurementUnit.tsp, MeasurementUnit.cup), 1.0));
      test('cup → tsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.cup, MeasurementUnit.tsp), 48.0));
      test('tsp → flOz', () => expect(MeasurementService.convert(6.0, MeasurementUnit.tsp, MeasurementUnit.flOz), 1.0));
      test('flOz → tsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.flOz, MeasurementUnit.tsp), 6.0));
      test('tsp → pint', () => expect(MeasurementService.convert(94.6, MeasurementUnit.tsp, MeasurementUnit.pint), 1.0));
      test('pint → tsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.pint, MeasurementUnit.tsp), 94.6));
      test('tsp → quart', () => expect(MeasurementService.convert(189.2, MeasurementUnit.tsp, MeasurementUnit.quart), 1.0));
      test('quart → tsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.quart, MeasurementUnit.tsp), 189.2));
    });

    // tbsp conversions (remaining)
    group('tbsp conversions', () {
      test('tbsp → cup', () => expect(MeasurementService.convert(16.0, MeasurementUnit.tbsp, MeasurementUnit.cup), 1.0));
      test('cup → tbsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.cup, MeasurementUnit.tbsp), 16.0));
      test('tbsp → flOz', () => expect(MeasurementService.convert(2.0, MeasurementUnit.tbsp, MeasurementUnit.flOz), 1.0));
      test('flOz → tbsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.flOz, MeasurementUnit.tbsp), 2.0));
      test('tbsp → pint', () => expect(MeasurementService.convert(31.53, MeasurementUnit.tbsp, MeasurementUnit.pint), closeTo(1.0, 0.01)));
      test('pint → tbsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.pint, MeasurementUnit.tbsp), closeTo(31.53, 0.01)));
      test('tbsp → quart', () => expect(MeasurementService.convert(63.07, MeasurementUnit.tbsp, MeasurementUnit.quart), closeTo(1.0, 0.01)));
      test('quart → tbsp', () => expect(MeasurementService.convert(1.0, MeasurementUnit.quart, MeasurementUnit.tbsp), closeTo(63.07, 0.01)));
    });

    // cup conversions (remaining)
    group('cup conversions', () {
      test('cup → flOz', () => expect(MeasurementService.convert(1.0, MeasurementUnit.cup, MeasurementUnit.flOz), 8.0));
      test('flOz → cup', () => expect(MeasurementService.convert(8.0, MeasurementUnit.flOz, MeasurementUnit.cup), 1.0));
      test('cup → pint', () => expect(MeasurementService.convert(1.97, MeasurementUnit.cup, MeasurementUnit.pint), closeTo(1.0, 0.01)));
      test('pint → cup', () => expect(MeasurementService.convert(1.0, MeasurementUnit.pint, MeasurementUnit.cup), closeTo(1.97, 0.01)));
      test('cup → quart', () => expect(MeasurementService.convert(3.94, MeasurementUnit.cup, MeasurementUnit.quart), closeTo(1.0, 0.01)));
      test('quart → cup', () => expect(MeasurementService.convert(1.0, MeasurementUnit.quart, MeasurementUnit.cup), closeTo(3.94, 0.01)));
    });

    // flOz conversions (remaining)
    group('flOz conversions', () {
      test('flOz → pint', () => expect(MeasurementService.convert(15.77, MeasurementUnit.flOz, MeasurementUnit.pint), closeTo(1.0, 0.01)));
      test('pint → flOz', () => expect(MeasurementService.convert(1.0, MeasurementUnit.pint, MeasurementUnit.flOz), closeTo(15.77, 0.01)));
      test('flOz → quart', () => expect(MeasurementService.convert(31.53, MeasurementUnit.flOz, MeasurementUnit.quart), closeTo(1.0, 0.01)));
      test('quart → flOz', () => expect(MeasurementService.convert(1.0, MeasurementUnit.quart, MeasurementUnit.flOz), closeTo(31.53, 0.01)));
    });

    // pint ↔ quart
    group('pint-quart conversions', () {
      test('pint → quart', () => expect(MeasurementService.convert(2.0, MeasurementUnit.pint, MeasurementUnit.quart), closeTo(1.0, 0.01)));
      test('quart → pint', () => expect(MeasurementService.convert(1.0, MeasurementUnit.quart, MeasurementUnit.pint), closeTo(2.0, 0.01)));
    });
  });

  group('Complete bidirectional weight conversions', () {
    // g conversions
    group('g conversions', () {
      test('g → kg', () => expect(MeasurementService.convert(1000.0, MeasurementUnit.g, MeasurementUnit.kg), 1.0));
      test('kg → g', () => expect(MeasurementService.convert(1.0, MeasurementUnit.kg, MeasurementUnit.g), 1000.0));
      test('g → oz', () => expect(MeasurementService.convert(28.35, MeasurementUnit.g, MeasurementUnit.oz), 1.0));
      test('oz → g', () => expect(MeasurementService.convert(1.0, MeasurementUnit.oz, MeasurementUnit.g), 28.35));
      test('g → lb', () => expect(MeasurementService.convert(453.59, MeasurementUnit.g, MeasurementUnit.lb), 1.0));
      test('lb → g', () => expect(MeasurementService.convert(1.0, MeasurementUnit.lb, MeasurementUnit.g), 453.59));
    });

    // kg conversions (non-g)
    group('kg conversions', () {
      test('kg → oz', () => expect(MeasurementService.convert(1.0, MeasurementUnit.kg, MeasurementUnit.oz), closeTo(35.27, 0.01)));
      test('oz → kg', () => expect(MeasurementService.convert(35.27, MeasurementUnit.oz, MeasurementUnit.kg), closeTo(1.0, 0.01)));
      test('kg → lb', () => expect(MeasurementService.convert(1.0, MeasurementUnit.kg, MeasurementUnit.lb), closeTo(2.20, 0.01)));
      test('lb → kg', () => expect(MeasurementService.convert(2.20, MeasurementUnit.lb, MeasurementUnit.kg), closeTo(1.0, 0.01)));
    });

    // oz ↔ lb
    group('oz-lb conversions', () {
      test('oz → lb', () => expect(MeasurementService.convert(16.0, MeasurementUnit.oz, MeasurementUnit.lb), closeTo(1.0, 0.01)));
      test('lb → oz', () => expect(MeasurementService.convert(1.0, MeasurementUnit.lb, MeasurementUnit.oz), closeTo(16.0, 0.01)));
    });
  });

  group('Round-trip precision tests', () {
    group('Volume round-trips', () {
      test('cup → ml → cup', () {
        final ml = MeasurementService.convert(1.0, MeasurementUnit.cup, MeasurementUnit.ml);
        final back = MeasurementService.convert(ml!, MeasurementUnit.ml, MeasurementUnit.cup);
        expect(back, closeTo(1.0, 0.01));
      });

      test('tbsp → tsp → tbsp', () {
        final tsp = MeasurementService.convert(1.0, MeasurementUnit.tbsp, MeasurementUnit.tsp);
        final back = MeasurementService.convert(tsp!, MeasurementUnit.tsp, MeasurementUnit.tbsp);
        expect(back, closeTo(1.0, 0.01));
      });

      test('L → cup → L', () {
        final cup = MeasurementService.convert(1.0, MeasurementUnit.l, MeasurementUnit.cup);
        final back = MeasurementService.convert(cup!, MeasurementUnit.cup, MeasurementUnit.l);
        expect(back, closeTo(1.0, 0.01));
      });

      test('pint → ml → pint', () {
        final ml = MeasurementService.convert(1.0, MeasurementUnit.pint, MeasurementUnit.ml);
        final back = MeasurementService.convert(ml!, MeasurementUnit.ml, MeasurementUnit.pint);
        expect(back, closeTo(1.0, 0.01));
      });

      test('quart → flOz → quart', () {
        final flOz = MeasurementService.convert(1.0, MeasurementUnit.quart, MeasurementUnit.flOz);
        final back = MeasurementService.convert(flOz!, MeasurementUnit.flOz, MeasurementUnit.quart);
        expect(back, closeTo(1.0, 0.01));
      });

      test('flOz → tbsp → flOz', () {
        final tbsp = MeasurementService.convert(1.0, MeasurementUnit.flOz, MeasurementUnit.tbsp);
        final back = MeasurementService.convert(tbsp!, MeasurementUnit.tbsp, MeasurementUnit.flOz);
        expect(back, closeTo(1.0, 0.01));
      });

      test('cup → L → cup', () {
        final l = MeasurementService.convert(1.0, MeasurementUnit.cup, MeasurementUnit.l);
        final back = MeasurementService.convert(l!, MeasurementUnit.l, MeasurementUnit.cup);
        expect(back, closeTo(1.0, 0.01));
      });

      test('tsp → ml → tsp', () {
        final ml = MeasurementService.convert(1.0, MeasurementUnit.tsp, MeasurementUnit.ml);
        final back = MeasurementService.convert(ml!, MeasurementUnit.ml, MeasurementUnit.tsp);
        expect(back, closeTo(1.0, 0.01));
      });
    });

    group('Weight round-trips', () {
      test('oz → g → oz', () {
        final g = MeasurementService.convert(1.0, MeasurementUnit.oz, MeasurementUnit.g);
        final back = MeasurementService.convert(g!, MeasurementUnit.g, MeasurementUnit.oz);
        expect(back, closeTo(1.0, 0.01));
      });

      test('lb → kg → lb', () {
        final kg = MeasurementService.convert(1.0, MeasurementUnit.lb, MeasurementUnit.kg);
        final back = MeasurementService.convert(kg!, MeasurementUnit.kg, MeasurementUnit.lb);
        expect(back, closeTo(1.0, 0.02)); // Wider tolerance due to double rounding
      });

      test('kg → g → kg', () {
        final g = MeasurementService.convert(1.0, MeasurementUnit.kg, MeasurementUnit.g);
        final back = MeasurementService.convert(g!, MeasurementUnit.g, MeasurementUnit.kg);
        expect(back, closeTo(1.0, 0.01));
      });

      test('lb → oz → lb', () {
        final oz = MeasurementService.convert(1.0, MeasurementUnit.lb, MeasurementUnit.oz);
        final back = MeasurementService.convert(oz!, MeasurementUnit.oz, MeasurementUnit.lb);
        expect(back, closeTo(1.0, 0.01));
      });

      test('oz → kg → oz', () {
        final kg = MeasurementService.convert(1.0, MeasurementUnit.oz, MeasurementUnit.kg);
        final back = MeasurementService.convert(kg!, MeasurementUnit.kg, MeasurementUnit.oz);
        expect(back, closeTo(1.0, 0.1)); // Wider tolerance: oz→kg loses precision (0.03→1.06 oz)
      });

      test('g → lb → g', () {
        final lb = MeasurementService.convert(100.0, MeasurementUnit.g, MeasurementUnit.lb);
        final back = MeasurementService.convert(lb!, MeasurementUnit.lb, MeasurementUnit.g);
        expect(back, closeTo(100.0, 0.5));
      });

      test('kg → oz → kg', () {
        final oz = MeasurementService.convert(1.0, MeasurementUnit.kg, MeasurementUnit.oz);
        final back = MeasurementService.convert(oz!, MeasurementUnit.oz, MeasurementUnit.kg);
        expect(back, closeTo(1.0, 0.01));
      });

      test('g → oz → g', () {
        final oz = MeasurementService.convert(100.0, MeasurementUnit.g, MeasurementUnit.oz);
        final back = MeasurementService.convert(oz!, MeasurementUnit.oz, MeasurementUnit.g);
        expect(back, closeTo(100.0, 0.5));
      });
    });
  });

  group('Real-world recipe quantities', () {
    group('Fractional cup measurements', () {
      test('1/4 cup → 60 ml', () {
        expect(MeasurementService.convert(0.25, MeasurementUnit.cup, MeasurementUnit.ml), 60.0);
      });

      test('1/3 cup → ~80 ml', () {
        expect(MeasurementService.convert(1 / 3, MeasurementUnit.cup, MeasurementUnit.ml), closeTo(80.0, 0.1));
      });

      test('1/2 cup → 120 ml', () {
        expect(MeasurementService.convert(0.5, MeasurementUnit.cup, MeasurementUnit.ml), 120.0);
      });

      test('2/3 cup → ~160 ml', () {
        expect(MeasurementService.convert(2 / 3, MeasurementUnit.cup, MeasurementUnit.ml), closeTo(160.0, 0.1));
      });

      test('3/4 cup → 180 ml', () {
        expect(MeasurementService.convert(0.75, MeasurementUnit.cup, MeasurementUnit.ml), 180.0);
      });

      test('1.5 cups → 360 ml', () {
        expect(MeasurementService.convert(1.5, MeasurementUnit.cup, MeasurementUnit.ml), 360.0);
      });

      test('2.5 cups → 600 ml', () {
        expect(MeasurementService.convert(2.5, MeasurementUnit.cup, MeasurementUnit.ml), 600.0);
      });
    });

    group('Fractional tablespoon measurements', () {
      test('1/2 tbsp → 7.5 ml', () {
        expect(MeasurementService.convert(0.5, MeasurementUnit.tbsp, MeasurementUnit.ml), 7.5);
      });

      test('1.5 tbsp → 22.5 ml', () {
        expect(MeasurementService.convert(1.5, MeasurementUnit.tbsp, MeasurementUnit.ml), 22.5);
      });

      test('2.5 tbsp → 37.5 ml', () {
        expect(MeasurementService.convert(2.5, MeasurementUnit.tbsp, MeasurementUnit.ml), 37.5);
      });
    });

    group('Common weight measurements', () {
      test('4 oz (quarter pound) → 113.4 g', () {
        expect(MeasurementService.convert(4.0, MeasurementUnit.oz, MeasurementUnit.g), 113.4);
      });

      test('8 oz (half pound) → 226.8 g', () {
        expect(MeasurementService.convert(8.0, MeasurementUnit.oz, MeasurementUnit.g), 226.8);
      });

      test('0.5 lb → 226.80 g', () {
        expect(MeasurementService.convert(0.5, MeasurementUnit.lb, MeasurementUnit.g), closeTo(226.80, 0.01));
      });

      test('1.5 kg → 1500 g', () {
        expect(MeasurementService.convert(1.5, MeasurementUnit.kg, MeasurementUnit.g), 1500.0);
      });

      test('250 g → ~8.82 oz', () {
        expect(MeasurementService.convert(250.0, MeasurementUnit.g, MeasurementUnit.oz), closeTo(8.82, 0.01));
      });

      test('500 g → ~1.1 lb', () {
        expect(MeasurementService.convert(500.0, MeasurementUnit.g, MeasurementUnit.lb), closeTo(1.10, 0.01));
      });
    });

    group('Common liquid measurements', () {
      test('1 pint → ~473 ml', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.pint, MeasurementUnit.ml), 473.0);
      });

      test('1 quart → ~946 ml', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.quart, MeasurementUnit.ml), 946.0);
      });

      test('500 ml → ~2.08 cups', () {
        expect(MeasurementService.convert(500.0, MeasurementUnit.ml, MeasurementUnit.cup), closeTo(2.08, 0.01));
      });

      test('1 L → ~4.17 cups', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.l, MeasurementUnit.cup), closeTo(4.17, 0.01));
      });
    });
  });

  group('Edge cases and boundaries', () {
    group('Zero quantity', () {
      test('0 cups → 0 ml', () {
        expect(MeasurementService.convert(0.0, MeasurementUnit.cup, MeasurementUnit.ml), 0.0);
      });

      test('0 g → 0 oz', () {
        expect(MeasurementService.convert(0.0, MeasurementUnit.g, MeasurementUnit.oz), 0.0);
      });

      test('0 L → 0 tbsp', () {
        expect(MeasurementService.convert(0.0, MeasurementUnit.l, MeasurementUnit.tbsp), 0.0);
      });
    });

    group('Very small quantities', () {
      test('0.001 cup → 0.24 ml', () {
        expect(MeasurementService.convert(0.001, MeasurementUnit.cup, MeasurementUnit.ml), 0.24);
      });

      test('0.01 tsp → 0.05 ml', () {
        expect(MeasurementService.convert(0.01, MeasurementUnit.tsp, MeasurementUnit.ml), 0.05);
      });

      test('0.1 g → ~0.00 oz (rounds to 0)', () {
        expect(MeasurementService.convert(0.1, MeasurementUnit.g, MeasurementUnit.oz), closeTo(0.0, 0.01));
      });

      test('0.5 g → ~0.02 oz', () {
        expect(MeasurementService.convert(0.5, MeasurementUnit.g, MeasurementUnit.oz), closeTo(0.02, 0.01));
      });
    });

    group('Very large quantities', () {
      test('10000 ml → ~41.67 cups', () {
        expect(MeasurementService.convert(10000.0, MeasurementUnit.ml, MeasurementUnit.cup), closeTo(41.67, 0.01));
      });

      test('100 L → 100000 ml', () {
        expect(MeasurementService.convert(100.0, MeasurementUnit.l, MeasurementUnit.ml), 100000.0);
      });

      test('10000 g → 10 kg', () {
        expect(MeasurementService.convert(10000.0, MeasurementUnit.g, MeasurementUnit.kg), 10.0);
      });

      test('1000 oz → ~28350 g', () {
        expect(MeasurementService.convert(1000.0, MeasurementUnit.oz, MeasurementUnit.g), 28350.0);
      });
    });

    group('Precision edge cases', () {
      test('1/8 tbsp (0.125) → 1.88 ml', () {
        expect(MeasurementService.convert(0.125, MeasurementUnit.tbsp, MeasurementUnit.ml), closeTo(1.88, 0.01));
      });

      test('1/16 cup (0.0625) → 15 ml', () {
        expect(MeasurementService.convert(0.0625, MeasurementUnit.cup, MeasurementUnit.ml), 15.0);
      });

      test('repeating decimal 1/3 tsp → ~1.67 ml', () {
        expect(MeasurementService.convert(1 / 3, MeasurementUnit.tsp, MeasurementUnit.ml), closeTo(1.67, 0.01));
      });

      test('0.999 cups → 239.76 ml', () {
        expect(MeasurementService.convert(0.999, MeasurementUnit.cup, MeasurementUnit.ml), 239.76);
      });
    });
  });

  group('Cross-type conversion rejection (complete)', () {
    group('Volume to weight (all should return null)', () {
      test('cup → g returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.cup, MeasurementUnit.g), isNull);
      });

      test('ml → oz returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.ml, MeasurementUnit.oz), isNull);
      });

      test('tbsp → kg returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.tbsp, MeasurementUnit.kg), isNull);
      });

      test('L → lb returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.l, MeasurementUnit.lb), isNull);
      });

      test('tsp → g returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.tsp, MeasurementUnit.g), isNull);
      });

      test('flOz → kg returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.flOz, MeasurementUnit.kg), isNull);
      });

      test('pint → oz returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.pint, MeasurementUnit.oz), isNull);
      });

      test('quart → lb returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.quart, MeasurementUnit.lb), isNull);
      });
    });

    group('Weight to volume (all should return null)', () {
      test('g → cup returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.g, MeasurementUnit.cup), isNull);
      });

      test('oz → ml returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.oz, MeasurementUnit.ml), isNull);
      });

      test('kg → tbsp returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.kg, MeasurementUnit.tbsp), isNull);
      });

      test('lb → L returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.lb, MeasurementUnit.l), isNull);
      });

      test('g → tsp returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.g, MeasurementUnit.tsp), isNull);
      });

      test('oz → flOz returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.oz, MeasurementUnit.flOz), isNull);
      });

      test('kg → pint returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.kg, MeasurementUnit.pint), isNull);
      });

      test('lb → quart returns null', () {
        expect(MeasurementService.convert(1.0, MeasurementUnit.lb, MeasurementUnit.quart), isNull);
      });
    });
  });

  group('Count unit passthrough', () {
    final countUnits = [
      MeasurementUnit.piece,
      MeasurementUnit.pinch,
      MeasurementUnit.dash,
      MeasurementUnit.toTaste,
      MeasurementUnit.clove,
      MeasurementUnit.bunch,
      MeasurementUnit.can,
      MeasurementUnit.package,
    ];

    group('With METRIC preference', () {
      for (final unit in countUnits) {
        test('$unit unchanged with METRIC preference', () {
          final result = MeasurementService.convertForPreference(
            2.0,
            unit,
            MeasurementPreference.metric,
          );
          expect(result.unit, unit);
          expect(result.quantity, 2.0);
        });
      }
    });

    group('With US preference', () {
      for (final unit in countUnits) {
        test('$unit unchanged with US preference', () {
          final result = MeasurementService.convertForPreference(
            3.0,
            unit,
            MeasurementPreference.us,
          );
          expect(result.unit, unit);
          expect(result.quantity, 3.0);
        });
      }
    });
  });

  group('ConversionResult.format edge cases (extended)', () {
    test('very small quantity: 0.01 g', () {
      final result = ConversionResult(quantity: 0.01, unit: MeasurementUnit.g);
      expect(result.format(), '0.01 g');
    });

    test('very large quantity: 10000 ml', () {
      final result = ConversionResult(quantity: 10000.0, unit: MeasurementUnit.ml);
      expect(result.format(), '10000 ml');
    });

    test('trailing zeros removed: 2.10 → 2.1', () {
      final result = ConversionResult(quantity: 2.10, unit: MeasurementUnit.cup);
      expect(result.format(), '2.1 cup');
    });

    test('integer displayed without decimal: 5.0 → 5', () {
      final result = ConversionResult(quantity: 5.0, unit: MeasurementUnit.g);
      expect(result.format(), '5 g');
    });

    test('precise decimal: 1.25 tbsp', () {
      final result = ConversionResult(quantity: 1.25, unit: MeasurementUnit.tbsp);
      expect(result.format(), '1.25 tbsp');
    });

    test('repeating decimal truncated: 1.333... → 1.33', () {
      final result = ConversionResult(quantity: 1.333333, unit: MeasurementUnit.cup);
      expect(result.format(), '1.33 cup');
    });

    test('rounds correctly: 1.999 → 2', () {
      final result = ConversionResult(quantity: 1.999, unit: MeasurementUnit.ml);
      expect(result.format(), '2 ml');
    });

    test('handles 0.5 correctly', () {
      final result = ConversionResult(quantity: 0.5, unit: MeasurementUnit.cup);
      expect(result.format(), '0.5 cup');
    });

    test('handles single decimal: 1.5 kg', () {
      final result = ConversionResult(quantity: 1.5, unit: MeasurementUnit.kg);
      expect(result.format(), '1.5 kg');
    });

    test('handles two decimals: 0.25 oz', () {
      final result = ConversionResult(quantity: 0.25, unit: MeasurementUnit.oz);
      expect(result.format(), '0.25 oz');
    });

    test('handles 100+ quantity', () {
      final result = ConversionResult(quantity: 150.0, unit: MeasurementUnit.g);
      expect(result.format(), '150 g');
    });

    test('handles 1000+ quantity', () {
      final result = ConversionResult(quantity: 2500.0, unit: MeasurementUnit.ml);
      expect(result.format(), '2500 ml');
    });
  });

  group('Preference-based conversion matrix (complete)', () {
    group('METRIC preference - volume units', () {
      test('cup → ml', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.cup, MeasurementPreference.metric), MeasurementUnit.ml);
      });

      test('tbsp → ml', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.tbsp, MeasurementPreference.metric), MeasurementUnit.ml);
      });

      test('tsp → ml', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.tsp, MeasurementPreference.metric), MeasurementUnit.ml);
      });

      test('flOz → ml', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.flOz, MeasurementPreference.metric), MeasurementUnit.ml);
      });

      test('pint → ml', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.pint, MeasurementPreference.metric), MeasurementUnit.ml);
      });

      test('quart → ml', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.quart, MeasurementPreference.metric), MeasurementUnit.ml);
      });

      test('ml stays ml', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.ml, MeasurementPreference.metric), MeasurementUnit.ml);
      });

      test('L → ml', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.l, MeasurementPreference.metric), MeasurementUnit.ml);
      });
    });

    group('METRIC preference - weight units', () {
      test('oz → g', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.oz, MeasurementPreference.metric), MeasurementUnit.g);
      });

      test('lb → g', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.lb, MeasurementPreference.metric), MeasurementUnit.g);
      });

      test('g stays g', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.g, MeasurementPreference.metric), MeasurementUnit.g);
      });

      test('kg → g', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.kg, MeasurementPreference.metric), MeasurementUnit.g);
      });
    });

    group('US preference - volume units', () {
      test('ml → cup', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.ml, MeasurementPreference.us), MeasurementUnit.cup);
      });

      test('L → cup', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.l, MeasurementPreference.us), MeasurementUnit.cup);
      });

      test('cup stays cup', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.cup, MeasurementPreference.us), MeasurementUnit.cup);
      });

      test('tbsp stays tbsp', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.tbsp, MeasurementPreference.us), MeasurementUnit.tbsp);
      });

      test('tsp stays tsp', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.tsp, MeasurementPreference.us), MeasurementUnit.tsp);
      });

      test('flOz stays flOz', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.flOz, MeasurementPreference.us), MeasurementUnit.flOz);
      });

      test('pint stays pint', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.pint, MeasurementPreference.us), MeasurementUnit.pint);
      });

      test('quart stays quart', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.quart, MeasurementPreference.us), MeasurementUnit.quart);
      });
    });

    group('US preference - weight units', () {
      test('g → oz', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.g, MeasurementPreference.us), MeasurementUnit.oz);
      });

      test('kg → oz', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.kg, MeasurementPreference.us), MeasurementUnit.oz);
      });

      test('oz stays oz', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.oz, MeasurementPreference.us), MeasurementUnit.oz);
      });

      test('lb stays lb', () {
        expect(MeasurementService.getTargetUnit(MeasurementUnit.lb, MeasurementPreference.us), MeasurementUnit.lb);
      });
    });

    group('ORIGINAL preference - all units unchanged', () {
      final allUnits = MeasurementUnit.values;
      for (final unit in allUnits) {
        test('$unit stays $unit with ORIGINAL preference', () {
          expect(MeasurementService.getTargetUnit(unit, MeasurementPreference.original), unit);
        });
      }
    });
  });
}
