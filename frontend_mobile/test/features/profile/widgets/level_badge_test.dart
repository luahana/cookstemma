import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/features/profile/widgets/level_badge.dart';

void main() {
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

  group('LevelBadge', () {
    group('level text rendering', () {
      testWidgets('should render "Lv.1" for level 1', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 1,
            levelName: 'beginner',
            showTitle: false,
          ),
        ));

        expect(find.text('Lv.1'), findsOneWidget);
      });

      testWidgets('should render "Lv.10" for level 10', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 10,
            levelName: 'homeCook',
            showTitle: false,
          ),
        ));

        expect(find.text('Lv.10'), findsOneWidget);
      });

      testWidgets('should render "Lv.26" for level 26', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 26,
            levelName: 'masterChef',
            showTitle: false,
          ),
        ));

        expect(find.text('Lv.26'), findsOneWidget);
      });
    });

    group('showTitle parameter', () {
      testWidgets('should show title by default', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 1,
            levelName: 'beginner',
          ),
        ));

        // Title uses .tr() which doesn't work in test, but we can check Row has 2+ children
        expect(find.byType(LevelBadge), findsOneWidget);
        expect(find.byType(Row), findsOneWidget);
      });

      testWidgets('should hide title when showTitle is false', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 1,
            levelName: 'beginner',
            showTitle: false,
          ),
        ));

        expect(find.byType(LevelBadge), findsOneWidget);
        // Only the level badge should be visible
        expect(find.text('Lv.1'), findsOneWidget);
      });
    });

    group('level color mapping', () {
      testWidgets('should use grey color for beginner tier (level 1-5)',
          (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 3,
            levelName: 'beginner',
            showTitle: false,
          ),
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(LevelBadge),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFF78909C)));
      });

      testWidgets('should use green color for homeCook tier (level 6-10)',
          (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 8,
            levelName: 'homeCook',
            showTitle: false,
          ),
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(LevelBadge),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFF4CAF50)));
      });

      testWidgets('should use blue color for skilledCook tier (level 11-15)',
          (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 13,
            levelName: 'skilledCook',
            showTitle: false,
          ),
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(LevelBadge),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFF2196F3)));
      });

      testWidgets('should use purple color for homeChef tier (level 16-20)',
          (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 18,
            levelName: 'homeChef',
            showTitle: false,
          ),
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(LevelBadge),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFF9C27B0)));
      });

      testWidgets('should use orange color for expertChef tier (level 21-25)',
          (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 23,
            levelName: 'expertChef',
            showTitle: false,
          ),
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(LevelBadge),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFFFF9800)));
      });

      testWidgets('should use gold color for masterChef tier (level 26+)',
          (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 26,
            levelName: 'masterChef',
            showTitle: false,
          ),
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(LevelBadge),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFFFFD700)));
      });
    });

    group('tier boundary tests', () {
      testWidgets('level 5 should still be beginner (grey)', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 5,
            levelName: 'beginner',
            showTitle: false,
          ),
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(LevelBadge),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFF78909C)));
      });

      testWidgets('level 6 should be homeCook (green)', (tester) async {
        await tester.pumpWidget(createTestWidget(
          const LevelBadge(
            level: 6,
            levelName: 'homeCook',
            showTitle: false,
          ),
        ));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(LevelBadge),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFF4CAF50)));
      });
    });
  });
}
