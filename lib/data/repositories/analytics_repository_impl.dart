import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/data/datasources/analytics/analytics_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/analytics/analytics_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/local/queued_event.dart';
import 'package:pairing_planet2_frontend/domain/entities/analytics/app_event.dart';
import 'package:pairing_planet2_frontend/domain/repositories/analytics_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsLocalDataSource _localDataSource;
  final AnalyticsRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final Talker _talker;

  AnalyticsRepositoryImpl({
    required AnalyticsLocalDataSource localDataSource,
    required AnalyticsRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required Talker talker,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _talker = talker;

  @override
  Future<Either<Failure, Unit>> trackEvent(AppEvent event) async {
    try {
      // Always queue locally first (Outbox pattern)
      await _localDataSource.queueEvent(event);

      // If immediate priority and online, send now
      if (event.priority == EventPriority.immediate &&
          await _networkInfo.isConnected) {
        try {
          await _remoteDataSource.trackEvent(event);
          await _localDataSource.markAsSynced(event.eventId);
          _talker.info(
              'Event ${event.eventType.name} sent immediately (eventId: ${event.eventId})');
        } catch (e) {
          // Failed, will retry in background sync
          _talker.error('Failed to send immediate event', e);
          await _localDataSource.markAsFailed(event.eventId);
        }
      } else {
        _talker.debug(
            'Event ${event.eventType.name} queued for batch sync (eventId: ${event.eventId})');
      }
      return const Right(unit);
    } catch (e) {
      _talker.error('Failed to track event', e);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> syncPendingEvents() async {
    try {
      if (!await _networkInfo.isConnected) {
        _talker.debug('Sync skipped: no network connection');
        return const Right(unit);
      }

      // Sync immediate events first (priority)
      final immediateEvents = await _localDataSource.getPendingEvents(
        priority: EventPriority.immediate,
      );

      for (final event in immediateEvents) {
        try {
          final appEvent = _convertToAppEvent(event);
          await _remoteDataSource.trackEvent(appEvent);
          await _localDataSource.markAsSynced(event.eventId);
          _talker.info('Synced immediate event: ${event.eventType}');
        } catch (e) {
          // Retry logic handled by background worker
          _talker.error('Failed to sync event ${event.eventId}', e);
          await _localDataSource.markAsFailed(event.eventId);
        }
      }

      // Batch sync analytics events
      final batchedEvents = await _localDataSource.getPendingEvents(
        priority: EventPriority.batched,
      );

      if (batchedEvents.isNotEmpty) {
        try {
          final appEvents = batchedEvents.map(_convertToAppEvent).toList();
          await _remoteDataSource.trackBatchEvents(appEvents);

          for (final event in batchedEvents) {
            await _localDataSource.markAsSynced(event.eventId);
          }

          _talker.info('Batch synced ${batchedEvents.length} events');
        } catch (e) {
          _talker.error('Failed to batch sync events', e);
          for (final event in batchedEvents) {
            await _localDataSource.markAsFailed(event.eventId);
          }
        }
      }

      // Cleanup old synced events (keep last 7 days)
      await _localDataSource.cleanupSyncedEvents(olderThanDays: 7);
      return const Right(unit);
    } catch (e) {
      _talker.error('Failed to sync pending events', e);
      return Left(UnknownFailure(e.toString()));
    }
  }

  AppEvent _convertToAppEvent(QueuedEvent queuedEvent) {
    return AppEvent(
      eventId: queuedEvent.eventId,
      eventType: EventType.values
          .firstWhere((e) => e.name == queuedEvent.eventType),
      userId: queuedEvent.userId,
      timestamp: queuedEvent.timestamp,
      properties: jsonDecode(queuedEvent.propertiesJson),
      recipeId: queuedEvent.recipeId,
      logId: queuedEvent.logId,
      priority: queuedEvent.priority == 'immediate'
          ? EventPriority.immediate
          : EventPriority.batched,
    );
  }
}
