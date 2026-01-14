abstract class Failure {
  final String message;
  Failure(this.message);

  @override
  String toString() => message;
}

// 404 Not Found
class NotFoundFailure extends Failure {
  NotFoundFailure([super.message = 'error.notFound']);
}

// 500 Server Error
class ServerFailure extends Failure {
  ServerFailure([super.message = 'error.server']);
}

// Network / Timeout
class ConnectionFailure extends Failure {
  ConnectionFailure([super.message = 'error.connection']);
}

// 401 Unauthorized
class UnauthorizedFailure extends Failure {
  UnauthorizedFailure([super.message = 'error.unauthorized']);
}

// Unknown error
class UnknownFailure extends Failure {
  UnknownFailure([super.message = 'error.unknown']);
}

// Validation Error
class ValidationFailure extends Failure {
  ValidationFailure([super.message = 'error.validation']);
}
