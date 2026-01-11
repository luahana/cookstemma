import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_summary.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/slice_response.dart';
import 'package:pairing_planet2_frontend/data/models/auth/auth_response_dto.dart';

// ============================================================
// Auth Test Data
// ============================================================

class TestAuthData {
  static const String testAccessToken = 'test-access-token-12345';
  static const String testRefreshToken = 'test-refresh-token-67890';
  static const String testFirebaseIdToken = 'firebase-id-token-abcdef';
  static const String testUserPublicId = 'user-public-id-abc123';
  static const String testUsername = 'test_user';

  static AuthResponseDto get authResponse => AuthResponseDto(
        accessToken: testAccessToken,
        refreshToken: testRefreshToken,
        userPublicId: testUserPublicId,
        username: testUsername,
      );
}

// ============================================================
// Recipe Test Data
// ============================================================

class TestRecipeData {
  static RecipeSummary createRecipeSummary({
    String? publicId,
    String? title,
    String? foodName,
    String? creatorName,
    int variantCount = 0,
    int logCount = 0,
  }) {
    return RecipeSummary(
      publicId: publicId ?? 'recipe-${DateTime.now().millisecondsSinceEpoch}',
      foodName: foodName ?? 'Kimchi Fried Rice',
      title: title ?? 'Mom\'s Special Kimchi Fried Rice',
      description: 'A delicious recipe passed down from my grandmother.',
      culinaryLocale: 'ko-KR',
      thumbnailUrl: 'https://example.com/recipe-thumb.jpg',
      creatorName: creatorName ?? 'chef_kim',
      variantCount: variantCount,
      logCount: logCount,
    );
  }

  static List<RecipeSummary> createRecipeList({int count = 5}) {
    return List.generate(
      count,
      (i) => createRecipeSummary(
        publicId: 'recipe-$i',
        title: 'Recipe $i',
        creatorName: 'user$i',
      ),
    );
  }

  static SliceResponse<RecipeSummary> createRecipeSlice({
    int count = 5,
    bool hasNext = false,
    int page = 0,
  }) {
    return SliceResponse(
      content: createRecipeList(count: count),
      number: page,
      size: count,
      first: page == 0,
      last: !hasNext,
      hasNext: hasNext,
    );
  }
}

// ============================================================
// Log Post Test Data
// ============================================================

class TestLogPostData {
  static LogPostSummary createLogPostSummary({
    String? id,
    String? title,
    String? outcome,
    String? creatorName,
    DateTime? createdAt,
  }) {
    return LogPostSummary(
      id: id ?? 'log-${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'My Cooking Log',
      outcome: outcome ?? 'SUCCESS',
      thumbnailUrl: 'https://example.com/log-thumb.jpg',
      creatorName: creatorName ?? 'home_cook',
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static List<LogPostSummary> createLogPostList({int count = 5}) {
    final outcomes = ['SUCCESS', 'PARTIAL', 'FAILED'];
    return List.generate(
      count,
      (i) => createLogPostSummary(
        id: 'log-$i',
        title: 'Log $i',
        outcome: outcomes[i % 3],
        creatorName: 'user$i',
      ),
    );
  }

  static SliceResponse<LogPostSummary> createLogPostSlice({
    int count = 5,
    bool hasNext = false,
    int page = 0,
  }) {
    return SliceResponse(
      content: createLogPostList(count: count),
      number: page,
      size: count,
      first: page == 0,
      last: !hasNext,
      hasNext: hasNext,
    );
  }
}

// ============================================================
// Constants for Tests
// ============================================================

class TestConstants {
  static const String testUserId = 'user-test-123';
  static const String testRecipeId = 'recipe-test-456';
  static const String testLogId = 'log-test-789';
  static const String testLocale = 'en-US';
}
