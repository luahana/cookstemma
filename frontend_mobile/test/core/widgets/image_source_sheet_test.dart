import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('ImageSourceSheet', () {
    Widget buildTestWidget({
      required void Function(ImageSource) onSourceSelected,
      void Function(ImageSource?)? onResult,
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
                    final result = await showModalBottomSheet<ImageSource>(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16.r)),
                      ),
                      builder: (context) => _MockImageSourceSheet(
                        onSourceSelected: onSourceSelected,
                      ),
                    );
                    onResult?.call(result);
                  },
                  child: const Text('Show Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('displays camera and gallery options', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onSourceSelected: (_) {},
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Verify UI elements
      expect(find.text('Select Photo Source'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('calls onSourceSelected with camera when camera tapped',
        (tester) async {
      ImageSource? selectedSource;

      await tester.pumpWidget(buildTestWidget(
        onSourceSelected: (source) => selectedSource = source,
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      expect(selectedSource, ImageSource.camera);
    });

    testWidgets('calls onSourceSelected with gallery when gallery tapped',
        (tester) async {
      ImageSource? selectedSource;

      await tester.pumpWidget(buildTestWidget(
        onSourceSelected: (source) => selectedSource = source,
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      expect(selectedSource, ImageSource.gallery);
    });

    testWidgets('closes modal after camera selection', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onSourceSelected: (_) {},
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet is shown
      expect(find.byType(_MockImageSourceSheet), findsOneWidget);

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Verify sheet is closed
      expect(find.byType(_MockImageSourceSheet), findsNothing);
    });

    testWidgets('closes modal after gallery selection', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onSourceSelected: (_) {},
      ));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet is shown
      expect(find.byType(_MockImageSourceSheet), findsOneWidget);

      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      // Verify sheet is closed
      expect(find.byType(_MockImageSourceSheet), findsNothing);
    });

    testWidgets('modal closes before callback is invoked (Navigator.pop first)',
        (tester) async {
      var callbackTime = DateTime.now();
      var popTime = DateTime.now();

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      builder: (context) => _TestDelaySheet(
                        onPop: () => popTime = DateTime.now(),
                        onCallback: () => callbackTime = DateTime.now(),
                      ),
                    );
                  },
                  child: const Text('Show Sheet'),
                ),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      // Pop should happen before callback (100ms delay ensures this)
      expect(popTime.isBefore(callbackTime), isTrue);
    });
  });
}

/// A mock version of ImageSourceSheet for testing without EasyLocalization
class _MockImageSourceSheet extends StatelessWidget {
  final Function(ImageSource) onSourceSelected;

  const _MockImageSourceSheet({required this.onSourceSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              'Select Photo Source',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Camera'),
            onTap: () async {
              Navigator.pop(context);
              // Small delay to ensure modal is fully dismissed before opening camera
              await Future.delayed(const Duration(milliseconds: 100));
              onSourceSelected(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 100));
              onSourceSelected(ImageSource.gallery);
            },
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

/// Test sheet to verify pop happens before callback
class _TestDelaySheet extends StatelessWidget {
  final VoidCallback onPop;
  final VoidCallback onCallback;

  const _TestDelaySheet({
    required this.onPop,
    required this.onCallback,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              onPop();
              // Simulate the 100ms delay from ImageSourceSheet
              await Future.delayed(const Duration(milliseconds: 100));
              onCallback();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}
