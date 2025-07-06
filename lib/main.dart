import 'package:bharat_ace/common/observers/app_route_observer.dart';
import 'package:bharat_ace/common/routes.dart';
import 'package:bharat_ace/core/providers/auth_provider.dart'
    show authStateProvider;
import 'package:bharat_ace/core/providers/student_details_listener.dart';
import 'package:bharat_ace/core/services/auth_checker.dart';
import 'package:bharat_ace/core/config/supabase_config.dart';
import 'package:bharat_ace/core/utils/supabase_test.dart';
import 'package:bharat_ace/core/services/initialization_service.dart';

import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with proper error handling
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: true, // Enable debug mode to see more logs
    );
    print('✅ Supabase initialized successfully');
    print('🔗 Supabase URL: ${SupabaseConfig.supabaseUrl}');

    // Mark as initialized
    InitializationService.markSupabaseInitialized();

    // Test connection and run comprehensive tests
    SupabaseTest.testConnection();

    // Run async tests after a short delay to let the app initialize
    Future.delayed(const Duration(seconds: 2), () async {
      print('\n🧪 Running Supabase diagnostic tests...\n');
      await SupabaseTest.runAllTests();
    });
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
    print(
        '🔧 Please check your Supabase configuration in supabase_config.dart');
    // Continue without Supabase for now
  }

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
    final appRouteObserver = AppRouteObserver(ref);

    return MaterialApp(
      // ... rest of MaterialApp setup ...
      title: 'BharatAce',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [appRouteObserver],
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
  static const platform = MethodChannel('com.bharatace.app/lifecycle');
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
