import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/data/models/log_post/log_post_detail_response_dto.dart';
import 'package:pairing_planet2_frontend/data/repositories/log_post_repository_impl.dart';

import '../../helpers/mock_providers.dart';

// Fake classes for registerFallbackValue
class FakeLogPostDetailResponseDto extends Fake
    implements LogPostDetailResponseDto {}

void main() {
  late LogPostRepositoryImpl repository;
  late MockLogPostRemoteDataSource mockRemoteDataSource;
  late MockLogPostLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  // Test data
  final testLogDetailDto = LogPostDetailResponseDto(
    publicId: 'log-123',
    title: 'My Cooking Log',
    content: 'My cooking experience was great!',
    outcome: 'SUCCESS',
    creatorPublicId: 'user-456',
    createdAt: DateTime.now().toIso8601String(),
    images: [],
    linkedRecipe: null,
    hashtags: [],
  );

  setUpAll(() {
    registerFallbackValue(FakeLogPostDetailResponseDto());
  });

  setUp(() {
    mockRemoteDataSource = MockLogPostRemoteDataSource();
    mockLocalDataSource = MockLogPostLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();

    repository = LogPostRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('LogPostRepositoryImpl', () {
    group('getLogDetail', () {
      test('should return log from remote when online and cache it', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockLocalDataSource.getLastLogDetail(any()))
            .thenAnswer((_) async => null);
        when(() => mockRemoteDataSource.getLogDetail(any()))
            .thenAnswer((_) async => testLogDetailDto);
        when(() => mockLocalDataSource.cacheLogDetail(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getLogDetail('log-123');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return success'),
          (log) {
            expect(log.publicId, 'log-123');
            expect(log.outcome, 'SUCCESS');
          },
        );
        verify(() => mockRemoteDataSource.getLogDetail('log-123')).called(1);
        verify(() => mockLocalDataSource.cacheLogDetail(testLogDetailDto)).called(1);
      });

      test('should return cached log when offline', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getLastLogDetail(any()))
            .thenAnswer((_) async => testLogDetailDto);

        // Act
        final result = await repository.getLogDetail('log-123');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return success'),
          (log) {
            expect(log.publicId, 'log-123');
          },
        );
        verifyNever(() => mockRemoteDataSource.getLogDetail(any()));
      });

      test('should return ConnectionFailure when offline and no cache', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getLastLogDetail(any()))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getLogDetail('log-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return cached log when remote throws exception', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockLocalDataSource.getLastLogDetail(any()))
            .thenAnswer((_) async => testLogDetailDto);
        when(() => mockRemoteDataSource.getLogDetail(any()))
            .thenThrow(Exception('Server error'));

        // Act
        final result = await repository.getLogDetail('log-123');

        // Assert
        expect(result.isRight(), true);
      });

      test('should return ServerFailure when remote throws and no cache exists', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockLocalDataSource.getLastLogDetail(any()))
            .thenAnswer((_) async => null);
        when(() => mockRemoteDataSource.getLogDetail(any()))
            .thenThrow(Exception('Server error'));

        // Act
        final result = await repository.getLogDetail('log-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getLogPosts', () {
      test('should return ConnectionFailure when offline', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.getLogPosts();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('saveLog', () {
      test('should call remote save and return success', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.saveLog(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.saveLog('log-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.saveLog('log-123')).called(1);
      });

      test('should return ConnectionFailure when offline', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.saveLog('log-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('unsaveLog', () {
      test('should call remote unsave and return success', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.unsaveLog(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.unsaveLog('log-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.unsaveLog('log-123')).called(1);
      });

      test('should return ConnectionFailure when offline', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.unsaveLog('log-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('deleteLog', () {
      test('should call remote delete and return success', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteLog(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.deleteLog('log-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.deleteLog('log-123')).called(1);
      });

      test('should return ConnectionFailure when offline', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.deleteLog('log-123');

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
