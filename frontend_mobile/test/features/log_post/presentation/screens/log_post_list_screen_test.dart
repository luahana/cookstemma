import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';

/// Unit tests for LogPostListScreen components.
/// Note: Full widget tests require extensive mocking of Hive, SyncQueue,
/// and other providers. These tests focus on isolated components.
void main() {
  group('LogOutcome', () {
    test('fromString returns correct outcome for SUCCESS', () {
      expect(LogOutcome.fromString('SUCCESS'), LogOutcome.success);
    });

    test('fromString returns correct outcome for PARTIAL', () {
      expect(LogOutcome.fromString('PARTIAL'), LogOutcome.partial);
    });

    test('fromString returns correct outcome for FAILED', () {
      expect(LogOutcome.fromString('FAILED'), LogOutcome.failed);
    });

    test('fromString returns null for unknown string', () {
      expect(LogOutcome.fromString('UNKNOWN'), isNull);
    });

    test('fromString handles null input', () {
      expect(LogOutcome.fromString(null), isNull);
    });

    test('fromString is case-sensitive', () {
      // fromString expects uppercase values
      expect(LogOutcome.fromString('success'), isNull);
      expect(LogOutcome.fromString('Success'), isNull);
      expect(LogOutcome.fromString('SUCCESS'), LogOutcome.success);
    });
  });

  group('OutcomeBadge', () {
    testWidgets('renders with success outcome', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutcomeBadge(outcome: LogOutcome.success),
          ),
        ),
      );

      expect(find.byType(OutcomeBadge), findsOneWidget);
    });

    testWidgets('renders with partial outcome', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutcomeBadge(outcome: LogOutcome.partial),
          ),
        ),
      );

      expect(find.byType(OutcomeBadge), findsOneWidget);
    });

    testWidgets('renders with failed outcome', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutcomeBadge(outcome: LogOutcome.failed),
          ),
        ),
      );

      expect(find.byType(OutcomeBadge), findsOneWidget);
    });

    testWidgets('renders compact variant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutcomeBadge(
              outcome: LogOutcome.success,
              variant: OutcomeBadgeVariant.compact,
            ),
          ),
        ),
      );

      expect(find.byType(OutcomeBadge), findsOneWidget);
    });
  });
}
