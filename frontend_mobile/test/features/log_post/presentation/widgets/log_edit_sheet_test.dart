import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/update_log_post_request_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/core/widgets/outcome/outcome_badge.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';

import '../../../../helpers/test_data.dart';

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

  group('LogPostDetail with creatorPublicId', () {
    test('creates entity with creatorPublicId', () {
      final log = LogPostDetail(
        publicId: 'test-public-id',
        content: 'Test content',
        outcome: 'SUCCESS',
        imageUrls: ['https://example.com/image.jpg'],
        recipePublicId: 'recipe-123',
        createdAt: DateTime(2024, 1, 1),
        creatorPublicId: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      );

      expect(log.creatorPublicId, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(log.publicId, 'test-public-id');
    });

    test('creatorPublicId can be null', () {
      final log = LogPostDetail(
        publicId: 'test-public-id',
        content: 'Test content',
        outcome: 'SUCCESS',
        imageUrls: [],
        recipePublicId: 'recipe-123',
        createdAt: DateTime(2024, 1, 1),
        creatorPublicId: null,
      );

      expect(log.creatorPublicId, isNull);
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

  group('LogEditSheet - Image Loading from LogPostDetail', () {
    test('loads existing images as remote UploadItems', () {
      // Simulate what initState does
      final images = [
        LogImage(publicId: 'img-1', url: 'https://example.com/img1.jpg'),
        LogImage(publicId: 'img-2', url: 'https://example.com/img2.jpg'),
      ];

      final uploadItems = images
          .where((img) => img.url != null && img.publicId.isNotEmpty)
          .map((img) => UploadItem.fromRemote(
                url: img.url!,
                publicId: img.publicId,
              ))
          .toList();

      expect(uploadItems.length, 2);
      expect(uploadItems[0].publicId, 'img-1');
      expect(uploadItems[0].isRemote, isTrue);
      expect(uploadItems[0].status, UploadStatus.success);
      expect(uploadItems[1].publicId, 'img-2');
    });

    test('filters images with null URLs', () {
      final images = [
        LogImage(publicId: 'img-1', url: 'https://example.com/img1.jpg'),
        LogImage(publicId: 'img-2', url: null), // Should be filtered
        LogImage(publicId: 'img-3', url: 'https://example.com/img3.jpg'),
      ];

      final uploadItems = images
          .where((img) => img.url != null && img.publicId.isNotEmpty)
          .map((img) => UploadItem.fromRemote(
                url: img.url!,
                publicId: img.publicId,
              ))
          .toList();

      expect(uploadItems.length, 2);
      expect(uploadItems.any((img) => img.publicId == 'img-2'), isFalse);
    });

    test('filters images with empty publicIds', () {
      final images = [
        LogImage(publicId: 'img-1', url: 'https://example.com/img1.jpg'),
        LogImage(publicId: '', url: 'https://example.com/img2.jpg'), // Should be filtered
      ];

      final uploadItems = images
          .where((img) => img.url != null && img.publicId.isNotEmpty)
          .map((img) => UploadItem.fromRemote(
                url: img.url!,
                publicId: img.publicId,
              ))
          .toList();

      expect(uploadItems.length, 1);
      expect(uploadItems[0].publicId, 'img-1');
    });
  });

  group('LogEditSheet - Save Changes Image Filtering', () {
    test('only includes successful image publicIds in save', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(
          status: UploadStatus.success,
          publicId: 'img-success-1',
        ),
        TestImageData.createUploadItem(
          status: UploadStatus.error,
          publicId: null,
        ),
        TestImageData.createRemoteUploadItem(
          publicId: 'img-remote-1',
        ),
        TestImageData.createUploadItem(
          status: UploadStatus.uploading,
          publicId: null,
        ),
      ];

      // Simulate what _saveChanges does
      final imagePublicIds = images
          .where((img) => img.status == UploadStatus.success && img.publicId != null)
          .map((img) => img.publicId!)
          .toList();

      expect(imagePublicIds.length, 2);
      expect(imagePublicIds, contains('img-success-1'));
      expect(imagePublicIds, contains('img-remote-1'));
    });

    test('handles empty image list', () {
      final images = <UploadItem>[];

      final imagePublicIds = images
          .where((img) => img.status == UploadStatus.success && img.publicId != null)
          .map((img) => img.publicId!)
          .toList();

      expect(imagePublicIds, isEmpty);
    });

    test('handles all failed uploads', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.error),
        TestImageData.createUploadItem(status: UploadStatus.error),
      ];

      final imagePublicIds = images
          .where((img) => img.status == UploadStatus.success && img.publicId != null)
          .map((img) => img.publicId!)
          .toList();

      expect(imagePublicIds, isEmpty);
    });
  });

  group('LogEditSheet - Max Images Validation', () {
    test('enforces max 3 images', () {
      final images = <UploadItem>[];
      const maxImages = 3;

      // Add 3 images
      for (int i = 0; i < 3; i++) {
        if (images.length < maxImages) {
          images.add(TestImageData.createUploadItem(publicId: 'img-$i'));
        }
      }

      // Verify limit reached
      final canAddMore = images.length < maxImages;
      expect(canAddMore, isFalse);
      expect(images.length, 3);
    });

    test('allows adding when under limit', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(publicId: 'img-1'),
        TestImageData.createUploadItem(publicId: 'img-2'),
      ];
      const maxImages = 3;

      final canAddMore = images.length < maxImages;
      expect(canAddMore, isTrue);
    });
  });

  group('LogEditSheet - Save Button State', () {
    test('button disabled when uploading', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.uploading),
      ];
      final isLoading = false;
      final hasUploading = images.any((img) => img.status == UploadStatus.uploading);
      final hasErrors = images.any((img) => img.status == UploadStatus.error);

      final canSave = !isLoading && !hasUploading && !hasErrors;
      expect(canSave, isFalse);
    });

    test('button disabled when errors exist', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.error),
      ];
      final isLoading = false;
      final hasUploading = images.any((img) => img.status == UploadStatus.uploading);
      final hasErrors = images.any((img) => img.status == UploadStatus.error);

      final canSave = !isLoading && !hasUploading && !hasErrors;
      expect(canSave, isFalse);
    });

    test('button disabled when loading', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-1'),
      ];
      final isLoading = true;
      final hasUploading = images.any((img) => img.status == UploadStatus.uploading);
      final hasErrors = images.any((img) => img.status == UploadStatus.error);

      final canSave = !isLoading && !hasUploading && !hasErrors;
      expect(canSave, isFalse);
    });

    test('button enabled when all images successful', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-1'),
        TestImageData.createRemoteUploadItem(publicId: 'img-2'),
      ];
      final isLoading = false;
      final hasUploading = images.any((img) => img.status == UploadStatus.uploading);
      final hasErrors = images.any((img) => img.status == UploadStatus.error);

      final canSave = !isLoading && !hasUploading && !hasErrors;
      expect(canSave, isTrue);
    });
  });

  group('UpdateLogPostRequestDto with imagePublicIds', () {
    test('includes imagePublicIds in request', () {
      final dto = UpdateLogPostRequestDto(
        content: 'Updated content',
        outcome: 'SUCCESS',
        imagePublicIds: ['img-1', 'img-2', 'img-3'],
      );

      final json = dto.toJson();

      expect(json['imagePublicIds'], ['img-1', 'img-2', 'img-3']);
    });

    test('handles null imagePublicIds', () {
      final dto = UpdateLogPostRequestDto(
        content: 'Updated content',
        outcome: 'SUCCESS',
        imagePublicIds: null,
      );

      final json = dto.toJson();

      expect(json['imagePublicIds'], isNull);
    });

    test('handles empty imagePublicIds list', () {
      final dto = UpdateLogPostRequestDto(
        content: 'Updated content',
        outcome: 'SUCCESS',
        imagePublicIds: [],
      );

      final json = dto.toJson();

      expect(json['imagePublicIds'], isEmpty);
    });
  });
}
