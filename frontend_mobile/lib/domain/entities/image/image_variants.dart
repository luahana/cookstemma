/// Represents image variants at different sizes for responsive loading.
/// Matches the backend ImageVariantsDto structure.
class ImageVariants {
  final String? imagePublicId;
  final String original;
  final String large;    // 1200px max
  final String medium;   // 800px max
  final String thumbnail; // 400px max
  final String small;    // 200px max

  const ImageVariants({
    this.imagePublicId,
    required this.original,
    required this.large,
    required this.medium,
    required this.thumbnail,
    required this.small,
  });

  /// Create from a single URL (no variants available)
  factory ImageVariants.fromUrl(String url) {
    return ImageVariants(
      original: url,
      large: url,
      medium: url,
      thumbnail: url,
      small: url,
    );
  }

  /// Create from API response JSON
  factory ImageVariants.fromJson(Map<String, dynamic> json) {
    final original = json['original'] as String? ?? '';
    return ImageVariants(
      imagePublicId: json['imagePublicId'] as String?,
      original: original,
      large: json['large'] as String? ?? original,
      medium: json['medium'] as String? ?? original,
      thumbnail: json['thumbnail'] as String? ?? original,
      small: json['small'] as String? ?? original,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imagePublicId': imagePublicId,
      'original': original,
      'large': large,
      'medium': medium,
      'thumbnail': thumbnail,
      'small': small,
    };
  }

  /// Get the best URL for the given display width in logical pixels.
  /// Takes into account device pixel ratio for sharp images.
  String getBestUrl(double displayWidth, double devicePixelRatio) {
    final physicalWidth = displayWidth * devicePixelRatio;

    if (physicalWidth <= 200) return small;
    if (physicalWidth <= 400) return thumbnail;
    if (physicalWidth <= 800) return medium;
    if (physicalWidth <= 1200) return large;
    return original;
  }

  /// Get URL for specific variant size
  String getVariant(ImageVariantSize size) {
    return switch (size) {
      ImageVariantSize.small => small,
      ImageVariantSize.thumbnail => thumbnail,
      ImageVariantSize.medium => medium,
      ImageVariantSize.large => large,
      ImageVariantSize.original => original,
    };
  }
}

/// Enum for explicitly requesting a specific variant size
enum ImageVariantSize {
  small,      // 200px - small previews, avatars
  thumbnail,  // 400px - grid thumbnails
  medium,     // 800px - mobile full, detail views
  large,      // 1200px - web full-screen
  original,   // Full resolution
}
