// --- lib/core/services/auth_checker.dart (Simple Reactive Version - For Initial Load) ---
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:bharat_ace/screens/authentication/login_screen.dart';
import 'package:bharat_ace/screens/main_layout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<User?> authState = ref.watch(authStateProvider);
    print(
        "AuthChecker Build: Watching Auth State -> ${authState.map(data: (d) => 'Data(${d.value?.uid})', error: (e) => 'Error', loading: (_) => 'Loading')}");

    // Handles initial app load state
    return authState.when(
      data: (user) {
        print(
            "AuthChecker Data: User = ${user?.uid ?? 'null'}. Returning ${user == null ? 'LoginScreen' : 'MainLayout'}");
        return user == null ? const LoginScreen() : const MainLayout();
      },
      loading: () {
        print("AuthChecker Loading...");
        return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()));
      },
      error: (err, stack) {
        print("AuthChecker Error: $err. Returning LoginScreen.");
        return const LoginScreen();
      },
    );
  }
}
