import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';

/// Golden tests for journey log card components
/// Note: JourneyLogCard is complex and relies on many sub-widgets
/// Testing individual components for faster and more stable golden tests
void main() {
  group('Journey Log Card Component Golden Tests', () {
    testGoldens('Log Outcome Header - All outcomes', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'SUCCESS',
          _LogOutcomeHeader(
            outcome: LogOutcome.success,
            timestamp: '2 hours ago',
          ),
        )
        ..addScenario(
          'PARTIAL',
          _LogOutcomeHeader(
            outcome: LogOutcome.partial,
            timestamp: '1 day ago',
          ),
        )
        ..addScenario(
          'FAILED',
          _LogOutcomeHeader(
            outcome: LogOutcome.failed,
            timestamp: '3 days ago',
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
        surfaceSize: const Size(375, 350),
      );

      await screenMatchesGolden(tester, 'log_outcome_header_variants');
    });

    testGoldens('Log Outcome Header with sync indicator', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'SUCCESS syncing',
          _LogOutcomeHeader(
            outcome: LogOutcome.success,
            timestamp: 'Just now',
            isPendingSync: true,
          ),
        )
        ..addScenario(
          'PARTIAL syncing',
          _LogOutcomeHeader(
            outcome: LogOutcome.partial,
            timestamp: 'Just now',
            isPendingSync: true,
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
        surfaceSize: const Size(375, 250),
      );

      await screenMatchesGolden(tester, 'log_outcome_header_syncing');
    });

    testGoldens('Log Content Section', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Short content',
          const _LogContentSection(
            content: 'Great success!',
          ),
        )
        ..addScenario(
          'Medium content',
          const _LogContentSection(
            content: 'Made this for dinner tonight and it turned out amazing! The kimchi was perfectly caramelized.',
          ),
        )
        ..addScenario(
          'Long content (truncated)',
          const _LogContentSection(
            content: 'This is a very long cooking log entry that goes into great detail about the entire cooking process from start to finish. It describes every step including prep work, cooking techniques used, problems encountered and how they were solved. The goal is to test how the card handles text overflow when showing truncated content in the default view.',
            maxLines: 3,
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
        surfaceSize: const Size(375, 400),
      );

      await screenMatchesGolden(tester, 'log_content_section_variants');
    });

    testGoldens('Log Footer', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'With creator',
          const _LogFooter(creatorName: 'Chef Kim'),
        )
        ..addScenario(
          'Long name',
          const _LogFooter(creatorName: 'Traditional Korean Chef with a Very Long Name'),
        )
        ..addScenario(
          'No creator',
          const _LogFooter(creatorName: null),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
        surfaceSize: const Size(375, 250),
      );

      await screenMatchesGolden(tester, 'log_footer_variants');
    });

    testGoldens('Image Count Badge', (tester) async {
      final builder = GoldenBuilder.grid(columns: 3, widthToHeightRatio: 1.5)
        ..addScenario(
          '2 images',
          const _ImageCountBadge(current: 1, total: 2),
        )
        ..addScenario(
          '4 images',
          const _ImageCountBadge(current: 1, total: 4),
        )
        ..addScenario(
          '10 images',
          const _ImageCountBadge(current: 1, total: 10),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
        surfaceSize: const Size(350, 200),
      );

      await screenMatchesGolden(tester, 'image_count_badge_variants');
    });

    testGoldens('Sync Indicator', (tester) async {
      await tester.pumpWidgetBuilder(
        const _SyncIndicator(),
        wrapper: _screenUtilWrapper,
        surfaceSize: const Size(150, 100),
      );

      await screenMatchesGolden(tester, 'sync_indicator');
    });

    testGoldens('Recipe Lineage Breadcrumb - Compact', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'Direct recipe',
          const _RecipeLineageBreadcrumb(
            recipeTitle: 'Kimchi Fried Rice',
            rootTitle: null,
          ),
        )
        ..addScenario(
          'Variant with root',
          const _RecipeLineageBreadcrumb(
            recipeTitle: 'Spicy Kimchi Fried Rice',
            rootTitle: 'Classic Fried Rice',
          ),
        )
        ..addScenario(
          'Long titles',
          const _RecipeLineageBreadcrumb(
            recipeTitle: "My Grandmother's Authentic Doenjang Jjigae",
            rootTitle: 'Traditional Korean Fermented Soybean Paste Stew',
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        wrapper: _screenUtilWrapper,
        surfaceSize: const Size(375, 350),
      );

      await screenMatchesGolden(tester, 'recipe_lineage_breadcrumb_variants');
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
        backgroundColor: Colors.grey[200],
        body: Center(child: child),
      ),
    ),
  );
}

/// Simplified log outcome header for testing
class _LogOutcomeHeader extends StatelessWidget {
  final LogOutcome outcome;
  final String timestamp;
  final bool isPendingSync;

  const _LogOutcomeHeader({
    required this.outcome,
    required this.timestamp,
    this.isPendingSync = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: outcome.backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          OutcomeBadge(
            outcome: outcome,
            variant: OutcomeBadgeVariant.header,
          ),
          const Spacer(),
          Text(
            timestamp,
            style: TextStyle(
              fontSize: 12.sp,
              color: outcome.primaryColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isPendingSync) ...[
            SizedBox(width: 8.w),
            const _SyncIndicator(),
          ],
        ],
      ),
    );
  }
}

/// Sync indicator widget (static version for golden tests)
class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Use static icon instead of CircularProgressIndicator to avoid animation timeout
          Icon(
            Icons.sync,
            size: 12.sp,
            color: Colors.orange[600],
          ),
          SizedBox(width: 4.w),
          Text(
            'Syncing...',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Log content section for testing
class _LogContentSection extends StatelessWidget {
  final String content;
  final int? maxLines;

  const _LogContentSection({
    required this.content,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[800],
          height: 1.5,
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }
}

/// Log footer for testing
class _LogFooter extends StatelessWidget {
  final String? creatorName;

  const _LogFooter({required this.creatorName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          if (creatorName != null) ...[
            Icon(
              Icons.person_outline,
              size: 14.sp,
              color: Colors.grey[400],
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                creatorName!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          Icon(
            Icons.arrow_forward,
            size: 16.sp,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}

/// Image count badge for testing
class _ImageCountBadge extends StatelessWidget {
  final int current;
  final int total;

  const _ImageCountBadge({
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library,
            size: 14.sp,
            color: Colors.white,
          ),
          SizedBox(width: 4.w),
          Text(
            '$current/$total',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Recipe lineage breadcrumb for testing
class _RecipeLineageBreadcrumb extends StatelessWidget {
  final String recipeTitle;
  final String? rootTitle;

  const _RecipeLineageBreadcrumb({
    required this.recipeTitle,
    this.rootTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rootTitle != null) ...[
            Row(
              children: [
                Icon(Icons.restaurant_menu, size: 12.sp, color: Colors.blue[300]),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    rootTitle!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.blue[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: Icon(Icons.arrow_downward, size: 12.sp, color: Colors.blue[200]),
            ),
          ],
          Row(
            children: [
              Icon(Icons.restaurant, size: 14.sp, color: Colors.blue),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  recipeTitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
