class ImageConfig {
  final int maxWidth;
  final int maxHeight;
  final int quality; // 0-100 (WebP quality)

  const ImageConfig({
    required this.maxWidth,
    required this.maxHeight,
    this.quality = 80,
  });

  // Predefined configurations for different upload types
  static const cover = ImageConfig(
    maxWidth: 800,
    maxHeight: 800,
    quality: 80,
  );

  static const logPost = ImageConfig(
    maxWidth: 800,
    maxHeight: 800,
    quality: 80,
  );

  static const step = ImageConfig(
    maxWidth: 600,
    maxHeight: 600,
    quality: 80,
  );

  // Map upload type strings to configurations
  static const Map<String, ImageConfig> typeConfigs = {
    'COVER': cover,
    'LOG_POST': logPost,
    'STEP': step,
  };

  /// Get configuration for upload type, with fallback
  static ImageConfig forType(String type) {
    return typeConfigs[type] ?? logPost; // Default to logPost if type not found
  }
}
