import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/features/home/screens/main_screen.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/screens/log_post_create_screen.dart';
import 'package:pairing_planet2_frontend/features/log_post/presentation/screens/log_post_detail_screen.dart';
import 'package:pairing_planet2_frontend/features/login/screens/login_screen.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/screens/recipe_create_screen.dart';
import 'package:pairing_planet2_frontend/features/recipe/presentation/screens/recipe_list_screen.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart'; // 💡 추가
import '../../features/auth/providers/auth_provider.dart';
import '../../features/recipe/presentation/screens/recipe_detail_screen.dart';

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
    initialLocation: RouteConstants.home,
    refreshListenable: routerNotifier,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.status == AuthStatus.initial) return null;
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == RouteConstants.login;
      if (!isLoggedIn && !isLoggingIn) return RouteConstants.login;
      if (isLoggedIn && isLoggingIn) return RouteConstants.home;
      return null;
    },
    routes: [
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
        path: RouteConstants.logPostCreate,
        name: 'log_post_create',
        builder: (context, state) {
          final recipe = state.extra as RecipeDetail; // 💡 필수 객체 수신
          return LogPostCreateScreen(recipe: recipe);
        },
      ),
      GoRoute(
        path: RouteConstants.logDetail, // '/log/:id'
        name: 'log_detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          // 💡 로그 상세 페이지로 이동 (해당 위젯은 별도로 생성 필요)
          return LogPostDetailScreen(logId: id);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const Center(child: Text('홈 화면')),
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
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.search,
                builder: (context, state) => const Center(child: Text('검색 화면')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.profile,
                builder: (context, state) => const Center(child: Text('마이페이지')),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
