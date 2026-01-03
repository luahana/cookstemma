import 'package:dartz/dartz.dart';
import '../error/failures.dart';

// Type은 성공 시 반환할 타입, Params는 실행 시 필요한 매개변수
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}
