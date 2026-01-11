import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

/// Global test configuration for Flutter tests.
/// This file is automatically loaded by the test framework.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async {
      // Load fonts for golden tests to render text correctly
      await loadAppFonts();
      return testMain();
    },
    config: GoldenToolkitConfiguration(
      // Use real shadows for more accurate golden comparisons
      enableRealShadows: true,
      // Skip golden assertions in CI if needed (set via environment variable)
      skipGoldenAssertion: () => false,
      // Default device configurations for multi-device testing
      defaultDevices: const [
        Device.phone,
        Device.iphone11,
      ],
    ),
  );
}
