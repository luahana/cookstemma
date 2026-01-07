import 'package:dio/dio.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/domain/entities/analytics/app_event.dart';

class AnalyticsRemoteDataSource {
  final Dio _dio;

  AnalyticsRemoteDataSource(this._dio);

  // Send single event (immediate)
  Future<void> trackEvent(AppEvent event) async {
    await _dio.post(ApiEndpoints.events, data: event.toJson());
  }

  // Batch send events (analytics)
  Future<void> trackBatchEvents(List<AppEvent> events) async {
    await _dio.post(ApiEndpoints.eventsBatch, data: {
      'events': events.map((e) => e.toJson()).toList(),
    });
  }
}
