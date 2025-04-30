// --- lib/screens/authentication/login_screen.dart (Reactive Navigation - FINAL) ---

import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

// Import ACTUAL providers (Ensure path is correct)
import 'package:bharat_ace/core/providers/auth_provider.dart';

// Import Routes (Ensure path is correct)
import 'package:bharat_ace/common/routes.dart'; // Needed for signup navigation

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  List<AnimationController> controllers = [];
  List<Animation<Offset>> animations = [];
  List<double> sizes = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    Random random = Random();
    for (int i = 0; i < 10; i++) {
      double size = random.nextInt(30) + 70.0;
      sizes.add(size);
      AnimationController controller = AnimationController(
          vsync: this, duration: Duration(seconds: random.nextInt(6) + 5))
        ..repeat(reverse: true);
      Animation<Offset> animation = Tween<Offset>(
              begin: Offset(random.nextDouble(), random.nextDouble()),
              end: Offset(random.nextDouble(), random.nextDouble()))
          .animate(
              CurvedAnimation(parent: controller, curve: Curves.easeInOut));
      controllers.add(controller);
      animations.add(animation);
    }
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Login Function ---
  Future<void> _handleLogin() async {
    final authService = ref.read(authServiceProvider); // Read service provider
    if (_isLoading) return; // Prevent multiple taps while already loading

    // Basic Frontend Validation
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter both email & password")),
        );
      }
      return; // Stop processing if fields are empty
    }

    setState(() => _isLoading = true); // Start loading indicator

    try {
      UserCredential? userCredential =
          await authService.signIn(email, password);

      // *** CRITICAL CHANGE: Only print success, DO NOT NAVIGATE ***
      if (userCredential != null && userCredential.user != null) {
        print(
            "Login Successful for ${userCredential.user?.email}. AuthChecker will handle navigation.");
        // Navigation is handled reactively by AuthChecker watching authStateProvider
        // Successful login will trigger authStateProvider update, AuthChecker rebuilds -> shows MainLayout
      } else {
        // If signIn returns null without throwing an exception (less common)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Login failed. Please check credentials.")),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors more gracefully
      print("Login FirebaseAuthException: ${e.code} - ${e.message}");
      String errorMessage = "Login failed. Please try again.";
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check connection.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      // Handle other potential errors during login
      print("Login General Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("An unexpected error occurred: ${e.toString()}"),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      // Always turn off loading indicator if the widget is still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- End Login Function ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
              child: Stack(children: _buildFloatingGlows())), // Background anim
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        height: 50,
                        child: AnimatedTextKit(
                            repeatForever: true,
                            animatedTexts: [
                              RotateAnimatedText("Bharat Ace",
                                  textStyle: _titleStyle),
                              RotateAnimatedText("भारत ऐस",
                                  textStyle: _titleStyle),
                              RotateAnimatedText("ਭਾਰਤ ਏਸ",
                                  textStyle: _titleStyle)
                            ])),
                    const SizedBox(height: 50),
                    _buildNeonTextField("Email", false, _emailController),
                    const SizedBox(height: 20),
                    _buildNeonTextField("Password", true, _passwordController),
                    const SizedBox(height: 35),
                    _buildGlowingButton(), // Button calls _handleLogin
                    const SizedBox(height: 30),
                    GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.signup);
                        },
                        child: const Text("Don't have an account? Sign Up",
                            style: TextStyle(
                                color: Colors.white54,
                                decoration: TextDecoration.underline))),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  List<Widget> _buildFloatingGlows() {
    List<Color> colors = [
      Colors.purpleAccent.withOpacity(0.05),
      Colors.blueAccent.withOpacity(0.05),
      Colors.pinkAccent.withOpacity(0.05),
      Colors.orangeAccent.withOpacity(0.005)
    ];
    Random random = Random();
    return List.generate(10, (index) {
      return AnimatedBuilder(
          animation: animations[index],
          builder: (context, child) {
            return Positioned(
                left: MediaQuery.of(context).size.width *
                    animations[index].value.dx,
                top: MediaQuery.of(context).size.height *
                    animations[index].value.dy,
                child: child!);
          },
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                  width: sizes[index],
                  height: sizes[index],
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[index % colors.length],
                      boxShadow: [
                        BoxShadow(
                            color:
                                colors[index % colors.length].withOpacity(0.6),
                            blurRadius: 50,
                            spreadRadius: 25)
                      ]))));
    });
  }

  Widget _buildNeonTextField(
      String hint, bool isPassword, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(
              isPassword ? Icons.lock_outline : Icons.email_outlined,
              color: accentCyan.withOpacity(0.8)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentCyan, width: 1.5))),
    );
  }

  Widget _buildGlowingButton() {
    return GestureDetector(
        onTap: _handleLogin,
        child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 50,
            decoration: BoxDecoration(
                color: _isLoading ? Colors.grey.shade800 : Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryPurple, width: 1.5),
                boxShadow: !_isLoading
                    ? [
                        BoxShadow(
                            color: primaryPurple.withOpacity(0.5),
                            blurRadius: 15.0,
                            spreadRadius: 1.0)
                      ]
                    : []),
            child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : const Text("Login",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)))));
  }
} // End of _LoginScreenState

// --- Constants ---
const Color primaryPurple = Color(0xFF8A2BE2);
const Color accentCyan = Color(0xFF00FFFF);
const TextStyle _titleStyle =
    TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.bold);
