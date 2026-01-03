import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';

import '../../features/recipe/screens/recipe_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    // 💡 딥링크 및 네비게이션 가드: 인증 상태에 따른 리디렉션
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login'; // 로그인 안 됨 -> 로그인 화면으로
      if (isLoggedIn && isLoggingIn) return '/'; // 로그인 됨 -> 홈 화면으로
      return null;
    },
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const Placeholder(),
        routes: [
          // 💡 하위 경로 설정 (딥링크 지원: /recipe/123)
          GoRoute(
            path: 'recipe/:id',
            name: 'recipe_detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RecipeDetailScreen(recipeId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Placeholder(), // 로그인 화면 위젯
      ),
    ],
  );
});
