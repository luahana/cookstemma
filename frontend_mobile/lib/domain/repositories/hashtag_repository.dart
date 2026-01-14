import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/cursor_page_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';

abstract class HashtagRepository {
  /// Fetch recipes tagged with the given hashtag.
  Future<Either<Failure, CursorPageResponse<RecipeSummary>>> getRecipesByHashtag({
    required String hashtagName,
    String? cursor,
    int size = 20,
  });

  /// Fetch log posts tagged with the given hashtag.
  Future<Either<Failure, CursorPageResponse<LogPostSummary>>> getLogPostsByHashtag({
    required String hashtagName,
    String? cursor,
    int size = 20,
  });
}
