import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/data/datasources/follow/follow_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/follow/follower_dto.dart';

/// Provider for FollowRemoteDataSource
final followRemoteDataSourceProvider = Provider<FollowRemoteDataSource>((ref) {
  return FollowRemoteDataSource(ref.read(dioProvider));
});

/// Follow status provider - checks if current user follows a target user
final followStatusProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final dataSource = ref.read(followRemoteDataSourceProvider);
  final status = await dataSource.getFollowStatus(userId);
  return status.isFollowing;
});

/// Follow action state
class FollowActionState {
  final bool isLoading;
  final bool isFollowing;
  final String? error;

  FollowActionState({
    this.isLoading = false,
    this.isFollowing = false,
    this.error,
  });

  FollowActionState copyWith({
    bool? isLoading,
    bool? isFollowing,
    String? error,
  }) {
    return FollowActionState(
      isLoading: isLoading ?? this.isLoading,
      isFollowing: isFollowing ?? this.isFollowing,
      error: error,
    );
  }
}

/// Follow action notifier - handles follow/unfollow with optimistic updates
class FollowActionNotifier extends StateNotifier<FollowActionState> {
  final FollowRemoteDataSource _dataSource;
  final String _userId;

  FollowActionNotifier({
    required FollowRemoteDataSource dataSource,
    required String userId,
    required bool initialFollowState,
  })  : _dataSource = dataSource,
        _userId = userId,
        super(FollowActionState(isFollowing: initialFollowState));

  Future<void> toggleFollow() async {
    if (state.isLoading) return;

    final wasFollowing = state.isFollowing;

    // Optimistic update
    state = state.copyWith(
      isLoading: true,
      isFollowing: !wasFollowing,
      error: null,
    );

    try {
      if (wasFollowing) {
        await _dataSource.unfollow(_userId);
      } else {
        await _dataSource.follow(_userId);
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        isLoading: false,
        isFollowing: wasFollowing,
        error: e.toString(),
      );
    }
  }
}

/// Provider for follow action notifier
final followActionProvider = StateNotifierProvider.family<FollowActionNotifier, FollowActionState, ({String userId, bool initialFollowState})>(
  (ref, params) {
    return FollowActionNotifier(
      dataSource: ref.read(followRemoteDataSourceProvider),
      userId: params.userId,
      initialFollowState: params.initialFollowState,
    );
  },
);

/// Followers list state
class FollowersListState {
  final List<FollowerDto> items;
  final bool hasNext;
  final int currentPage;
  final bool isLoading;
  final String? error;

  FollowersListState({
    this.items = const [],
    this.hasNext = true,
    this.currentPage = 0,
    this.isLoading = false,
    this.error,
  });

  FollowersListState copyWith({
    List<FollowerDto>? items,
    bool? hasNext,
    int? currentPage,
    bool? isLoading,
    String? error,
  }) {
    return FollowersListState(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Followers list notifier
class FollowersListNotifier extends StateNotifier<FollowersListState> {
  final FollowRemoteDataSource _dataSource;
  final String _userId;

  FollowersListNotifier({
    required FollowRemoteDataSource dataSource,
    required String userId,
  })  : _dataSource = dataSource,
        _userId = userId,
        super(FollowersListState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await _fetchPage(0);
  }

  Future<void> _fetchPage(int page) async {
    if (state.isLoading && page > 0) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dataSource.getFollowers(_userId, page: page);

      if (page == 0) {
        state = state.copyWith(
          items: response.content,
          hasNext: response.hasNext,
          currentPage: page,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          items: [...state.items, ...response.content],
          hasNext: response.hasNext,
          currentPage: page,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasNext || state.isLoading) return;
    await _fetchPage(state.currentPage + 1);
  }

  Future<void> refresh() async {
    state = FollowersListState(isLoading: true);
    await _fetchPage(0);
  }
}

/// Provider for followers list
final followersListProvider = StateNotifierProvider.family<FollowersListNotifier, FollowersListState, String>(
  (ref, userId) {
    return FollowersListNotifier(
      dataSource: ref.read(followRemoteDataSourceProvider),
      userId: userId,
    );
  },
);

/// Following list notifier
class FollowingListNotifier extends StateNotifier<FollowersListState> {
  final FollowRemoteDataSource _dataSource;
  final String _userId;

  FollowingListNotifier({
    required FollowRemoteDataSource dataSource,
    required String userId,
  })  : _dataSource = dataSource,
        _userId = userId,
        super(FollowersListState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await _fetchPage(0);
  }

  Future<void> _fetchPage(int page) async {
    if (state.isLoading && page > 0) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dataSource.getFollowing(_userId, page: page);

      if (page == 0) {
        state = state.copyWith(
          items: response.content,
          hasNext: response.hasNext,
          currentPage: page,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          items: [...state.items, ...response.content],
          hasNext: response.hasNext,
          currentPage: page,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasNext || state.isLoading) return;
    await _fetchPage(state.currentPage + 1);
  }

  Future<void> refresh() async {
    state = FollowersListState(isLoading: true);
    await _fetchPage(0);
  }
}

/// Provider for following list
final followingListProvider = StateNotifierProvider.family<FollowingListNotifier, FollowersListState, String>(
  (ref, userId) {
    return FollowingListNotifier(
      dataSource: ref.read(followRemoteDataSourceProvider),
      userId: userId,
    );
  },
);
