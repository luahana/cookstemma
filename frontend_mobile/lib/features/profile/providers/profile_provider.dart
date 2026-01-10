import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_summary_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/my_profile_response_dto.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';

/// Provider for UserLocalDataSource
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSource();
});

/// 내 프로필 Provider
final myProfileProvider = FutureProvider.autoDispose<MyProfileResponseDto>((ref) async {
  final dataSource = UserRemoteDataSource(ref.read(dioProvider));
  return dataSource.getMyProfile();
});

/// 내 레시피 페이지네이션 상태 (with cache metadata)
class MyRecipesState {
  final List<RecipeSummaryDto> items;
  final bool hasNext;
  final int currentPage;
  final bool isLoading;
  final bool isFromCache;
  final DateTime? cachedAt;
  final String? error;

  MyRecipesState({
    this.items = const [],
    this.hasNext = true,
    this.currentPage = 0,
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
    int? currentPage,
    bool? isLoading,
    bool? isFromCache,
    DateTime? cachedAt,
    String? error,
  }) {
    return MyRecipesState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
      error: error,
    );
  }
}

/// Recipe type filter for My Recipes tab
enum RecipeTypeFilter { all, original, variants }

/// 내 레시피 목록 Notifier (cache-first)
class MyRecipesNotifier extends StateNotifier<MyRecipesState> {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  RecipeTypeFilter _currentFilter = RecipeTypeFilter.all;

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
        RecipeTypeFilter.original => 'original',
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
          isLoading: true, // Still fetching fresh
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
          page: 0,
          typeFilter: _typeFilterParam,
        );

        // Cache the new data only for 'all' filter
        if (_currentFilter == RecipeTypeFilter.all) {
          await _localDataSource.cacheMyRecipes(
            response.content,
            response.hasNext ?? false,
          );
        }

        state = MyRecipesState(
          items: response.content,
          hasNext: response.hasNext ?? false,
          currentPage: 0,
          isLoading: false,
          isFromCache: false,
          cachedAt: DateTime.now(),
        );
      } else {
        // Offline - keep showing cached data if available
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
        page: state.currentPage + 1,
        typeFilter: _typeFilterParam,
      );
      state = state.copyWith(
        items: [...state.items, ...response.content],
        hasNext: response.hasNext ?? false,
        currentPage: state.currentPage + 1,
        isLoading: false,
        isFromCache: false, // After loading more, no longer purely from cache
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _fetchFromNetwork();
  }
}

final myRecipesProvider = StateNotifierProvider.autoDispose<MyRecipesNotifier, MyRecipesState>((ref) {
  return MyRecipesNotifier(
    remoteDataSource: UserRemoteDataSource(ref.read(dioProvider)),
    localDataSource: ref.read(userLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

/// 내 로그 페이지네이션 상태 (with cache metadata)
class MyLogsState {
  final List<LogPostSummaryDto> items;
  final bool hasNext;
  final int currentPage;
  final bool isLoading;
  final bool isFromCache;
  final DateTime? cachedAt;
  final String? error;

  MyLogsState({
    this.items = const [],
    this.hasNext = true,
    this.currentPage = 0,
    this.isLoading = false,
    this.isFromCache = false,
    this.cachedAt,
    this.error,
  });

  bool get isStale {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt!) > CacheTTL.profileTabs;
  }

  MyLogsState copyWith({
    List<LogPostSummaryDto>? items,
    bool? hasNext,
    int? currentPage,
    bool? isLoading,
    bool? isFromCache,
    DateTime? cachedAt,
    String? error,
  }) {
    return MyLogsState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
      error: error,
    );
  }
}

/// Outcome filter for My Logs tab
enum LogOutcomeFilter { all, wins, learning, lessons }

/// 내 로그 목록 Notifier (cache-first with optimistic pending items)
class MyLogsNotifier extends StateNotifier<MyLogsState> {
  final Ref _ref;
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  LogOutcomeFilter _currentFilter = LogOutcomeFilter.all;

  MyLogsNotifier({
    required Ref ref,
    required UserRemoteDataSource remoteDataSource,
    required UserLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _ref = ref,
        _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        super(MyLogsState(isLoading: true)) {
    _init();
  }

  LogOutcomeFilter get currentFilter => _currentFilter;

  String? get _outcomeParam => switch (_currentFilter) {
        LogOutcomeFilter.all => null,
        LogOutcomeFilter.wins => 'SUCCESS',
        LogOutcomeFilter.learning => 'PARTIAL',
        LogOutcomeFilter.lessons => 'FAILED',
      };

  /// Fetch pending log posts from sync queue for optimistic UI
  Future<List<LogPostSummaryDto>> _fetchPendingItems() async {
    try {
      final syncQueue = _ref.read(syncQueueRepositoryProvider);
      final pendingItems = await syncQueue.getPendingLogPosts();

      // Convert to LogPostSummaryDto
      return pendingItems
          .map((item) => LogPostSummaryDto.fromSyncQueueItem(item))
          .toList();
    } catch (e) {
      // If sync queue fails, just return empty list
      return [];
    }
  }

  Future<void> _init() async {
    // 1. Load cached data first (only for 'all' filter)
    if (_currentFilter == LogOutcomeFilter.all) {
      final cached = await _localDataSource.getCachedMyLogs();
      if (cached != null) {
        // Also fetch pending items for optimistic display
        final pendingItems = await _fetchPendingItems();

        state = state.copyWith(
          items: [...pendingItems, ...cached.data.items],
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

  Future<void> setFilter(LogOutcomeFilter filter) async {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    state = MyLogsState(isLoading: true);
    await _fetchFromNetwork();
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final isConnected = await _networkInfo.isConnected;

      // Fetch pending items for optimistic display (only for 'all' filter)
      final pendingItems = _currentFilter == LogOutcomeFilter.all
          ? await _fetchPendingItems()
          : <LogPostSummaryDto>[];

      if (isConnected) {
        final response = await _remoteDataSource.getMyLogs(
          page: 0,
          outcome: _outcomeParam,
        );

        // Cache the new data only for 'all' filter
        if (_currentFilter == LogOutcomeFilter.all) {
          await _localDataSource.cacheMyLogs(
            response.content,
            response.hasNext ?? false,
          );
        }

        // Combine pending items with server items
        state = MyLogsState(
          items: [...pendingItems, ...response.content],
          hasNext: response.hasNext ?? false,
          currentPage: 0,
          isLoading: false,
          isFromCache: false,
          cachedAt: DateTime.now(),
        );
      } else {
        if (state.items.isNotEmpty) {
          state = state.copyWith(isLoading: false, error: '오프라인 모드');
        } else {
          // Even offline, show pending items
          if (pendingItems.isNotEmpty) {
            state = MyLogsState(
              items: pendingItems,
              hasNext: false,
              currentPage: 0,
              isLoading: false,
              error: '오프라인 모드',
            );
          } else {
            state = state.copyWith(isLoading: false, error: '네트워크 연결이 없습니다.');
          }
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
      final response = await _remoteDataSource.getMyLogs(
        page: state.currentPage + 1,
        outcome: _outcomeParam,
      );
      state = state.copyWith(
        items: [...state.items, ...response.content],
        hasNext: response.hasNext ?? false,
        currentPage: state.currentPage + 1,
        isLoading: false,
        isFromCache: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _fetchFromNetwork();
  }
}

final myLogsProvider = StateNotifierProvider.autoDispose<MyLogsNotifier, MyLogsState>((ref) {
  return MyLogsNotifier(
    ref: ref,
    remoteDataSource: UserRemoteDataSource(ref.read(dioProvider)),
    localDataSource: ref.read(userLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

/// 저장한 레시피 페이지네이션 상태 (with cache metadata)
class SavedRecipesState {
  final List<RecipeSummaryDto> items;
  final bool hasNext;
  final int currentPage;
  final bool isLoading;
  final bool isFromCache;
  final DateTime? cachedAt;
  final String? error;

  SavedRecipesState({
    this.items = const [],
    this.hasNext = true,
    this.currentPage = 0,
    this.isLoading = false,
    this.isFromCache = false,
    this.cachedAt,
    this.error,
  });

  bool get isStale {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt!) > CacheTTL.profileTabs;
  }

  SavedRecipesState copyWith({
    List<RecipeSummaryDto>? items,
    bool? hasNext,
    int? currentPage,
    bool? isLoading,
    bool? isFromCache,
    DateTime? cachedAt,
    String? error,
  }) {
    return SavedRecipesState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
      error: error,
    );
  }
}

/// 저장한 레시피 목록 Notifier (cache-first)
class SavedRecipesNotifier extends StateNotifier<SavedRecipesState> {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  SavedRecipesNotifier({
    required UserRemoteDataSource remoteDataSource,
    required UserLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        super(SavedRecipesState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    // 1. Load cached data first
    final cached = await _localDataSource.getCachedSavedRecipes();
    if (cached != null) {
      state = state.copyWith(
        items: cached.data.items,
        hasNext: cached.data.hasNext,
        isFromCache: true,
        cachedAt: cached.cachedAt,
        isLoading: true,
      );
    }

    // 2. Fetch from network
    await _fetchFromNetwork();
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final isConnected = await _networkInfo.isConnected;

      if (isConnected) {
        final response = await _remoteDataSource.getSavedRecipes(page: 0);

        await _localDataSource.cacheSavedRecipes(
          response.content,
          response.hasNext ?? false,
        );

        state = SavedRecipesState(
          items: response.content,
          hasNext: response.hasNext ?? false,
          currentPage: 0,
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
      final response = await _remoteDataSource.getSavedRecipes(
        page: state.currentPage + 1,
      );
      state = state.copyWith(
        items: [...state.items, ...response.content],
        hasNext: response.hasNext ?? false,
        currentPage: state.currentPage + 1,
        isLoading: false,
        isFromCache: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _fetchFromNetwork();
  }
}

final savedRecipesProvider = StateNotifierProvider.autoDispose<SavedRecipesNotifier, SavedRecipesState>((ref) {
  return SavedRecipesNotifier(
    remoteDataSource: UserRemoteDataSource(ref.read(dioProvider)),
    localDataSource: ref.read(userLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

/// 저장한 로그 페이지네이션 상태
class SavedLogsState {
  final List<LogPostSummaryDto> items;
  final bool hasNext;
  final int currentPage;
  final bool isLoading;
  final String? error;

  SavedLogsState({
    this.items = const [],
    this.hasNext = true,
    this.currentPage = 0,
    this.isLoading = false,
    this.error,
  });

  SavedLogsState copyWith({
    List<LogPostSummaryDto>? items,
    bool? hasNext,
    int? currentPage,
    bool? isLoading,
    String? error,
  }) {
    return SavedLogsState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 저장한 로그 목록 Notifier
class SavedLogsNotifier extends StateNotifier<SavedLogsState> {
  final LogPostRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  SavedLogsNotifier({
    required LogPostRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        super(SavedLogsState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await _fetchFromNetwork();
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final isConnected = await _networkInfo.isConnected;

      if (isConnected) {
        final response = await _remoteDataSource.getSavedLogs(page: 0);

        state = SavedLogsState(
          items: response.content,
          hasNext: response.hasNext ?? false,
          currentPage: 0,
          isLoading: false,
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
      final response = await _remoteDataSource.getSavedLogs(
        page: state.currentPage + 1,
      );
      state = state.copyWith(
        items: [...state.items, ...response.content],
        hasNext: response.hasNext ?? false,
        currentPage: state.currentPage + 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _fetchFromNetwork();
  }
}

final savedLogsProvider = StateNotifierProvider.autoDispose<SavedLogsNotifier, SavedLogsState>((ref) {
  return SavedLogsNotifier(
    remoteDataSource: LogPostRemoteDataSource(ref.read(dioProvider)),
    networkInfo: ref.read(networkInfoProvider),
  );
});

/// Saved tab filter
enum SavedTypeFilter { all, recipes, logs }
