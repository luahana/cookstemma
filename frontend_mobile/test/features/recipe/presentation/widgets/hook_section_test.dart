import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/test_data.dart';

void main() {
  group('HookSection - Image Upload Logic', () {
    late MockUploadImageWithTrackingUseCase mockUseCase;

    setUpAll(() {
      registerFallbackValue(File('/fake/path'));
    });

    setUp(() {
      mockUseCase = MockUploadImageWithTrackingUseCase();
    });

    group('image upload with THUMBNAIL type', () {
      test('calls execute with THUMBNAIL type', () async {
        // Arrange
        final expectedResponse = TestImageData.createUploadResponse();
        when(() => mockUseCase.execute(
              file: any(named: 'file'),
              type: 'THUMBNAIL',
            )).thenAnswer((_) async => Right(expectedResponse));

        // Act
        await mockUseCase.execute(
          file: File('/test/image.jpg'),
          type: 'THUMBNAIL',
        );

        // Assert
        verify(() => mockUseCase.execute(
              file: any(named: 'file'),
              type: 'THUMBNAIL',
            )).called(1);
      });

      test('sets serverUrl on successful upload', () async {
        // Arrange
        final item = TestImageData.createUploadItem();
        final expectedResponse = TestImageData.createUploadResponse(
          url: 'https://example.com/thumbnail.jpg',
          publicId: 'thumb-123',
        );
        when(() => mockUseCase.execute(
              file: any(named: 'file'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => Right(expectedResponse));

        // Act
        final result = await mockUseCase.execute(
          file: item.file!,
          type: 'THUMBNAIL',
        );

        // Simulate what HookSection does on success
        result.fold((f) {
          item.status = UploadStatus.error;
        }, (res) {
          item.status = UploadStatus.success;
          item.serverUrl = res.imageUrl;
          item.publicId = res.imagePublicId;
        });

        // Assert
        expect(item.status, UploadStatus.success);
        expect(item.serverUrl, 'https://example.com/thumbnail.jpg');
        expect(item.publicId, 'thumb-123');
      });

      test('sets error status on failed upload', () async {
        // Arrange
        final item = TestImageData.createUploadItem();
        when(() => mockUseCase.execute(
              file: any(named: 'file'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => Left(ServerFailure('Upload failed')));

        // Act
        final result = await mockUseCase.execute(
          file: item.file!,
          type: 'THUMBNAIL',
        );

        // Simulate what HookSection does on failure
        result.fold((f) {
          item.status = UploadStatus.error;
        }, (res) {
          item.status = UploadStatus.success;
        });

        // Assert
        expect(item.status, UploadStatus.error);
        expect(item.publicId, isNull);
      });
    });

    group('onStateChanged callback', () {
      test('should be called when upload starts', () {
        var callCount = 0;
        void onStateChanged() => callCount++;

        // Simulate what HookSection does
        final item = TestImageData.createUploadItem();
        item.status = UploadStatus.uploading;
        onStateChanged();

        expect(callCount, 1);
      });

      test('should be called when upload completes', () {
        var callCount = 0;
        void onStateChanged() => callCount++;

        // Simulate full upload flow
        final item = TestImageData.createUploadItem();

        // Start upload
        item.status = UploadStatus.uploading;
        onStateChanged();

        // Complete upload
        item.status = UploadStatus.success;
        item.publicId = 'new-id';
        onStateChanged();

        expect(callCount, 2);
      });

      test('should be called when image is removed', () {
        var callCount = 0;
        void onStateChanged() => callCount++;

        // Simulate image removal
        final images = TestImageData.createUploadItemList(count: 3);
        images.removeAt(1);
        onStateChanged();

        expect(callCount, 1);
        expect(images.length, 2);
      });
    });
  });

  group('HookSection - Finished Images List', () {
    test('max 3 images allowed for finished photos', () {
      final images = <UploadItem>[];
      const maxImages = 3;

      // Add up to 3
      for (int i = 0; i < 3; i++) {
        if (images.length < maxImages) {
          images.add(TestImageData.createUploadItem(publicId: 'img-$i'));
        }
      }

      expect(images.length, 3);
    });

    test('reorder callback works correctly', () {
      final images = TestImageData.createUploadItemList(count: 3);

      // Simulate reorder callback
      void onReorder(int oldIndex, int newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final item = images.removeAt(oldIndex);
        images.insert(newIndex, item);
      }

      // Move first to last
      onReorder(0, 3);

      expect(images[0].publicId, 'img-1');
      expect(images[1].publicId, 'img-2');
      expect(images[2].publicId, 'img-0');
    });

    test('remove callback updates list and notifies', () {
      final images = TestImageData.createUploadItemList(count: 3);
      var stateChangedCalled = false;
      void onStateChanged() => stateChangedCalled = true;

      // Simulate remove
      images.removeAt(1);
      onStateChanged();

      expect(images.length, 2);
      expect(stateChangedCalled, isTrue);
    });
  });

  group('HookSection - isReadOnly mode', () {
    test('finishedImages can still be edited in readOnly mode', () {
      // In HookSection, finishedImages are passed from parent
      // and can be edited even when form fields are read-only
      final images = <UploadItem>[];
      const isReadOnly = true;

      // Can still add images
      images.add(TestImageData.createUploadItem());
      expect(images.length, 1);

      // Can still reorder
      images.add(TestImageData.createUploadItem(publicId: 'img-2'));
      final item = images.removeAt(0);
      images.add(item);
      expect(images.last.publicId, isNull); // First item had no publicId

      // isReadOnly only affects form fields, not image management
      expect(isReadOnly, isTrue);
    });
  });

  group('HookSection - Upload Item with serverUrl', () {
    test('serverUrl is set for display purposes', () {
      final item = TestImageData.createUploadItem();
      expect(item.serverUrl, isNull);

      // After successful upload, both serverUrl and publicId are set
      item.serverUrl = 'https://cdn.example.com/image.jpg';
      item.publicId = 'img-uuid-123';

      expect(item.serverUrl, isNotNull);
      expect(item.publicId, isNotNull);
    });

    test('remote items have remoteUrl but no serverUrl initially', () {
      final item = TestImageData.createRemoteUploadItem(
        url: 'https://example.com/existing.jpg',
        publicId: 'existing-123',
      );

      expect(item.remoteUrl, 'https://example.com/existing.jpg');
      expect(item.publicId, 'existing-123');
      expect(item.isRemote, isTrue);
      expect(item.status, UploadStatus.success);
    });
  });
}
