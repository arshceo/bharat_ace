import 'package:flutter/material.dart';

class ScrollArrow extends StatefulWidget {
  const ScrollArrow({super.key});

  @override
  _ScrollArrowState createState() => _ScrollArrowState();
}

class _ScrollArrowState extends State<ScrollArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // Makes the animation go up and down continuously

    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up the controller when widget is removed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value), // Moves the arrow up and down
          child: child,
        );
      },
      child: const Icon(Icons.keyboard_arrow_up, size: 32, color: Colors.white),
    );
  }
}
