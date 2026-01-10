import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pairing_planet2_frontend/core/config/app_config.dart';
import 'package:pairing_planet2_frontend/domain/entities/image/image_variants.dart';

/// A cached network image widget that automatically selects the optimal
/// image variant based on display size and device pixel ratio.
///
/// Supports two modes:
/// 1. Simple URL mode: Pass [imageUrl] for backward compatibility
/// 2. Variants mode: Pass [variants] for optimized loading
class AppCachedImage extends StatelessWidget {
  /// Simple image URL (for backward compatibility)
  final String? imageUrl;

  /// Image variants for responsive loading
  final ImageVariants? variants;

  /// Force a specific variant size instead of auto-selecting
  final ImageVariantSize? forceVariant;

  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const AppCachedImage({
    super.key,
    this.imageUrl,
    this.variants,
    this.forceVariant,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  }) : assert(
         imageUrl != null || variants != null,
         'Either imageUrl or variants must be provided',
       );

  /// Named constructor for using variants
  const AppCachedImage.variants({
    super.key,
    required ImageVariants this.variants,
    this.forceVariant,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  }) : imageUrl = null;

  @override
  Widget build(BuildContext context) {
    final url = _resolveUrl(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  String _resolveUrl(BuildContext context) {
    String url;

    // If using simple URL mode
    if (variants == null) {
      url = imageUrl ?? '';
    } else if (forceVariant != null) {
      // If force variant is specified
      url = variants!.getVariant(forceVariant!);
    } else {
      // Auto-select based on display size
      final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
      final displayWidth = width ?? _estimateDisplayWidth(context);
      url = variants!.getBestUrl(displayWidth, devicePixelRatio);
    }

    // Adjust URL for platform (iOS uses localhost, Android uses 10.0.2.2)
    return AppConfig.adjustUrlForPlatform(url);
  }

  double _estimateDisplayWidth(BuildContext context) {
    // If width is provided, use it
    if (width != null) return width!;

    // Try to get width from layout constraints
    // Default to screen width / 2 for grid items
    final screenWidth = MediaQuery.sizeOf(context).width;
    return screenWidth / 2;
  }
}
