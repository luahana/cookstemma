import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/network/dio_provider.dart';
import 'package:pairing_planet2_frontend/core/providers/locale_provider.dart';
import 'package:pairing_planet2_frontend/core/services/social_auth_service.dart';
import 'package:pairing_planet2_frontend/core/services/storage_service.dart';
import 'package:pairing_planet2_frontend/data/datasources/user/user_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/models/user/accept_legal_terms_request_dto.dart';
import 'package:pairing_planet2_frontend/domain/usecases/auth/login_usecase.dart';
import 'package:pairing_planet2_frontend/domain/usecases/auth/logout_usecase.dart';
import 'package:pairing_planet2_frontend/data/datasources/auth/auth_local_data_source.dart';
import 'package:pairing_planet2_frontend/data/datasources/auth/auth_remote_data_source.dart';
import 'package:pairing_planet2_frontend/data/repositories/auth_repository_impl.dart';
import 'package:pairing_planet2_frontend/domain/repositories/auth_repository.dart';

// --- State 정의 ---
enum AuthStatus { authenticated, unauthenticated, guest, initial, needsLegalAcceptance }

class AuthState extends Equatable {
  // 💡 Equatable 상속
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({required this.status, this.errorMessage});

  @override
  List<Object?> get props => [status, errorMessage]; // 💡 동등성 비교 기준 설정
}

// --- Notifier 정의 ---
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthRepository _repository;
  final StorageService _storageService;
  final UserRemoteDataSource _userRemoteDataSource;

  // Pending action to execute after login (for guest -> authenticated flow)
  VoidCallback? _pendingAction;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthRepository repository,
    required StorageService storageService,
    required UserRemoteDataSource userRemoteDataSource,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _repository = repository,
       _storageService = storageService,
       _userRemoteDataSource = userRemoteDataSource,
       super(AuthState(status: AuthStatus.initial)) {
    checkAuthStatus();
  }

  Future<void> login() async {
    final result = await _loginUseCase.executeGoogleLogin();

    if (!mounted) return;

    await result.fold(
      (failure) async => state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: failure.toString(),
      ),
      (_) async => await _checkLegalAcceptanceAndSetState(),
    );
  }

  Future<void> loginWithApple() async {
    final result = await _loginUseCase.executeAppleLogin();

    if (!mounted) return;

    await result.fold(
      (failure) async => state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: failure.toString(),
      ),
      (_) async => await _checkLegalAcceptanceAndSetState(),
    );
  }

  /// Check if user has accepted legal terms from backend and set appropriate state
  Future<void> _checkLegalAcceptanceAndSetState() async {
    try {
      final profile = await _userRemoteDataSource.getMyProfile();
      if (!mounted) return;

      final user = profile.user;
      final currentTermsVersion = StorageService.currentTermsVersion;
      final currentPrivacyVersion = StorageService.currentPrivacyVersion;

      // Check if user has accepted the current versions
      final hasAcceptedTerms = user.termsVersion == currentTermsVersion;
      final hasAcceptedPrivacy = user.privacyVersion == currentPrivacyVersion;

      if (hasAcceptedTerms && hasAcceptedPrivacy) {
        // Sync to local storage for offline reference
        await _storageService.saveLegalAcceptance(
          marketingAgreed: user.marketingAgreed ?? false,
        );
        state = AuthState(status: AuthStatus.authenticated);
      } else {
        state = AuthState(status: AuthStatus.needsLegalAcceptance);
      }
    } catch (e) {
      // Fallback to local storage check if backend fails
      final hasAccepted = await _storageService.hasAcceptedLegalTerms();
      if (!mounted) return;

      if (hasAccepted) {
        state = AuthState(status: AuthStatus.authenticated);
      } else {
        state = AuthState(status: AuthStatus.needsLegalAcceptance);
      }
    }
  }

  /// Called after user accepts legal terms - syncs to backend and local storage
  Future<void> acceptLegalTerms({required bool marketingAgreed}) async {
    try {
      // Send to backend first
      final request = AcceptLegalTermsRequestDto(
        termsVersion: StorageService.currentTermsVersion,
        privacyVersion: StorageService.currentPrivacyVersion,
        marketingAgreed: marketingAgreed,
      );
      await _userRemoteDataSource.acceptLegalTerms(request);

      // Also save locally for offline reference
      await _storageService.saveLegalAcceptance(marketingAgreed: marketingAgreed);

      if (!mounted) return;
      state = AuthState(status: AuthStatus.authenticated);
    } catch (e) {
      // Still save locally even if backend fails - will sync on next login
      await _storageService.saveLegalAcceptance(marketingAgreed: marketingAgreed);
      if (!mounted) return;
      state = AuthState(status: AuthStatus.authenticated);
    }
  }

  Future<void> logout() async {
    final result = await _logoutUseCase.execute();

    if (!mounted) return;

    result.fold(
      (failure) => state = AuthState(status: AuthStatus.unauthenticated),
      (_) => state = AuthState(status: AuthStatus.unauthenticated),
    );
  }

  void loginSuccess() {
    if (!mounted) return;
    state = AuthState(status: AuthStatus.authenticated);
  }

  /// Enter guest mode to browse without signing in
  Future<void> enterGuestMode() async {
    // Clear any existing tokens to ensure clean guest state
    await _repository.clearTokens();
    if (!mounted) return;
    state = AuthState(status: AuthStatus.guest);
  }

  /// Store a pending action to execute after successful login
  void setPendingAction(VoidCallback action) {
    _pendingAction = action;
  }

  /// Execute and clear the pending action (called after login success)
  void executePendingAction() {
    _pendingAction?.call();
    _pendingAction = null;
  }

  /// Check if there's a pending action waiting
  bool get hasPendingAction => _pendingAction != null;

  Future<void> checkAuthStatus() async {
    final result = await _repository.reissueToken();

    if (!mounted) return;

    await result.fold(
      (_) async => state = AuthState(status: AuthStatus.unauthenticated),
      (_) async => await _checkLegalAcceptanceAndSetState(),
    );
  }
}

// --- Providers 등록 (무한 루프 방지를 위해 read 권장) ---

// 1. Data Sources
final authRemoteDataSourceProvider = Provider((ref) {
  // Dio가 바뀌면 통째로 바뀌어야 하므로 여기는 watch를 유지하거나,
  // dioProvider 자체에서 리빌드를 방지해야 합니다.
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSource(dio);
});

final authLocalDataSourceProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AuthLocalDataSource(storage);
});

// 2. Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // 💡 리포지토리는 앱 실행 중 한 번만 생성되도록 read를 권장하지만,
  // 💡 만약 Dio가 바뀔 때 리포지토리도 갱신되어야 한다면 watch를 사용해도 됩니다.
  // 💡 여기서는 안정성을 위해 핵심 의존성은 read로 가져옵니다.
  final remote = ref.read(authRemoteDataSourceProvider);
  final local = ref.read(authLocalDataSourceProvider);
  final social = ref.read(socialAuthServiceProvider);

  // 💡 현재 에러가 발생한 지점: 마지막 인자로 ref를 그대로 넘겨줍니다.
  return AuthRepositoryImpl(
    remote,
    local,
    social,
    () => ref.read(localeProvider),
  );
});

// 3. UseCases
final loginUseCaseProvider = Provider((ref) {
  final repository = ref.read(authRepositoryProvider);
  final socialService = ref.read(socialAuthServiceProvider);
  return LoginUseCase(repository, socialService);
});

final logoutUseCaseProvider = Provider((ref) {
  final repository = ref.read(authRepositoryProvider);
  return LogoutUseCase(repository);
});

// 4. UserRemoteDataSource (for legal acceptance check)
final userRemoteDataSourceForAuthProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(ref.read(dioProvider));
});

// 5. StateNotifier
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // 💡 Notifier 자체는 한 번만 생성되어야 하므로 read 사용
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    logoutUseCase: ref.read(logoutUseCaseProvider),
    repository: ref.read(authRepositoryProvider),
    storageService: ref.read(storageServiceProvider),
    userRemoteDataSource: ref.read(userRemoteDataSourceForAuthProvider),
  );
});
