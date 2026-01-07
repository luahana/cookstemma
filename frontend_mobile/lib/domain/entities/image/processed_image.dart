import 'dart:io';

/// Value object representing a processed image with compression metadata
class ProcessedImage {
  /// Compressed WebP file in temporary directory
  final File file;

  /// Perceptual hash (8x8 average hash) for deduplication
  final String hash;

  /// Original file size in bytes
  final int originalSize;

  /// Compressed file size in bytes
  final int compressedSize;

  /// Compression ratio (0.0 to 1.0, where 0.8 = 80% reduction)
  final double compressionRatio;

  /// Time taken to process the image
  final Duration processingTime;

  ProcessedImage({
    required this.file,
    required this.hash,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.processingTime,
  });

  /// Compression percentage (0-100)
  double get compressionPercentage => compressionRatio * 100;

  /// Size reduction in bytes
  int get sizeSaved => originalSize - compressedSize;

  @override
  String toString() {
    return 'ProcessedImage('
        'original: ${_formatBytes(originalSize)}, '
        'compressed: ${_formatBytes(compressedSize)}, '
        'saved: ${compressionPercentage.toStringAsFixed(1)}%, '
        'time: ${processingTime.inMilliseconds}ms'
        ')';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
