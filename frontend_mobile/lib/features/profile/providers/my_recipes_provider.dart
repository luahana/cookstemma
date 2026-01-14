import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/browse_filter_provider.dart'
    show RecipeTypeFilter;
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart'
    show networkInfoProvider;

/// 내 레시피 페이지네이션 상태 (with cache metadata, cursor-based)
class MyRecipesState {
  final List<RecipeSummaryDto> items;
  final bool hasNext;
  final String? nextCursor;
  final bool isLoading;
  final bool isFromCache;
  final DateTime? cachedAt;
  final String? error;

  MyRecipesState({
    this.items = const [],
    this.hasNext = true,
    this.nextCursor,
    this.isLoading = false,
    this.isFromCache = false,
    this.cachedAt,
    this.error,
  });

  bool get isStale {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt!) > CacheTTL.profileTabs;
  }

  MyRecipesState copyWith({
    List<RecipeSummaryDto>? items,
    bool? hasNext,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoading,
    bool? isFromCache,
    DateTime? cachedAt,
    String? error,
  }) {
    return MyRecipesState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoading: isLoading ?? this.isLoading,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
      error: error,
    );
  }
}

// RecipeTypeFilter imported from browse_filter_provider.dart

/// 내 레시피 목록 Notifier (cache-first)
class MyRecipesNotifier extends StateNotifier<MyRecipesState> {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  RecipeTypeFilter _currentFilter = RecipeTypeFilter.all;
  bool _isRefreshing = false;

  MyRecipesNotifier({
    required UserRemoteDataSource remoteDataSource,
    required UserLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        super(MyRecipesState(isLoading: true)) {
    _init();
  }

  RecipeTypeFilter get currentFilter => _currentFilter;

  String? get _typeFilterParam => switch (_currentFilter) {
        RecipeTypeFilter.all => null,
        RecipeTypeFilter.originals => 'original',
        RecipeTypeFilter.variants => 'variants',
      };

  Future<void> _init() async {
    // 1. Load cached data first (only for 'all' filter)
    if (_currentFilter == RecipeTypeFilter.all) {
      final cached = await _localDataSource.getCachedMyRecipes();
      if (cached != null) {
        state = state.copyWith(
          items: cached.data.items,
          hasNext: cached.data.hasNext,
          isFromCache: true,
          cachedAt: cached.cachedAt,
          isLoading: true,
        );
      }
    }

    // 2. Fetch from network
    await _fetchFromNetwork();
  }

  Future<void> setFilter(RecipeTypeFilter filter) async {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    state = MyRecipesState(isLoading: true);
    await _fetchFromNetwork();
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final isConnected = await _networkInfo.isConnected;

      if (isConnected) {
        final response = await _remoteDataSource.getMyRecipes(
          cursor: null,
          typeFilter: _typeFilterParam,
        );

        // Cache the new data only for 'all' filter
        if (_currentFilter == RecipeTypeFilter.all) {
          await _localDataSource.cacheMyRecipes(
            response.content,
            response.hasNext,
          );
        }

        state = MyRecipesState(
          items: response.content,
          hasNext: response.hasNext,
          nextCursor: response.nextCursor,
          isLoading: false,
          isFromCache: false,
          cachedAt: DateTime.now(),
        );
      } else {
        if (state.items.isNotEmpty) {
          state = state.copyWith(isLoading: false, error: '오프라인 모드');
        } else {
          state = state.copyWith(isLoading: false, error: '네트워크 연결이 없습니다.');
        }
      }
    } catch (e) {
      if (state.items.isNotEmpty) {
        state = state.copyWith(isLoading: false, error: '업데이트 실패');
      } else {
        state = state.copyWith(isLoading: false, error: '데이터를 불러올 수 없습니다.');
      }
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasNext || state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _remoteDataSource.getMyRecipes(
        cursor: state.nextCursor,
        typeFilter: _typeFilterParam,
      );
      state = state.copyWith(
        items: [...state.items, ...response.content],
        hasNext: response.hasNext,
        nextCursor: response.nextCursor,
        isLoading: false,
        isFromCache: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _fetchFromNetwork();
    } finally {
      _isRefreshing = false;
    }
  }
}

final myRecipesProvider =
    StateNotifierProvider.autoDispose<MyRecipesNotifier, MyRecipesState>((ref) {
  return MyRecipesNotifier(
    remoteDataSource: ref.read(userRemoteDataSourceProvider),
    localDataSource: ref.read(userLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});
