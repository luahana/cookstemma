import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';

/// Splash screen state
enum SplashStatus { loading, ready }

/// Splash state containing status and final auth result
class SplashState {
  final SplashStatus status;
  final AuthStatus? authStatus;

  const SplashState({
    required this.status,
    this.authStatus,
  });

  factory SplashState.loading() => const SplashState(status: SplashStatus.loading);

  SplashState copyWith({
    SplashStatus? status,
    AuthStatus? authStatus,
  }) {
    return SplashState(
      status: status ?? this.status,
      authStatus: authStatus ?? this.authStatus,
    );
  }
}

/// Provider that manages splash screen timing
/// Waits for BOTH: 2-second timer AND auth check completion
class SplashNotifier extends StateNotifier<SplashState> {
  final Ref _ref;
  Timer? _timer;
  bool _timerComplete = false;
  bool _authComplete = false;
  AuthStatus? _finalAuthStatus;

  SplashNotifier(this._ref) : super(SplashState.loading()) {
    _startSplashSequence();
  }

  void _startSplashSequence() {
    // Start 2-second timer
    _timer = Timer(const Duration(seconds: 2), () {
      _timerComplete = true;
      _checkReady();
    });

    // Listen to auth state changes
    _ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status != AuthStatus.initial) {
        _authComplete = true;
        _finalAuthStatus = next.status;
        _checkReady();
      }
    }, fireImmediately: true);
  }

  void _checkReady() {
    if (_timerComplete && _authComplete && mounted) {
      state = SplashState(
        status: SplashStatus.ready,
        authStatus: _finalAuthStatus,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Splash provider - auto-disposes when leaving splash screen
final splashProvider = StateNotifierProvider.autoDispose<SplashNotifier, SplashState>((ref) {
  return SplashNotifier(ref);
});
