abstract class Failure {
  final String message;
  Failure(this.message);

  @override
  String toString() => message;
}

// 404 Not Found
class NotFoundFailure extends Failure {
  NotFoundFailure([String message = '요청하신 정보를 찾을 수 없습니다.']) : super(message);
}

// 500 Server Error
class ServerFailure extends Failure {
  ServerFailure([String message = '서버에 일시적인 오류가 발생했습니다.']) : super(message);
}

// Network / Timeout
class ConnectionFailure extends Failure {
  ConnectionFailure([String message = '네트워크 연결 상태를 확인해주세요.']) : super(message);
}

// 401 Unauthorized
class UnauthorizedFailure extends Failure {
  UnauthorizedFailure([String message = '접근 권한이 없습니다. 다시 로그인해주세요.'])
    : super(message);
}

// 기타 알 수 없는 에러
class UnknownFailure extends Failure {
  UnknownFailure([String message = '알 수 없는 에러가 발생했습니다.']) : super(message);
}

// Validation Error
class ValidationFailure extends Failure {
  ValidationFailure([String message = '입력값이 유효하지 않습니다.']) : super(message);
}
