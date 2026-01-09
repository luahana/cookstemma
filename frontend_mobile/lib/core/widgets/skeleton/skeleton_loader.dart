import 'package:flutter/material.dart';

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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            const SkeletonBox(
              width: double.infinity,
              height: 180,
              borderRadius: 16,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  const SkeletonBox(width: 80, height: 14, borderRadius: 4),
                  const SizedBox(height: 8),
                  // Title
                  const SkeletonBox(width: 200, height: 20, borderRadius: 4),
                  const SizedBox(height: 8),
                  // Description
                  const SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                  const SizedBox(height: 4),
                  const SkeletonBox(width: 150, height: 14, borderRadius: 4),
                  const SizedBox(height: 16),
                  // Creator row
                  Row(
                    children: [
                      SkeletonBox(width: 24, height: 24, borderRadius: 12),
                      const SizedBox(width: 8),
                      const SkeletonBox(width: 100, height: 14, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 40, borderRadius: 8)),
                      const SizedBox(width: 8),
                      Expanded(child: SkeletonBox(height: 40, borderRadius: 8)),
                      const SizedBox(width: 8),
                      Expanded(child: SkeletonBox(height: 40, borderRadius: 8)),
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
          borderRadius: BorderRadius.circular(12),
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
                borderRadius: 12,
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 60, height: 12, borderRadius: 4),
                    const SizedBox(height: 6),
                    const SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 28, borderRadius: 6)),
                        const SizedBox(width: 4),
                        Expanded(child: SkeletonBox(height: 28, borderRadius: 6)),
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
      padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const CompactCardSkeleton();
      },
    );
  }
}
