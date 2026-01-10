import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Simple shimmer box without animation (to avoid crashes)
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Full home feed skeleton
class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header skeleton
            _buildSectionHeaderSkeleton(),
            SizedBox(height: 12.h),
            // Bento grid skeleton
            const BentoGridSkeleton(),
            SizedBox(height: 24.h),
            // Section header skeleton
            _buildSectionHeaderSkeleton(),
            SizedBox(height: 12.h),
            // Horizontal scroll skeleton
            const HorizontalScrollSkeleton(),
            SizedBox(height: 24.h),
            // Section header skeleton
            _buildSectionHeaderSkeleton(),
            SizedBox(height: 12.h),
            // Recipe cards skeleton
            ...List.generate(3, (index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: const RecipeCardSkeleton(),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeaderSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ShimmerBox(width: 120.w, height: 20.h, borderRadius: 4.r),
        ShimmerBox(width: 60.w, height: 16.h, borderRadius: 4.r),
      ],
    );
  }
}

/// Bento grid skeleton
class BentoGridSkeleton extends StatelessWidget {
  const BentoGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220.h,
      child: Row(
        children: [
          // Featured card skeleton
          Expanded(
            flex: 6,
            child: ShimmerBox(
              width: double.infinity,
              height: 220.h,
              borderRadius: 16.r,
            ),
          ),
          SizedBox(width: 12.w),
          // Small cards skeleton
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 12.r,
                  ),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 12.r,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scroll skeleton
class HorizontalScrollSkeleton extends StatelessWidget {
  const HorizontalScrollSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: ShimmerBox(width: 140.w, height: 160.h, borderRadius: 12.r),
          );
        },
      ),
    );
  }
}

/// Recipe card skeleton
class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Thumbnail skeleton
          ShimmerBox(width: 80.w, height: 80.w, borderRadius: 8.r),
          SizedBox(width: 12.w),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 60.w, height: 12.h, borderRadius: 4.r),
                SizedBox(height: 8.h),
                ShimmerBox(width: double.infinity, height: 16.h, borderRadius: 4.r),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    ShimmerBox(width: 50.w, height: 20.h, borderRadius: 6.r),
                    SizedBox(width: 8.w),
                    ShimmerBox(width: 50.w, height: 20.h, borderRadius: 6.r),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
