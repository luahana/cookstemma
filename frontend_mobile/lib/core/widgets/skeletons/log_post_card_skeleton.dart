import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton widget for log post grid loading state.
/// Matches the 2-column grid layout with aspect ratio 0.75.
class LogPostGridSkeleton extends StatelessWidget {
  final int itemCount;
  final bool showFilterBar;
  final bool showProgressCard;

  const LogPostGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.showFilterBar = true,
    this.showProgressCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // Progress overview card skeleton
          if (showProgressCard)
            const SliverToBoxAdapter(
              child: _ProgressOverviewSkeleton(),
            ),
          // Filter bar skeleton
          if (showFilterBar)
            const SliverToBoxAdapter(
              child: _FilterBarSkeleton(),
            ),
          // Grid skeleton
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => const _LogPostCardSkeleton(),
                childCount: itemCount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter bar skeleton
class _FilterBarSkeleton extends StatelessWidget {
  const _FilterBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChipSkeleton(width: 50),
          const SizedBox(width: 8),
          _buildChipSkeleton(width: 70),
          const SizedBox(width: 8),
          _buildChipSkeleton(width: 80),
          const SizedBox(width: 8),
          _buildChipSkeleton(width: 75),
        ],
      ),
    );
  }

  Widget _buildChipSkeleton({required double width}) {
    return Container(
      width: width,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// Progress overview card skeleton
class _ProgressOverviewSkeleton extends StatelessWidget {
  const _ProgressOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

/// Single log post card skeleton.
class _LogPostCardSkeleton extends StatelessWidget {
  const _LogPostCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area with outcome badge (flex: 3)
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
                // Outcome badge skeleton
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Text area (flex: 1)
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
