import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/providers/scroll_to_top_provider.dart';
import 'package:pairing_planet2_frontend/core/widgets/custom_bottom_nav_bar.dart';
import 'package:pairing_planet2_frontend/core/widgets/fab_action_sheet.dart';
import 'package:pairing_planet2_frontend/core/widgets/global_sync_indicator.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/quick_log_sheet.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/widgets/recipe_picker_sheet.dart';
import 'package:pairing_planet2_frontend/features/log_post/providers/quick_log_draft_provider.dart';
import 'package:pairing_planet2_frontend/features/notification/providers/notification_provider.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/cooking_dna_provider.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    // If tapping the current tab, trigger scroll-to-top
    if (index == navigationShell.currentIndex) {
      ref.triggerScrollToTop(index);
    }
    navigationShell.goBranch(
      index,
      // Home tab (0) always goes to initial location for consistent UX
      // Other tabs preserve navigation state unless re-tapped
      initialLocation: index == 0 || index == navigationShell.currentIndex,
    );
  }

  /// Show the FAB action sheet with options
  void _showActionSheet(BuildContext context, WidgetRef ref) {
    FabActionSheet.show(
      context,
      onNewRecipe: () => context.push('/recipe/create'),
      onQuickLog: () => _showQuickLogFlow(context, ref),
    );
  }

  /// Show the quick log flow: Recipe Picker → Quick Log Sheet
  void _showQuickLogFlow(BuildContext context, WidgetRef ref) {
    RecipePickerSheet.show(
      context,
      onRecipeSelected: (recipeId, recipeTitle) {
        // Pre-set the recipe in the quick log draft
        ref.read(quickLogDraftProvider.notifier).startFlowWithRecipe(
              recipeId,
              recipeTitle,
            );
        // Show the quick log sheet
        QuickLogSheet.show(context);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize FCM when main screen is shown (user is authenticated)
    ref.watch(fcmInitializerProvider);

    // Get auth state to determine if user is guest
    final authState = ref.watch(authStateProvider);
    final isGuest = authState.status == AuthStatus.guest ||
        authState.status == AuthStatus.unauthenticated;

    // Get cooking DNA for progress ring (only for authenticated users)
    final cookingDnaState = isGuest ? null : ref.watch(cookingDnaProvider);

    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: const GlobalSyncIndicator(),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, ref, index),
        onFabTap: () => _showActionSheet(context, ref),
        levelProgress: cookingDnaState?.data?.levelProgress,
        level: cookingDnaState?.data?.level,
        isGuest: isGuest,
      ),
    );
  }
}
