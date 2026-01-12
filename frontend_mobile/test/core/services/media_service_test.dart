import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/services/media_service.dart';

import '../../helpers/mock_providers.dart';
import '../../helpers/test_data.dart';

void main() {
  late MediaService mediaService;
  late MockImagePicker mockPicker;

  setUp(() {
    mockPicker = MockImagePicker();
    mediaService = MediaService(picker: mockPicker);
  });

  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
  });

  group('MediaService', () {
    group('takePhoto', () {
      test('returns XFile when user takes photo', () async {
        // Arrange
        final expectedFile = TestImageData.createXFile(path: '/camera/photo.jpg');
        when(() => mockPicker.pickImage(
              source: ImageSource.camera,
              imageQuality: any(named: 'imageQuality'),
              maxWidth: any(named: 'maxWidth'),
            )).thenAnswer((_) async => expectedFile);

        // Act
        final result = await mediaService.takePhoto();

        // Assert
        expect(result, isNotNull);
        expect(result!.path, equals('/camera/photo.jpg'));
        verify(() => mockPicker.pickImage(
              source: ImageSource.camera,
              imageQuality: 80,
              maxWidth: 1080,
            )).called(1);
      });

      test('returns null when user cancels', () async {
        // Arrange
        when(() => mockPicker.pickImage(
              source: ImageSource.camera,
              imageQuality: any(named: 'imageQuality'),
              maxWidth: any(named: 'maxWidth'),
            )).thenAnswer((_) async => null);

        // Act
        final result = await mediaService.takePhoto();

        // Assert
        expect(result, isNull);
      });

      test('returns null when ImagePicker throws exception', () async {
        // Arrange - This covers the permission denied case we fixed
        when(() => mockPicker.pickImage(
              source: ImageSource.camera,
              imageQuality: any(named: 'imageQuality'),
              maxWidth: any(named: 'maxWidth'),
            )).thenThrow(Exception('Camera access denied'));

        // Act
        final result = await mediaService.takePhoto();

        // Assert
        expect(result, isNull);
      });

      test('uses correct image quality and max width', () async {
        // Arrange
        when(() => mockPicker.pickImage(
              source: any(named: 'source'),
              imageQuality: any(named: 'imageQuality'),
              maxWidth: any(named: 'maxWidth'),
            )).thenAnswer((_) async => TestImageData.createXFile());

        // Act
        await mediaService.takePhoto();

        // Assert
        verify(() => mockPicker.pickImage(
              source: ImageSource.camera,
              imageQuality: 80,
              maxWidth: 1080,
            )).called(1);
      });
    });

    group('pickImage', () {
      test('returns XFile when user selects image', () async {
        // Arrange
        final expectedFile = TestImageData.createXFile(path: '/gallery/image.jpg');
        when(() => mockPicker.pickImage(
              source: ImageSource.gallery,
              imageQuality: any(named: 'imageQuality'),
            )).thenAnswer((_) async => expectedFile);

        // Act
        final result = await mediaService.pickImage();

        // Assert
        expect(result, isNotNull);
        expect(result!.path, equals('/gallery/image.jpg'));
        verify(() => mockPicker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            )).called(1);
      });

      test('returns null when user cancels', () async {
        // Arrange
        when(() => mockPicker.pickImage(
              source: ImageSource.gallery,
              imageQuality: any(named: 'imageQuality'),
            )).thenAnswer((_) async => null);

        // Act
        final result = await mediaService.pickImage();

        // Assert
        expect(result, isNull);
      });

      test('returns null when ImagePicker throws exception', () async {
        // Arrange - This covers the permission denied case
        when(() => mockPicker.pickImage(
              source: ImageSource.gallery,
              imageQuality: any(named: 'imageQuality'),
            )).thenThrow(Exception('Gallery access denied'));

        // Act
        final result = await mediaService.pickImage();

        // Assert
        expect(result, isNull);
      });

      test('uses correct image quality', () async {
        // Arrange
        when(() => mockPicker.pickImage(
              source: any(named: 'source'),
              imageQuality: any(named: 'imageQuality'),
            )).thenAnswer((_) async => TestImageData.createXFile());

        // Act
        await mediaService.pickImage();

        // Assert
        verify(() => mockPicker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            )).called(1);
      });
    });

    group('constructor', () {
      test('uses provided ImagePicker when given', () async {
        // Arrange
        final customPicker = MockImagePicker();
        when(() => customPicker.pickImage(
              source: any(named: 'source'),
              imageQuality: any(named: 'imageQuality'),
              maxWidth: any(named: 'maxWidth'),
            )).thenAnswer((_) async => TestImageData.createXFile());

        final service = MediaService(picker: customPicker);

        // Act
        await service.takePhoto();

        // Assert
        verify(() => customPicker.pickImage(
              source: ImageSource.camera,
              imageQuality: 80,
              maxWidth: 1080,
            )).called(1);
      });

      test('creates default ImagePicker when none provided', () {
        // Act
        final service = MediaService();

        // Assert - service should be created without error
        expect(service, isNotNull);
      });
    });
  });
}
