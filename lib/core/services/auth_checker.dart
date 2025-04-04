import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:bharat_ace/screens/authentication/login_screen.dart';
import 'package:bharat_ace/screens/main_layout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => user == null ? LoginScreen() : MainLayout(),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (_, __) => LoginScreen(),
    );
  }
}
