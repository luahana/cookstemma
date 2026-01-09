import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/outcome_badge.dart';

/// Large outcome selection buttons for quick log flow
/// Designed for rapid, one-tap selection (~2 seconds)
class OutcomeSelector extends StatelessWidget {
  final LogOutcome? selectedOutcome;
  final ValueChanged<LogOutcome> onOutcomeSelected;

  const OutcomeSelector({
    super.key,
    this.selectedOutcome,
    required this.onOutcomeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header question
        Text(
          'logPost.quickLog.howDidItGo'.tr(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'logPost.quickLog.tapToSelect'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // Outcome buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: LogOutcome.values.map((outcome) {
            return _OutcomeButton(
              outcome: outcome,
              isSelected: selectedOutcome == outcome,
              onTap: () {
                HapticFeedback.mediumImpact();
                onOutcomeSelected(outcome);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Large, tappable outcome button with emoji and label
class _OutcomeButton extends StatefulWidget {
  final LogOutcome outcome;
  final bool isSelected;
  final VoidCallback onTap;

  const _OutcomeButton({
    required this.outcome,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_OutcomeButton> createState() => _OutcomeButtonState();
}

class _OutcomeButtonState extends State<_OutcomeButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.outcome.label} outcome',
      selected: widget.isSelected,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.outcome.primaryColor
                  : widget.outcome.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isSelected
                    ? widget.outcome.primaryColor
                    : widget.outcome.primaryColor.withValues(alpha: 0.3),
                width: widget.isSelected ? 3 : 2,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.outcome.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Large emoji
                Text(
                  widget.outcome.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                // Label
                Text(
                  widget.outcome.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isSelected
                        ? Colors.white
                        : widget.outcome.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal compact variant for smaller spaces
class CompactOutcomeSelector extends StatelessWidget {
  final LogOutcome? selectedOutcome;
  final ValueChanged<LogOutcome> onOutcomeSelected;

  const CompactOutcomeSelector({
    super.key,
    this.selectedOutcome,
    required this.onOutcomeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: LogOutcome.values.map((outcome) {
        final isSelected = selectedOutcome == outcome;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onOutcomeSelected(outcome);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? outcome.primaryColor
                    : outcome.backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? outcome.primaryColor
                      : outcome.primaryColor.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(outcome.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    outcome.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : outcome.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
