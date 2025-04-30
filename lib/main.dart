import 'package:bharat_ace/common/routes.dart';
import 'package:bharat_ace/core/providers/auth_provider.dart'
    show authStateProvider;
import 'package:bharat_ace/screens/home_screen/home_screen2.dart'
    show studentDetailsFetcher;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  runApp(ProviderScope(child: MyApp())); // Riverpod ProviderScope
}

class MyApp extends ConsumerWidget {
  // Make sure it's ConsumerWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = ref.watch(authStateProvider);
    final __ = ref.watch(studentDetailsFetcher); // Ensure listener is active
    print("MyApp Build: Watched critical providers.");

    return MaterialApp(
      // ... rest of MaterialApp setup ...
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.authChecker,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
