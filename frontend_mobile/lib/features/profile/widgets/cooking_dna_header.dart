import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/models/user/cooking_dna_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/my_profile_response_dto.dart';
import 'xp_progress_bar.dart';

/// Expandable header for the profile page showing Cooking DNA
class CookingDnaHeader extends StatelessWidget {
  final MyProfileResponseDto profile;
  final CookingDnaDto? cookingDna;
  final bool isLoading;
  final VoidCallback? onRecipesTap;
  final VoidCallback? onLogsTap;

  const CookingDnaHeader({
    super.key,
    required this.profile,
    this.cookingDna,
    this.isLoading = false,
    this.onRecipesTap,
    this.onLogsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile avatar and username
          _buildProfileSection(context),
          SizedBox(height: 16.h),
          // XP Progress bar
          if (cookingDna != null)
            XpProgressBar(
              level: cookingDna!.level,
              levelName: cookingDna!.levelName,
              totalXp: cookingDna!.totalXp,
              xpForCurrentLevel: cookingDna!.xpForCurrentLevel,
              xpForNextLevel: cookingDna!.xpForNextLevel,
              levelProgress: cookingDna!.levelProgress,
            )
          else if (isLoading)
            _buildXpProgressSkeleton()
          else
            _buildXpProgressPlaceholder(),
          SizedBox(height: 16.h),
          // Profile stats (followers, following, recipes, logs)
          _buildProfileStats(context),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 32.r,
          backgroundColor: Colors.grey[200],
          backgroundImage: profile.user.profileImageUrl != null
              ? NetworkImage(profile.user.profileImageUrl!)
              : null,
          child: profile.user.profileImageUrl == null
              ? Icon(Icons.person, size: 32.sp, color: Colors.grey[400])
              : null,
        ),
        SizedBox(width: 16.w),
        // Username and level badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${profile.user.username}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (cookingDna != null) ...[
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getLevelColor(cookingDna!.level).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'profile.${cookingDna!.levelName}'.tr(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: _getLevelColor(cookingDna!.level),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTappableStatItem(
            context,
            'profile.followers'.tr(),
            profile.user.followerCount,
            () => context.push(RouteConstants.followersPath(profile.user.id)),
          ),
        ),
        Expanded(
          child: _buildTappableStatItem(
            context,
            'profile.following'.tr(),
            profile.user.followingCount,
            () => context.push(
              '${RouteConstants.followersPath(profile.user.id)}?tab=1',
            ),
          ),
        ),
        Expanded(
          child: _buildTappableStatItem(
            context,
            'profile.recipes'.tr(),
            profile.recipeCount,
            onRecipesTap,
          ),
        ),
        Expanded(
          child: _buildTappableStatItem(
            context,
            'profile.logs'.tr(),
            profile.logCount,
            onLogsTap,
          ),
        ),
      ],
    );
  }

  Widget _buildTappableStatItem(
    BuildContext context,
    String label,
    int count,
    VoidCallback? onTap,
  ) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          count.toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }

  Color _getLevelColor(int level) {
    if (level <= 5) return const Color(0xFF78909C);
    if (level <= 10) return const Color(0xFF4CAF50);
    if (level <= 15) return const Color(0xFF2196F3);
    if (level <= 20) return const Color(0xFF9C27B0);
    if (level <= 25) return const Color(0xFFFF9800);
    return const Color(0xFFFFD700);
  }

  // Skeleton widgets for loading state
  Widget _buildXpProgressSkeleton() {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16.r),
      ),
    );
  }

  Widget _buildXpProgressPlaceholder() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Text(
          'profile.startCookingToUnlock'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
