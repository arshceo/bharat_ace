import 'package:bharat_ace/common/app_theme.dart';
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/screens/onboarding_screen/student_details_screen.dart';
import 'package:bharat_ace/widgets/floating_particles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import 'package:google_fonts/google_fonts.dart';

class ClassSelectionScreen extends ConsumerStatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  _ClassSelectionScreenState createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends ConsumerState<ClassSelectionScreen>
    with SingleTickerProviderStateMixin {
  int _selectedClass = 0;
  final Random _random = Random();
  late AnimationController _swirlController;
  late Animation<double> _twistAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<IconData> _classIcons = [
    Icons.home,
    Icons.biotech,
    Icons.computer,
    Icons.calculate,
    Icons.history_edu,
    Icons.language,
    Icons.psychology
  ];
  // final Map<> _classIcons = {icon}
  //   Icons.home,
  //   Icons.biotech,
  //   Icons.computer,
  //   Icons.calculate,
  //   Icons.history_edu,
  //   Icons.language,
  //   Icons.psychology
  // ];
  final Map<String, List<String>> _classData = {
    "6": ["6", "A fresh start! Stay curious. 🌱"],
    "7": ["7", "Keep growing, keep learning! 📖"],
    "8": ["8", "Almost a senior! Stay focused. 💪"],
    "9": ["9", "High school begins! Aim high. 🚀"],
    "10": ["10", "Board exams ahead! Stay strong. 🎯"],
    "11": ["11", "Big year! Build your future. 📚"],
    "12": ["12", "Final year! Give it your best. 🎓"],
  };

  final List<String> _classLabels = ["6", "7", "8", "9", "10", "11", "12"];

  @override
  void initState() {
    super.initState();
    _swirlController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _twistAnimation = Tween<double>(begin: 0.0, end: 2.0 * pi).animate(
        CurvedAnimation(parent: _swirlController, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
        CurvedAnimation(parent: _swirlController, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _swirlController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _swirlController.dispose();
    super.dispose();
  }

  List<Widget> _generateScatteredNumbers() {
    return List.generate(10, (index) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        left: _random.nextDouble() * MediaQuery.of(context).size.width,
        top: _random.nextDouble() * MediaQuery.of(context).size.height,
        child: AnimatedBuilder(
          animation: _swirlController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _twistAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Text(
                  _classLabels[_selectedClass],
                  style: TextStyle(
                    fontSize: _random.nextDouble() * 50 + 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.withAlpha(40),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              // color: AppTheme.secondaryColor,
              color: Colors.black,
            ),
          ),
          Positioned.fill(
            child: FloatingParticles(
              numParticles: 40,
              particleColor: Colors.white30,
            ),
          ),
          Stack(children: _generateScatteredNumbers()),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 150, left: 20, right: 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: DefaultTextStyle(
                  key: ValueKey<int>(
                      _selectedClass), // This ensures animation happens when _selectedClass changes
                  style: GoogleFonts.firaCode(),
                  child: Column(
                    children: [
                      Text(
                        "${_classLabels[_selectedClass]}ᵗʰ",
                        key: ValueKey<String>(_classLabels[
                            _selectedClass]), // Unique key for animation
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        _classData[_classLabels[_selectedClass]]![1],
                        key: ValueKey<String>(
                            _classData[_classLabels[_selectedClass]]![
                                1]), // Unique key for description animation
                        style: TextStyle(
                          color: Colors.white60,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: ClipOval(
              child: Container(
                width: 220,
                height: 250,
                decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    // color: AppTheme.primaryColor.withAlpha(80),
                    // color: Colors.deepPurple.withAlpha(120)),
                    color: Colors.white10),
                child: Center(
                  child: SizedBox(
                    height: 320,
                    child: CupertinoPicker(
                      itemExtent: 50,
                      magnification: 1.5,
                      scrollController: FixedExtentScrollController(
                          initialItem: _selectedClass),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedClass = index;
                        });
                      },
                      children: _classLabels.map((label) {
                        return Center(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white54,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 220),
              child: Text(
                "Select your class",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.blueAccent,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: GestureDetector(
                onTap: () {
                  // Get the notifier
                  final studentNotifier =
                      ref.read(studentDetailsNotifierProvider.notifier);
                  // Get the currently logged-in user (should exist here)
                  final user = ref.read(firebaseAuthProvider).currentUser;

                  if (user == null) {
                    print("Error: User is null in ClassSelectionScreen");
                    // Handle error appropriately, maybe navigate back to login
                    return;
                  }

                  // Get the selected class label
                  final String selectedClass = _classLabels[_selectedClass];

                  // Update the state via the notifier
                  // The notifier handles creating the initial state if it's null
                  studentNotifier.setClass(
                      selectedClass); // Assuming setClass handles creation/update

                  // ---- NO Firestore write here ----

                  // Navigate to the next onboarding screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentDetailsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white54,
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
