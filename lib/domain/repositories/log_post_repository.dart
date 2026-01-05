import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/create_log_post_request_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import '../../core/error/failures.dart';

abstract class LogPostRepository {
  // 로그 생성
  Future<Either<Failure, LogPostDetail>> createLog(
    CreateLogPostRequestDto request,
  );
  // 로그 상세 조회
  Future<Either<Failure, LogPostDetail>> getLogDetail(String publicId);
}
