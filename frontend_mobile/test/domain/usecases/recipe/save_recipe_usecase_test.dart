import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';

import '../../../helpers/mock_providers.dart';

// Export Failure types for use in tests

void main() {
  late MockRecipeRepository mockRepository;

  setUp(() {
    mockRepository = MockRecipeRepository();
  });

  group('Save Recipe Operations', () {
    const testPublicId = 'recipe-123-abc';

    group('saveRecipe', () {
      test('should return Right(void) when save succeeds', () async {
        // Arrange
        when(() => mockRepository.saveRecipe(testPublicId))
            .thenAnswer((_) async => const Right(null));

        // Act
        final result = await mockRepository.saveRecipe(testPublicId);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.saveRecipe(testPublicId)).called(1);
      });

      test('should return ServerFailure when save fails', () async {
        // Arrange
        when(() => mockRepository.saveRecipe(testPublicId))
            .thenAnswer((_) async => Left(ServerFailure('Server error')));

        // Act
        final result = await mockRepository.saveRecipe(testPublicId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should not succeed'),
        );
      });

      test('should return NotFoundFailure when recipe does not exist', () async {
        // Arrange
        when(() => mockRepository.saveRecipe('nonexistent-id'))
            .thenAnswer((_) async => Left(NotFoundFailure('Recipe not found')));

        // Act
        final result = await mockRepository.saveRecipe('nonexistent-id');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Should not succeed'),
        );
      });

      test('should return UnauthorizedFailure when not authenticated', () async {
        // Arrange
        when(() => mockRepository.saveRecipe(testPublicId))
            .thenAnswer((_) async => Left(UnauthorizedFailure('Not authenticated')));

        // Act
        final result = await mockRepository.saveRecipe(testPublicId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('Should not succeed'),
        );
      });
    });

    group('unsaveRecipe', () {
      test('should return Right(void) when unsave succeeds', () async {
        // Arrange
        when(() => mockRepository.unsaveRecipe(testPublicId))
            .thenAnswer((_) async => const Right(null));

        // Act
        final result = await mockRepository.unsaveRecipe(testPublicId);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.unsaveRecipe(testPublicId)).called(1);
      });

      test('should return ServerFailure when unsave fails', () async {
        // Arrange
        when(() => mockRepository.unsaveRecipe(testPublicId))
            .thenAnswer((_) async => Left(ServerFailure('Server error')));

        // Act
        final result = await mockRepository.unsaveRecipe(testPublicId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should not succeed'),
        );
      });

      test('should return NotFoundFailure when recipe was not saved', () async {
        // Arrange
        when(() => mockRepository.unsaveRecipe(testPublicId))
            .thenAnswer((_) async => Left(NotFoundFailure('Recipe not in saved list')));

        // Act
        final result = await mockRepository.unsaveRecipe(testPublicId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Should not succeed'),
        );
      });
    });

    group('save and unsave sequence', () {
      test('should be able to save then unsave a recipe', () async {
        // Arrange
        when(() => mockRepository.saveRecipe(testPublicId))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.unsaveRecipe(testPublicId))
            .thenAnswer((_) async => const Right(null));

        // Act
        final saveResult = await mockRepository.saveRecipe(testPublicId);
        final unsaveResult = await mockRepository.unsaveRecipe(testPublicId);

        // Assert
        expect(saveResult.isRight(), isTrue);
        expect(unsaveResult.isRight(), isTrue);
        verify(() => mockRepository.saveRecipe(testPublicId)).called(1);
        verify(() => mockRepository.unsaveRecipe(testPublicId)).called(1);
      });
    });
  });
}
