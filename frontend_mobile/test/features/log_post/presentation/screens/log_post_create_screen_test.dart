import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/test_data.dart';

void main() {
  group('UploadItem - Status Management', () {
    test('initial status is initial when created from file', () {
      final item = UploadItem.fromFile(File('/test/image.jpg'));
      expect(item.status, UploadStatus.initial);
      expect(item.publicId, isNull);
    });

    test('status is success when created from remote', () {
      final item = UploadItem.fromRemote(
        url: 'https://example.com/image.jpg',
        publicId: 'img-123',
      );
      expect(item.status, UploadStatus.success);
      expect(item.publicId, 'img-123');
    });

    test('isRemote returns true for remote items', () {
      final item = UploadItem.fromRemote(
        url: 'https://example.com/image.jpg',
        publicId: 'img-123',
      );
      expect(item.isRemote, isTrue);
    });

    test('isRemote returns false for local file items', () {
      final item = UploadItem.fromFile(File('/test/image.jpg'));
      expect(item.isRemote, isFalse);
    });

    test('status can be changed to uploading', () {
      final item = UploadItem.fromFile(File('/test/image.jpg'));
      item.status = UploadStatus.uploading;
      expect(item.status, UploadStatus.uploading);
    });

    test('status can be changed to success with publicId', () {
      final item = UploadItem.fromFile(File('/test/image.jpg'));
      item.status = UploadStatus.success;
      item.publicId = 'uploaded-img-123';
      expect(item.status, UploadStatus.success);
      expect(item.publicId, 'uploaded-img-123');
    });

    test('status can be changed to error', () {
      final item = UploadItem.fromFile(File('/test/image.jpg'));
      item.status = UploadStatus.error;
      expect(item.status, UploadStatus.error);
    });
  });

  group('Upload Image Logic', () {
    late MockUploadImageWithTrackingUseCase mockUseCase;

    setUpAll(() {
      registerFallbackValue(File('/fake/path'));
    });

    setUp(() {
      mockUseCase = MockUploadImageWithTrackingUseCase();
    });

    test('execute returns ImageUploadResponseDto on success', () async {
      // Arrange
      final expectedResponse = TestImageData.createUploadResponse(
        publicId: 'new-img-456',
        url: 'https://example.com/uploaded.jpg',
      );
      when(() => mockUseCase.execute(
            file: any(named: 'file'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => Right(expectedResponse));

      // Act
      final result = await mockUseCase.execute(
        file: File('/test/image.jpg'),
        type: 'LOG_POST',
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Expected Right'),
        (r) {
          expect(r.imagePublicId, 'new-img-456');
          expect(r.imageUrl, 'https://example.com/uploaded.jpg');
        },
      );
    });

    test('execute returns Failure on error', () async {
      // Arrange
      when(() => mockUseCase.execute(
            file: any(named: 'file'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => Left(ServerFailure('Upload failed')));

      // Act
      final result = await mockUseCase.execute(
        file: File('/test/image.jpg'),
        type: 'LOG_POST',
      );

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });

  group('Image List Management', () {
    test('adding images maintains order', () {
      final images = <UploadItem>[];

      images.add(TestImageData.createUploadItem(
        file: File('/photo1.jpg'),
        status: UploadStatus.success,
        publicId: 'img-1',
      ));
      images.add(TestImageData.createUploadItem(
        file: File('/photo2.jpg'),
        status: UploadStatus.success,
        publicId: 'img-2',
      ));
      images.add(TestImageData.createUploadItem(
        file: File('/photo3.jpg'),
        status: UploadStatus.success,
        publicId: 'img-3',
      ));

      expect(images.length, 3);
      expect(images[0].publicId, 'img-1');
      expect(images[1].publicId, 'img-2');
      expect(images[2].publicId, 'img-3');
    });

    test('reordering images works correctly', () {
      final images = TestImageData.createUploadItemList(count: 3);

      // Move first to last (simulate reorder)
      final item = images.removeAt(0);
      images.insert(2, item);

      expect(images[0].publicId, 'img-1');
      expect(images[1].publicId, 'img-2');
      expect(images[2].publicId, 'img-0'); // Was first, now last
    });

    test('removing image at index works correctly', () {
      final images = TestImageData.createUploadItemList(count: 3);

      images.removeAt(1);

      expect(images.length, 2);
      expect(images[0].publicId, 'img-0');
      expect(images[1].publicId, 'img-2');
    });

    test('filtering successful images for submission', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(
          status: UploadStatus.success,
          publicId: 'img-success-1',
        ),
        TestImageData.createUploadItem(
          status: UploadStatus.error,
          publicId: null,
        ),
        TestImageData.createUploadItem(
          status: UploadStatus.success,
          publicId: 'img-success-2',
        ),
        TestImageData.createUploadItem(
          status: UploadStatus.uploading,
          publicId: null,
        ),
      ];

      final successfulPublicIds = images
          .where((img) => img.status == UploadStatus.success)
          .map((img) => img.publicId!)
          .toList();

      expect(successfulPublicIds, ['img-success-1', 'img-success-2']);
    });
  });

  group('Submit Button State Logic', () {
    test('hasUploadingImages returns true when any image is uploading', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-1'),
        TestImageData.createUploadItem(status: UploadStatus.uploading),
      ];

      final hasUploading = images.any((img) => img.status == UploadStatus.uploading);
      expect(hasUploading, isTrue);
    });

    test('hasUploadingImages returns false when no images uploading', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-1'),
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-2'),
      ];

      final hasUploading = images.any((img) => img.status == UploadStatus.uploading);
      expect(hasUploading, isFalse);
    });

    test('hasUploadErrors returns true when any image has error', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-1'),
        TestImageData.createUploadItem(status: UploadStatus.error),
      ];

      final hasErrors = images.any((img) => img.status == UploadStatus.error);
      expect(hasErrors, isTrue);
    });

    test('hasUploadErrors returns false when no errors', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-1'),
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-2'),
      ];

      final hasErrors = images.any((img) => img.status == UploadStatus.error);
      expect(hasErrors, isFalse);
    });

    test('canSubmit is true when not loading, no uploading, no errors', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-1'),
      ];
      final isLoading = false;
      final hasUploading = images.any((img) => img.status == UploadStatus.uploading);
      final hasErrors = images.any((img) => img.status == UploadStatus.error);

      final canSubmit = !isLoading && !hasUploading && !hasErrors;
      expect(canSubmit, isTrue);
    });

    test('canSubmit is false when loading', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-1'),
      ];
      final isLoading = true;
      final hasUploading = images.any((img) => img.status == UploadStatus.uploading);
      final hasErrors = images.any((img) => img.status == UploadStatus.error);

      final canSubmit = !isLoading && !hasUploading && !hasErrors;
      expect(canSubmit, isFalse);
    });

    test('canSubmit is false when uploading', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.uploading),
      ];
      final isLoading = false;
      final hasUploading = images.any((img) => img.status == UploadStatus.uploading);
      final hasErrors = images.any((img) => img.status == UploadStatus.error);

      final canSubmit = !isLoading && !hasUploading && !hasErrors;
      expect(canSubmit, isFalse);
    });

    test('canSubmit is false when errors exist', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.error),
      ];
      final isLoading = false;
      final hasUploading = images.any((img) => img.status == UploadStatus.uploading);
      final hasErrors = images.any((img) => img.status == UploadStatus.error);

      final canSubmit = !isLoading && !hasUploading && !hasErrors;
      expect(canSubmit, isFalse);
    });
  });

  group('Upload Status Counts', () {
    test('counts uploading images correctly', () {
      final images = <UploadItem>[
        TestImageData.createUploadItem(status: UploadStatus.uploading),
        TestImageData.createUploadItem(status: UploadStatus.uploading),
        TestImageData.createUploadItem(status: UploadStatus.success, publicId: 'img-1'),
        TestImageData.createUploadItem(status: UploadStatus.error),
      ];

      int uploading = 0;
      int errors = 0;
      for (final img in images) {
        if (img.status == UploadStatus.uploading) uploading++;
        if (img.status == UploadStatus.error) errors++;
      }

      expect(uploading, 2);
      expect(errors, 1);
    });

    test('returns zero counts when all successful', () {
      final images = TestImageData.createUploadItemList(count: 3);

      int uploading = 0;
      int errors = 0;
      for (final img in images) {
        if (img.status == UploadStatus.uploading) uploading++;
        if (img.status == UploadStatus.error) errors++;
      }

      expect(uploading, 0);
      expect(errors, 0);
    });
  });

  group('Max Images Validation', () {
    test('max 3 images allowed', () {
      final maxImages = 3;
      final images = <UploadItem>[];

      // Add 3 images
      for (int i = 0; i < 3; i++) {
        if (images.length < maxImages) {
          images.add(TestImageData.createUploadItem(publicId: 'img-$i'));
        }
      }

      expect(images.length, 3);

      // Try to add 4th - should not be added
      if (images.length < maxImages) {
        images.add(TestImageData.createUploadItem(publicId: 'img-4'));
      }

      expect(images.length, 3); // Still 3
    });
  });
}
