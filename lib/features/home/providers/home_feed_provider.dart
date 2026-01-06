import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/data/datasources/recipe/recipe_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/home/home_feed_response_dto.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';

final homeFeedProvider = FutureProvider.autoDispose<HomeFeedResponseDto>((ref) async {
  final dataSource = RecipeRemoteDataSource(ref.read(dioProvider));
  return dataSource.getHomeFeed();
});
