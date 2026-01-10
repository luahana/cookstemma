import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/features/home/screens/main_screen.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/screens/log_post_create_screen.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/screens/log_post_detail_screen.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/screens/log_post_list_screen.dart';
import 'package:pairing_planet2_frontend/features/home/screens/home_feed_screen.dart';
import 'package:pairing_planet2_frontend/features/login/screens/login_screen.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/screens/recipe_create_screen.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/screens/recipe_list_screen.dart';
import 'package:pairing_planet2_frontend/features/profile/screens/profile_screen.dart';
import 'package:pairing_planet2_frontend/features/profile/screens/profile_edit_screen.dart';
import 'package:pairing_planet2_frontend/features/profile/screens/settings_screen.dart';
import 'package:pairing_planet2_frontend/features/profile/screens/delete_account_screen.dart';
import 'package:pairing_planet2_frontend/features/profile/screens/followers_list_screen.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart'; // 💡 추가
import 'package:pairing_planet2_frontend/features/notification/screens/notification_inbox_screen.dart';
import 'package:pairing_planet2_frontend/features/splash/screens/splash_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/recipe/presentation/screens/recipe_detail_screen.dart';
import '../../features/recipe/presentation/screens/recipe_edit_screen.dart';
import '../../features/recipe/presentation/screens/star_view_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: RouteConstants.splash,
    refreshListenable: routerNotifier,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final status = authState.status;
      final location = state.matchedLocation;
      final isLoggingIn = location == RouteConstants.login;
      final isSplash = location == RouteConstants.splash;

      // Skip redirect for splash screen - it handles its own navigation
      if (isSplash) return null;

      // Wait for auth check to complete
      if (status == AuthStatus.initial) return null;

      // Authenticated user on login page -> go home
      if (status == AuthStatus.authenticated && isLoggingIn) {
        return RouteConstants.home;
      }

      // Guest or unauthenticated: allow browsing, block protected routes
      if (status == AuthStatus.guest || status == AuthStatus.unauthenticated) {
        // Protected paths that require authentication
        final protectedPaths = [
          RouteConstants.recipeCreate,
          '/recipe/edit', // Recipe edit requires authentication
          RouteConstants.logPostCreate,
          RouteConstants.profileEdit,
          RouteConstants.settings,
          RouteConstants.deleteAccount,
        ];

        // Block access to protected routes for guests
        if (protectedPaths.any((path) => location.startsWith(path))) {
          return RouteConstants.login;
        }

        // Allow guests to browse all other routes (except already on login)
        if (status == AuthStatus.guest) {
          return null; // Allow navigation
        }

        // Unauthenticated (not guest) - redirect to login
        if (!isLoggingIn) {
          return RouteConstants.login;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteConstants.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.recipeCreate,
        name: 'recipe_create',
        builder: (context, state) {
          // 💡 쿼리 파라미터 대신 extra로 전달된 RecipeDetail 객체를 직접 추출합니다.
          final parentRecipe = state.extra as RecipeDetail?;

          return RecipeCreateScreen(
            parentRecipe: parentRecipe, // 💡 객체 하나만 전달
          );
        },
      ),
      GoRoute(
        path: RouteConstants.recipeEdit,
        name: 'recipe_edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RecipeEditScreen(recipeId: id);
        },
      ),
      GoRoute(
        path: RouteConstants.logPostCreate,
        name: 'log_post_create',
        builder: (context, state) {
          final recipe = state.extra as RecipeDetail; // 💡 필수 객체 수신
          return LogPostCreateScreen(recipe: recipe);
        },
      ),
      GoRoute(
        path: RouteConstants.logPostDetail, // '/log_post/:id'
        name: 'log_post_detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LogPostDetailScreen(logId: id);
        },
      ),
      GoRoute(
        path: RouteConstants.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationInboxScreen(),
      ),
      GoRoute(
        path: RouteConstants.followers, // '/users/:userId/followers'
        name: 'followers',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final tabIndex = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return FollowersListScreen(userId: userId, initialTabIndex: tabIndex);
        },
      ),
      GoRoute(
        path: RouteConstants.profileEdit,
        name: 'profile_edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: RouteConstants.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteConstants.deleteAccount,
        name: 'delete_account',
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeFeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.recipes,
                builder: (context, state) => const RecipeListScreen(),
                routes: [
                  GoRoute(
                    path: RouteConstants.recipeDetail,
                    name: 'recipe_detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return RecipeDetailScreen(recipeId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'star',
                        name: 'recipe_star',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return StarViewScreen(recipeId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.logPosts,
                builder: (context, state) => const LogPostListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.profile,
                builder: (context, state) {
                  final tabIndex = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
                  return ProfileScreen(initialTabIndex: tabIndex);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
