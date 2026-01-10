import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';

/// Large, prominent floating action button for quick log entry
/// Designed for rapid access - the primary action on the log list screen
class QuickLogFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isExpanded;

  const QuickLogFAB({
    super.key,
    required this.onPressed,
    this.isExpanded = true,
  });

  @override
  State<QuickLogFAB> createState() => _QuickLogFABState();
}

class _QuickLogFABState extends State<QuickLogFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      label: 'logPost.quickLog.fabLabel'.tr(),
      hint: 'logPost.quickLog.fabHint'.tr(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring effect
                Container(
                  width: 72 + (_pulseAnimation.value * 16),
                  height: 72 + (_pulseAnimation.value * 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: 0.2 * (1 - _pulseAnimation.value),
                    ),
                  ),
                ),
                // Main FAB
                child!,
              ],
            ),
          );
        },
        child: _buildFAB(),
      ),
    );
  }

  Widget _buildFAB() {
    if (widget.isExpanded) {
      return _buildExpandedFAB();
    }
    return _buildCompactFAB();
  }

  Widget _buildExpandedFAB() {
    return Material(
      elevation: 8,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onPressed();
        },
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFD35400)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'logPost.quickLog.button'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFAB() {
    return Material(
      elevation: 8,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onPressed();
        },
        customBorder: const CircleBorder(),
        child: Ink(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFFD35400)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Minimal FAB variant for when space is limited
class MiniQuickLogFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const MiniQuickLogFAB({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'logPost.quickLog.fabLabel'.tr(),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        backgroundColor: AppColors.primary,
        elevation: 6,
        child: const Icon(
          Icons.add_a_photo_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
