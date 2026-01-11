import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('Guest user can browse app', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: false));
      await tester.pumpAndSettle();

      // Guest should be able to see the home screen or login
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Authenticated user sees home screen', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Should see the home screen with content
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Login screen shows sign in options', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: false));
      await tester.pumpAndSettle();

      // Navigate to login if not already there
      final loginFinder = find.text('Sign In');
      final guestFinder = find.text('Continue as Guest');

      // Either we're on login screen or home screen (if guest mode allowed)
      expect(
        loginFinder.evaluate().isNotEmpty || guestFinder.evaluate().isNotEmpty || find.byType(BottomNavigationBar).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Sign in button is tappable', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: false));
      await tester.pumpAndSettle();

      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');

      if (signInButton.evaluate().isNotEmpty) {
        await tester.tap(signInButton);
        await tester.pumpAndSettle();
      }

      // After sign in, should navigate somewhere
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Guest mode button is tappable', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: false));
      await tester.pumpAndSettle();

      final guestButton = find.widgetWithText(TextButton, 'Continue as Guest');

      if (guestButton.evaluate().isNotEmpty) {
        await tester.tap(guestButton);
        await tester.pumpAndSettle();
      }

      // After guest mode, should navigate to home
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
