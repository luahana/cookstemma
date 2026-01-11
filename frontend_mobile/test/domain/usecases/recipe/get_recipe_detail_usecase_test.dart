import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/recipe_detail.dart';
import 'package:pairing_planet2_frontend/domain/usecases/recipe/get_recipe_detail.dart';

import '../../../helpers/mock_providers.dart';

void main() {
  late GetRecipeDetailUseCase useCase;
  late MockRecipeRepository mockRepository;

  setUp(() {
    mockRepository = MockRecipeRepository();
    useCase = GetRecipeDetailUseCase(mockRepository);
  });

  group('GetRecipeDetailUseCase', () {
    const testPublicId = 'recipe-123-abc';
    final testRecipeDetail = RecipeDetail(
      publicId: testPublicId,
      title: 'Test Recipe',
      description: 'A test recipe description',
      foodName: 'Test Food',
      foodMasterPublicId: 'food-master-123',
      creatorName: 'Test Chef',
      ingredients: [],
      steps: [],
      imageUrls: [],
      imagePublicIds: [],
      variants: [],
      logs: [],
      hashtags: [],
    );

    test('should return RecipeDetail when repository call succeeds', () async {
      // Arrange
      when(() => mockRepository.getRecipeDetail(testPublicId))
          .thenAnswer((_) async => Right(testRecipeDetail));

      // Act
      final result = await useCase(testPublicId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (recipe) {
          expect(recipe.publicId, testPublicId);
          expect(recipe.title, 'Test Recipe');
        },
      );
      verify(() => mockRepository.getRecipeDetail(testPublicId)).called(1);
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      when(() => mockRepository.getRecipeDetail(testPublicId))
          .thenAnswer((_) async => Left(ServerFailure('Server error')));

      // Act
      final result = await useCase(testPublicId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (recipe) => fail('Should not return recipe'),
      );
    });

    test('should return NotFoundFailure when recipe does not exist', () async {
      // Arrange
      when(() => mockRepository.getRecipeDetail('nonexistent-id'))
          .thenAnswer((_) async => Left(NotFoundFailure('Recipe not found')));

      // Act
      final result = await useCase('nonexistent-id');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (recipe) => fail('Should not return recipe'),
      );
    });

    test('should pass correct publicId to repository', () async {
      // Arrange
      const specificId = 'specific-recipe-id-xyz';
      when(() => mockRepository.getRecipeDetail(specificId))
          .thenAnswer((_) async => Right(testRecipeDetail));

      // Act
      await useCase(specificId);

      // Assert
      verify(() => mockRepository.getRecipeDetail(specificId)).called(1);
      verifyNever(() => mockRepository.getRecipeDetail(testPublicId));
    });
  });
}
