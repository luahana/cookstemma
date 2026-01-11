import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';

void main() {
  group('OutcomeBadge Golden Tests', () {
    // Note: Testing only header and compact variants as they don't require localization
    // Full and chip variants use localized labels which cause overflow in test environment

    testGoldens('OutcomeBadge - Header and Compact Variants for SUCCESS', (tester) async {
      final builder = GoldenBuilder.grid(
        columns: 2,
        widthToHeightRatio: 1.5,
      )
        ..addScenario(
          'compact',
          const OutcomeBadge(
            outcome: LogOutcome.success,
            variant: OutcomeBadgeVariant.compact,
          ),
        )
        ..addScenario(
          'header',
          const OutcomeBadge(
            outcome: LogOutcome.success,
            variant: OutcomeBadgeVariant.header,
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
      );

      await screenMatchesGolden(tester, 'outcome_badge_success_variants');
    });

    testGoldens('OutcomeBadge - All Outcomes (compact variant)', (tester) async {
      final builder = GoldenBuilder.grid(columns: 3, widthToHeightRatio: 1)
        ..addScenario(
          'SUCCESS',
          const OutcomeBadge(
            outcome: LogOutcome.success,
            variant: OutcomeBadgeVariant.compact,
          ),
        )
        ..addScenario(
          'PARTIAL',
          const OutcomeBadge(
            outcome: LogOutcome.partial,
            variant: OutcomeBadgeVariant.compact,
          ),
        )
        ..addScenario(
          'FAILED',
          const OutcomeBadge(
            outcome: LogOutcome.failed,
            variant: OutcomeBadgeVariant.compact,
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
      );

      await screenMatchesGolden(tester, 'outcome_badge_all_outcomes_compact');
    });

    testGoldens('OutcomeBadge - All Outcomes (header variant)', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'SUCCESS',
          const OutcomeBadge(
            outcome: LogOutcome.success,
            variant: OutcomeBadgeVariant.header,
          ),
        )
        ..addScenario(
          'PARTIAL',
          const OutcomeBadge(
            outcome: LogOutcome.partial,
            variant: OutcomeBadgeVariant.header,
          ),
        )
        ..addScenario(
          'FAILED',
          const OutcomeBadge(
            outcome: LogOutcome.failed,
            variant: OutcomeBadgeVariant.header,
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
      );

      await screenMatchesGolden(tester, 'outcome_badge_all_outcomes_header');
    });

    testGoldens('OutcomeStatsRow - Standard and Compact', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Standard - equal counts',
          const OutcomeStatsRow(
            successCount: 10,
            partialCount: 10,
            failedCount: 10,
          ),
        )
        ..addScenario(
          'Standard - varied counts',
          const OutcomeStatsRow(
            successCount: 23,
            partialCount: 8,
            failedCount: 3,
          ),
        )
        ..addScenario(
          'Compact - equal counts',
          const OutcomeStatsRow(
            successCount: 10,
            partialCount: 10,
            failedCount: 10,
            compact: true,
          ),
        )
        ..addScenario(
          'Compact - varied counts',
          const OutcomeStatsRow(
            successCount: 23,
            partialCount: 8,
            failedCount: 3,
            compact: true,
          ),
        )
        ..addScenario(
          'Standard - zero counts',
          const OutcomeStatsRow(
            successCount: 0,
            partialCount: 0,
            failedCount: 0,
          ),
        )
        ..addScenario(
          'Standard - large numbers',
          const OutcomeStatsRow(
            successCount: 999,
            partialCount: 456,
            failedCount: 123,
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
      );

      await screenMatchesGolden(tester, 'outcome_stats_row_variants');
    });
  });
}

/// Wrapper that initializes ScreenUtil for golden tests
Widget _screenUtilWrapper(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: child),
      ),
    ),
  );
}
