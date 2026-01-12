import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/providers/isar_provider.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/user/my_profile_response_dto.dart';

// Re-export all profile providers for backward compatibility
export 'my_recipes_provider.dart';
export 'my_logs_provider.dart';
export 'saved_recipes_provider.dart';
export 'saved_logs_provider.dart';

/// Provider for UserLocalDataSource
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  final isar = ref.read(isarProvider);
  return UserLocalDataSource(isar);
});

/// Provider for UserRemoteDataSource (singleton to avoid duplicate instances)
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(ref.read(dioProvider));
});

/// 내 프로필 Provider
final myProfileProvider =
    FutureProvider.autoDispose<MyProfileResponseDto>((ref) async {
  final dataSource = ref.read(userRemoteDataSourceProvider);
  return dataSource.getMyProfile();
});
