// lib/features/log/providers/log_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/create_log_post_request_dto.dart';
import 'package:pairing_planet2_frontend/data/repositories/log_post_repository_impl.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/domain/repositories/log_post_repository.dart';
import 'package:pairing_planet2_frontend/features/recipe/providers/recipe_providers.dart';
import '../../../core/network/dio_provider.dart';

final logRemoteDataSourceProvider = Provider(
  (ref) => LogPostRemoteDataSource(ref.watch(dioProvider)),
);

final logPostLocalDataSourceProvider = Provider(
  (ref) => LogPostLocalDataSource(),
);

final logPostRepositoryProvider = Provider<LogPostRepository>(
  (ref) => LogPostRepositoryImpl(
    remoteDataSource: ref.watch(logRemoteDataSourceProvider),
    localDataSource: ref.watch(logPostLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  ),
);

// 로그 생성을 담당하는 Notifier
final logPostCreationProvider =
    StateNotifierProvider<LogPostCreationNotifier, AsyncValue<LogPostDetail?>>((
      ref,
    ) {
      return LogPostCreationNotifier(ref.watch(logPostRepositoryProvider));
    });

class LogPostCreationNotifier
    extends StateNotifier<AsyncValue<LogPostDetail?>> {
  final LogPostRepository _repository;
  LogPostCreationNotifier(this._repository)
    : super(const AsyncValue.data(null));

  Future<void> createLog(CreateLogPostRequestDto request) async {
    state = const AsyncValue.loading();
    final result = await _repository.createLog(request);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (success) =>
          AsyncValue.data(success), // 💡 여기서 success(LogPostDetail)를 넘겨야 함
    );
  }
}

final logPostDetailProvider = FutureProvider.family<LogPostDetail, String>((
  ref,
  id,
) async {
  final repository = ref.watch(logPostRepositoryProvider);
  final result = await repository.getLogDetail(id);

  return result.fold((failure) => throw failure.message, (logPost) => logPost);
});
