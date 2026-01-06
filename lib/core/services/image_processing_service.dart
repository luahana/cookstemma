import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pairing_planet2_frontend/domain/entities/image/image_config.dart';
import 'package:pairing_planet2_frontend/domain/entities/image/processed_image.dart';
import 'package:uuid/uuid.dart';

/// Service for processing images: compression, resizing, format conversion, and hashing
class ImageProcessingService {
  /// Process image with compression, resizing, WebP conversion, and hashing
  ///
  /// Throws exception if processing fails - caller should handle fallback
  Future<ProcessedImage> processImage({
    required File originalFile,
    required String imageType,
  }) async {
    final startTime = DateTime.now();

    // Get configuration for this image type
    final config = ImageConfig.forType(imageType);

    // Get file sizes before processing
    final originalSize = await originalFile.length();

    try {
      // Step 1: Resize and compress to WebP
      final compressedFile = await _compressToWebP(
        originalFile,
        config,
      );

      // Step 2: Generate perceptual hash for deduplication (Phase 3)
      final hash = await _computePerceptualHash(compressedFile);

      // Get compressed file size
      final compressedSize = await compressedFile.length();

      // Calculate compression ratio
      final compressionRatio = originalSize > 0
          ? (originalSize - compressedSize) / originalSize
          : 0.0;

      final processingTime = DateTime.now().difference(startTime);

      return ProcessedImage(
        file: compressedFile,
        hash: hash,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: compressionRatio,
        processingTime: processingTime,
      );
    } catch (e) {
      // Clean up any partially created files
      rethrow; // Let UseCase handle fallback
    }
  }

  /// Compress image to WebP format with resizing
  Future<File> _compressToWebP(
    File originalFile,
    ImageConfig config,
  ) async {
    // Create temp directory for compressed file
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = const Uuid().v4().substring(0, 8);
    final tempPath = '${tempDir.path}/compressed_${timestamp}_$uuid.webp';

    // Compress to WebP with resizing
    final result = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      tempPath,
      quality: config.quality,
      minWidth: config.maxWidth,
      minHeight: config.maxHeight,
      format: CompressFormat.webp,
    );

    if (result == null) {
      throw Exception('Image compression failed - result is null');
    }

    return File(result.path);
  }

  /// Compute 8x8 average perceptual hash for image deduplication
  ///
  /// This hash is used to identify similar/duplicate images even if they've
  /// been resized or slightly modified. Returns hex string (16 characters).
  Future<String> _computePerceptualHash(File file) async {
    try {
      // Read image bytes
      final bytes = await file.readAsBytes();

      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image for hashing');
      }

      // Resize to 8x8 for average hash
      final resized = img.copyResize(
        image,
        width: 8,
        height: 8,
        interpolation: img.Interpolation.average,
      );

      // Convert to grayscale
      final grayscale = img.grayscale(resized);

      // Calculate average pixel value
      int sum = 0;
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final pixel = grayscale.getPixel(x, y);
          sum += pixel.r.toInt(); // R, G, B are same in grayscale
        }
      }
      final average = sum / 64;

      // Generate hash bits: 1 if pixel > average, 0 otherwise
      int hash = 0;
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final pixel = grayscale.getPixel(x, y);
          if (pixel.r > average) {
            hash |= 1 << (y * 8 + x);
          }
        }
      }

      // Convert to hex string (16 characters for 64 bits)
      return hash.toRadixString(16).padLeft(16, '0');
    } catch (e) {
      // Fallback: generate random hash if hashing fails
      // This ensures upload isn't blocked by hash computation failure
      return const Uuid().v4().replaceAll('-', '').substring(0, 16);
    }
  }
}
