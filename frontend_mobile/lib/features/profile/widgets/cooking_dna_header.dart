import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/core/utils/url_launcher_utils.dart';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar + Stats
          _buildAvatarAndStats(context),
          SizedBox(height: 12.h),
          // Row 2: Username
          Text(
            '@${profile.user.username}',
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.secondary,
            ),
          ),
          // Row 3-4: Bio and social links
          if (_hasBioOrSocialLinks) ...[
            SizedBox(height: 4.h),
            _buildBioAndSocialLinks(context),
          ],
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
        ],
      ),
    );
  }

  Widget _buildAvatarAndStats(BuildContext context) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 40.r,
          backgroundColor: Colors.grey[200],
          backgroundImage: profile.user.profileImageUrl != null
              ? NetworkImage(profile.user.profileImageUrl!)
              : null,
          child: profile.user.profileImageUrl == null
              ? Icon(Icons.person, size: 40.sp, color: Colors.grey[400])
              : null,
        ),
        SizedBox(width: 20.w),
        // Stats
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTappableStatItem(
                context,
                'profile.followers'.tr(),
                profile.user.followerCount,
                () => context.push(RouteConstants.followersPath(profile.user.id)),
              ),
              _buildTappableStatItem(
                context,
                'profile.following'.tr(),
                profile.user.followingCount,
                () => context.push(
                  '${RouteConstants.followersPath(profile.user.id)}?tab=1',
                ),
              ),
              _buildTappableStatItem(
                context,
                'profile.recipes'.tr(),
                profile.recipeCount,
                onRecipesTap,
              ),
              _buildTappableStatItem(
                context,
                'profile.logs'.tr(),
                profile.logCount,
                onLogsTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Check if user has bio or social links to display
  bool get _hasBioOrSocialLinks {
    final user = profile.user;
    return (user.bio != null && user.bio!.isNotEmpty) ||
        (user.youtubeUrl != null && user.youtubeUrl!.isNotEmpty) ||
        (user.instagramHandle != null && user.instagramHandle!.isNotEmpty);
  }

  /// Build bio and social links section
  Widget _buildBioAndSocialLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bio
        if (profile.user.bio != null && profile.user.bio!.isNotEmpty) ...[
          Text(
            profile.user.bio!,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (_hasSocialLinks) SizedBox(height: 8.h),
        ],
        // Social links
        if (_hasSocialLinks) _buildSocialLinksRow(),
      ],
    );
  }

  bool get _hasSocialLinks {
    final user = profile.user;
    return (user.youtubeUrl != null && user.youtubeUrl!.isNotEmpty) ||
        (user.instagramHandle != null && user.instagramHandle!.isNotEmpty);
  }

  Widget _buildSocialLinksRow() {
    return Row(
      children: [
        if (profile.user.youtubeUrl != null &&
            profile.user.youtubeUrl!.isNotEmpty)
          _buildSocialButton(
            icon: Icons.play_circle_filled,
            color: const Color(0xFFFF0000), // YouTube red
            label: 'YouTube',
            onTap: () => UrlLauncherUtils.launchYoutube(profile.user.youtubeUrl!),
          ),
        if (profile.user.youtubeUrl != null &&
            profile.user.youtubeUrl!.isNotEmpty &&
            profile.user.instagramHandle != null &&
            profile.user.instagramHandle!.isNotEmpty)
          SizedBox(width: 8.w),
        if (profile.user.instagramHandle != null &&
            profile.user.instagramHandle!.isNotEmpty)
          _buildSocialButton(
            icon: Icons.camera_alt,
            color: const Color(0xFFE1306C), // Instagram pink
            label: 'Instagram',
            onTap: () =>
                UrlLauncherUtils.launchInstagram(profile.user.instagramHandle!),
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTappableStatItem(
    BuildContext context,
    String label,
    int count,
    VoidCallback? onTap,
  ) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
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
        SizedBox(height: 2.h),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
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
