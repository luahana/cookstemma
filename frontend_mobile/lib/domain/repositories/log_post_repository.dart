import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/slice_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/create_log_post_request.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_detail.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import '../../core/error/failures.dart';

abstract class LogPostRepository {
  // 로그 생성
  Future<Either<Failure, LogPostDetail>> createLog(
    CreateLogPostRequest request,
  );
  // 로그 상세 조회
  Future<Either<Failure, LogPostDetail>> getLogDetail(String publicId);
  // 로그 리스트 조회
  Future<Either<Failure, SliceResponse<LogPostSummary>>> getLogPosts({
    int page = 0,
    int size = 20,
    String? query,
    List<String>? outcomes,
  });

  // 로그 저장 (북마크)
  Future<Either<Failure, void>> saveLog(String publicId);

  // 로그 저장 취소
  Future<Either<Failure, void>> unsaveLog(String publicId);

  // 저장한 로그 목록 조회
  Future<Either<Failure, SliceResponse<LogPostSummary>>> getSavedLogs({
    int page = 0,
    int size = 20,
  });
}
