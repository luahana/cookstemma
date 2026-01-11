import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/config/platform_url_resolver.dart';

/// A thumbnail widget for recipes that handles null URLs gracefully.
///
/// When [imageUrl] is null, displays a placeholder with a restaurant icon.
/// When [imageUrl] fails to load, displays a grey placeholder.
class RecipeThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final double? iconSize;

  const RecipeThumbnail({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? 20.sp;

    // No image URL - show placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(effectiveIconSize);
    }

    // Has image URL - load with error fallback
    final url = PlatformUrlResolver.adjustUrlForPlatform(imageUrl!);

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildLoadingPlaceholder(effectiveIconSize),
      errorWidget: (context, url, error) =>
          _buildErrorPlaceholder(effectiveIconSize),
    );

    if (borderRadius > 0) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder(double iconSize) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: borderRadius > 0 ? BorderRadius.circular(borderRadius) : null,
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          color: Colors.orange[300],
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(double iconSize) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          color: Colors.grey[400],
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(double iconSize) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          color: Colors.grey,
          size: iconSize,
        ),
      ),
    );
  }
}

/// A larger thumbnail for featured cards with gradient overlay support.
class FeaturedRecipeThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double? iconSize;

  const FeaturedRecipeThumbnail({
    super.key,
    this.imageUrl,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? 60.sp;

    // No image URL - show placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Colors.orange[200],
        child: Center(
          child: Icon(
            Icons.restaurant_menu,
            size: effectiveIconSize,
            color: Colors.orange[400],
          ),
        ),
      );
    }

    // Has image URL - load with error fallback
    final url = PlatformUrlResolver.adjustUrlForPlatform(imageUrl!);

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.orange[100],
        child: Center(
          child: Icon(
            Icons.restaurant_menu,
            size: effectiveIconSize,
            color: Colors.orange[300],
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.orange[200],
        child: Center(
          child: Icon(
            Icons.restaurant_menu,
            size: effectiveIconSize,
            color: Colors.orange[400],
          ),
        ),
      ),
    );
  }
}
