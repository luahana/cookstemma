import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';
import 'package:pairing_planet2_frontend/core/services/measurement_service.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/ingredient_dto.dart';

void main() {
  group('Ingredient Entity', () {
    group('hasStructuredMeasurement', () {
      test('returns true when both quantity and unit are provided', () {
        final ingredient = Ingredient(
          name: 'Sugar',
          quantity: 2.5,
          unit: 'cup',
          type: 'MAIN',
        );

        expect(ingredient.hasStructuredMeasurement, isTrue);
      });

      test('returns false when quantity is null', () {
        final ingredient = Ingredient(
          name: 'Sugar',
          unit: 'cup',
          type: 'MAIN',
        );

        expect(ingredient.hasStructuredMeasurement, isFalse);
      });

      test('returns false when unit is null', () {
        final ingredient = Ingredient(
          name: 'Sugar',
          quantity: 2.5,
          type: 'MAIN',
        );

        expect(ingredient.hasStructuredMeasurement, isFalse);
      });

      test('returns false when using legacy amount field only', () {
        final ingredient = Ingredient(
          name: 'Sugar',
          amount: '2 cups',
          type: 'MAIN',
        );

        expect(ingredient.hasStructuredMeasurement, isFalse);
      });
    });

    group('displayAmount', () {
      test('formats structured measurement with whole number', () {
        final ingredient = Ingredient(
          name: 'Flour',
          quantity: 2.0,
          unit: 'cup',
          type: 'MAIN',
        );

        expect(ingredient.displayAmount, '2 cup');
      });

      test('formats structured measurement with decimal', () {
        final ingredient = Ingredient(
          name: 'Salt',
          quantity: 1.5,
          unit: 'tsp',
          type: 'SEASONING',
        );

        expect(ingredient.displayAmount, '1.5 tsp');
      });

      test('removes trailing zeros from decimal', () {
        final ingredient = Ingredient(
          name: 'Water',
          quantity: 2.50,
          unit: 'l',
          type: 'MAIN',
        );

        expect(ingredient.displayAmount, '2.5 L');
      });

      test('returns legacy amount when no structured measurement', () {
        final ingredient = Ingredient(
          name: 'Garlic',
          amount: 'a pinch',
          type: 'SEASONING',
        );

        expect(ingredient.displayAmount, 'a pinch');
      });

      test('returns empty string when no amount data', () {
        final ingredient = Ingredient(
          name: 'Oregano',
          type: 'SEASONING',
        );

        expect(ingredient.displayAmount, '');
      });
    });

    group('unit formatting', () {
      test('formats ml correctly', () {
        final ingredient = Ingredient(
          name: 'Water',
          quantity: 100,
          unit: 'ml',
          type: 'MAIN',
        );
        expect(ingredient.displayAmount, '100 ml');
      });

      test('formats L correctly', () {
        final ingredient = Ingredient(
          name: 'Water',
          quantity: 2,
          unit: 'l',
          type: 'MAIN',
        );
        expect(ingredient.displayAmount, '2 L');
      });

      test('formats floz as fl oz', () {
        final ingredient = Ingredient(
          name: 'Milk',
          quantity: 4,
          unit: 'floz',
          type: 'MAIN',
        );
        expect(ingredient.displayAmount, '4 fl oz');
      });

      test('formats piece as pc', () {
        final ingredient = Ingredient(
          name: 'Eggs',
          quantity: 3,
          unit: 'piece',
          type: 'MAIN',
        );
        expect(ingredient.displayAmount, '3 pc');
      });

      test('formats toTaste correctly', () {
        final ingredient = Ingredient(
          name: 'Salt',
          quantity: 1,
          unit: 'totaste',
          type: 'SEASONING',
        );
        expect(ingredient.displayAmount, '1 to taste');
      });
    });
  });

  group('MeasurementService', () {
    group('convert', () {
      test('returns null for null inputs', () {
        expect(MeasurementService.convert(null, MeasurementUnit.cup, MeasurementUnit.ml), isNull);
        expect(MeasurementService.convert(2.0, null, MeasurementUnit.ml), isNull);
        expect(MeasurementService.convert(2.0, MeasurementUnit.cup, null), isNull);
      });

      test('returns same value for same unit', () {
        expect(
          MeasurementService.convert(2.0, MeasurementUnit.cup, MeasurementUnit.cup),
          2.0,
        );
      });

      test('converts cups to ml correctly', () {
        // 1 cup = 240 ml
        expect(
          MeasurementService.convert(1.0, MeasurementUnit.cup, MeasurementUnit.ml),
          240.0,
        );
      });

      test('converts ml to cups correctly', () {
        // 240 ml = 1 cup
        expect(
          MeasurementService.convert(240.0, MeasurementUnit.ml, MeasurementUnit.cup),
          1.0,
        );
      });

      test('converts tsp to tbsp correctly', () {
        // 3 tsp = 1 tbsp (15ml / 5ml)
        expect(
          MeasurementService.convert(3.0, MeasurementUnit.tsp, MeasurementUnit.tbsp),
          1.0,
        );
      });

      test('converts g to kg correctly', () {
        expect(
          MeasurementService.convert(1000.0, MeasurementUnit.g, MeasurementUnit.kg),
          1.0,
        );
      });

      test('converts oz to g correctly', () {
        // 1 oz = 28.35 g
        expect(
          MeasurementService.convert(1.0, MeasurementUnit.oz, MeasurementUnit.g),
          28.35,
        );
      });

      test('returns null for volume to weight conversion', () {
        expect(
          MeasurementService.convert(1.0, MeasurementUnit.cup, MeasurementUnit.g),
          isNull,
        );
      });

      test('returns null for weight to volume conversion', () {
        expect(
          MeasurementService.convert(100.0, MeasurementUnit.g, MeasurementUnit.cup),
          isNull,
        );
      });
    });

    group('getTargetUnit', () {
      test('returns original unit for original preference', () {
        expect(
          MeasurementService.getTargetUnit(
            MeasurementUnit.cup,
            MeasurementPreference.original,
          ),
          MeasurementUnit.cup,
        );
      });

      test('returns ml for metric preference with volume', () {
        expect(
          MeasurementService.getTargetUnit(
            MeasurementUnit.cup,
            MeasurementPreference.metric,
          ),
          MeasurementUnit.ml,
        );
      });

      test('returns g for metric preference with weight', () {
        expect(
          MeasurementService.getTargetUnit(
            MeasurementUnit.oz,
            MeasurementPreference.metric,
          ),
          MeasurementUnit.g,
        );
      });

      test('returns cup for US preference with ml', () {
        expect(
          MeasurementService.getTargetUnit(
            MeasurementUnit.ml,
            MeasurementPreference.us,
          ),
          MeasurementUnit.cup,
        );
      });

      test('returns oz for US preference with g', () {
        expect(
          MeasurementService.getTargetUnit(
            MeasurementUnit.g,
            MeasurementPreference.us,
          ),
          MeasurementUnit.oz,
        );
      });

      test('keeps count units unchanged for metric', () {
        expect(
          MeasurementService.getTargetUnit(
            MeasurementUnit.piece,
            MeasurementPreference.metric,
          ),
          MeasurementUnit.piece,
        );
      });

      test('keeps count units unchanged for US', () {
        expect(
          MeasurementService.getTargetUnit(
            MeasurementUnit.piece,
            MeasurementPreference.us,
          ),
          MeasurementUnit.piece,
        );
      });
    });

    group('convertForPreference', () {
      test('returns original for original preference', () {
        final result = MeasurementService.convertForPreference(
          240.0,
          MeasurementUnit.ml,
          MeasurementPreference.original,
        );

        expect(result.quantity, 240.0);
        expect(result.unit, MeasurementUnit.ml);
      });

      test('converts ml to cup for US preference', () {
        final result = MeasurementService.convertForPreference(
          240.0,
          MeasurementUnit.ml,
          MeasurementPreference.us,
        );

        expect(result.quantity, 1.0);
        expect(result.unit, MeasurementUnit.cup);
      });

      test('converts cups to ml for metric preference', () {
        final result = MeasurementService.convertForPreference(
          1.0,
          MeasurementUnit.cup,
          MeasurementPreference.metric,
        );

        expect(result.quantity, 240.0);
        expect(result.unit, MeasurementUnit.ml);
      });
    });

    group('ConversionResult', () {
      test('isConverted returns true when both values present', () {
        final result = ConversionResult(quantity: 2.0, unit: MeasurementUnit.cup);
        expect(result.isConverted, isTrue);
      });

      test('isConverted returns false when quantity is null', () {
        final result = ConversionResult(unit: MeasurementUnit.cup);
        expect(result.isConverted, isFalse);
      });

      test('format returns formatted string', () {
        final result = ConversionResult(quantity: 2.5, unit: MeasurementUnit.cup);
        expect(result.format(), '2.5 cup');
      });

      test('format returns empty string when not converted', () {
        final result = ConversionResult();
        expect(result.format(), '');
      });

      test('format removes trailing zeros', () {
        final result = ConversionResult(quantity: 2.0, unit: MeasurementUnit.cup);
        expect(result.format(), '2 cup');
      });
    });

    group('getUnitLabel', () {
      test('returns correct labels for all units', () {
        expect(MeasurementService.getUnitLabel(MeasurementUnit.ml), 'ml');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.l), 'L');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.tsp), 'tsp');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.tbsp), 'tbsp');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.cup), 'cup');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.flOz), 'fl oz');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.g), 'g');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.kg), 'kg');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.oz), 'oz');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.lb), 'lb');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.piece), 'pc');
        expect(MeasurementService.getUnitLabel(MeasurementUnit.toTaste), 'to taste');
      });
    });

    group('unit categories', () {
      test('volumeUnits contains correct units', () {
        final volumeUnits = MeasurementService.volumeUnits;
        expect(volumeUnits, contains(MeasurementUnit.ml));
        expect(volumeUnits, contains(MeasurementUnit.cup));
        expect(volumeUnits, contains(MeasurementUnit.tsp));
        expect(volumeUnits, isNot(contains(MeasurementUnit.g)));
      });

      test('weightUnits contains correct units', () {
        final weightUnits = MeasurementService.weightUnits;
        expect(weightUnits, contains(MeasurementUnit.g));
        expect(weightUnits, contains(MeasurementUnit.oz));
        expect(weightUnits, isNot(contains(MeasurementUnit.cup)));
      });

      test('countUnits contains correct units', () {
        final countUnits = MeasurementService.countUnits;
        expect(countUnits, contains(MeasurementUnit.piece));
        expect(countUnits, contains(MeasurementUnit.pinch));
        expect(countUnits, isNot(contains(MeasurementUnit.cup)));
        expect(countUnits, isNot(contains(MeasurementUnit.g)));
      });
    });
  });

  group('Ingredient Grouping Logic', () {
    test('groups ingredients by type correctly', () {
      final ingredients = [
        Ingredient(name: 'Flour', type: 'MAIN'),
        Ingredient(name: 'Butter', type: 'MAIN'),
        Ingredient(name: 'Onion', type: 'SECONDARY'),
        Ingredient(name: 'Salt', type: 'SEASONING'),
        Ingredient(name: 'Pepper', type: 'SEASONING'),
      ];

      final mainIngredients =
          ingredients.where((i) => i.type == 'MAIN').toList();
      final secondaryIngredients =
          ingredients.where((i) => i.type == 'SECONDARY').toList();
      final seasoningIngredients =
          ingredients.where((i) => i.type == 'SEASONING').toList();

      expect(mainIngredients, hasLength(2));
      expect(secondaryIngredients, hasLength(1));
      expect(seasoningIngredients, hasLength(2));
    });

    test('handles empty ingredient groups', () {
      final ingredients = [
        Ingredient(name: 'Salt', type: 'SEASONING'),
      ];

      final mainIngredients =
          ingredients.where((i) => i.type == 'MAIN').toList();
      final secondaryIngredients =
          ingredients.where((i) => i.type == 'SECONDARY').toList();

      expect(mainIngredients, isEmpty);
      expect(secondaryIngredients, isEmpty);
    });
  });
}
