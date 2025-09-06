import 'package:flutter/material.dart';

/// A custom painter that renders a starfield background effect
class StarfieldPainter extends CustomPainter {
  final List<Offset> particles;
  final Color accentColor;

  StarfieldPainter({
    required this.particles,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw background stars/particles
    for (final particle in particles) {
      // Calculate position relative to the size
      final x = (particle.dx % size.width);
      final y = (particle.dy % size.height);

      // Vary the sizes of stars
      final starSize = (x * y) % 3 + 1;

      // Vary the opacity based on position
      final opacity = 0.1 + ((x + y) % 80) / 100;
      paint.color = accentColor.withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) {
    return oldDelegate.particles != particles ||
        oldDelegate.accentColor != accentColor;
  }
}
