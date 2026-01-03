import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/services/storage_service.dart';

enum AuthStatus { authenticated, unauthenticated, initial }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  AuthState({required this.status, this.errorMessage});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final StorageService _storage;

  AuthNotifier(this._storage) : super(AuthState(status: AuthStatus.initial)) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      state = AuthState(status: AuthStatus.authenticated);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void logout() async {
    await _storage.clearTokens();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

// 💡 전역 프로바이더 등록
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(StorageService());
});
