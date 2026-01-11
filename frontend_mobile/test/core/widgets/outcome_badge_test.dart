import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/models/log_outcome.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';

void main() {
  // Create a larger test widget to avoid overflow
  Widget createTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: UnconstrainedBox(child: child),
          ),
        ),
      ),
    );
  }

  group('OutcomeBadge', () {
    group('header variant (no localization needed)', () {
      testWidgets('should render header badge with SUCCESS text', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const OutcomeBadge(
            outcome: LogOutcome.success,
            variant: OutcomeBadgeVariant.header,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
        expect(find.text('SUCCESS'), findsOneWidget);
      });

      testWidgets('should render header badge with PARTIAL text', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const OutcomeBadge(
            outcome: LogOutcome.partial,
            variant: OutcomeBadgeVariant.header,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
        expect(find.text('PARTIAL'), findsOneWidget);
      });

      testWidgets('should render header badge with FAILED text', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const OutcomeBadge(
            outcome: LogOutcome.failed,
            variant: OutcomeBadgeVariant.header,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
        expect(find.text('FAILED'), findsOneWidget);
      });
    });

    group('compact variant (no localization needed)', () {
      testWidgets('should render compact success badge', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const OutcomeBadge(
            outcome: LogOutcome.success,
            variant: OutcomeBadgeVariant.compact,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
      });

      testWidgets('should render compact partial badge', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const OutcomeBadge(
            outcome: LogOutcome.partial,
            variant: OutcomeBadgeVariant.compact,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
      });

      testWidgets('should render compact failed badge', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const OutcomeBadge(
            outcome: LogOutcome.failed,
            variant: OutcomeBadgeVariant.compact,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
      });
    });

    // NOTE: chip variant tests require localization which is not available in test env
    // Testing chip variant interaction through unit tests of the notifier is more reliable

    group('fromString factory', () {
      testWidgets('should create badge from SUCCESS string (compact)', (tester) async {
        await tester.pumpWidget(createTestWidget(
          OutcomeBadge.fromString(
            outcomeValue: 'SUCCESS',
            variant: OutcomeBadgeVariant.compact,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
      });

      testWidgets('should create badge from PARTIAL string (compact)', (tester) async {
        await tester.pumpWidget(createTestWidget(
          OutcomeBadge.fromString(
            outcomeValue: 'PARTIAL',
            variant: OutcomeBadgeVariant.compact,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
      });

      testWidgets('should create badge from FAILED string (compact)', (tester) async {
        await tester.pumpWidget(createTestWidget(
          OutcomeBadge.fromString(
            outcomeValue: 'FAILED',
            variant: OutcomeBadgeVariant.compact,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
      });

      testWidgets('should handle null value (compact)', (tester) async {
        await tester.pumpWidget(createTestWidget(
          OutcomeBadge.fromString(
            outcomeValue: null,
            variant: OutcomeBadgeVariant.compact,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
      });

      testWidgets('should handle unknown value (compact)', (tester) async {
        await tester.pumpWidget(createTestWidget(
          OutcomeBadge.fromString(
            outcomeValue: 'UNKNOWN',
            variant: OutcomeBadgeVariant.compact,
          ),
        ));

        expect(find.byType(OutcomeBadge), findsOneWidget);
      });
    });
  });

  group('OutcomeStatsRow', () {
    testWidgets('should display all three outcome count values', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const OutcomeStatsRow(
          successCount: 10,
          partialCount: 5,
          failedCount: 2,
        ),
      ));

      expect(find.byType(OutcomeStatsRow), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('should display zero counts', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const OutcomeStatsRow(
          successCount: 0,
          partialCount: 0,
          failedCount: 0,
        ),
      ));

      expect(find.byType(OutcomeStatsRow), findsOneWidget);
      expect(find.text('0'), findsNWidgets(3));
    });

    testWidgets('should display large counts', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const OutcomeStatsRow(
          successCount: 1234,
          partialCount: 567,
          failedCount: 89,
        ),
      ));

      expect(find.text('1234'), findsOneWidget);
      expect(find.text('567'), findsOneWidget);
      expect(find.text('89'), findsOneWidget);
    });

    testWidgets('should render compact variant', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const OutcomeStatsRow(
          successCount: 10,
          partialCount: 5,
          failedCount: 2,
          compact: true,
        ),
      ));

      expect(find.byType(OutcomeStatsRow), findsOneWidget);
    });

    testWidgets('should have dividers in non-compact variant', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const OutcomeStatsRow(
          successCount: 10,
          partialCount: 5,
          failedCount: 2,
          compact: false,
        ),
      ));

      expect(find.byType(OutcomeStatsRow), findsOneWidget);
      // Non-compact has middle dot dividers between each stat
      expect(find.text('\u00B7'), findsNWidgets(2));
    });
  });

  group('OutcomeBadgeVariant enum', () {
    test('should have all expected variants', () {
      expect(OutcomeBadgeVariant.values, containsAll([
        OutcomeBadgeVariant.full,
        OutcomeBadgeVariant.compact,
        OutcomeBadgeVariant.header,
        OutcomeBadgeVariant.chip,
      ]));
      expect(OutcomeBadgeVariant.values.length, 4);
    });
  });

  group('LogOutcome colors', () {
    test('success should have green primary color', () {
      expect(LogOutcome.success.primaryColor, const Color(0xFF4CAF50));
    });

    test('success should have light green background color', () {
      expect(LogOutcome.success.backgroundColor, const Color(0xFFE8F5E9));
    });

    test('partial should have yellow primary color', () {
      expect(LogOutcome.partial.primaryColor, const Color(0xFFFFC107));
    });

    test('partial should have light yellow background color', () {
      expect(LogOutcome.partial.backgroundColor, const Color(0xFFFFF8E1));
    });

    test('failed should have red primary color', () {
      expect(LogOutcome.failed.primaryColor, const Color(0xFFF44336));
    });

    test('failed should have light red background color', () {
      expect(LogOutcome.failed.backgroundColor, const Color(0xFFFFEBEE));
    });
  });

  group('LogOutcome values', () {
    test('success value should be SUCCESS', () {
      expect(LogOutcome.success.value, 'SUCCESS');
    });

    test('partial value should be PARTIAL', () {
      expect(LogOutcome.partial.value, 'PARTIAL');
    });

    test('failed value should be FAILED', () {
      expect(LogOutcome.failed.value, 'FAILED');
    });
  });

  group('LogOutcome fromString', () {
    test('should return success for SUCCESS string', () {
      expect(LogOutcome.fromString('SUCCESS'), LogOutcome.success);
    });

    test('should return partial for PARTIAL string', () {
      expect(LogOutcome.fromString('PARTIAL'), LogOutcome.partial);
    });

    test('should return failed for FAILED string', () {
      expect(LogOutcome.fromString('FAILED'), LogOutcome.failed);
    });

    test('should return null for unknown string', () {
      expect(LogOutcome.fromString('UNKNOWN'), isNull);
    });

    test('should return null for null input', () {
      expect(LogOutcome.fromString(null), isNull);
    });
  });
}
