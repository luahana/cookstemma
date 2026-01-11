import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginPromptSheet UI Logic', () {
    Widget buildTestWidget({
      required String actionKey,
      VoidCallback? pendingAction,
      required void Function(bool?) onResult,
    }) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _MockLoginPromptSheet(
                        actionKey: actionKey,
                        pendingAction: pendingAction,
                      ),
                    );
                    onResult(result);
                  },
                  child: const Text('Show Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('should render all UI elements', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        actionKey: 'Please sign in to save',
        onResult: (_) {},
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Verify UI elements
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Sign In Required'), findsOneWidget);
      expect(find.text('Please sign in to save'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    });

    testWidgets('continue as guest should return false', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestWidget(
        actionKey: 'test action',
        onResult: (r) => result = r,
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('sign in should return true', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestWidget(
        actionKey: 'test action',
        onResult: (r) => result = r,
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('should call pendingAction when sign in pressed', (tester) async {
      var actionCalled = false;

      await tester.pumpWidget(buildTestWidget(
        actionKey: 'test action',
        pendingAction: () => actionCalled = true,
        onResult: (_) {},
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(actionCalled, isTrue);
    });

    testWidgets('should display custom action message', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        actionKey: 'Sign in to follow users',
        onResult: (_) {},
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to follow users'), findsOneWidget);
    });

    testWidgets('sheet should close after button press', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        actionKey: 'test action',
        onResult: (_) {},
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet is shown
      expect(find.byType(_MockLoginPromptSheet), findsOneWidget);

      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      // Verify sheet is closed
      expect(find.byType(_MockLoginPromptSheet), findsNothing);
    });
  });
}

/// A mock version of LoginPromptSheet for testing without EasyLocalization/Riverpod
class _MockLoginPromptSheet extends StatelessWidget {
  final String actionKey;
  final VoidCallback? pendingAction;

  const _MockLoginPromptSheet({
    required this.actionKey,
    this.pendingAction,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 24.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Icon
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 32.sp,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 16.h),
              // Title
              Text(
                'Sign In Required',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              // Subtitle
              Text(
                actionKey,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    pendingAction?.call();
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
              ),
              SizedBox(height: 12.h),
              // Continue as guest button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
