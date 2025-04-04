import 'dart:ui';
import 'dart:math';
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
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
      // 🔥 **Increased blobs to fill screen**
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

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🔥 **Floating Glows Cover Entire Screen**
          Positioned.fill(child: Stack(children: _buildFloatingGlows())),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔥 **Title Animation Fix (Prevent Jumping)**
                    SizedBox(
                      height: 50, // ✅ Fixed height to prevent jumping
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

                    // 🔥 **Login Fields**
                    _buildNeonTextField("Email", false, _emailController),
                    const SizedBox(height: 15),
                    _buildNeonTextField("Password", true, _passwordController),
                    const SizedBox(height: 25),

                    // 🔥 **Login Button**
                    _buildGlowingButton(),
                    const SizedBox(height: 20),

                    // 🔥 **Signup Navigation (Fix for Empty Black Space)**
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 50), // ✅ Ensures content fills screen
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **🔥 Floating Blobs (FULL SCREEN)**
  List<Widget> _buildFloatingGlows() {
    List<Color> colors = [
      Colors.purpleAccent.withOpacity(0.05),
      Colors.blueAccent.withOpacity(0.05),
      Colors.pinkAccent.withOpacity(0.05),
      Colors.orangeAccent.withOpacity(0.005),
    ];
    Random random = Random();

    return List.generate(10, (index) {
      // 🔥 **More blobs for balance**
      return AnimatedBuilder(
        animation: animations[index],
        builder: (context, child) {
          return Positioned(
            left:
                MediaQuery.of(context).size.width * animations[index].value.dx,
            top:
                MediaQuery.of(context).size.height * animations[index].value.dy,
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

  /// **💡 Neon Text Field**
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
    final authService = ref.read(authServiceProvider);

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () async {
              setState(() => _isLoading = true);
              String email = _emailController.text.trim();
              String password = _passwordController.text.trim();

              if (email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Please enter email & password")),
                );
                setState(() => _isLoading = false);
                return;
              }

              try {
                UserCredential? userCredential =
                    await authService.signIn(email, password);
                if (userCredential != null) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Login failed. Check credentials.")),
                  );
                }
              } finally {
                setState(() => _isLoading = false);
              }
            },
      child: Container(
        width: MediaQuery.of(context).size.width / 2,
        height: 50,
        decoration: BoxDecoration(
          color: _isLoading ? Colors.grey : Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purpleAccent, width: 1),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Login",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }
}

final _titleStyle = TextStyle(fontSize: 38, color: Colors.white);
