import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/cursor_page_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/slice_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/domain/repositories/log_post_repository.dart';

class GetLogPostListUseCase {
  final LogPostRepository _repository;

  GetLogPostListUseCase(this._repository);

  /// Get log posts with cursor-based pagination
  Future<Either<Failure, CursorPageResponse<LogPostSummary>>> call({
    String? cursor,
    int size = 20,
    String? query,
    List<String>? outcomes,
  }) async {
    return await _repository.getLogPosts(
      cursor: cursor,
      size: size,
      query: query,
      outcomes: outcomes,
    );
  }

  /// Get logs for a specific recipe (page-based pagination)
  Future<Either<Failure, SliceResponse<LogPostSummary>>> getByRecipe({
    required String recipeId,
    int page = 0,
    int size = 20,
  }) async {
    return await _repository.getLogsByRecipe(
      recipeId: recipeId,
      page: page,
      size: size,
    );
  }
}
