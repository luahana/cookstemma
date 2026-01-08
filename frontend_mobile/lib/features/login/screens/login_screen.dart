import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 AuthState를 구독하여 에러 메시지가 있으면 스낵바를 띄웁니다.
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Pairing Planet ${'login.title'.tr()}'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'login.welcome'.tr(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: Text('login.googleLogin'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                  ),
                  onPressed: () async {
                    // 💡 UI에서는 로직을 직접 수행하지 않고 Notifier에게 로그인하라고 시키기만 합니다.
                    // 이렇게 하면 위젯이 Dispose되어도 Notifier 안에서 비즈니스 로직은 안전하게 끝납니다.
                    await ref.read(authStateProvider.notifier).login();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
