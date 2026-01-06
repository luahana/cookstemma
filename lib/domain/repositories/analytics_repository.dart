import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/entities/analytics/app_event.dart';

abstract class AnalyticsRepository {
  Future<Either<Failure, Unit>> trackEvent(AppEvent event);
  Future<Either<Failure, Unit>> syncPendingEvents();
}
