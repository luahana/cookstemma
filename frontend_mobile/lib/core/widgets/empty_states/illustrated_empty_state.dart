import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Illustrated empty state with animated icon and action button
class IllustratedEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool animate;

  const IllustratedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.animate = true,
  });

  @override
  State<IllustratedEmptyState> createState() => _IllustratedEmptyStateState();
}

class _IllustratedEmptyStateState extends State<IllustratedEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon with decorative background
            ScaleTransition(
              scale: _bounceAnimation,
              child: Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: (widget.iconColor ?? Colors.grey[400])!.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: (widget.iconColor ?? Colors.grey[400])!.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 40.sp,
                      color: widget.iconColor ?? Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            // Title and subtitle
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subtitle != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (widget.actionLabel != null && widget.onAction != null) ...[
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: widget.onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(widget.actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Specialized empty state for no recipes
class NoRecipesEmptyState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const NoRecipesEmptyState({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return IllustratedEmptyState(
      icon: Icons.restaurant_menu_outlined,
      title: 'No recipes yet',
      subtitle: 'Pull down to refresh or check back later',
      actionLabel: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
      iconColor: Colors.orange[300],
    );
  }
}

/// Specialized empty state for no filter results
class NoFilterResultsEmptyState extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const NoFilterResultsEmptyState({
    super.key,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return IllustratedEmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: 'No matching recipes',
      subtitle: 'Try adjusting your filters',
      actionLabel: onClearFilters != null ? 'Clear filters' : null,
      onAction: onClearFilters,
      iconColor: AppColors.growth,
    );
  }
}

/// Specialized empty state for no star variants
class NoVariantsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateVariant;

  const NoVariantsEmptyState({
    super.key,
    this.onCreateVariant,
  });

  @override
  Widget build(BuildContext context) {
    return IllustratedEmptyState(
      icon: Icons.auto_awesome_outlined,
      title: 'No variants yet',
      subtitle: 'Be the first to create a variation of this recipe!',
      actionLabel: onCreateVariant != null ? 'Create Variant' : null,
      onAction: onCreateVariant,
      iconColor: Colors.purple[300],
    );
  }
}

/// Specialized empty state for connection errors
class ConnectionErrorEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? errorMessage;

  const ConnectionErrorEmptyState({
    super.key,
    this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return IllustratedEmptyState(
      icon: Icons.wifi_off_outlined,
      title: 'Connection error',
      subtitle: errorMessage ?? 'Please check your internet connection',
      actionLabel: onRetry != null ? 'Try again' : null,
      onAction: onRetry,
      iconColor: Colors.red[300],
    );
  }
}
