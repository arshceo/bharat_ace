import 'package:bharat_ace/common/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class StudentQueryScreen extends StatefulWidget {
  const StudentQueryScreen({super.key});

  @override
  _StudentQueryScreenState createState() => _StudentQueryScreenState();
}

class _StudentQueryScreenState extends State<StudentQueryScreen> {
  int _selectedClass = 0; // Default class index
  final Random _random = Random();

  final Color _secondaryColor = AppTheme.secondaryColor;

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

  List<Widget> _generateScatteredNumbers() {
    return List.generate(15, (index) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        left: _random.nextDouble() * MediaQuery.of(context).size.width,
        top: _random.nextDouble() * MediaQuery.of(context).size.height,
        child: Text(
          _classLabels[_selectedClass], // Only the digit is displayed
          style: TextStyle(
            fontSize: _random.nextDouble() * 50 + 20,
            fontWeight: FontWeight.bold,
            color: Colors.amber.withAlpha(50),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: double.infinity,
        color: _secondaryColor,
        child: Stack(
          children: [
            // Scattered Numbers Background
            Stack(children: _generateScatteredNumbers()),

            // Icon Above Picker
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

            // Main UI - Circular Picker
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

            // Glowing Next Button
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: GestureDetector(
                  onTap: () {
                    // Handle Next Button Press
                  },
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
