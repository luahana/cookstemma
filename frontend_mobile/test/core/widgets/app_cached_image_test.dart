import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pairing_planet2_frontend/core/widgets/app_cached_image.dart';
import 'package:pairing_planet2_frontend/domain/entities/image/image_variants.dart';

void main() {
  group('ImageVariants', () {
    group('getBestUrl', () {
      final variants = ImageVariants(
        original: 'https://example.com/original.jpg',
        large: 'https://example.com/large.jpg',
        medium: 'https://example.com/medium.jpg',
        thumbnail: 'https://example.com/thumbnail.jpg',
        small: 'https://example.com/small.jpg',
      );

      test('should return small for physical width <= 200', () {
        // 100px display * 2.0 pixel ratio = 200 physical
        expect(variants.getBestUrl(100, 2.0), variants.small);
        expect(variants.getBestUrl(200, 1.0), variants.small);
        expect(variants.getBestUrl(66, 3.0), variants.small); // 198 physical
      });

      test('should return thumbnail for physical width <= 400', () {
        expect(variants.getBestUrl(200, 2.0), variants.thumbnail);
        expect(variants.getBestUrl(400, 1.0), variants.thumbnail);
        expect(variants.getBestUrl(133, 3.0), variants.thumbnail); // 399 physical
      });

      test('should return medium for physical width <= 800', () {
        expect(variants.getBestUrl(400, 2.0), variants.medium);
        expect(variants.getBestUrl(800, 1.0), variants.medium);
        expect(variants.getBestUrl(266, 3.0), variants.medium); // 798 physical
      });

      test('should return large for physical width <= 1200', () {
        expect(variants.getBestUrl(600, 2.0), variants.large);
        expect(variants.getBestUrl(1200, 1.0), variants.large);
        expect(variants.getBestUrl(400, 3.0), variants.large); // 1200 physical
      });

      test('should return original for physical width > 1200', () {
        expect(variants.getBestUrl(601, 2.0), variants.original);
        expect(variants.getBestUrl(1201, 1.0), variants.original);
        expect(variants.getBestUrl(500, 3.0), variants.original); // 1500 physical
      });
    });

    group('getVariant', () {
      final variants = ImageVariants(
        original: 'original.jpg',
        large: 'large.jpg',
        medium: 'medium.jpg',
        thumbnail: 'thumbnail.jpg',
        small: 'small.jpg',
      );

      test('should return correct URL for each variant size', () {
        expect(variants.getVariant(ImageVariantSize.small), 'small.jpg');
        expect(variants.getVariant(ImageVariantSize.thumbnail), 'thumbnail.jpg');
        expect(variants.getVariant(ImageVariantSize.medium), 'medium.jpg');
        expect(variants.getVariant(ImageVariantSize.large), 'large.jpg');
        expect(variants.getVariant(ImageVariantSize.original), 'original.jpg');
      });
    });

    group('fromUrl factory', () {
      test('should create variants with same URL for all sizes', () {
        final variants = ImageVariants.fromUrl('https://example.com/image.jpg');

        expect(variants.original, 'https://example.com/image.jpg');
        expect(variants.large, 'https://example.com/image.jpg');
        expect(variants.medium, 'https://example.com/image.jpg');
        expect(variants.thumbnail, 'https://example.com/image.jpg');
        expect(variants.small, 'https://example.com/image.jpg');
      });
    });

    group('fromJson factory', () {
      test('should parse all fields correctly', () {
        final json = {
          'imagePublicId': 'img-123',
          'original': 'original.jpg',
          'large': 'large.jpg',
          'medium': 'medium.jpg',
          'thumbnail': 'thumbnail.jpg',
          'small': 'small.jpg',
        };

        final variants = ImageVariants.fromJson(json);

        expect(variants.imagePublicId, 'img-123');
        expect(variants.original, 'original.jpg');
        expect(variants.large, 'large.jpg');
        expect(variants.medium, 'medium.jpg');
        expect(variants.thumbnail, 'thumbnail.jpg');
        expect(variants.small, 'small.jpg');
      });

      test('should fallback to original for missing variants', () {
        final json = {
          'original': 'original.jpg',
        };

        final variants = ImageVariants.fromJson(json);

        expect(variants.original, 'original.jpg');
        expect(variants.large, 'original.jpg');
        expect(variants.medium, 'original.jpg');
        expect(variants.thumbnail, 'original.jpg');
        expect(variants.small, 'original.jpg');
      });

      test('should handle null imagePublicId', () {
        final json = {
          'original': 'original.jpg',
          'large': 'large.jpg',
          'medium': 'medium.jpg',
          'thumbnail': 'thumbnail.jpg',
          'small': 'small.jpg',
        };

        final variants = ImageVariants.fromJson(json);

        expect(variants.imagePublicId, isNull);
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        final variants = ImageVariants(
          imagePublicId: 'img-123',
          original: 'original.jpg',
          large: 'large.jpg',
          medium: 'medium.jpg',
          thumbnail: 'thumbnail.jpg',
          small: 'small.jpg',
        );

        final json = variants.toJson();

        expect(json['imagePublicId'], 'img-123');
        expect(json['original'], 'original.jpg');
        expect(json['large'], 'large.jpg');
        expect(json['medium'], 'medium.jpg');
        expect(json['thumbnail'], 'thumbnail.jpg');
        expect(json['small'], 'small.jpg');
      });
    });
  });

  group('AppCachedImage Widget', () {
    testWidgets('should render with simple URL', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppCachedImage(
                imageUrl: 'https://example.com/image.jpg',
                width: 100,
                height: 100,
              ),
            ),
          ),
        );

        expect(find.byType(AppCachedImage), findsOneWidget);
      });
    });

    testWidgets('should render with variants', (tester) async {
      await mockNetworkImagesFor(() async {
        final variants = ImageVariants(
          original: 'https://example.com/original.jpg',
          large: 'https://example.com/large.jpg',
          medium: 'https://example.com/medium.jpg',
          thumbnail: 'https://example.com/thumbnail.jpg',
          small: 'https://example.com/small.jpg',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppCachedImage.variants(
                variants: variants,
                width: 100,
                height: 100,
              ),
            ),
          ),
        );

        expect(find.byType(AppCachedImage), findsOneWidget);
      });
    });

    testWidgets('should apply border radius', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppCachedImage(
                imageUrl: 'https://example.com/image.jpg',
                width: 100,
                height: 100,
                borderRadius: 16,
              ),
            ),
          ),
        );

        final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
        expect(
          clipRRect.borderRadius,
          BorderRadius.circular(16),
        );
      });
    });

    testWidgets('should render with forceVariant', (tester) async {
      await mockNetworkImagesFor(() async {
        final variants = ImageVariants(
          original: 'https://example.com/original.jpg',
          large: 'https://example.com/large.jpg',
          medium: 'https://example.com/medium.jpg',
          thumbnail: 'https://example.com/thumbnail.jpg',
          small: 'https://example.com/small.jpg',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppCachedImage.variants(
                variants: variants,
                forceVariant: ImageVariantSize.thumbnail,
                width: 500, // Would normally select medium
                height: 500,
              ),
            ),
          ),
        );

        expect(find.byType(AppCachedImage), findsOneWidget);
      });
    });

    testWidgets('should use default BoxFit.cover', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppCachedImage(
                imageUrl: 'https://example.com/image.jpg',
              ),
            ),
          ),
        );

        final widget = tester.widget<AppCachedImage>(find.byType(AppCachedImage));
        expect(widget.fit, BoxFit.cover);
      });
    });

    testWidgets('should accept custom BoxFit', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppCachedImage(
                imageUrl: 'https://example.com/image.jpg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );

        final widget = tester.widget<AppCachedImage>(find.byType(AppCachedImage));
        expect(widget.fit, BoxFit.contain);
      });
    });

    testWidgets('should render without explicit dimensions', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppCachedImage(
                imageUrl: 'https://example.com/image.jpg',
              ),
            ),
          ),
        );

        expect(find.byType(AppCachedImage), findsOneWidget);
      });
    });
  });
}
