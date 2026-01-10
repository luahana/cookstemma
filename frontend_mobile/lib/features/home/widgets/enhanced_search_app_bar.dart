import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';

/// EnhancedSearchAppBar - Search-first header with greeting and notifications
/// Simplified version without overlay to avoid crashes
class EnhancedSearchAppBar extends ConsumerWidget {
  const EnhancedSearchAppBar({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'home.goodMorning'.tr();
    } else if (hour >= 12 && hour < 17) {
      return 'home.goodAfternoon'.tr();
    } else {
      return 'home.goodEvening'.tr();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Only watch profile if authenticated
    String? username;
    if (authState.status == AuthStatus.authenticated) {
      final profileAsync = ref.watch(myProfileProvider);
      username = profileAsync.whenOrNull(
        data: (profile) => profile.user.username,
      );
    }

    final greeting = _getGreeting();
    final displayName = username ?? 'home.welcome'.tr();

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Greeting row with notification bell
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: '$greeting, ',
                            style: const TextStyle(fontWeight: FontWeight.normal),
                          ),
                          TextSpan(
                            text: displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '!'),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push(RouteConstants.notifications),
                    icon: const Icon(Icons.notifications_outlined),
                    color: AppColors.textPrimary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search bar - taps navigate to search screen
              GestureDetector(
                onTap: () => context.push(RouteConstants.search),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'home.searchHint'.tr(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
