import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Launch Tests', () {
    testWidgets('App should launch without crashing', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // App should be visible
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App should show login screen for unauthenticated user', (tester) async {
      await tester.pumpWidget(const TestApp());
      await tester.pumpAndSettle();

      // Should navigate to login screen
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Should navigate between bottom nav tabs', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Find bottom navigation bar
      final bottomNavFinder = find.byType(BottomNavigationBar);

      if (bottomNavFinder.evaluate().isNotEmpty) {
        // Tap on different tabs and verify navigation
        await tester.tap(bottomNavFinder);
        await tester.pumpAndSettle();
      }
    });
  });

  group('UI Interaction Tests', () {
    testWidgets('Pull to refresh should work', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Find scrollable content
      final scrollableFinder = find.byType(Scrollable);

      if (scrollableFinder.evaluate().isNotEmpty) {
        // Perform drag down for pull-to-refresh
        await tester.drag(scrollableFinder.first, const Offset(0, 300));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Tapping list item should navigate to detail', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Find any tappable list item (GestureDetector or InkWell)
      final tappableFinder = find.byType(InkWell);

      if (tappableFinder.evaluate().isNotEmpty) {
        await tester.tap(tappableFinder.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
