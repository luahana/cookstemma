import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_summary_dto.dart';

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

final savedLogsProvider =
    StateNotifierProvider.autoDispose<SavedLogsNotifier, SavedLogsState>((ref) {
  return SavedLogsNotifier(
    remoteDataSource: LogPostRemoteDataSource(ref.read(dioProvider)),
    networkInfo: ref.read(networkInfoProvider),
  );
});

/// Saved tab filter
enum SavedTypeFilter { all, recipes, logs }
