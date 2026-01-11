import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bottom Navigation', () {
    testWidgets('All navigation tabs are visible', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Should show bottom navigation with all tabs
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Recipes'), findsOneWidget);
      expect(find.text('Logs'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Can navigate to Home tab', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Tap Home tab
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Should show home content
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Can navigate to Recipes tab', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Tap Recipes tab
      await tester.tap(find.text('Recipes'));
      await tester.pumpAndSettle();

      // Should show recipes list
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Can navigate to Logs tab', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Tap Logs tab
      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();

      // Should show logs list with FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Can navigate to Profile tab', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Should show profile content
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('@testuser'), findsOneWidget);
    });

    testWidgets('Navigation persists when switching tabs', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Test User'), findsOneWidget);

      // Navigate to Recipes
      await tester.tap(find.text('Recipes'));
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsWidgets);

      // Navigate back to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('Can switch between all tabs sequentially', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Recipes
      await tester.tap(find.text('Recipes'));
      await tester.pumpAndSettle();

      // Logs
      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();

      // Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Should be on home tab
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Logs Screen', () {
    testWidgets('Shows cooking log entries', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to Logs
      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();

      // Should show log entries
      expect(find.byType(Card), findsWidgets);
      expect(find.textContaining('Log Entry'), findsWidgets);
    });

    testWidgets('Shows FAB for creating new log', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to Logs
      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();

      // Should show FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Shows outcome emojis in log entries', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to Logs
      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle();

      // Should show emoji indicators in CircleAvatars
      expect(find.byType(CircleAvatar), findsWidgets);
    });
  });

  group('Profile Screen', () {
    testWidgets('Shows user info', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Should show user info
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('@testuser'), findsOneWidget);
    });

    testWidgets('Shows user stats', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Should show stats
      expect(find.text('Recipes'), findsOneWidget);
      expect(find.text('Logs'), findsOneWidget);
      expect(find.text('Followers'), findsOneWidget);
    });

    testWidgets('Shows settings button', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Should show settings icon
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('Shows user grid of content', (tester) async {
      await tester.pumpWidget(const TestApp(startAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Should show grid
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
