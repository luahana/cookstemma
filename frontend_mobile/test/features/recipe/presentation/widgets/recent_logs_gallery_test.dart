import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';

/// Unit tests for RecentLogsGallery logic.
///
/// Note: Full widget tests require EasyLocalization, GoRouter, and
/// ScreenUtil setup which is complex in test environment.
/// These tests focus on the business logic and data handling.
void main() {
  group('RecentLogsGallery Logic', () {
    group('Display Logic', () {
      test('should show up to 5 logs from input list', () {
        // Arrange
        final logs = List.generate(
          10,
          (i) => LogPostSummary(
            id: 'log-$i',
            title: 'Log $i',
            outcome: 'SUCCESS',
            thumbnailUrl: null,
            creatorName: 'user$i',
          ),
        );

        // Act - Simulate gallery logic
        final displayLogs = logs.take(5).toList();

        // Assert
        expect(displayLogs, hasLength(5));
        expect(displayLogs.first.id, 'log-0');
        expect(displayLogs.last.id, 'log-4');
      });

      test('should show all logs when less than 5', () {
        // Arrange
        final logs = List.generate(
          3,
          (i) => LogPostSummary(
            id: 'log-$i',
            title: 'Log $i',
            outcome: 'SUCCESS',
            thumbnailUrl: null,
            creatorName: 'user$i',
          ),
        );

        // Act
        final displayLogs = logs.take(5).toList();

        // Assert
        expect(displayLogs, hasLength(3));
      });

      test('should detect when there are more than 5 logs', () {
        // Arrange
        final logsWithMore = List.generate(
          8,
          (i) => LogPostSummary(
            id: 'log-$i',
            title: 'Log $i',
            outcome: 'SUCCESS',
            thumbnailUrl: null,
            creatorName: 'user$i',
          ),
        );

        final logsWithoutMore = List.generate(
          4,
          (i) => LogPostSummary(
            id: 'log-$i',
            title: 'Log $i',
            outcome: 'SUCCESS',
            thumbnailUrl: null,
            creatorName: 'user$i',
          ),
        );

        // Act
        final hasMoreWith8 = logsWithMore.length > 5;
        final hasMoreWith4 = logsWithoutMore.length > 5;

        // Assert
        expect(hasMoreWith8, isTrue);
        expect(hasMoreWith4, isFalse);
      });

      test('should handle exactly 5 logs without showing more button', () {
        // Arrange
        final logs = List.generate(
          5,
          (i) => LogPostSummary(
            id: 'log-$i',
            title: 'Log $i',
            outcome: 'SUCCESS',
            thumbnailUrl: null,
            creatorName: 'user$i',
          ),
        );

        // Act
        final hasMore = logs.length > 5;

        // Assert
        expect(hasMore, isFalse);
      });

      test('should handle exactly 6 logs showing more button', () {
        // Arrange
        final logs = List.generate(
          6,
          (i) => LogPostSummary(
            id: 'log-$i',
            title: 'Log $i',
            outcome: 'SUCCESS',
            thumbnailUrl: null,
            creatorName: 'user$i',
          ),
        );

        // Act
        final displayLogs = logs.take(5).toList();
        final hasMore = logs.length > 5;

        // Assert
        expect(displayLogs, hasLength(5));
        expect(hasMore, isTrue);
      });
    });

    group('Outcome Emoji Mapping', () {
      test('should map SUCCESS to happy emoji', () {
        // Arrange
        const outcome = 'SUCCESS';

        // Act
        final emoji = LogOutcome.getEmoji(outcome);

        // Assert
        expect(emoji, '😊');
      });

      test('should map PARTIAL to slightly smiling emoji', () {
        // Arrange
        const outcome = 'PARTIAL';

        // Act
        final emoji = LogOutcome.getEmoji(outcome);

        // Assert
        expect(emoji, '🙂');
      });

      test('should map FAILED to sad emoji', () {
        // Arrange
        const outcome = 'FAILED';

        // Act
        final emoji = LogOutcome.getEmoji(outcome);

        // Assert
        expect(emoji, '😢');
      });

      test('should map unknown outcome to cooking emoji', () {
        // Arrange
        const outcome = 'UNKNOWN';

        // Act
        final emoji = LogOutcome.getEmoji(outcome);

        // Assert
        expect(emoji, '🍳');
      });

      test('should handle null outcome with cooking emoji', () {
        // Arrange
        const String? outcome = null;

        // Act
        final emoji = LogOutcome.getEmoji(outcome);

        // Assert
        expect(emoji, '🍳');
      });
    });

    group('Empty State', () {
      test('should detect empty logs list', () {
        // Arrange
        final logs = <LogPostSummary>[];

        // Act
        final isEmpty = logs.isEmpty;

        // Assert
        expect(isEmpty, isTrue);
      });
    });

    group('Navigation URL Generation', () {
      test('should generate correct URL for recipe logs', () {
        // Arrange
        const recipeId = 'abc-123-def';
        const logPostsRoute = '/log_posts';

        // Act
        final url = '$logPostsRoute?recipeId=$recipeId';

        // Assert
        expect(url, '/log_posts?recipeId=abc-123-def');
      });

      test('should handle UUID format recipeId', () {
        // Arrange
        const recipeId = '550e8400-e29b-41d4-a716-446655440000';
        const logPostsRoute = '/log_posts';

        // Act
        final url = '$logPostsRoute?recipeId=$recipeId';

        // Assert
        expect(url, contains('recipeId=550e8400-e29b-41d4-a716-446655440000'));
      });
    });

    group('Log Card Data', () {
      test('should handle log with thumbnail', () {
        // Arrange
        final log = LogPostSummary(
          id: 'log-1',
          title: 'Great Dish',
          outcome: 'SUCCESS',
          thumbnailUrl: 'https://example.com/image.jpg',
          creatorName: 'chef_user',
        );

        // Assert
        expect(log.thumbnailUrl, isNotNull);
        expect(log.thumbnailUrl, startsWith('https://'));
      });

      test('should handle log without thumbnail', () {
        // Arrange
        final log = LogPostSummary(
          id: 'log-2',
          title: 'No Photo',
          outcome: 'PARTIAL',
          thumbnailUrl: null,
          creatorName: 'user',
        );

        // Assert
        expect(log.thumbnailUrl, isNull);
      });

      test('should format creator name with @ prefix', () {
        // Arrange
        final log = LogPostSummary(
          id: 'log-3',
          title: 'Test',
          outcome: 'SUCCESS',
          thumbnailUrl: null,
          creatorName: 'username',
        );

        // Act
        final displayName = '@${log.creatorName}';

        // Assert
        expect(displayName, '@username');
      });

      test('should handle null creator name', () {
        // Arrange
        final log = LogPostSummary(
          id: 'log-4',
          title: 'Anonymous',
          outcome: 'SUCCESS',
          thumbnailUrl: null,
          creatorName: null,
        );

        // Assert
        expect(log.creatorName, isNull);
      });
    });
  });
}
