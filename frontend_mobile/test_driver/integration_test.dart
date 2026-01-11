import 'package:integration_test/integration_test_driver.dart';

/// This file is the entry point for running integration tests on real devices.
///
/// Run with:
/// ```bash
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/app_test.dart \
///   -d <device_id>
/// ```
Future<void> main() => integrationDriver();
