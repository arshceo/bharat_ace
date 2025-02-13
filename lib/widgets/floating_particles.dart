import 'dart:math';
import 'package:flutter/material.dart';

class FloatingParticles extends StatefulWidget {
  final int numParticles;
  final Color particleColor;

  const FloatingParticles(
      {super.key, this.numParticles = 30, this.particleColor = Colors.white});

  @override
  _FloatingParticlesState createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true); // 🔥 Ensures smooth looping

    _particles = List.generate(widget.numParticles, (index) => Particle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
              _particles, _controller.value, widget.particleColor),
          child: Container(),
        );
      },
    );
  }
}

class Particle {
  double x = Random().nextDouble() * 400; // Random horizontal position
  double y = Random().nextDouble() * 800; // Random vertical position
  double radius = Random().nextDouble() * 4 + 1; // Random size
  double speed = Random().nextDouble() * 0.5 + 0.1; // Random speed
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color color;

  ParticlePainter(this.particles, this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.5);

    for (var particle in particles) {
      double yOffset = animationValue * size.height * 0.3; // Smooth movement
      double newY =
          (particle.y + yOffset) % size.height; // Loop particles seamlessly
      canvas.drawCircle(Offset(particle.x, newY), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
