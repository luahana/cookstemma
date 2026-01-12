import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/core/providers/isar_provider.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/data/datasources/home/home_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/recipe/recipe_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/home/home_feed_response_dto.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';

/// State class for home feed with cache status information.
class HomeFeedState {
  final HomeFeedResponseDto? data;
  final bool isFromCache;
  final DateTime? cachedAt;
  final bool isLoading;
  final String? error;

  const HomeFeedState({
    this.data,
    this.isFromCache = false,
    this.cachedAt,
    this.isLoading = false,
    this.error,
  });

  HomeFeedState copyWith({
    HomeFeedResponseDto? data,
    bool? isFromCache,
    DateTime? cachedAt,
    bool? isLoading,
    String? error,
  }) {
    return HomeFeedState(
      data: data ?? this.data,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Check if the cached data is stale (expired).
  bool get isStale {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt!) > CacheTTL.homeFeed;
  }
}

/// Provider for HomeLocalDataSource.
final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) {
  final isar = ref.read(isarProvider);
  return HomeLocalDataSource(isar);
});

/// Cache-first home feed provider using StateNotifier.
final homeFeedProvider =
    StateNotifierProvider<HomeFeedNotifier, HomeFeedState>((ref) {
  return HomeFeedNotifier(
    remoteDataSource: RecipeRemoteDataSource(ref.read(dioProvider)),
    localDataSource: ref.read(homeLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

/// Provider for selected locale filter in home feed.
/// null means "All" (no filter).
final homeLocaleFilterProvider = StateProvider<String?>((ref) => null);

/// StateNotifier for managing home feed with cache-first strategy.
class HomeFeedNotifier extends StateNotifier<HomeFeedState> {
  final RecipeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  bool _isRefreshing = false; // Guard against race condition in rapid pulls
  Completer<void>? _refreshCompleter; // Used to coordinate concurrent refresh calls
  DateTime? _lastRefreshTime; // Debounce: track last refresh time
  static const _refreshCooldown = Duration(milliseconds: 500); // Minimum time between refreshes

  HomeFeedNotifier({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  }) : super(const HomeFeedState(isLoading: true)) {
    // Load data on initialization
    _init();
  }

  /// Initialize: Load cached data immediately, then fetch fresh data.
  Future<void> _init() async {
    // 1. Try to load cached data first for immediate display
    final cached = await localDataSource.getCachedHomeFeed();

    if (cached != null) {
      state = state.copyWith(
        data: cached.data,
        isFromCache: true,
        cachedAt: cached.cachedAt,
        isLoading: true, // Still loading fresh data
      );
    }

    // 2. Fetch fresh data from network
    await _fetchFromNetwork();
  }

  /// Refresh: Force fetch from network.
  /// Uses debounce + _isRefreshing guard + Completer pattern to prevent
  /// race conditions during rapid pull-to-refresh (prevents blank page issues).
  Future<void> refresh() async {
    // Debounce: Skip if refreshed recently (prevents rapid sequential refreshes)
    if (_lastRefreshTime != null &&
        DateTime.now().difference(_lastRefreshTime!) < _refreshCooldown) {
      return;
    }

    // Early return if already refreshing (covers race condition)
    if (_isRefreshing) {
      if (_refreshCompleter != null) {
        await _refreshCompleter!.future;
      }
      return;
    }

    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();
    _refreshCompleter = Completer<void>();

    try {
      // Clear error but don't set isLoading if we have data
      // (CupertinoSliverRefreshControl shows its own spinner)
      state = state.copyWith(error: null);
      // Timeout to prevent indefinite hang during network issues
      await _fetchFromNetwork().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          state = state.copyWith(
            isLoading: false,
            error: '요청 시간이 초과되었습니다.',
          );
        },
      );
    } catch (e) {
      // Ensure any exception doesn't prevent completion
      state = state.copyWith(
        isLoading: false,
        error: '새로고침 실패',
      );
    } finally {
      _refreshCompleter?.complete();
      _refreshCompleter = null;
      _isRefreshing = false;
    }
  }

  /// Fetch data from network and update cache.
  Future<void> _fetchFromNetwork() async {
    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        final feed = await remoteDataSource.getHomeFeed();

        // Cache the new data
        await localDataSource.cacheHomeFeed(feed);

        // Use copyWith to preserve state continuity during refresh
        state = state.copyWith(
          data: feed,
          isFromCache: false,
          cachedAt: DateTime.now(),
          isLoading: false,
          error: null,
        );
      } else {
        // Offline: keep showing cached data if available
        if (state.data != null) {
          state = state.copyWith(
            isLoading: false,
            error: '오프라인 모드',
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: '네트워크 연결이 없습니다.',
          );
        }
      }
    } catch (e) {
      // On error: keep showing cached data if available
      if (state.data != null) {
        state = state.copyWith(
          isLoading: false,
          error: '업데이트 실패',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '데이터를 불러올 수 없습니다.',
        );
      }
    }
  }
}
