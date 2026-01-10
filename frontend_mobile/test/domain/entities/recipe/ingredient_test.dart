import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';

void main() {
  group('Ingredient', () {
    group('hasStructuredMeasurement', () {
      test('returns true when both quantity and unit are set', () {
        final ingredient = Ingredient(
          name: 'Flour',
          quantity: 2.0,
          unit: 'cup',
          type: 'MAIN',
        );
        expect(ingredient.hasStructuredMeasurement, isTrue);
      });

      test('returns false when only quantity is set', () {
        final ingredient = Ingredient(
          name: 'Flour',
          quantity: 2.0,
          type: 'MAIN',
        );
        expect(ingredient.hasStructuredMeasurement, isFalse);
      });

      test('returns false when only unit is set', () {
        final ingredient = Ingredient(
          name: 'Flour',
          unit: 'cup',
          type: 'MAIN',
        );
        expect(ingredient.hasStructuredMeasurement, isFalse);
      });

      test('returns false when both quantity and unit are null', () {
        final ingredient = Ingredient(
          name: 'Salt',
          amount: 'a pinch',
          type: 'SEASONING',
        );
        expect(ingredient.hasStructuredMeasurement, isFalse);
      });
    });

    group('displayAmount', () {
      group('with structured measurement', () {
        test('formats whole number quantity with unit', () {
          final ingredient = Ingredient(
            name: 'Flour',
            quantity: 2.0,
            unit: 'cup',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '2 cup');
        });

        test('formats decimal quantity with unit', () {
          final ingredient = Ingredient(
            name: 'Milk',
            quantity: 1.5,
            unit: 'cup',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '1.5 cup');
        });

        test('removes trailing zeros from decimal', () {
          final ingredient = Ingredient(
            name: 'Sugar',
            quantity: 2.50,
            unit: 'g',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '2.5 g');
        });

        test('formats ml unit correctly', () {
          final ingredient = Ingredient(
            name: 'Water',
            quantity: 500.0,
            unit: 'ml',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '500 ml');
        });

        test('formats L unit correctly (uppercase)', () {
          final ingredient = Ingredient(
            name: 'Water',
            quantity: 1.0,
            unit: 'l',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '1 L');
        });

        test('formats tsp unit correctly', () {
          final ingredient = Ingredient(
            name: 'Salt',
            quantity: 1.0,
            unit: 'tsp',
            type: 'SEASONING',
          );
          expect(ingredient.displayAmount, '1 tsp');
        });

        test('formats tbsp unit correctly', () {
          final ingredient = Ingredient(
            name: 'Olive Oil',
            quantity: 2.0,
            unit: 'tbsp',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '2 tbsp');
        });

        test('formats floz unit as "fl oz"', () {
          final ingredient = Ingredient(
            name: 'Cream',
            quantity: 4.0,
            unit: 'floz',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '4 fl oz');
        });

        test('formats g unit correctly', () {
          final ingredient = Ingredient(
            name: 'Sugar',
            quantity: 100.0,
            unit: 'g',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '100 g');
        });

        test('formats kg unit correctly', () {
          final ingredient = Ingredient(
            name: 'Chicken',
            quantity: 1.5,
            unit: 'kg',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '1.5 kg');
        });

        test('formats oz unit correctly', () {
          final ingredient = Ingredient(
            name: 'Cheese',
            quantity: 8.0,
            unit: 'oz',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '8 oz');
        });

        test('formats lb unit correctly', () {
          final ingredient = Ingredient(
            name: 'Beef',
            quantity: 2.0,
            unit: 'lb',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '2 lb');
        });

        test('formats piece unit as "pc"', () {
          final ingredient = Ingredient(
            name: 'Eggs',
            quantity: 3.0,
            unit: 'piece',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '3 pc');
        });

        test('formats pinch unit correctly', () {
          final ingredient = Ingredient(
            name: 'Salt',
            quantity: 1.0,
            unit: 'pinch',
            type: 'SEASONING',
          );
          expect(ingredient.displayAmount, '1 pinch');
        });

        test('formats dash unit correctly', () {
          final ingredient = Ingredient(
            name: 'Hot Sauce',
            quantity: 2.0,
            unit: 'dash',
            type: 'SEASONING',
          );
          expect(ingredient.displayAmount, '2 dash');
        });

        test('formats totaste unit as "to taste"', () {
          final ingredient = Ingredient(
            name: 'Pepper',
            quantity: 1.0,
            unit: 'totaste',
            type: 'SEASONING',
          );
          expect(ingredient.displayAmount, '1 to taste');
        });

        test('formats clove unit correctly', () {
          final ingredient = Ingredient(
            name: 'Garlic',
            quantity: 3.0,
            unit: 'clove',
            type: 'SEASONING',
          );
          expect(ingredient.displayAmount, '3 clove');
        });

        test('formats bunch unit correctly', () {
          final ingredient = Ingredient(
            name: 'Parsley',
            quantity: 1.0,
            unit: 'bunch',
            type: 'SECONDARY',
          );
          expect(ingredient.displayAmount, '1 bunch');
        });

        test('formats can unit correctly', () {
          final ingredient = Ingredient(
            name: 'Tomatoes',
            quantity: 2.0,
            unit: 'can',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '2 can');
        });

        test('formats package unit as "pkg"', () {
          final ingredient = Ingredient(
            name: 'Pasta',
            quantity: 1.0,
            unit: 'package',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '1 pkg');
        });

        test('returns unknown unit as-is', () {
          final ingredient = Ingredient(
            name: 'Mystery',
            quantity: 5.0,
            unit: 'unknown_unit',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '5 unknown_unit');
        });
      });

      group('with legacy amount', () {
        test('returns legacy amount when no structured measurement', () {
          final ingredient = Ingredient(
            name: 'Salt',
            amount: 'a pinch',
            type: 'SEASONING',
          );
          expect(ingredient.displayAmount, 'a pinch');
        });

        test('returns empty string when no amount and no structured measurement', () {
          final ingredient = Ingredient(
            name: 'Oregano',
            type: 'SEASONING',
          );
          expect(ingredient.displayAmount, '');
        });
      });

      group('structured vs legacy priority', () {
        test('prefers structured measurement over legacy amount', () {
          final ingredient = Ingredient(
            name: 'Flour',
            amount: '2 cups (legacy)',
            quantity: 2.0,
            unit: 'cup',
            type: 'MAIN',
          );
          expect(ingredient.displayAmount, '2 cup');
        });
      });
    });
  });
}
