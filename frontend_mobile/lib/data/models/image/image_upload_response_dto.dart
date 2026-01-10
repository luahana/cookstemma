import 'package:json_annotation/json_annotation.dart';

part 'image_upload_response_dto.g.dart';

@JsonSerializable()
class ImageUploadResponseDto {
  final String imagePublicId; // UUID
  final String imageUrl; // 이미지 접근 URL
  final String originalFilename;

  ImageUploadResponseDto({
    required this.imagePublicId,
    required this.imageUrl,
    required this.originalFilename,
  });

  factory ImageUploadResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ImageUploadResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ImageUploadResponseDtoToJson(this);
}

/// Extended result that includes both the upload response and compression metadata
class ImageUploadResult {
  final ImageUploadResponseDto response;
  final ImageUploadMetadata metadata;

  ImageUploadResult({
    required this.response,
    required this.metadata,
  });
}

/// Metadata about image processing for analytics and monitoring
class ImageUploadMetadata {
  /// Perceptual hash for deduplication (Phase 3 feature)
  final String? hash;

  /// Original file size in bytes
  final int originalSize;

  /// Compressed file size in bytes
  final int compressedSize;

  /// Compression ratio (0.0 to 1.0, where 0.8 = 80% reduction)
  final double compressionRatio;

  /// Whether compression failed and we fell back to original file
  final bool compressionFailed;

  ImageUploadMetadata({
    this.hash,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    this.compressionFailed = false,
  });

  /// Convert to analytics properties for event tracking
  Map<String, dynamic> toAnalyticsProperties() => {
        if (hash != null) 'image_hash': hash,
        'original_size': originalSize,
        'compressed_size': compressedSize,
        'compression_ratio': (compressionRatio * 100).toStringAsFixed(1),
        'format': 'webp',
        'compression_failed': compressionFailed,
      };

  /// Compression percentage (0-100)
  double get compressionPercentage => compressionRatio * 100;

  /// Size saved in bytes
  int get sizeSaved => originalSize - compressedSize;
}
