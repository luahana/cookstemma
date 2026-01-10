import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Circular progress ring widget for displaying XP progress in navigation
class NavProgressRing extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final int? level;
  final Widget child;
  final bool isActive;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? trackColor;

  const NavProgressRing({
    super.key,
    required this.progress,
    this.level,
    required this.child,
    this.isActive = false,
    this.size = 40,
    this.strokeWidth = 3,
    this.progressColor,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = progressColor ?? Theme.of(context).primaryColor;
    final bgColor = trackColor ?? Colors.grey[300]!;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: progress.clamp(0.0, 1.0),
              trackColor: bgColor,
              progressColor: isActive ? primaryColor : primaryColor.withValues(alpha: 0.6),
              strokeWidth: strokeWidth,
            ),
          ),
          // Icon inside
          child,
          // Level badge (small, positioned at bottom-right)
          if (level != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    level.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track paint (background circle)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Progress paint (filled arc)
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw track
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc (starting from top, -90 degrees)
    if (progress > 0) {
      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
