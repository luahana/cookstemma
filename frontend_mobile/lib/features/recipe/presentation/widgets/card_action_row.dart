import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Action buttons for recipe cards: Log and Fork
class CardActionRow extends StatelessWidget {
  final VoidCallback? onLog;
  final VoidCallback? onFork;

  const CardActionRow({
    super.key,
    this.onLog,
    this.onFork,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Log button
        Expanded(
          child: _ActionButton(
            icon: Icons.edit_note,
            label: 'recipe.action.log'.tr(),
            onTap: onLog,
          ),
        ),
        SizedBox(width: 8.w),
        // Fork button
        Expanded(
          child: _ActionButton(
            icon: Icons.call_split,
            label: 'recipe.action.fork'.tr(),
            onTap: onFork,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16.sp,
                  color: Colors.grey[700],
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact action row for grid view cards
class CompactCardActionRow extends StatelessWidget {
  final VoidCallback? onLog;
  final VoidCallback? onFork;

  const CompactCardActionRow({
    super.key,
    this.onLog,
    this.onFork,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactActionButton(
            icon: Icons.edit_note,
            onTap: onLog,
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: _CompactActionButton(
            icon: Icons.call_split,
            onTap: onFork,
          ),
        ),
      ],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CompactActionButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Icon(
            icon,
            size: 18.sp,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
