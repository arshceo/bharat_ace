import 'package:bharat_ace/common/app_theme.dart';
import 'package:bharat_ace/screens/student_details_screen.dart';
import 'package:bharat_ace/widgets/floating_particles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

class StudentQueryScreen extends StatefulWidget {
  const StudentQueryScreen({super.key});

  @override
  _StudentQueryScreenState createState() => _StudentQueryScreenState();
}

class _StudentQueryScreenState extends State<StudentQueryScreen>
    with TickerProviderStateMixin {
  int _selectedClass = 0;
  final Random _random = Random();
  late AnimationController _swirlController;
  late Animation<double> _twistAnimation;
  late Animation<double> _scaleAnimation;
  bool _isAnimating = false;

  final List<IconData> _classIcons = [
    Icons.one_k_plus_outlined,
    Icons.school,
    Icons.menu_book,
    Icons.auto_stories,
    Icons.workspace_premium,
    Icons.science,
    Icons.biotech,
    Icons.computer,
    Icons.calculate,
    Icons.history_edu,
    Icons.language,
    Icons.psychology
  ];

  final List<String> _classLabels = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "11",
    "12"
  ];

  @override
  void initState() {
    super.initState();
    _swirlController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _twistAnimation = Tween<double>(begin: 0.0, end: 2.0 * pi).animate(
        CurvedAnimation(parent: _swirlController, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
        CurvedAnimation(parent: _swirlController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _swirlController.dispose();
    super.dispose();
  }

  List<Widget> _generateScatteredNumbers() {
    return List.generate(15, (index) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        left: _random.nextDouble() * MediaQuery.of(context).size.width,
        top: _random.nextDouble() * MediaQuery.of(context).size.height,
        child: Transform.rotate(
          angle: _twistAnimation.value,
          child: Text(
            _classLabels[_selectedClass],
            style: TextStyle(
              fontSize: _random.nextDouble() * 50 + 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber.withAlpha(50),
            ),
          ),
        ),
      );
    });
  }

  void _goToUserDetailsScreen() {
    setState(() {
      _isAnimating = true;
    });
    _swirlController.forward().then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StudentDetailsScreen()),
      ).then((_) {
        setState(() {
          _isAnimating = false;
          _swirlController.reverse();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _swirlController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _twistAnimation.value,
              child: child,
            ),
          );
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: AppTheme.secondaryColor),
            ),
            Positioned.fill(
              child: FloatingParticles(
                  numParticles: 40, particleColor: Colors.white30),
            ),
            Stack(children: _generateScatteredNumbers()),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 150),
                child: Icon(
                  _classIcons[_selectedClass],
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ),
            Center(
              child: ClipOval(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withAlpha(80),
                  ),
                  child: Center(
                    child: SizedBox(
                      height: 150,
                      child: CupertinoPicker(
                        itemExtent: 50,
                        magnification: 2,
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
                                color: Colors.white,
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
                padding: const EdgeInsets.only(bottom: 100),
                child: GestureDetector(
                  onTap: _isAnimating ? null : _goToUserDetailsScreen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 40),
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
      ),
    );
  }
}
