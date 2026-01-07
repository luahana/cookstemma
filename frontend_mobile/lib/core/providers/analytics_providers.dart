import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/network/network_info_impl.dart';
import 'package:pairing_planet2_frontend/core/providers/isar_provider.dart';
import 'package:pairing_planet2_frontend/core/utils/logger.dart';
import 'package:pairing_planet2_frontend/data/datasources/analytics/analytics_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/analytics/analytics_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/repositories/analytics_repository_impl.dart';
import 'package:pairing_planet2_frontend/domain/repositories/analytics_repository.dart';

// Analytics Local Data Source Provider
final analyticsLocalDataSourceProvider = Provider<AnalyticsLocalDataSource>((ref) {
  final isar = ref.read(isarProvider);
  return AnalyticsLocalDataSource(isar);
});

// Analytics Remote Data Source Provider
final analyticsRemoteDataSourceProvider = Provider<AnalyticsRemoteDataSource>((ref) {
  final dio = ref.read(dioProvider);
  return AnalyticsRemoteDataSource(dio);
});

// Analytics Repository Provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(
    localDataSource: ref.read(analyticsLocalDataSourceProvider),
    remoteDataSource: ref.read(analyticsRemoteDataSourceProvider),
    networkInfo: NetworkInfoImpl(Connectivity()),
    talker: talker,
  );
});
