import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/follow_provider.dart';

class FollowButton extends ConsumerWidget {
  final String userId;
  final bool initialIsFollowing;
  final VoidCallback? onFollowChanged;

  const FollowButton({
    super.key,
    required this.userId,
    required this.initialIsFollowing,
    this.onFollowChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      followActionProvider((userId: userId, initialFollowState: initialIsFollowing)),
    );
    final notifier = ref.read(
      followActionProvider((userId: userId, initialFollowState: initialIsFollowing)).notifier,
    );

    final isFollowing = state.isFollowing;
    final isLoading = state.isLoading;

    return SizedBox(
      height: 36.h,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                await notifier.toggleFollow();
                onFollowChanged?.call();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing
              ? Colors.grey[200]
              : Theme.of(context).colorScheme.primary,
          foregroundColor: isFollowing
              ? Colors.black87
              : Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isFollowing ? Colors.black54 : Colors.white,
                ),
              )
            : Text(
                isFollowing ? '팔로잉' : '팔로우',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Compact follow button for list items
class FollowButtonCompact extends ConsumerWidget {
  final String userId;
  final bool initialIsFollowing;
  final VoidCallback? onFollowChanged;

  const FollowButtonCompact({
    super.key,
    required this.userId,
    required this.initialIsFollowing,
    this.onFollowChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      followActionProvider((userId: userId, initialFollowState: initialIsFollowing)),
    );
    final notifier = ref.read(
      followActionProvider((userId: userId, initialFollowState: initialIsFollowing)).notifier,
    );

    final isFollowing = state.isFollowing;
    final isLoading = state.isLoading;

    return SizedBox(
      height: 32.h,
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : () async {
                await notifier.toggleFollow();
                onFollowChanged?.call();
              },
        style: OutlinedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.transparent : Theme.of(context).colorScheme.primary,
          foregroundColor: isFollowing ? Theme.of(context).colorScheme.primary : Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 14.w,
                height: 14.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Text(
                isFollowing ? '팔로잉' : '팔로우',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
