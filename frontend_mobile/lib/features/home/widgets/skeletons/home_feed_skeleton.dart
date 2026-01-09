import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header skeleton
            _buildSectionHeaderSkeleton(),
            const SizedBox(height: 12),
            // Bento grid skeleton
            const BentoGridSkeleton(),
            const SizedBox(height: 24),
            // Section header skeleton
            _buildSectionHeaderSkeleton(),
            const SizedBox(height: 12),
            // Horizontal scroll skeleton
            const HorizontalScrollSkeleton(),
            const SizedBox(height: 24),
            // Section header skeleton
            _buildSectionHeaderSkeleton(),
            const SizedBox(height: 12),
            // Recipe cards skeleton
            ...List.generate(3, (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: RecipeCardSkeleton(),
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
        ShimmerBox(width: 120, height: 20, borderRadius: 4),
        ShimmerBox(width: 60, height: 16, borderRadius: 4),
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
      height: 220,
      child: Row(
        children: [
          // Featured card skeleton
          Expanded(
            flex: 6,
            child: ShimmerBox(
              width: double.infinity,
              height: 220,
              borderRadius: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Small cards skeleton
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 12,
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
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ShimmerBox(width: 140, height: 160, borderRadius: 12),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail skeleton
          ShimmerBox(width: 80, height: 80, borderRadius: 8),
          const SizedBox(width: 12),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 60, height: 12, borderRadius: 4),
                const SizedBox(height: 8),
                ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerBox(width: 50, height: 20, borderRadius: 6),
                    const SizedBox(width: 8),
                    ShimmerBox(width: 50, height: 20, borderRadius: 6),
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
