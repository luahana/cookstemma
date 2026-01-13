import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import '../../providers/cooking_mode_provider.dart';

/// Circular timer widget for cooking mode
class CookingTimerWidget extends StatelessWidget {
  final StepTimerState? timerState;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final VoidCallback onSetTimer;

  const CookingTimerWidget({
    super.key,
    this.timerState,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onSetTimer,
  });

  @override
  Widget build(BuildContext context) {
    if (timerState == null) {
      return _buildAddTimerButton();
    }

    return _buildTimerDisplay(context);
  }

  Widget _buildAddTimerButton() {
    return GestureDetector(
      onTap: onSetTimer,
      child: Container(
        width: 120.w,
        height: 120.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!, width: 2.w),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 32.sp,
              color: Colors.grey[600],
            ),
            SizedBox(height: 4.h),
            Text(
              'cooking.addTimer'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(BuildContext context) {
    final state = timerState!;
    final isRunning = state.isRunning;
    final isCompleted = state.isCompleted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular timer
        GestureDetector(
          onTap: isCompleted ? onReset : (isRunning ? onPause : onStart),
          child: SizedBox(
            width: 140.w,
            height: 140.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                CustomPaint(
                  size: Size(140.w, 140.w),
                  painter: _TimerPainter(
                    progress: state.progress,
                    isCompleted: isCompleted,
                    isRunning: isRunning,
                  ),
                ),
                // Time display
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.formattedRemaining,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? AppColors.growth
                            : (isRunning ? AppColors.primary : Colors.grey[800]),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      isCompleted
                          ? 'cooking.timerDone'.tr()
                          : (isRunning
                              ? 'cooking.tapToPause'.tr()
                              : 'cooking.tapToStart'.tr()),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reset button
            _buildControlButton(
              icon: Icons.refresh,
              onTap: onReset,
              tooltip: 'cooking.reset'.tr(),
            ),
            SizedBox(width: 16.w),
            // Edit timer button
            _buildControlButton(
              icon: Icons.edit_outlined,
              onTap: onSetTimer,
              tooltip: 'cooking.editTimer'.tr(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the circular timer
class _TimerPainter extends CustomPainter {
  final double progress;
  final bool isCompleted;
  final bool isRunning;

  _TimerPainter({
    required this.progress,
    required this.isCompleted,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = 8.0;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = isCompleted
          ? AppColors.growth
          : (isRunning ? AppColors.primary : Colors.grey[400]!)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isRunning != isRunning;
  }
}

/// Dialog to set timer duration
class TimerDurationPicker extends StatefulWidget {
  final Duration? initialDuration;
  final Function(Duration) onDurationSet;

  const TimerDurationPicker({
    super.key,
    this.initialDuration,
    required this.onDurationSet,
  });

  @override
  State<TimerDurationPicker> createState() => _TimerDurationPickerState();
}

class _TimerDurationPickerState extends State<TimerDurationPicker> {
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialDuration?.inMinutes ?? 5;
    _seconds = (widget.initialDuration?.inSeconds ?? 0) % 60;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('cooking.setTimer'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minutes picker
              _buildNumberPicker(
                value: _minutes,
                maxValue: 180,
                label: 'cooking.minutes'.tr(),
                onChanged: (v) => setState(() => _minutes = v),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Seconds picker
              _buildNumberPicker(
                value: _seconds,
                maxValue: 59,
                label: 'cooking.seconds'.tr(),
                onChanged: (v) => setState(() => _seconds = v),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Quick presets
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildPresetChip(1),
              _buildPresetChip(3),
              _buildPresetChip(5),
              _buildPresetChip(10),
              _buildPresetChip(15),
              _buildPresetChip(30),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton(
          onPressed: () {
            final duration = Duration(minutes: _minutes, seconds: _seconds);
            widget.onDurationSet(duration);
            Navigator.pop(context);
          },
          child: Text('common.set'.tr()),
        ),
      ],
    );
  }

  Widget _buildNumberPicker({
    required int value,
    required int maxValue,
    required String label,
    required Function(int) onChanged,
  }) {
    return Column(
      children: [
        Container(
          width: 80.w,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove, size: 16.sp),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 24.w, minHeight: 40.h),
              ),
              Expanded(
                child: Text(
                  value.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, size: 16.sp),
                onPressed: value < maxValue ? () => onChanged(value + 1) : null,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 24.w, minHeight: 40.h),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPresetChip(int minutes) {
    return ActionChip(
      label: Text('${minutes}min'),
      onPressed: () {
        setState(() {
          _minutes = minutes;
          _seconds = 0;
        });
      },
    );
  }
}
