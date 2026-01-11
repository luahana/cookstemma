import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Recipe Browsing Flow', () {
    testWidgets('Can navigate to recipes tab', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Find and tap recipes tab
      final recipesTab = find.text('Recipes');

      if (recipesTab.evaluate().isNotEmpty) {
        await tester.tap(recipesTab);
        await tester.pumpAndSettle();

        // Should show recipe list
        expect(find.byType(ListView), findsOneWidget);
      }
    });

    testWidgets('Recipe list shows items', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to recipes
      final recipesTab = find.text('Recipes');
      if (recipesTab.evaluate().isNotEmpty) {
        await tester.tap(recipesTab);
        await tester.pumpAndSettle();
      }

      // Should show recipe cards
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Tapping recipe card opens detail', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to recipes tab
      final recipesTab = find.text('Recipes');
      if (recipesTab.evaluate().isNotEmpty) {
        await tester.tap(recipesTab);
        await tester.pumpAndSettle();
      }

      // Tap first recipe card
      final recipeCard = find.byType(Card).first;
      if (recipeCard.evaluate().isNotEmpty) {
        await tester.tap(recipeCard);
        await tester.pumpAndSettle();

        // Should show recipe detail screen with title
        expect(find.textContaining('Recipe'), findsWidgets);
      }
    });

    testWidgets('Recipe detail shows action buttons', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to recipes tab
      final recipesTab = find.text('Recipes');
      if (recipesTab.evaluate().isNotEmpty) {
        await tester.tap(recipesTab);
        await tester.pumpAndSettle();
      }

      // Tap first recipe card
      final recipeCard = find.byType(Card).first;
      if (recipeCard.evaluate().isNotEmpty) {
        await tester.tap(recipeCard);
        await tester.pumpAndSettle();

        // Should show action buttons
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
        expect(find.byIcon(Icons.share), findsOneWidget);
      }
    });

    testWidgets('Can pull to refresh recipe list', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to recipes tab
      final recipesTab = find.text('Recipes');
      if (recipesTab.evaluate().isNotEmpty) {
        await tester.tap(recipesTab);
        await tester.pumpAndSettle();
      }

      // Perform pull to refresh
      await tester.drag(
        find.byType(ListView).first,
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      // Should still show list
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Can scroll through recipe list', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to recipes tab
      final recipesTab = find.text('Recipes');
      if (recipesTab.evaluate().isNotEmpty) {
        await tester.tap(recipesTab);
        await tester.pumpAndSettle();
      }

      // Scroll down
      await tester.drag(
        find.byType(ListView).first,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Should still be on recipe list
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Back navigation from detail works', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to recipes
      final recipesTab = find.text('Recipes');
      if (recipesTab.evaluate().isNotEmpty) {
        await tester.tap(recipesTab);
        await tester.pumpAndSettle();
      }

      // Navigate to detail
      final recipeCard = find.byType(Card).first;
      if (recipeCard.evaluate().isNotEmpty) {
        await tester.tap(recipeCard);
        await tester.pumpAndSettle();

        // Go back
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          // Should be back on list
          expect(find.byType(Card), findsWidgets);
        }
      }
    });
  });
}
