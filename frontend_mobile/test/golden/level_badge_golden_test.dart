import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/level_badge.dart';

void main() {
  group('LevelBadge Golden Tests', () {
    // Note: Testing without title as it uses .tr() which requires localization setup
    // The badge colors and level text are the primary visual elements to test

    testGoldens('LevelBadge - All Level Tiers (without title)', (tester) async {
      final builder = GoldenBuilder.grid(
        columns: 3,
        widthToHeightRatio: 1.5,
      )
        ..addScenario(
          'Lv.1 Beginner',
          const LevelBadge(
            level: 1,
            levelName: 'beginner',
            showTitle: false,
          ),
        )
        ..addScenario(
          'Lv.6 HomeCook',
          const LevelBadge(
            level: 6,
            levelName: 'homeCook',
            showTitle: false,
          ),
        )
        ..addScenario(
          'Lv.11 SkilledCook',
          const LevelBadge(
            level: 11,
            levelName: 'skilledCook',
            showTitle: false,
          ),
        )
        ..addScenario(
          'Lv.16 HomeChef',
          const LevelBadge(
            level: 16,
            levelName: 'homeChef',
            showTitle: false,
          ),
        )
        ..addScenario(
          'Lv.21 ExpertChef',
          const LevelBadge(
            level: 21,
            levelName: 'expertChef',
            showTitle: false,
          ),
        )
        ..addScenario(
          'Lv.26 MasterChef',
          const LevelBadge(
            level: 26,
            levelName: 'masterChef',
            showTitle: false,
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
      );

      await screenMatchesGolden(tester, 'level_badge_all_tiers');
    });

    testGoldens('LevelBadge - Tier Boundary Levels', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Level 5 (last beginner)',
          const LevelBadge(
            level: 5,
            levelName: 'beginner',
            showTitle: false,
          ),
        )
        ..addScenario(
          'Level 10 (last homeCook)',
          const LevelBadge(
            level: 10,
            levelName: 'homeCook',
            showTitle: false,
          ),
        )
        ..addScenario(
          'Level 15 (last skilledCook)',
          const LevelBadge(
            level: 15,
            levelName: 'skilledCook',
            showTitle: false,
          ),
        )
        ..addScenario(
          'Level 20 (last homeChef)',
          const LevelBadge(
            level: 20,
            levelName: 'homeChef',
            showTitle: false,
          ),
        )
        ..addScenario(
          'Level 25 (last expertChef)',
          const LevelBadge(
            level: 25,
            levelName: 'expertChef',
            showTitle: false,
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
      );

      await screenMatchesGolden(tester, 'level_badge_tier_boundaries');
    });

    testGoldens('LevelBadge - Various Levels Within Tiers', (tester) async {
      final builder = GoldenBuilder.grid(
        columns: 5,
        widthToHeightRatio: 1.2,
      )
        ..addScenario(
          'Lv.1',
          const LevelBadge(level: 1, levelName: 'beginner', showTitle: false),
        )
        ..addScenario(
          'Lv.3',
          const LevelBadge(level: 3, levelName: 'beginner', showTitle: false),
        )
        ..addScenario(
          'Lv.7',
          const LevelBadge(level: 7, levelName: 'homeCook', showTitle: false),
        )
        ..addScenario(
          'Lv.12',
          const LevelBadge(level: 12, levelName: 'skilledCook', showTitle: false),
        )
        ..addScenario(
          'Lv.18',
          const LevelBadge(level: 18, levelName: 'homeChef', showTitle: false),
        )
        ..addScenario(
          'Lv.22',
          const LevelBadge(level: 22, levelName: 'expertChef', showTitle: false),
        )
        ..addScenario(
          'Lv.30',
          const LevelBadge(level: 30, levelName: 'masterChef', showTitle: false),
        )
        ..addScenario(
          'Lv.50',
          const LevelBadge(level: 50, levelName: 'masterChef', showTitle: false),
        )
        ..addScenario(
          'Lv.99',
          const LevelBadge(level: 99, levelName: 'masterChef', showTitle: false),
        )
        ..addScenario(
          'Lv.100',
          const LevelBadge(level: 100, levelName: 'masterChef', showTitle: false),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
      );

      await screenMatchesGolden(tester, 'level_badge_various_levels');
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
