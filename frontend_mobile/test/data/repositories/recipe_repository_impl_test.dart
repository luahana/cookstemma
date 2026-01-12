import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/recipe_detail_response_dto.dart';
import 'package:pairing_planet2_frontend/data/repositories/recipe_repository_impl.dart';

import '../../helpers/mock_providers.dart';

// Fake classes for registerFallbackValue
class FakeRecipeDetailResponseDto extends Fake
    implements RecipeDetailResponseDto {}

void main() {
  late RecipeRepositoryImpl repository;
  late MockRecipeRemoteDataSource mockRemoteDataSource;
  late MockRecipeLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  // Test data
  final testRecipeDto = RecipeDetailResponseDto(
    publicId: 'recipe-123',
    foodName: 'Kimchi Fried Rice',
    foodMasterPublicId: 'food-master-1',
    creatorName: 'chef_kim',
    title: 'Mom\'s Special Kimchi Fried Rice',
    description: 'A delicious recipe from my grandmother',
    culinaryLocale: 'ko-KR',
  );

  setUpAll(() {
    registerFallbackValue(FakeRecipeDetailResponseDto());
  });

  setUp(() {
    mockRemoteDataSource = MockRecipeRemoteDataSource();
    mockLocalDataSource = MockRecipeLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();

    repository = RecipeRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('RecipeRepositoryImpl', () {
    group('getRecipeDetail', () {
      test('should return recipe from remote when online and cache it', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockLocalDataSource.getLastRecipeDetail(any()))
            .thenAnswer((_) async => null);
        when(() => mockRemoteDataSource.getRecipeDetail(any()))
            .thenAnswer((_) async => testRecipeDto);
        when(() => mockLocalDataSource.cacheRecipeDetail(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getRecipeDetail('recipe-123');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return success'),
          (recipe) {
            expect(recipe.publicId, 'recipe-123');
            expect(recipe.title, 'Mom\'s Special Kimchi Fried Rice');
          },
        );
        verify(() => mockRemoteDataSource.getRecipeDetail('recipe-123')).called(1);
        verify(() => mockLocalDataSource.cacheRecipeDetail(testRecipeDto)).called(1);
      });

      test('should return cached recipe when offline', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getLastRecipeDetail(any()))
            .thenAnswer((_) async => testRecipeDto);

        // Act
        final result = await repository.getRecipeDetail('recipe-123');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return success'),
          (recipe) {
            expect(recipe.publicId, 'recipe-123');
          },
        );
        verifyNever(() => mockRemoteDataSource.getRecipeDetail(any()));
      });

      test('should return ConnectionFailure when offline and no cache', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getLastRecipeDetail(any()))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getRecipeDetail('recipe-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return cached recipe when remote throws DioException', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockLocalDataSource.getLastRecipeDetail(any()))
            .thenAnswer((_) async => testRecipeDto);
        when(() => mockRemoteDataSource.getRecipeDetail(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/recipes/123'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act
        final result = await repository.getRecipeDetail('recipe-123');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return cached data'),
          (recipe) {
            expect(recipe.publicId, 'recipe-123');
          },
        );
      });

      test('should return failure when remote throws and no cache exists', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockLocalDataSource.getLastRecipeDetail(any()))
            .thenAnswer((_) async => null);
        when(() => mockRemoteDataSource.getRecipeDetail(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/recipes/123'),
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 404,
              requestOptions: RequestOptions(path: '/recipes/123'),
            ),
          ),
        );

        // Act
        final result = await repository.getRecipeDetail('recipe-123');

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('saveRecipe', () {
      test('should call remote save and return success', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.saveRecipe(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.saveRecipe('recipe-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.saveRecipe('recipe-123')).called(1);
      });

      test('should return failure when save throws DioException', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.saveRecipe(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/recipes/123/save'),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act
        final result = await repository.saveRecipe('recipe-123');

        // Assert
        expect(result.isLeft(), true);
      });

      test('should return ConnectionFailure when offline', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.saveRecipe('recipe-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('unsaveRecipe', () {
      test('should call remote unsave and return success', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.unsaveRecipe(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.unsaveRecipe('recipe-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.unsaveRecipe('recipe-123')).called(1);
      });

      test('should return failure when unsave throws', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.unsaveRecipe(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/recipes/123/unsave'),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act
        final result = await repository.unsaveRecipe('recipe-123');

        // Assert
        expect(result.isLeft(), true);
      });

      test('should return ConnectionFailure when offline', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.unsaveRecipe('recipe-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('deleteRecipe', () {
      test('should call remote delete and return success', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteRecipe(any()))
            .thenAnswer((_) async {});
        when(() => mockLocalDataSource.removeRecipeDetail(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.deleteRecipe('recipe-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.deleteRecipe('recipe-123')).called(1);
        verify(() => mockLocalDataSource.removeRecipeDetail('recipe-123')).called(1);
      });

      test('should return failure when delete throws', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteRecipe(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/recipes/123'),
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 403,
              requestOptions: RequestOptions(path: '/recipes/123'),
            ),
          ),
        );

        // Act
        final result = await repository.deleteRecipe('recipe-123');

        // Assert
        expect(result.isLeft(), true);
      });

      test('should return ConnectionFailure when offline', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.deleteRecipe('recipe-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
