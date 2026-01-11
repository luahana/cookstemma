import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer effect animation for skeleton loading
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Base skeleton box with rounded corners
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
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

/// Skeleton for recipe card in list view
class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            SkeletonBox(
              width: double.infinity,
              height: 180.h,
              borderRadius: 16.r,
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  SkeletonBox(width: 80.w, height: 14.h, borderRadius: 4.r),
                  SizedBox(height: 8.h),
                  // Title
                  SkeletonBox(width: 200.w, height: 20.h, borderRadius: 4.r),
                  SizedBox(height: 8.h),
                  // Description
                  SkeletonBox(width: double.infinity, height: 14.h, borderRadius: 4.r),
                  SizedBox(height: 4.h),
                  SkeletonBox(width: 150.w, height: 14.h, borderRadius: 4.r),
                  SizedBox(height: 16.h),
                  // Creator row
                  Row(
                    children: [
                      SkeletonBox(width: 24.w, height: 24.w, borderRadius: 12.r),
                      SizedBox(width: 8.w),
                      SkeletonBox(width: 100.w, height: 14.h, borderRadius: 4.r),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 40.h, borderRadius: 8.r)),
                      SizedBox(width: 8.w),
                      Expanded(child: SkeletonBox(height: 40.h, borderRadius: 8.r)),
                      SizedBox(width: 8.w),
                      Expanded(child: SkeletonBox(height: 40.h, borderRadius: 8.r)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for compact recipe card in grid view
class CompactCardSkeleton extends StatelessWidget {
  final double height;

  const CompactCardSkeleton({
    super.key,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              flex: 3,
              child: SkeletonBox(
                width: double.infinity,
                borderRadius: 12.r,
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 60.w, height: 12.h, borderRadius: 4.r),
                    SizedBox(height: 6.h),
                    SkeletonBox(width: double.infinity, height: 14.h, borderRadius: 4.r),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 28.h, borderRadius: 6.r)),
                        SizedBox(width: 4.w),
                        Expanded(child: SkeletonBox(height: 28.h, borderRadius: 6.r)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton list for recipe list view
class RecipeListSkeleton extends StatelessWidget {
  final int itemCount;

  const RecipeListSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const RecipeCardSkeleton();
      },
    );
  }
}

/// Skeleton grid for grid view
class RecipeGridSkeleton extends StatelessWidget {
  final int itemCount;

  const RecipeGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(16.r),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const CompactCardSkeleton();
      },
    );
  }
}
