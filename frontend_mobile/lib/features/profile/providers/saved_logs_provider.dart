import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';

/// 저장한 로그 페이지네이션 상태 (cursor-based)
class SavedLogsState {
  final List<LogPostSummaryDto> items;
  final bool hasNext;
  final String? nextCursor;
  final bool isLoading;
  final String? error;

  SavedLogsState({
    this.items = const [],
    this.hasNext = true,
    this.nextCursor,
    this.isLoading = false,
    this.error,
  });

  SavedLogsState copyWith({
    List<LogPostSummaryDto>? items,
    bool? hasNext,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoading,
    String? error,
  }) {
    return SavedLogsState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 저장한 로그 목록 Notifier (cursor-based)
class SavedLogsNotifier extends StateNotifier<SavedLogsState> {
  final LogPostRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  bool _isRefreshing = false;

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
        final response = await _remoteDataSource.getSavedLogs(cursor: null);

        state = SavedLogsState(
          items: response.content,
          hasNext: response.hasNext,
          nextCursor: response.nextCursor,
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
        cursor: state.nextCursor,
      );
      state = state.copyWith(
        items: [...state.items, ...response.content],
        hasNext: response.hasNext,
        nextCursor: response.nextCursor,
        isLoading: false,
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

final savedLogsProvider =
    StateNotifierProvider.autoDispose<SavedLogsNotifier, SavedLogsState>((ref) {
  return SavedLogsNotifier(
    remoteDataSource: LogPostRemoteDataSource(ref.read(dioProvider)),
    networkInfo: ref.read(networkInfoProvider),
  );
});
