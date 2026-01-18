import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/models/log_rating.dart';

// Re-export LogRating for backward compatibility
export 'package:pairing_planet2_frontend/core/models/log_rating.dart';

/// Badge variants for different display contexts
enum RatingBadgeVariant {
  /// Full badge with stars and label: [★★★★☆ 4/5]
  full,
  /// Compact badge with stars only: [★★★★☆]
  compact,
  /// Large stars for card headers
  header,
  /// Single row of small stars
  mini,
}

/// Styled rating badge widget for cooking logs
class RatingBadge extends StatelessWidget {
  final int rating; // 1-5
  final RatingBadgeVariant variant;
  final VoidCallback? onTap;

  const RatingBadge({
    super.key,
    required this.rating,
    this.variant = RatingBadgeVariant.full,
    this.onTap,
  });

  /// Create badge from nullable rating value
  factory RatingBadge.fromInt({
    int? ratingValue,
    RatingBadgeVariant variant = RatingBadgeVariant.full,
    VoidCallback? onTap,
  }) {
    return RatingBadge(
      rating: ratingValue ?? 3,
      variant: variant,
      onTap: onTap,
    );
  }

  Color get _starColor {
    if (rating >= 4) return const Color(0xFFFFC107);
    if (rating >= 3) return const Color(0xFFFF9800);
    return const Color(0xFFBDBDBD);
  }

  Color get _backgroundColor {
    if (rating >= 4) return const Color(0xFFFFF8E1);
    if (rating >= 3) return const Color(0xFFFFF3E0);
    return const Color(0xFFFAFAFA);
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case RatingBadgeVariant.full:
        return _buildFullBadge();
      case RatingBadgeVariant.compact:
        return _buildCompactBadge();
      case RatingBadgeVariant.header:
        return _buildHeaderBadge();
      case RatingBadgeVariant.mini:
        return _buildMiniBadge();
    }
  }

  Widget _buildStars(double iconSize, {Color? emptyColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < rating;
        return Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: iconSize,
          color: isFilled ? _starColor : (emptyColor ?? Colors.grey[300]),
        );
      }),
    );
  }

  Widget _buildFullBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: _starColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStars(14.sp),
          SizedBox(width: 6.w),
          Text(
            '$rating/5',
            style: TextStyle(
              color: _starColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBadge() {
    return _buildStars(16.sp);
  }

  Widget _buildHeaderBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStars(24.sp),
        SizedBox(width: 8.w),
        Text(
          '$rating/5',
          style: TextStyle(
            color: _starColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge() {
    return _buildStars(12.sp);
  }
}

/// Stats display showing average rating and distribution
class RatingStatsRow extends StatelessWidget {
  final double? averageRating;
  final int totalLogs;
  final bool compact;

  const RatingStatsRow({
    super.key,
    this.averageRating,
    required this.totalLogs,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (averageRating == null || totalLogs == 0) {
      return Text(
        '-',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: compact ? 12.sp : 14.sp,
        ),
      );
    }

    final starColor = averageRating! >= 4
        ? const Color(0xFFFFC107)
        : averageRating! >= 3
            ? const Color(0xFFFF9800)
            : const Color(0xFFBDBDBD);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 14.sp,
            color: starColor,
          ),
          SizedBox(width: 2.w),
          Text(
            averageRating!.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: 18.sp,
          color: starColor,
        ),
        SizedBox(width: 4.w),
        Text(
          averageRating!.toStringAsFixed(1),
          style: TextStyle(
            color: starColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '($totalLogs logs)',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}
