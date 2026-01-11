import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';

/// Wraps a widget with required providers for testing.
/// Use this for widget tests that need Riverpod providers.
Widget createTestableWidget({
  required Widget child,
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    ),
  );
}

/// Wraps a widget with Material app for basic widget tests.
Widget createMaterialTestWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

/// Pumps a widget and waits for all animations to complete.
Future<void> pumpAndSettleWidget(
  WidgetTester tester,
  Widget widget, {
  Duration? duration,
}) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 100));
}

/// Extension on WidgetTester for common test operations.
extension WidgetTesterExtensions on WidgetTester {
  /// Finds and taps a widget by key.
  Future<void> tapByKey(Key key) async {
    await tap(find.byKey(key));
    await pumpAndSettle();
  }

  /// Finds and taps a widget by type.
  Future<void> tapByType(Type type) async {
    await tap(find.byType(type));
    await pumpAndSettle();
  }

  /// Enters text into a TextField by key.
  Future<void> enterTextByKey(Key key, String text) async {
    await enterText(find.byKey(key), text);
    await pumpAndSettle();
  }

  /// Scrolls until a widget is visible.
  Future<void> scrollUntilVisible(
    Finder finder, {
    double delta = 300,
    int maxScrolls = 50,
  }) async {
    int scrollCount = 0;
    while (finder.evaluate().isEmpty && scrollCount < maxScrolls) {
      await drag(find.byType(Scrollable).first, Offset(0, -delta));
      await pumpAndSettle();
      scrollCount++;
    }
  }
}
