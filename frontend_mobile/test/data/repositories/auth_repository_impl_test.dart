import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/data/models/auth/social_login_request_dto.dart';
import 'package:pairing_planet2_frontend/data/models/auth/token_reissue_request_dto.dart';
import 'package:pairing_planet2_frontend/data/repositories/auth_repository_impl.dart';

import '../../helpers/mock_providers.dart';
import '../../helpers/test_data.dart';

// Fake classes for registerFallbackValue
class FakeSocialLoginRequestDto extends Fake implements SocialLoginRequestDto {}

class FakeTokenReissueRequestDto extends Fake implements TokenReissueRequestDto {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockSocialAuthService mockSocialAuthService;
  late String Function() getCurrentLocale;

  setUpAll(() {
    registerFallbackValue(FakeSocialLoginRequestDto());
    registerFallbackValue(FakeTokenReissueRequestDto());
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockSocialAuthService = MockSocialAuthService();
    getCurrentLocale = () => 'en-US';

    repository = AuthRepositoryImpl(
      mockRemoteDataSource,
      mockLocalDataSource,
      mockSocialAuthService,
      getCurrentLocale,
    );
  });

  group('AuthRepositoryImpl', () {
    group('socialLogin', () {
      test('should return Right(unit) when login is successful', () async {
        // Arrange
        when(() => mockRemoteDataSource.socialLogin(any()))
            .thenAnswer((_) async => TestAuthData.authResponse);
        when(() => mockLocalDataSource.saveTokens(any(), any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.socialLogin(TestAuthData.testFirebaseIdToken);

        // Assert
        expect(result, const Right(unit));
        verify(() => mockRemoteDataSource.socialLogin(any())).called(1);
        verify(() => mockLocalDataSource.saveTokens(
              TestAuthData.testAccessToken,
              TestAuthData.testRefreshToken,
            )).called(1);
      });

      test('should return Left(ServerFailure) when remote data source throws', () async {
        // Arrange
        when(() => mockRemoteDataSource.socialLogin(any()))
            .thenThrow(Exception('Server error'));

        // Act
        final result = await repository.socialLogin(TestAuthData.testFirebaseIdToken);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockLocalDataSource.saveTokens(any(), any()));
      });

      test('should pass correct locale to request', () async {
        // Arrange
        late SocialLoginRequestDto capturedRequest;
        when(() => mockRemoteDataSource.socialLogin(any())).thenAnswer((invocation) async {
          capturedRequest = invocation.positionalArguments[0] as SocialLoginRequestDto;
          return TestAuthData.authResponse;
        });
        when(() => mockLocalDataSource.saveTokens(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await repository.socialLogin(TestAuthData.testFirebaseIdToken);

        // Assert
        expect(capturedRequest.idToken, TestAuthData.testFirebaseIdToken);
        expect(capturedRequest.locale, 'en-US');
      });
    });

    group('reissueToken', () {
      test('should return Right(unit) when token reissue is successful', () async {
        // Arrange
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => TestAuthData.testRefreshToken);
        when(() => mockRemoteDataSource.reissueToken(any()))
            .thenAnswer((_) async => TestAuthData.authResponse);
        when(() => mockLocalDataSource.saveTokens(any(), any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.reissueToken();

        // Assert
        expect(result, const Right(unit));
        verify(() => mockLocalDataSource.getRefreshToken()).called(1);
        verify(() => mockRemoteDataSource.reissueToken(any())).called(1);
        verify(() => mockLocalDataSource.saveTokens(
              TestAuthData.testAccessToken,
              TestAuthData.testRefreshToken,
            )).called(1);
      });

      test('should return Left(ServerFailure) when refresh token is null', () async {
        // Arrange
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.reissueToken();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockRemoteDataSource.reissueToken(any()));
      });

      test('should return Left(ServerFailure) when refresh token is empty', () async {
        // Arrange
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => '');

        // Act
        final result = await repository.reissueToken();

        // Assert
        expect(result.isLeft(), true);
        verifyNever(() => mockRemoteDataSource.reissueToken(any()));
      });

      test('should clear tokens when reissue fails', () async {
        // Arrange
        when(() => mockLocalDataSource.getRefreshToken())
            .thenAnswer((_) async => TestAuthData.testRefreshToken);
        when(() => mockRemoteDataSource.reissueToken(any()))
            .thenThrow(Exception('Reissue failed'));
        when(() => mockLocalDataSource.clearAll())
            .thenAnswer((_) async {});

        // Act
        final result = await repository.reissueToken();

        // Assert
        expect(result.isLeft(), true);
        verify(() => mockLocalDataSource.clearAll()).called(1);
      });
    });

    group('logout', () {
      test('should return Right(unit) when logout is successful', () async {
        // Arrange
        when(() => mockLocalDataSource.clearAll())
            .thenAnswer((_) async {});
        when(() => mockSocialAuthService.signOut())
            .thenAnswer((_) async {});

        // Act
        final result = await repository.logout();

        // Assert
        expect(result, const Right(unit));
        verify(() => mockLocalDataSource.clearAll()).called(1);
        verify(() => mockSocialAuthService.signOut()).called(1);
      });

      test('should return Left(ServerFailure) when clearing tokens fails', () async {
        // Arrange
        when(() => mockLocalDataSource.clearAll())
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await repository.logout();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return Left(ServerFailure) when social sign out fails', () async {
        // Arrange
        when(() => mockLocalDataSource.clearAll())
            .thenAnswer((_) async {});
        when(() => mockSocialAuthService.signOut())
            .thenThrow(Exception('Social auth error'));

        // Act
        final result = await repository.logout();

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('clearTokens', () {
      test('should call local data source clearAll', () async {
        // Arrange
        when(() => mockLocalDataSource.clearAll())
            .thenAnswer((_) async {});

        // Act
        await repository.clearTokens();

        // Assert
        verify(() => mockLocalDataSource.clearAll()).called(1);
      });
    });
  });
}
