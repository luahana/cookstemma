import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/domain/repositories/log_post_repository.dart';

class GetLogPostDetailUseCase {
  final LogPostRepository _repository;

  GetLogPostDetailUseCase(this._repository);

  Future<Either<Failure, LogPostDetail>> call(String publicId) async {
    return await _repository.getLogDetail(publicId);
  }
}
