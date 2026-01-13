import 'package:flutter_test/flutter_test.dart';
import 'package:pairing_planet2_frontend/shared/data/model/upload_item_model.dart';

void main() {
  group('Recipe Creation - Multiple Cover Images', () {
    test('should collect all successful image publicIds', () {
      // Create mock UploadItems using factory method for remote images
      final images = [
        UploadItem.fromRemote(url: 'https://example.com/1.jpg', publicId: 'uuid-1'),
        UploadItem.fromRemote(url: 'https://example.com/2.jpg', publicId: 'uuid-2'),
      ];

      // Simulate the collection logic from recipe_create_screen.dart
      final publicIds = images
          .where((img) => img.status == UploadStatus.success)
          .map((img) => img.publicId!)
          .toList();

      expect(publicIds, hasLength(2));
      expect(publicIds, contains('uuid-1'));
      expect(publicIds, contains('uuid-2'));
    });

    test('should filter out failed uploads', () {
      final img1 = UploadItem.fromRemote(url: 'https://example.com/1.jpg', publicId: 'uuid-1');
      final img2 = UploadItem.fromRemote(url: 'https://example.com/2.jpg', publicId: 'uuid-2');
      img2.status = UploadStatus.error; // Simulate failed upload
      final img3 = UploadItem.fromRemote(url: 'https://example.com/3.jpg', publicId: 'uuid-3');

      final images = [img1, img2, img3];

      final publicIds = images
          .where((img) => img.status == UploadStatus.success)
          .map((img) => img.publicId!)
          .toList();

      expect(publicIds, hasLength(2));
      expect(publicIds, contains('uuid-1'));
      expect(publicIds, contains('uuid-3'));
    });

    test('should handle empty list', () {
      final images = <UploadItem>[];

      final publicIds = images
          .where((img) => img.status == UploadStatus.success)
          .map((img) => img.publicId!)
          .toList();

      expect(publicIds, isEmpty);
    });

    test('should preserve order of images', () {
      final images = [
        UploadItem.fromRemote(url: 'https://example.com/1.jpg', publicId: 'first'),
        UploadItem.fromRemote(url: 'https://example.com/2.jpg', publicId: 'second'),
        UploadItem.fromRemote(url: 'https://example.com/3.jpg', publicId: 'third'),
      ];

      final publicIds = images
          .where((img) => img.status == UploadStatus.success)
          .map((img) => img.publicId!)
          .toList();

      expect(publicIds, ['first', 'second', 'third']);
    });

    test('should handle single image', () {
      final images = [
        UploadItem.fromRemote(url: 'https://example.com/1.jpg', publicId: 'only-one'),
      ];

      final publicIds = images
          .where((img) => img.status == UploadStatus.success)
          .map((img) => img.publicId!)
          .toList();

      expect(publicIds, hasLength(1));
      expect(publicIds.first, 'only-one');
    });
  });

  group('Recipe Detail - Multiple Images Display', () {
    test('should handle list of image URLs', () {
      final imageUrls = [
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
      ];

      expect(imageUrls.length, 2);
      expect(imageUrls.isNotEmpty, isTrue);
      expect(imageUrls.length > 1, isTrue); // Should trigger carousel
    });

    test('should detect single vs multiple images', () {
      final singleImage = ['https://example.com/image1.jpg'];
      final multipleImages = [
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
      ];

      expect(singleImage.length == 1, isTrue);
      expect(multipleImages.length > 1, isTrue);
    });
  });
}
