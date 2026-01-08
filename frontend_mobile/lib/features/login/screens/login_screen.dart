import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pairing_planet2_frontend/core/constants/constants.dart';
import 'package:pairing_planet2_frontend/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for auth state changes
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      // Show error snackbar if login failed
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }

      // On successful login, execute pending action and navigate home
      if (next.status == AuthStatus.authenticated &&
          previous?.status != AuthStatus.authenticated) {
        // Execute pending action if any (e.g., save recipe, follow user)
        ref.read(authStateProvider.notifier).executePendingAction();

        // Navigate to home
        if (context.mounted) {
          context.go(RouteConstants.home);
        }
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
              // Google Sign-In button
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
                    await ref.read(authStateProvider.notifier).login();
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Browse as Guest button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: Text('login.browseAsGuest'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).enterGuestMode();
                    if (!context.mounted) return;
                    context.go(RouteConstants.home);
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
