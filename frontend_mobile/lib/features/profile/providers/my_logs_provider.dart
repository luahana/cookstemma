import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/log_sync_engine.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';

/// 내 로그 페이지네이션 상태 (with cache metadata, cursor-based)
class MyLogsState {
  final List<LogPostSummaryDto> items;
  final bool hasNext;
  final String? nextCursor;
  final bool isLoading;
  final bool isFromCache;
  final DateTime? cachedAt;
  final String? error;

  MyLogsState({
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

  MyLogsState copyWith({
    List<LogPostSummaryDto>? items,
    bool? hasNext,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoading,
    bool? isFromCache,
    DateTime? cachedAt,
    String? error,
  }) {
    return MyLogsState(
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

/// Outcome filter for My Logs tab
enum LogOutcomeFilter { all, wins, learning, lessons }

/// 내 로그 목록 Notifier (cache-first with optimistic pending items, cursor-based)
class MyLogsNotifier extends StateNotifier<MyLogsState> {
  final Ref _ref;
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  LogOutcomeFilter _currentFilter = LogOutcomeFilter.all;
  bool _isRefreshing = false;

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

      return pendingItems
          .map((item) => LogPostSummaryDto.fromSyncQueueItem(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _init() async {
    // 1. Load cached data first (only for 'all' filter)
    if (_currentFilter == LogOutcomeFilter.all) {
      final cached = await _localDataSource.getCachedMyLogs();
      if (cached != null) {
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

      final pendingItems = _currentFilter == LogOutcomeFilter.all
          ? await _fetchPendingItems()
          : <LogPostSummaryDto>[];

      if (isConnected) {
        final response = await _remoteDataSource.getMyLogs(
          cursor: null,
          outcome: _outcomeParam,
        );

        if (_currentFilter == LogOutcomeFilter.all) {
          await _localDataSource.cacheMyLogs(
            response.content,
            response.hasNext,
          );
        }

        state = MyLogsState(
          items: [...pendingItems, ...response.content],
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
          if (pendingItems.isNotEmpty) {
            state = MyLogsState(
              items: pendingItems,
              hasNext: false,
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
        cursor: state.nextCursor,
        outcome: _outcomeParam,
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
      state = state.copyWith(isLoading: true, error: null, clearNextCursor: true);
      await _fetchFromNetwork();
    } finally {
      _isRefreshing = false;
    }
  }
}

final myLogsProvider =
    StateNotifierProvider.autoDispose<MyLogsNotifier, MyLogsState>((ref) {
  return MyLogsNotifier(
    ref: ref,
    remoteDataSource: UserRemoteDataSource(ref.read(dioProvider)),
    localDataSource: ref.read(userLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});
