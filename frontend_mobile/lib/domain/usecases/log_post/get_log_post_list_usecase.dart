import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/slice_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/domain/repositories/log_post_repository.dart';

class GetLogPostListUseCase {
  final LogPostRepository _repository;

  GetLogPostListUseCase(this._repository);

  Future<Either<Failure, SliceResponse<LogPostSummary>>> call({
    int page = 0,
    int size = 20,
    String? query,
    List<String>? outcomes,
  }) async {
    return await _repository.getLogPosts(
      page: page,
      size: size,
      query: query,
      outcomes: outcomes,
    );
  }
}
