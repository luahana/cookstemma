import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/core/services/image_processing_service.dart';
import 'package:pairing_planet2_frontend/data/models/image/image_upload_response_dto.dart';
import 'package:pairing_planet2_frontend/domain/repositories/image_repository.dart';

class UploadImageUseCase {
  final ImageRepository _repository;
  final ImageProcessingService _processingService;

  UploadImageUseCase(this._repository, this._processingService);

  Future<Either<Failure, ImageUploadResult>> execute({
    required File file,
    required String type,
  }) async {
    File? tempFile;
    String? hash;
    int originalSize = 0;
    int compressedSize = 0;
    double compressionRatio = 0.0;
    bool compressionFailed = false;

    try {
      // Try to process (compress) the image
      final processed = await _processingService.processImage(
        originalFile: file,
        imageType: type,
      );

      tempFile = processed.file;
      hash = processed.hash;
      originalSize = processed.originalSize;
      compressedSize = processed.compressedSize;
      compressionRatio = processed.compressionRatio;
    } catch (e) {
      // Compression failed - fallback to original file
      compressionFailed = true;
      originalSize = await file.length();
      compressedSize = originalSize;
      compressionRatio = 0.0;
    }

    // Upload either processed file or original file
    final fileToUpload = tempFile ?? file;
    final uploadResult = await _repository.uploadImage(
      file: fileToUpload,
      type: type,
    );

    // Clean up temporary compressed file (if different from original)
    if (tempFile != null && tempFile.path != file.path) {
      try {
        await tempFile.delete();
      } catch (e) {
        // Ignore cleanup errors - OS will handle temp directory
      }
    }

    // Return result with metadata
    return uploadResult.map(
      (response) => ImageUploadResult(
        response: response,
        metadata: ImageUploadMetadata(
          hash: hash,
          originalSize: originalSize,
          compressedSize: compressedSize,
          compressionRatio: compressionRatio,
          compressionFailed: compressionFailed,
        ),
      ),
    );
  }
}
