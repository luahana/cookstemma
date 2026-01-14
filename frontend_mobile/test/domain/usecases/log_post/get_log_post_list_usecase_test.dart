import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/cursor_page_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/common/slice_response.dart';
import 'package:pairing_planet2_frontend/domain/entities/log_post/log_post_summary.dart';
import 'package:pairing_planet2_frontend/domain/repositories/log_post_repository.dart';
import 'package:pairing_planet2_frontend/domain/usecases/log_post/get_log_post_list_usecase.dart';

class MockLogPostRepository extends Mock implements LogPostRepository {}

void main() {
  late GetLogPostListUseCase useCase;
  late MockLogPostRepository mockRepository;

  setUp(() {
    mockRepository = MockLogPostRepository();
    useCase = GetLogPostListUseCase(mockRepository);
  });

  group('GetLogPostListUseCase', () {
    final testLogs = [
      LogPostSummary(
        id: 'log-1',
        title: 'Test Log 1',
        outcome: 'SUCCESS',
        thumbnailUrl: 'https://example.com/thumb1.jpg',
        creatorName: 'user1',
      ),
      LogPostSummary(
        id: 'log-2',
        title: 'Test Log 2',
        outcome: 'PARTIAL',
        thumbnailUrl: 'https://example.com/thumb2.jpg',
        creatorName: 'user2',
      ),
    ];

    final cursorResponse = CursorPageResponse<LogPostSummary>(
      content: testLogs,
      nextCursor: null,
      hasNext: false,
      size: 20,
    );

    final sliceResponse = SliceResponse<LogPostSummary>(
      content: testLogs,
      number: 0,
      size: 20,
      first: true,
      last: true,
      hasNext: false,
    );

    group('call() - cursor-based pagination for general logs', () {
      test('should call repository.getLogPosts with cursor parameters', () async {
        // Arrange
        when(() => mockRepository.getLogPosts(
              cursor: any(named: 'cursor'),
              size: any(named: 'size'),
              query: any(named: 'query'),
              outcomes: any(named: 'outcomes'),
            )).thenAnswer((_) async => Right(cursorResponse));

        // Act
        final result = await useCase(size: 20);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRepository.getLogPosts(
              cursor: null,
              size: 20,
              query: null,
              outcomes: null,
            )).called(1);
      });

      test('should pass cursor, query and outcomes to repository', () async {
        // Arrange
        when(() => mockRepository.getLogPosts(
              cursor: any(named: 'cursor'),
              size: any(named: 'size'),
              query: any(named: 'query'),
              outcomes: any(named: 'outcomes'),
            )).thenAnswer((_) async => Right(cursorResponse));

        // Act
        await useCase(
          cursor: 'next_cursor_token',
          size: 20,
          query: 'search term',
          outcomes: ['SUCCESS', 'PARTIAL'],
        );

        // Assert
        verify(() => mockRepository.getLogPosts(
              cursor: 'next_cursor_token',
              size: 20,
              query: 'search term',
              outcomes: ['SUCCESS', 'PARTIAL'],
            )).called(1);
      });

      test('should return failure when repository fails', () async {
        // Arrange
        when(() => mockRepository.getLogPosts(
              cursor: any(named: 'cursor'),
              size: any(named: 'size'),
              query: any(named: 'query'),
              outcomes: any(named: 'outcomes'),
            )).thenAnswer((_) async => Left(ServerFailure('Server error')));

        // Act
        final result = await useCase(size: 20);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should be Left'),
        );
      });

      test('should return CursorPageResponse with correct content', () async {
        // Arrange
        when(() => mockRepository.getLogPosts(
              cursor: any(named: 'cursor'),
              size: any(named: 'size'),
              query: any(named: 'query'),
              outcomes: any(named: 'outcomes'),
            )).thenAnswer((_) async => Right(cursorResponse));

        // Act
        final result = await useCase(size: 20);

        // Assert
        result.fold(
          (failure) => fail('Should be Right'),
          (response) {
            expect(response.content, hasLength(2));
            expect(response.content[0].id, 'log-1');
            expect(response.content[1].id, 'log-2');
            expect(response.hasNext, false);
            expect(response.nextCursor, isNull);
          },
        );
      });
    });

    group('getByRecipe() - page-based pagination for recipe logs', () {
      test('should call repository.getLogsByRecipe with page parameters', () async {
        // Arrange
        when(() => mockRepository.getLogsByRecipe(
              recipeId: any(named: 'recipeId'),
              page: any(named: 'page'),
              size: any(named: 'size'),
            )).thenAnswer((_) async => Right(sliceResponse));

        // Act
        final result = await useCase.getByRecipe(
          recipeId: 'recipe-123',
          page: 0,
          size: 20,
        );

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRepository.getLogsByRecipe(
              recipeId: 'recipe-123',
              page: 0,
              size: 20,
            )).called(1);
      });

      test('should pass pagination parameters correctly', () async {
        // Arrange
        when(() => mockRepository.getLogsByRecipe(
              recipeId: any(named: 'recipeId'),
              page: any(named: 'page'),
              size: any(named: 'size'),
            )).thenAnswer((_) async => Right(sliceResponse));

        // Act
        await useCase.getByRecipe(
          recipeId: 'recipe-123',
          page: 2,
          size: 10,
        );

        // Assert
        verify(() => mockRepository.getLogsByRecipe(
              recipeId: 'recipe-123',
              page: 2,
              size: 10,
            )).called(1);
      });

      test('should return failure when repository fails for recipe logs', () async {
        // Arrange
        when(() => mockRepository.getLogsByRecipe(
              recipeId: any(named: 'recipeId'),
              page: any(named: 'page'),
              size: any(named: 'size'),
            )).thenAnswer((_) async => Left(ServerFailure('Recipe not found')));

        // Act
        final result = await useCase.getByRecipe(
          recipeId: 'invalid-recipe',
          page: 0,
          size: 20,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should be Left'),
        );
      });

      test('should return SliceResponse with correct content', () async {
        // Arrange
        when(() => mockRepository.getLogsByRecipe(
              recipeId: any(named: 'recipeId'),
              page: any(named: 'page'),
              size: any(named: 'size'),
            )).thenAnswer((_) async => Right(sliceResponse));

        // Act
        final result = await useCase.getByRecipe(
          recipeId: 'recipe-123',
          page: 0,
          size: 20,
        );

        // Assert
        result.fold(
          (failure) => fail('Should be Right'),
          (response) {
            expect(response.content, hasLength(2));
            expect(response.content[0].id, 'log-1');
            expect(response.content[1].id, 'log-2');
            expect(response.hasNext, false);
          },
        );
      });
    });
  });
}
