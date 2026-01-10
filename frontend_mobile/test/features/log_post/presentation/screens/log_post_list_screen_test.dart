import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';

/// Unit tests for LogPostListScreen components.
/// Note: Full widget tests require extensive mocking of Hive, SyncQueue,
/// and other providers. These tests focus on isolated components.
void main() {
  group('LogOutcome', () {
    test('fromString returns correct outcome for SUCCESS', () {
      expect(LogOutcome.fromString('SUCCESS'), LogOutcome.success);
    });

    test('fromString returns correct outcome for PARTIAL', () {
      expect(LogOutcome.fromString('PARTIAL'), LogOutcome.partial);
    });

    test('fromString returns correct outcome for FAILED', () {
      expect(LogOutcome.fromString('FAILED'), LogOutcome.failed);
    });

    test('fromString returns null for unknown string', () {
      expect(LogOutcome.fromString('UNKNOWN'), isNull);
    });

    test('fromString handles null input', () {
      expect(LogOutcome.fromString(null), isNull);
    });

    test('fromString is case-sensitive', () {
      // fromString expects uppercase values
      expect(LogOutcome.fromString('success'), isNull);
      expect(LogOutcome.fromString('Success'), isNull);
      expect(LogOutcome.fromString('SUCCESS'), LogOutcome.success);
    });

    test('enum has correct values', () {
      expect(LogOutcome.success.value, 'SUCCESS');
      expect(LogOutcome.partial.value, 'PARTIAL');
      expect(LogOutcome.failed.value, 'FAILED');
    });

    test('enum has correct label keys', () {
      expect(LogOutcome.success.labelKey, 'logPost.outcomeLabel.success');
      expect(LogOutcome.partial.labelKey, 'logPost.outcomeLabel.partial');
      expect(LogOutcome.failed.labelKey, 'logPost.outcomeLabel.failed');
    });

    test('emoji returns correct emoji for each outcome', () {
      expect(LogOutcome.success.emoji, '\u{1F60A}');
      expect(LogOutcome.partial.emoji, '\u{1F610}');
      expect(LogOutcome.failed.emoji, '\u{1F622}');
    });
  });

  // Note: Widget tests for OutcomeBadge require EasyLocalization setup
  // which is complex in test environment. The component is tested via
  // integration tests and manual testing.
}
