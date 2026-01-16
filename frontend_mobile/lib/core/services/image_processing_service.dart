import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:pairing_planet2_frontend/domain/entities/image/processed_image.dart';
import 'package:uuid/uuid.dart';

/// Service for processing images: hashing only (compression moved to backend)
class ImageProcessingService {
  /// Process image - compute hash only, backend handles compression
  ///
  /// Throws exception if processing fails - caller should handle fallback
  Future<ProcessedImage> processImage({
    required File originalFile,
    required String imageType,
  }) async {
    final startTime = DateTime.now();

    // Get file size
    final originalSize = await originalFile.length();

    try {
      // Generate perceptual hash for deduplication
      final hash = await _computePerceptualHash(originalFile);

      final processingTime = DateTime.now().difference(startTime);

      // Return original file - backend will handle compression
      return ProcessedImage(
        file: originalFile,
        hash: hash,
        originalSize: originalSize,
        compressedSize: originalSize, // Same as original (no client compression)
        compressionRatio: 0.0, // No client-side compression
        processingTime: processingTime,
      );
    } catch (e) {
      rethrow; // Let UseCase handle fallback
    }
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
