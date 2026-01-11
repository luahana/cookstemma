import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pairing_planet2_frontend/core/widgets/stat_badge.dart';

/// Golden tests for recipe card components
/// Note: EnhancedRecipeCard is complex and relies on many sub-widgets
/// Testing individual components for faster and more stable golden tests
void main() {
  group('Recipe Card Component Golden Tests', () {
    testGoldens('StatBadge - All variants', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Icon + Count',
          const StatBadge(
            icon: Icons.call_split,
            count: 5,
            label: 'variants',
          ),
        )
        ..addScenario(
          'High Count',
          const StatBadge(
            icon: Icons.edit_note,
            count: 999,
            label: 'logs',
          ),
        )
        ..addScenario(
          'Zero Count',
          const StatBadge(
            icon: Icons.favorite,
            count: 0,
            label: 'likes',
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
      );

      await screenMatchesGolden(tester, 'stat_badge_variants');
    });

    testGoldens('Recipe Type Badge - Original', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidgetBuilder(
          _RecipeTypeBadge(isOriginal: true),
          wrapper: _screenUtilWrapper,
          surfaceSize: const Size(200, 100),
        );

        await screenMatchesGolden(tester, 'recipe_type_badge_original');
      });
    });

    testGoldens('Recipe Type Badge - Variant', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidgetBuilder(
          _RecipeTypeBadge(isOriginal: false),
          wrapper: _screenUtilWrapper,
          surfaceSize: const Size(200, 100),
        );

        await screenMatchesGolden(tester, 'recipe_type_badge_variant');
      });
    });

    testGoldens('Recipe Title Section', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Normal',
          const _RecipeTitleSection(
            foodName: 'Kimchi Fried Rice',
            title: "Grandma's Secret Recipe",
          ),
        )
        ..addScenario(
          'Long Title',
          const _RecipeTitleSection(
            foodName: 'Traditional Korean Fermented Soybean Paste',
            title: "My Grandmother's Authentic Doenjang Jjigae with Extra Tofu",
          ),
        )
        ..addScenario(
          'Short Title',
          const _RecipeTitleSection(
            foodName: 'Rice',
            title: 'Basic',
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
        surfaceSize: const Size(350, 400),
      );

      await screenMatchesGolden(tester, 'recipe_title_section_variants');
    });

    testGoldens('Recipe Creator Row', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Normal Name',
          const _CreatorRow(creatorName: 'Chef Kim'),
        )
        ..addScenario(
          'Long Name',
          const _CreatorRow(creatorName: 'Traditional Korean Chef with a Very Long Name'),
        )
        ..addScenario(
          'Short Name',
          const _CreatorRow(creatorName: 'Lee'),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
        surfaceSize: const Size(350, 300),
      );

      await screenMatchesGolden(tester, 'recipe_creator_row_variants');
    });

    testGoldens('Recipe Stats Row', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Normal Stats',
          const _StatsRow(variantCount: 5, logCount: 23),
        )
        ..addScenario(
          'Zero Stats',
          const _StatsRow(variantCount: 0, logCount: 0),
        )
        ..addScenario(
          'High Stats',
          const _StatsRow(variantCount: 999, logCount: 9999),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
        surfaceSize: const Size(350, 300),
      );

      await screenMatchesGolden(tester, 'recipe_stats_row_variants');
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

/// Simplified recipe type badge for testing
class _RecipeTypeBadge extends StatelessWidget {
  final bool isOriginal;

  const _RecipeTypeBadge({required this.isOriginal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isOriginal ? Colors.grey[800] : Colors.blue,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isOriginal ? '🌱' : '🔀',
            style: TextStyle(fontSize: 11.sp),
          ),
          SizedBox(width: 4.w),
          Text(
            isOriginal ? 'Original' : 'Variant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simplified recipe title section for testing
class _RecipeTitleSection extends StatelessWidget {
  final String foodName;
  final String title;

  const _RecipeTitleSection({
    required this.foodName,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          foodName,
          style: TextStyle(
            color: Colors.blue,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Simplified creator row for testing
class _CreatorRow extends StatelessWidget {
  final String creatorName;

  const _CreatorRow({required this.creatorName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.person_outline,
          size: 16.sp,
          color: Colors.grey[400],
        ),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            creatorName,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Simplified stats row for testing
class _StatsRow extends StatelessWidget {
  final int variantCount;
  final int logCount;

  const _StatsRow({
    required this.variantCount,
    required this.logCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatBadge(
          icon: Icons.call_split,
          count: variantCount,
          label: 'variants',
        ),
        SizedBox(width: 12.w),
        StatBadge(
          icon: Icons.edit_note,
          count: logCount,
          label: 'logs',
        ),
      ],
    );
  }
}
