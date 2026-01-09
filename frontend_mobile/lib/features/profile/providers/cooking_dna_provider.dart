import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/core/utils/cache_utils.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/user/cooking_dna_dto.dart';
import 'package:pairing_planet2_frontend/features/profile/providers/profile_provider.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';

/// State for Cooking DNA with cache metadata
class CookingDnaState {
  final CookingDnaDto? data;
  final bool isLoading;
  final bool isFromCache;
  final DateTime? cachedAt;
  final String? error;

  CookingDnaState({
    this.data,
    this.isLoading = false,
    this.isFromCache = false,
    this.cachedAt,
    this.error,
  });

  bool get isStale {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt!) > CacheTTL.profileTabs;
  }

  CookingDnaState copyWith({
    CookingDnaDto? data,
    bool? isLoading,
    bool? isFromCache,
    DateTime? cachedAt,
    String? error,
  }) {
    return CookingDnaState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
      error: error,
    );
  }
}

/// Cooking DNA Notifier with cache-first pattern
class CookingDnaNotifier extends StateNotifier<CookingDnaState> {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  CookingDnaNotifier({
    required UserRemoteDataSource remoteDataSource,
    required UserLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        super(CookingDnaState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    // 1. Load cached data first
    final cached = await _localDataSource.getCachedCookingDna();
    if (cached != null) {
      state = state.copyWith(
        data: cached.data,
        isFromCache: true,
        cachedAt: cached.cachedAt,
        isLoading: true, // Still fetching fresh
      );
    }

    // 2. Fetch from network
    await _fetchFromNetwork();
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final isConnected = await _networkInfo.isConnected;

      if (isConnected) {
        final response = await _remoteDataSource.getCookingDna();

        // Cache the new data
        await _localDataSource.cacheCookingDna(response);

        state = CookingDnaState(
          data: response,
          isLoading: false,
          isFromCache: false,
          cachedAt: DateTime.now(),
        );
      } else {
        // Offline - keep showing cached data if available
        if (state.data != null) {
          state = state.copyWith(isLoading: false, error: 'Offline mode');
        } else {
          state = state.copyWith(isLoading: false, error: 'No network connection');
        }
      }
    } catch (e) {
      if (state.data != null) {
        state = state.copyWith(isLoading: false, error: 'Update failed');
      } else {
        state = state.copyWith(isLoading: false, error: 'Could not load data');
      }
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _fetchFromNetwork();
  }
}

final cookingDnaProvider =
    StateNotifierProvider.autoDispose<CookingDnaNotifier, CookingDnaState>((ref) {
  return CookingDnaNotifier(
    remoteDataSource: UserRemoteDataSource(ref.read(dioProvider)),
    localDataSource: ref.read(userLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});
