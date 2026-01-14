import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pairing_planet2_frontend/core/error/failures.dart';
import 'package:pairing_planet2_frontend/core/services/storage_service.dart';
import 'package:pairing_planet2_frontend/data/models/user/accept_legal_terms_request_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/my_profile_response_dto.dart';
import 'package:pairing_planet2_frontend/data/models/user/user_dto.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';

import '../../../helpers/mock_providers.dart';

// Fake classes for registerFallbackValue
class FakeAcceptLegalTermsRequestDto extends Fake
    implements AcceptLegalTermsRequestDto {}

void main() {
  late AuthNotifier authNotifier;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockAuthRepository mockAuthRepository;
  late MockStorageService mockStorageService;
  late MockUserRemoteDataSource mockUserRemoteDataSource;

  // Test data
  final testUserDtoWithAcceptedTerms = UserDto(
    id: 'test-user-id',
    username: 'testuser',
    termsVersion: StorageService.currentTermsVersion,
    privacyVersion: StorageService.currentPrivacyVersion,
    marketingAgreed: false,
  );

  final testUserDtoWithoutAcceptedTerms = UserDto(
    id: 'test-user-id',
    username: 'testuser',
    termsVersion: null,
    privacyVersion: null,
    marketingAgreed: null,
  );

  final testProfileWithAcceptedTerms = MyProfileResponseDto(
    user: testUserDtoWithAcceptedTerms,
    recipeCount: 0,
    logCount: 0,
    savedCount: 0,
  );

  final testProfileWithoutAcceptedTerms = MyProfileResponseDto(
    user: testUserDtoWithoutAcceptedTerms,
    recipeCount: 0,
    logCount: 0,
    savedCount: 0,
  );

  setUpAll(() {
    registerFallbackValue(FakeAcceptLegalTermsRequestDto());
  });

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockAuthRepository = MockAuthRepository();
    mockStorageService = MockStorageService();
    mockUserRemoteDataSource = MockUserRemoteDataSource();

    // Default: reissueToken fails (unauthenticated state)
    when(() => mockAuthRepository.reissueToken())
        .thenAnswer((_) async => Left(ServerFailure('No token')));

    // Default: backend returns user with accepted terms
    when(() => mockUserRemoteDataSource.getMyProfile())
        .thenAnswer((_) async => testProfileWithAcceptedTerms);

    // Default: legal acceptance succeeds
    when(() => mockUserRemoteDataSource.acceptLegalTerms(any()))
        .thenAnswer((_) async => testUserDtoWithAcceptedTerms);

    // Default: local storage operations succeed
    when(() => mockStorageService.hasAcceptedLegalTerms())
        .thenAnswer((_) async => true);
    when(() => mockStorageService.saveLegalAcceptance(marketingAgreed: any(named: 'marketingAgreed')))
        .thenAnswer((_) async {});

    authNotifier = AuthNotifier(
      loginUseCase: mockLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
      repository: mockAuthRepository,
      storageService: mockStorageService,
      userRemoteDataSource: mockUserRemoteDataSource,
    );
  });

  group('AuthNotifier', () {
    group('initial state', () {
      test('should transition to unauthenticated after checkAuthStatus fails', () async {
        // The notifier calls checkAuthStatus in constructor
        // Wait for the async checkAuthStatus to complete
        await Future.delayed(const Duration(milliseconds: 50));

        expect(authNotifier.state.status, AuthStatus.unauthenticated);
      });

      test('should transition to authenticated when reissueToken succeeds and terms accepted', () async {
        // Arrange - set up a new notifier with successful token reissue
        when(() => mockAuthRepository.reissueToken())
            .thenAnswer((_) async => const Right(unit));

        final authenticatedNotifier = AuthNotifier(
          loginUseCase: mockLoginUseCase,
          logoutUseCase: mockLogoutUseCase,
          repository: mockAuthRepository,
          storageService: mockStorageService,
          userRemoteDataSource: mockUserRemoteDataSource,
        );

        // Wait for the async checkAuthStatus to complete
        await Future.delayed(const Duration(milliseconds: 50));

        expect(authenticatedNotifier.state.status, AuthStatus.authenticated);
      });

      test('should transition to needsLegalAcceptance when terms not accepted', () async {
        // Arrange - set up a new notifier with successful token reissue but no terms accepted
        when(() => mockAuthRepository.reissueToken())
            .thenAnswer((_) async => const Right(unit));
        when(() => mockUserRemoteDataSource.getMyProfile())
            .thenAnswer((_) async => testProfileWithoutAcceptedTerms);

        final authenticatedNotifier = AuthNotifier(
          loginUseCase: mockLoginUseCase,
          logoutUseCase: mockLogoutUseCase,
          repository: mockAuthRepository,
          storageService: mockStorageService,
          userRemoteDataSource: mockUserRemoteDataSource,
        );

        // Wait for the async checkAuthStatus to complete
        await Future.delayed(const Duration(milliseconds: 50));

        expect(authenticatedNotifier.state.status, AuthStatus.needsLegalAcceptance);
      });
    });

    group('login', () {
      test('should set authenticated status when login succeeds', () async {
        // Arrange
        when(() => mockLoginUseCase.executeGoogleLogin())
            .thenAnswer((_) async => const Right(unit));

        // Act
        await authNotifier.login();

        // Assert
        expect(authNotifier.state.status, AuthStatus.authenticated);
        expect(authNotifier.state.errorMessage, isNull);
      });

      test('should set unauthenticated status with error when login fails', () async {
        // Arrange
        final failure = ServerFailure('Login failed');
        when(() => mockLoginUseCase.executeGoogleLogin())
            .thenAnswer((_) async => Left(failure));

        // Act
        await authNotifier.login();

        // Assert
        expect(authNotifier.state.status, AuthStatus.unauthenticated);
        expect(authNotifier.state.errorMessage, isNotNull);
      });
    });

    group('logout', () {
      test('should set unauthenticated status when logout succeeds', () async {
        // Arrange - first login
        when(() => mockLoginUseCase.executeGoogleLogin())
            .thenAnswer((_) async => const Right(unit));
        when(() => mockLogoutUseCase.execute())
            .thenAnswer((_) async => const Right(unit));

        await authNotifier.login();
        expect(authNotifier.state.status, AuthStatus.authenticated);

        // Act
        await authNotifier.logout();

        // Assert
        expect(authNotifier.state.status, AuthStatus.unauthenticated);
      });

      test('should set unauthenticated status even when logout fails', () async {
        // Arrange - first login
        when(() => mockLoginUseCase.executeGoogleLogin())
            .thenAnswer((_) async => const Right(unit));
        when(() => mockLogoutUseCase.execute())
            .thenAnswer((_) async => Left(ServerFailure('Logout error')));

        await authNotifier.login();
        expect(authNotifier.state.status, AuthStatus.authenticated);

        // Act
        await authNotifier.logout();

        // Assert - still unauthenticated even on failure
        expect(authNotifier.state.status, AuthStatus.unauthenticated);
      });
    });

    group('enterGuestMode', () {
      test('should set guest status and clear tokens', () async {
        // Arrange
        when(() => mockAuthRepository.clearTokens())
            .thenAnswer((_) async {});

        // Act
        await authNotifier.enterGuestMode();

        // Assert
        expect(authNotifier.state.status, AuthStatus.guest);
        verify(() => mockAuthRepository.clearTokens()).called(1);
      });
    });

    group('loginSuccess', () {
      test('should set authenticated status directly', () {
        // Act
        authNotifier.loginSuccess();

        // Assert
        expect(authNotifier.state.status, AuthStatus.authenticated);
      });
    });

    group('pending action', () {
      test('should initially have no pending action', () {
        expect(authNotifier.hasPendingAction, false);
      });

      test('should store pending action', () {
        // Arrange
        bool actionExecuted = false;
        void testAction() => actionExecuted = true;

        // Act
        authNotifier.setPendingAction(testAction);

        // Assert
        expect(authNotifier.hasPendingAction, true);
        expect(actionExecuted, false); // Not executed yet
      });

      test('should execute and clear pending action', () {
        // Arrange
        bool actionExecuted = false;
        void testAction() => actionExecuted = true;

        authNotifier.setPendingAction(testAction);
        expect(authNotifier.hasPendingAction, true);

        // Act
        authNotifier.executePendingAction();

        // Assert
        expect(actionExecuted, true);
        expect(authNotifier.hasPendingAction, false);
      });

      test('should handle executePendingAction when no action is set', () {
        // Act & Assert - should not throw
        expect(() => authNotifier.executePendingAction(), returnsNormally);
        expect(authNotifier.hasPendingAction, false);
      });
    });

    group('checkAuthStatus', () {
      test('should set authenticated when token reissue succeeds', () async {
        // Arrange
        when(() => mockAuthRepository.reissueToken())
            .thenAnswer((_) async => const Right(unit));

        // Act
        await authNotifier.checkAuthStatus();

        // Assert
        expect(authNotifier.state.status, AuthStatus.authenticated);
      });

      test('should set unauthenticated when token reissue fails', () async {
        // Arrange
        when(() => mockAuthRepository.reissueToken())
            .thenAnswer((_) async => Left(ServerFailure('Token expired')));

        // Act
        await authNotifier.checkAuthStatus();

        // Assert
        expect(authNotifier.state.status, AuthStatus.unauthenticated);
      });
    });
  });

  group('AuthState', () {
    test('should be equal when status and errorMessage are the same', () {
      const state1 = AuthState(status: AuthStatus.authenticated);
      const state2 = AuthState(status: AuthStatus.authenticated);

      expect(state1, equals(state2));
    });

    test('should not be equal when status differs', () {
      const state1 = AuthState(status: AuthStatus.authenticated);
      const state2 = AuthState(status: AuthStatus.unauthenticated);

      expect(state1, isNot(equals(state2)));
    });

    test('should not be equal when errorMessage differs', () {
      const state1 = AuthState(status: AuthStatus.unauthenticated, errorMessage: 'Error 1');
      const state2 = AuthState(status: AuthStatus.unauthenticated, errorMessage: 'Error 2');

      expect(state1, isNot(equals(state2)));
    });
  });
}
