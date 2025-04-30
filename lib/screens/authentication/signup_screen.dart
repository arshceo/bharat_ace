import 'dart:ui';
import 'dart:math';
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/routes.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isLoading = false;

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
    for (int i = 0; i < 8; i++) {
      double size = random.nextInt(30) + 70.0;
      sizes.add(size);

      AnimationController controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: random.nextInt(6) + 5),
      )..repeat(reverse: true);

      Animation<Offset> animation = Tween<Offset>(
        begin: Offset(random.nextDouble(), random.nextDouble()),
        end: Offset(random.nextDouble(), random.nextDouble()),
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      controllers.add(controller);
      animations.add(animation);
    }
  }

  void _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => isLoading = true);
    final authService = ref.read(authServiceProvider);

    try {
      // Attempt sign up
      UserCredential? userCredential = await authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential != null && userCredential.user != null) {
        // --- SUCCESS ---
        // **CRITICAL: Do NOT update studentDetailsProvider state here.**
        // The StudentDetailsInitializer/fetcher will handle loading/creating
        // the initial state based on the now logged-in user.

        print("Signup successful for UID: ${userCredential.user!.uid}");
        // Navigate to the start of onboarding
        if (mounted) {
          // Check if widget is still in the tree
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.onboard, (route) => false);
        }
      } else {
        // Handle signup failure (userCredential is null)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("Signup failed. Email might be taken or invalid.")),
          );
        }
      }
    } catch (e) {
      // Handle potential errors during signup (e.g., network)
      print("Signup Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("An error occurred during signup: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = ref.read(studentDetailsProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Stack(children: _buildFloatingGlows())),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔥 **Title Animation**
                    SizedBox(
                      height: 50, // Prevents jumping
                      child: AnimatedTextKit(
                        repeatForever: true,
                        animatedTexts: [
                          RotateAnimatedText("Bharat Ace",
                              textStyle: _titleStyle),
                          RotateAnimatedText("भारत ऐस", textStyle: _titleStyle),
                          RotateAnimatedText("ਭਾਰਤ ਏਸ", textStyle: _titleStyle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 🔥 **Signup Fields**
                    _buildNeonTextField("Email", false, _emailController),
                    const SizedBox(height: 15),
                    _buildNeonTextField("Password", true, _passwordController),
                    const SizedBox(height: 15),
                    _buildNeonTextField(
                        "Confirm Password", true, _confirmPasswordController),
                    const SizedBox(height: 25),

                    // 🔥 **Signup Button**
                    _buildGlowingButton(),

                    const SizedBox(height: 20),

                    // 🔥 **Login Navigation**
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.login);
                      },
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(
                          color: Colors.white54,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50), // Prevents empty black space
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **🔥 Floating Glows (Neon Aura)**
  List<Widget> _buildFloatingGlows() {
    List<Color> colors = [
      Colors.purpleAccent.withOpacity(0.05),
      Colors.blueAccent.withOpacity(0.05),
      Colors.pinkAccent.withOpacity(0.05),
      Colors.orangeAccent.withOpacity(0.005),
    ];
    Random random = Random();

    return List.generate(8, (index) {
      return AnimatedBuilder(
        animation: animations[index],
        builder: (context, child) {
          return Positioned(
            left: MediaQuery.of(context).size.width *
                animations[index].value.dx *
                0.95,
            top: MediaQuery.of(context).size.height *
                animations[index].value.dy *
                0.95,
            child: child!,
          );
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
                  color: colors[index % colors.length].withOpacity(0.6),
                  blurRadius: 50,
                  spreadRadius: 25,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// **🔥 Neon Text Field**
  Widget _buildNeonTextField(
      String hint, bool isPassword, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(
            isPassword ? Icons.lock : Icons.email,
            color: Colors.cyanAccent,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  /// **🔵 Neon Glowing Button**
  Widget _buildGlowingButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: MediaQuery.of(context).size.width / 2,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _signUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Colors.purpleAccent, width: 1),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Sign Up",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ],
    );
  }

  final TextStyle _titleStyle =
      const TextStyle(fontSize: 38, color: Colors.white);
}
