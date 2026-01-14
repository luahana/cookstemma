import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/create_log_post_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/domain/repositories/log_post_repository.dart';

class CreateLogPostUseCase {
  final LogPostRepository _repository;

  CreateLogPostUseCase(this._repository);

  Future<Either<Failure, LogPostDetail>> execute(
    CreateLogPostRequest request,
  ) async {
    // Validation
    if (!['SUCCESS', 'PARTIAL', 'FAILED'].contains(request.outcome)) {
      return Left(ValidationFailure('error.invalidCookingResult'));
    }
    if (request.content.trim().isEmpty) {
      return Left(ValidationFailure('error.contentRequired'));
    }

    return await _repository.createLog(request);
  }
}
