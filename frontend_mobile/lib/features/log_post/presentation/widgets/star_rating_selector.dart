import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Star rating selector for quick log flow
/// Replaces the old 3-button OutcomeSelector with 1-5 star rating
class StarRatingSelector extends StatelessWidget {
  final int? selectedRating;
  final ValueChanged<int> onRatingSelected;

  const StarRatingSelector({
    super.key,
    this.selectedRating,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header question
        Text(
          'logPost.quickLog.howWouldYouRate'.tr(),
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          'logPost.quickLog.tapToRate'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32.h),
        // Star rating row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isSelected = selectedRating != null && starNumber <= selectedRating!;
            return _StarButton(
              starNumber: starNumber,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.mediumImpact();
                onRatingSelected(starNumber);
              },
            );
          }),
        ),
        SizedBox(height: 16.h),
        // Rating label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: selectedRating != null
              ? Text(
                  _getRatingLabel(selectedRating!),
                  key: ValueKey(selectedRating),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: _getRatingColor(selectedRating!),
                  ),
                )
              : SizedBox(height: 20.h),
        ),
      ],
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'logPost.ratingLabel.1'.tr();
      case 2:
        return 'logPost.ratingLabel.2'.tr();
      case 3:
        return 'logPost.ratingLabel.3'.tr();
      case 4:
        return 'logPost.ratingLabel.4'.tr();
      case 5:
        return 'logPost.ratingLabel.5'.tr();
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return const Color(0xFF4CAF50);
    if (rating >= 3) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}

/// Individual star button with animation
class _StarButton extends StatefulWidget {
  final int starNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const _StarButton({
    required this.starNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StarButton> createState() => _StarButtonState();
}

class _StarButtonState extends State<_StarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_StarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.starNumber} star rating',
      selected: widget.isSelected,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.isSelected
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                key: ValueKey(widget.isSelected),
                size: 48.sp,
                color: widget.isSelected
                    ? const Color(0xFFFFC107)
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact star rating selector for smaller spaces
class CompactStarRatingSelector extends StatelessWidget {
  final int? selectedRating;
  final ValueChanged<int> onRatingSelected;
  final double starSize;

  const CompactStarRatingSelector({
    super.key,
    this.selectedRating,
    required this.onRatingSelected,
    this.starSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isSelected = selectedRating != null && starNumber <= selectedRating!;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onRatingSelected(starNumber);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
              size: starSize.sp,
              color: isSelected ? const Color(0xFFFFC107) : Colors.grey[300],
            ),
          ),
        );
      }),
    );
  }
}
