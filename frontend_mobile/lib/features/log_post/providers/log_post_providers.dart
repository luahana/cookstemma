// lib/features/log/providers/log_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/providers/analytics_providers.dart';
import 'package:pairing_planet2_frontend/core/providers/isar_provider.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/repositories/log_post_repository_impl.dart';
import 'package:pairing_planet2_frontend/domain/entities/analytics/app_event.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/cursor_page_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/create_log_post_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/domain/repositories/analytics_repository.dart';
import 'package:pairing_planet2_frontend/domain/repositories/log_post_repository.dart';
import 'package:pairing_planet2_frontend/domain/usecases/log_post/create_log_post_usecase.dart';
import 'package:pairing_planet2_frontend/domain/usecases/log_post/get_log_post_detail_usecase.dart';
import 'package:pairing_planet2_frontend/domain/usecases/log_post/get_log_post_list_usecase.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/dio_provider.dart';

final logRemoteDataSourceProvider = Provider(
  (ref) => LogPostRemoteDataSource(ref.read(dioProvider)),
);

final logPostLocalDataSourceProvider = Provider(
  (ref) {
    final isar = ref.read(isarProvider);
    return LogPostLocalDataSource(isar);
  },
);

final logPostRepositoryProvider = Provider<LogPostRepository>(
  (ref) => LogPostRepositoryImpl(
    remoteDataSource: ref.read(logRemoteDataSourceProvider),
    localDataSource: ref.read(logPostLocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  ),
);

// UseCase Providers
final createLogPostUseCaseProvider = Provider<CreateLogPostUseCase>((ref) {
  return CreateLogPostUseCase(ref.read(logPostRepositoryProvider));
});

final getLogPostDetailUseCaseProvider = Provider<GetLogPostDetailUseCase>((ref) {
  return GetLogPostDetailUseCase(ref.read(logPostRepositoryProvider));
});

final getLogPostListUseCaseProvider = Provider<GetLogPostListUseCase>((ref) {
  return GetLogPostListUseCase(ref.read(logPostRepositoryProvider));
});

// 로그 생성을 담당하는 Notifier
final logPostCreationProvider =
    StateNotifierProvider<LogPostCreationNotifier, AsyncValue<LogPostDetail?>>((
      ref,
    ) {
      return LogPostCreationNotifier(
        ref.read(createLogPostUseCaseProvider),
        ref.read(analyticsRepositoryProvider),
      );
    });

class LogPostCreationNotifier
    extends StateNotifier<AsyncValue<LogPostDetail?>> {
  final CreateLogPostUseCase _useCase;
  final AnalyticsRepository _analyticsRepository;

  LogPostCreationNotifier(this._useCase, this._analyticsRepository)
    : super(const AsyncValue.data(null));

  Future<void> createLog(CreateLogPostRequest request) async {
    state = const AsyncValue.loading();
    final result = await _useCase.execute(request);

    state = result.fold(
      (failure) {
        // Track log creation failure event
        _analyticsRepository.trackEvent(AppEvent(
          eventId: const Uuid().v4(),
          eventType: EventType.logFailed,
          timestamp: DateTime.now(),
          priority: EventPriority.immediate,
          recipeId: request.recipePublicId,
          properties: {
            'error': failure.message,
            'outcome': request.outcome,
          },
        ));

        return AsyncValue.error(failure.message, StackTrace.current);
      },
      (success) {
        // Track log creation success event
        _analyticsRepository.trackEvent(AppEvent(
          eventId: const Uuid().v4(),
          eventType: EventType.logCreated,
          timestamp: DateTime.now(),
          priority: EventPriority.immediate,
          logId: success.publicId,
          recipeId: request.recipePublicId,
          properties: {
            'outcome': request.outcome,
            'has_title': request.title?.isNotEmpty ?? false,
            'image_count': request.imagePublicIds.length,
            'content_length': request.content.length,
          },
        ));

        return AsyncValue.data(success);
      },
    );
  }
}

final logPostDetailProvider = FutureProvider.family<LogPostDetail, String>((
  ref,
  id,
) async {
  final useCase = ref.read(getLogPostDetailUseCaseProvider);
  final analyticsRepo = ref.read(analyticsRepositoryProvider);

  final result = await useCase(id);

  return result.fold(
    (failure) => throw failure.message,
    (logPost) {
      // Track log view event
      analyticsRepo.trackEvent(AppEvent(
        eventId: const Uuid().v4(),
        eventType: EventType.logViewed,
        timestamp: DateTime.now(),
        priority: EventPriority.batched,
        logId: logPost.publicId,
        recipeId: logPost.recipePublicId,
        properties: {
          'outcome': logPost.outcome,
          'image_count': logPost.imageUrls.length,
          'content_length': logPost.content.length,
        },
      ));

      return logPost;
    },
  );
});

final logPostListProvider = FutureProvider<CursorPageResponse<LogPostSummary>>((ref) async {
  final useCase = ref.read(getLogPostListUseCaseProvider);
  final result = await useCase();

  return result.fold(
    (failure) => throw failure.message,
    (response) => response,
  );
});

/// 로그 북마크 상태를 관리하는 StateNotifier
class SaveLogNotifier extends StateNotifier<AsyncValue<bool>> {
  final LogPostRepository _repository;
  final String _logId;

  SaveLogNotifier(this._repository, this._logId)
      : super(const AsyncValue.data(false));

  /// 초기 저장 상태 설정 (API에서 받은 값으로)
  void setInitialState(bool isSaved) {
    state = AsyncValue.data(isSaved);
  }

  /// 저장/저장취소 토글
  Future<void> toggle() async {
    final currentlySaved = state.value ?? false;
    state = const AsyncValue.loading();

    final result = currentlySaved
        ? await _repository.unsaveLog(_logId)
        : await _repository.saveLog(_logId);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => AsyncValue.data(!currentlySaved),
    );
  }
}

/// 로그 북마크 상태 Provider (로그 ID별로 생성)
final saveLogProvider =
    StateNotifierProvider.family<SaveLogNotifier, AsyncValue<bool>, String>(
  (ref, logId) {
    final repository = ref.read(logPostRepositoryProvider);
    return SaveLogNotifier(repository, logId);
  },
);
