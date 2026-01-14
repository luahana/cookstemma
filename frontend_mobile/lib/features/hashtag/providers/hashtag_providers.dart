import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/data/datasources/hashtag/hashtag_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/repositories/hashtag_repository_impl.dart';
import 'package:pairing_planet2_frontend/domain/repositories/hashtag_repository.dart';

// ----------------------------------------------------------------
// Data Layer Providers
// ----------------------------------------------------------------

final hashtagRemoteDataSourceProvider = Provider<HashtagRemoteDataSource>((ref) {
  final dio = ref.read(dioProvider);
  return HashtagRemoteDataSource(dio);
});

final hashtagRepositoryProvider = Provider<HashtagRepository>((ref) {
  final remoteDataSource = ref.read(hashtagRemoteDataSourceProvider);
  return HashtagRepositoryImpl(remoteDataSource);
});
