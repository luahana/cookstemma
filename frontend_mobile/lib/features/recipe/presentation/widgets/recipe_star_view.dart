import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/widgets/star_node.dart';

/// Star graph visualization showing root recipe at center with variants around it
class RecipeStarView extends StatefulWidget {
  final RecipeSummary rootRecipe;
  final List<RecipeSummary> variants;
  final String? selectedRecipeId;
  final ValueChanged<RecipeSummary>? onNodeSelected;
  final VoidCallback? onBackPressed;

  const RecipeStarView({
    super.key,
    required this.rootRecipe,
    required this.variants,
    this.selectedRecipeId,
    this.onNodeSelected,
    this.onBackPressed,
  });

  @override
  State<RecipeStarView> createState() => _RecipeStarViewState();
}

class _RecipeStarViewState extends State<RecipeStarView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  RecipeSummary? _selectedRecipe;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Start animation
    _animationController.forward();

    // Set initial selection
    if (widget.selectedRecipeId != null) {
      if (widget.rootRecipe.publicId == widget.selectedRecipeId) {
        _selectedRecipe = widget.rootRecipe;
      } else {
        _selectedRecipe = widget.variants.firstWhere(
          (v) => v.publicId == widget.selectedRecipeId,
          orElse: () => widget.rootRecipe,
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onNodeTap(RecipeSummary recipe) {
    setState(() {
      if (_selectedRecipe?.publicId == recipe.publicId) {
        _selectedRecipe = null; // Deselect if tapping same node
      } else {
        _selectedRecipe = recipe;
      }
    });
    widget.onNodeSelected?.call(recipe);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Stack(
        children: [
          // Star graph
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _StarConnectionPainter(
                    variantCount: widget.variants.length,
                    progress: _fadeAnimation.value,
                  ),
                  child: child,
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildStarLayout(constraints);
                },
              ),
            ),
          ),
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),
          // Selected node card
          if (_selectedRecipe != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSelectedCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[100]!,
            Colors.grey[100]!.withValues(alpha: 0),
          ],
        ),
      ),
      child: Row(
        children: [
          if (widget.onBackPressed != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBackPressed,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'star.title'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.rootRecipe.foodName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem('📌', 'star.root'.tr()),
          const SizedBox(width: 12),
          _buildLegendItem('🔀', '${widget.variants.length}'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStarLayout(BoxConstraints constraints) {
    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2 - 40; // Offset up a bit
    final radius = math.min(constraints.maxWidth, constraints.maxHeight) * 0.32;

    // Calculate positions
    final positions = _calculatePositions(
      center: Offset(centerX, centerY),
      radius: radius,
      variantCount: widget.variants.length,
    );

    return Stack(
      children: [
        // Root node at center
        Positioned(
          left: positions.rootPosition.dx - 56,
          top: positions.rootPosition.dy - 56,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              children: [
                StarNode(
                  recipe: widget.rootRecipe,
                  isRoot: true,
                  isSelected: _selectedRecipe?.publicId == widget.rootRecipe.publicId,
                  onTap: () => _onNodeTap(widget.rootRecipe),
                ),
                const SizedBox(height: 4),
                StarNodeLabel(
                  text: widget.rootRecipe.title,
                  isRoot: true,
                ),
              ],
            ),
          ),
        ),
        // Variant nodes around
        ...List.generate(widget.variants.length, (index) {
          final variant = widget.variants[index];
          final position = positions.variantPositions[index];

          return Positioned(
            left: position.dx - 40,
            top: position.dy - 40,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  0.2 + (index * 0.1).clamp(0.0, 0.6),
                  0.8 + (index * 0.1).clamp(0.0, 0.2),
                  curve: Curves.easeOutBack,
                ),
              ),
              child: Column(
                children: [
                  StarNode(
                    recipe: variant,
                    isRoot: false,
                    isSelected: _selectedRecipe?.publicId == variant.publicId,
                    onTap: () => _onNodeTap(variant),
                  ),
                  const SizedBox(height: 4),
                  StarNodeLabel(text: variant.title),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  _StarPositions _calculatePositions({
    required Offset center,
    required double radius,
    required int variantCount,
  }) {
    final variantPositions = <Offset>[];

    for (int i = 0; i < variantCount; i++) {
      // Start from top (-π/2) and go clockwise
      final angle = (2 * math.pi * i / variantCount) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      variantPositions.add(Offset(x, y));
    }

    return _StarPositions(
      rootPosition: center,
      variantPositions: variantPositions,
    );
  }

  Widget _buildSelectedCard() {
    if (_selectedRecipe == null) return const SizedBox.shrink();

    final isRoot = _selectedRecipe!.publicId == widget.rootRecipe.publicId;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: Offset.zero,
      curve: Curves.easeOut,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: StarNodeCard(
          recipe: _selectedRecipe!,
          isRoot: isRoot,
          onViewRecipe: () {
            context.push(RouteConstants.recipeDetailPath(_selectedRecipe!.publicId));
          },
          onLog: () {
            context.push(RouteConstants.recipeDetailPath(_selectedRecipe!.publicId));
          },
          onFork: () {
            context.push(RouteConstants.recipeDetailPath(_selectedRecipe!.publicId));
          },
        ),
      ),
    );
  }
}

class _StarPositions {
  final Offset rootPosition;
  final List<Offset> variantPositions;

  _StarPositions({
    required this.rootPosition,
    required this.variantPositions,
  });
}

/// Custom painter for drawing connection lines between nodes
class _StarConnectionPainter extends CustomPainter {
  final int variantCount;
  final double progress;

  _StarConnectionPainter({
    required this.variantCount,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (variantCount == 0 || progress == 0) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2 - 40;
    final center = Offset(centerX, centerY);
    final radius = math.min(size.width, size.height) * 0.32;

    final paint = Paint()
      ..color = Colors.grey[300]!.withValues(alpha: progress * 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw lines from center to each variant position
    for (int i = 0; i < variantCount; i++) {
      final angle = (2 * math.pi * i / variantCount) - (math.pi / 2);
      final endX = centerX + radius * math.cos(angle) * progress;
      final endY = centerY + radius * math.sin(angle) * progress;

      canvas.drawLine(center, Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarConnectionPainter oldDelegate) {
    return oldDelegate.variantCount != variantCount ||
        oldDelegate.progress != progress;
  }
}

/// Compact star preview for grid/list cards
class StarPreviewMini extends StatelessWidget {
  final int variantCount;
  final int logCount;

  const StarPreviewMini({
    super.key,
    required this.variantCount,
    required this.logCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$variantCount',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (logCount > 0) ...[
            Text(
              ' · ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            Icon(Icons.edit_note, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 2),
            Text(
              '$logCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
