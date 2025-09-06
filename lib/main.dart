import 'dart:convert';

import 'package:bharat_ace/common/observers/app_route_observer.dart';
import 'package:bharat_ace/common/routes.dart';
import 'package:bharat_ace/core/providers/auth_provider.dart'
    show authStateProvider;
import 'package:bharat_ace/core/providers/student_details_listener.dart';
import 'package:bharat_ace/core/services/auth_checker.dart';
import 'package:bharat_ace/widgets/dark_mode_wrapper.dart';
import 'package:bharat_ace/core/config/supabase_config.dart';
import 'package:bharat_ace/core/utils/supabase_test.dart';
import 'package:bharat_ace/core/services/initialization_service.dart';
import 'package:bharat_ace/core/theme/app_theme.dart';

import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print Flutter rendering engine configuration
  print("🎨 FLUTTER RENDERER: Impeller should be enabled");
  print(
      "📱 If you're still seeing Impeller opt-out warnings, check your IDE configuration");

  // Configure Flutter for performance
  // This helps reduce jank by giving more resources to Flutter's engine
  // NOTE: For very heavy operations, we still need to use Isolates
  SchedulerBinding.instance.ensureVisualUpdate();

  // Test loading the career JSON file directly from multiple possible locations
  print("🔍 DIRECT JSON LOADING TEST 🔍");

  // Try different possible paths for the career database with full diagnostics
  print("📁 ASSET LOADING DIAGNOSTICS 📁");

  // List known assets explicitly in pubspec.yaml
  final List<String> possiblePaths = [
    'assets/career_database.json',
    'assets/career/career_database.json',
    'assets/careers/career_database.json',
    'career_database.json',
    '.env',
  ];

  for (String path in possiblePaths) {
    try {
      print("🔍 Attempting to load: '$path'");
      final String content = await rootBundle.loadString(path);
      print("✅ SUCCESS: Loaded '$path' (${content.length} characters)");

      // For JSON files, try parsing to ensure they're valid
      if (path.endsWith('.json')) {
        try {
          final jsonData = json.decode(content);
          print(
            "   ✓ JSON is valid and contains ${jsonData is Map ? jsonData.keys.length : 'non-map'} top-level keys",
          );
        } catch (jsonError) {
          print("   ⚠️ File loaded but JSON parsing failed: $jsonError");
        }
      }
    } catch (e) {
      print("❌ FAILED: Could not load '$path'");
      print("   Error: $e");
    }
  }

  // Test asset bundle contents
  try {
    print("🔍 Listing available assets in bundle (not all may be shown):");
    // While we can't directly list assets, we can check if a few common directories are accessible
    for (final dir in ['assets/', 'assets/career/', 'assets/fonts/']) {
      try {
        await rootBundle.loadString('$dir');
        print("   ✓ Directory exists: $dir");
      } catch (e) {
        print("   ✗ Could not access: $dir");
      }
    }
  } catch (e) {
    print("   ⚠️ Asset listing failed: $e");
  }

  // Initialize Firebase first
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  // Initialize App Timer for discipline system
  AppTimerManager.startSession();

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
      '🔧 Please check your Supabase configuration in supabase_config.dart',
    );
    // Continue without Supabase for now
  }

  runApp(
    ProviderScope(child: DarkModeWrapper(child: MyApp())),
  ); // Riverpod ProviderScope with forced dark mode
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = ref.watch(authStateProvider);
    final __ = ref.watch(studentDetailsFetcher); // Ensure listener is active
    // Always use dark theme for now
    print("MyApp Build: Watched critical providers.");
    final appRouteObserver = AppRouteObserver(ref);

    return MaterialApp(
      title: 'BharatAce',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Force dark theme as default
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Always use dark mode
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
      final String? navigateTo = await platform.invokeMethod<String>(
        'getLaunchRoute',
      );
      print("AppInitializer: Received launch route from native: $navigateTo");
      if (navigateTo == AppRoutes.alarm) {
        // Check if it matches the alarm route
        targetRoute = AppRoutes.alarm;
      }
    } on PlatformException catch (e) {
      print(
        "AppInitializer: Could not get launch route from native: ${e.message}. Using default.",
      );
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
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppTheme.primary,
        ),
      ),
    );
  }
}
