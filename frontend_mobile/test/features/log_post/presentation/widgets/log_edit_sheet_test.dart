import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/update_log_post_request_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';

/// Unit tests for LogEditSheet and related components.
/// Note: Full widget tests require extensive mocking of providers.
/// These tests focus on DTO serialization and entity structure.
void main() {
  group('UpdateLogPostRequestDto', () {
    test('serializes to JSON correctly with all fields', () {
      final dto = UpdateLogPostRequestDto(
        title: 'Updated Title',
        content: 'Updated content',
        outcome: 'PARTIAL',
        hashtags: ['tag1', 'tag2'],
      );

      final json = dto.toJson();

      expect(json['title'], 'Updated Title');
      expect(json['content'], 'Updated content');
      expect(json['outcome'], 'PARTIAL');
      expect(json['hashtags'], ['tag1', 'tag2']);
    });

    test('serializes to JSON correctly with null title', () {
      final dto = UpdateLogPostRequestDto(
        title: null,
        content: 'Updated content',
        outcome: 'SUCCESS',
        hashtags: null,
      );

      final json = dto.toJson();

      expect(json['title'], isNull);
      expect(json['content'], 'Updated content');
      expect(json['outcome'], 'SUCCESS');
      expect(json['hashtags'], isNull);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'title': 'Test Title',
        'content': 'Test content',
        'outcome': 'FAILED',
        'hashtags': ['test-tag'],
      };

      final dto = UpdateLogPostRequestDto.fromJson(json);

      expect(dto.title, 'Test Title');
      expect(dto.content, 'Test content');
      expect(dto.outcome, 'FAILED');
      expect(dto.hashtags, ['test-tag']);
    });
  });

  group('LogPostDetail with creatorId', () {
    test('creates entity with creatorId', () {
      final log = LogPostDetail(
        publicId: 'test-public-id',
        content: 'Test content',
        outcome: 'SUCCESS',
        imageUrls: ['https://example.com/image.jpg'],
        recipePublicId: 'recipe-123',
        createdAt: DateTime(2024, 1, 1),
        creatorId: 42,
      );

      expect(log.creatorId, 42);
      expect(log.publicId, 'test-public-id');
    });

    test('creatorId can be null', () {
      final log = LogPostDetail(
        publicId: 'test-public-id',
        content: 'Test content',
        outcome: 'SUCCESS',
        imageUrls: [],
        recipePublicId: 'recipe-123',
        createdAt: DateTime(2024, 1, 1),
        creatorId: null,
      );

      expect(log.creatorId, isNull);
    });
  });

  group('LogOutcome value mapping', () {
    test('success outcome has correct value', () {
      expect(LogOutcome.success.value, 'SUCCESS');
    });

    test('partial outcome has correct value', () {
      expect(LogOutcome.partial.value, 'PARTIAL');
    });

    test('failed outcome has correct value', () {
      expect(LogOutcome.failed.value, 'FAILED');
    });

    test('fromString and value are consistent', () {
      for (final outcome in LogOutcome.values) {
        expect(LogOutcome.fromString(outcome.value), outcome);
      }
    });
  });
}
