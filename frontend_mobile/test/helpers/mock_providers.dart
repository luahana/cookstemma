import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/network/network_info.dart';
import 'package:pairing_planet2_frontend/core/services/media_service.dart';
import 'package:pairing_planet2_frontend/core/services/social_auth_service.dart';
import 'package:pairing_planet2_frontend/core/providers/image_providers.dart';
import 'package:pairing_planet2_frontend/data/datasources/auth/auth_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/auth/auth_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/recipe/recipe_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/recipe/recipe_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/log_post/log_post_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/sync/sync_queue_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/follow/follow_remote_data_source.dart';
import 'package:pairing_planet2_frontend/domain/repositories/auth_repository.dart';
import 'package:pairing_planet2_frontend/domain/repositories/recipe_repository.dart';
import 'package:pairing_planet2_frontend/domain/repositories/log_post_repository.dart';
import 'package:pairing_planet2_frontend/domain/usecases/auth/login_usecase.dart';
import 'package:pairing_planet2_frontend/domain/usecases/auth/logout_usecase.dart';

// ============================================================
// Repository Mocks
// ============================================================

class MockAuthRepository extends Mock implements AuthRepository {}

class MockRecipeRepository extends Mock implements RecipeRepository {}

class MockLogPostRepository extends Mock implements LogPostRepository {}

// ============================================================
// Data Source Mocks
// ============================================================

// Auth
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

// Recipe
class MockRecipeRemoteDataSource extends Mock implements RecipeRemoteDataSource {}

class MockRecipeLocalDataSource extends Mock implements RecipeLocalDataSource {}

// Log Post
class MockLogPostRemoteDataSource extends Mock implements LogPostRemoteDataSource {}

class MockLogPostLocalDataSource extends Mock implements LogPostLocalDataSource {}

// Sync Queue
class MockSyncQueueLocalDataSource extends Mock
    implements SyncQueueLocalDataSource {}

// Follow
class MockFollowRemoteDataSource extends Mock
    implements FollowRemoteDataSource {}

// ============================================================
// Service Mocks
// ============================================================

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockSocialAuthService extends Mock implements SocialAuthService {}

// ============================================================
// UseCase Mocks
// ============================================================

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockUploadImageWithTrackingUseCase extends Mock
    implements UploadImageWithTrackingUseCase {}

// ============================================================
// Image/Media Mocks
// ============================================================

class MockImagePicker extends Mock implements ImagePicker {}

class MockMediaService extends Mock implements MediaService {}

// ============================================================
// Fake Classes for registerFallbackValue
// ============================================================

// Register these in setUpAll() when using mocktail with any() matchers
// Example:
//   setUpAll(() {
//     registerFallbackValue(FakeSocialLoginRequestDto());
//     registerFallbackValue(FakeFile());
//     registerFallbackValue(ImageSource.camera);
//   });

class FakeFile extends Fake implements File {}

// Add fake classes as needed for DTOs used with any() matcher
