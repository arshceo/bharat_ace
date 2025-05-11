import 'package:bharat_ace/common/routes.dart';
import 'package:bharat_ace/core/providers/auth_provider.dart'
    show authStateProvider;
import 'package:bharat_ace/core/services/auth_checker.dart';
import 'package:bharat_ace/screens/home_screen/home_screen2.dart'
    show studentDetailsFetcher;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart';
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

  static const platform = MethodChannel('com.bharatace.app/lifecycle');
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = ref.watch(authStateProvider);
    final __ = ref.watch(studentDetailsFetcher); // Ensure listener is active
    print("MyApp Build: Watched critical providers.");

    return MaterialApp(
      // ... rest of MaterialApp setup ...
      title: 'BharatAce',
      debugShowCheckedModeBanner: false,

      home: const AuthChecker(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  // Optional: Use MethodChannel to get initial launch intent data if needed reliably
  static const platform =
      MethodChannel('com.bharatace.app/lifecycle'); // Example channel

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is ready for navigation
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _determineInitialRouteAndNavigate();
    });
  }

  Future<void> _determineInitialRouteAndNavigate() async {
    String targetRoute = AppRoutes.authChecker; // Default route is AuthChecker

    // Check for Alarm Trigger via Platform Channel
    try {
      final String? navigateTo =
          await MyApp.platform.invokeMethod<String>('getLaunchRoute');
      print("AppInitializer: Received launch route from native: $navigateTo");
      if (navigateTo == AppRoutes.alarm) {
        // Check if it matches the alarm route
        targetRoute = AppRoutes.alarm;
      }
    } on PlatformException catch (e) {
      print(
          "AppInitializer: Could not get launch route from native: ${e.message}. Using default.");
    } catch (e) {
      print("AppInitializer: Error checking launch route: $e");
    }

    // Navigate and REPLACE the initializer screen
    if (mounted) {
      // Check if widget is still in the tree
      print("AppInitializer: Replacing with initial route: $targetRoute");
      // Use pushReplacementNamed to remove the Initializer from the stack
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while initializing
    return const Scaffold(
      backgroundColor: Colors.black, // Match your theme
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
