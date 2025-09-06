import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SparkleParticle {
  Offset position;
  Offset velocity;
  double size;
  Color color;
  double lifespan; // Total lifetime in seconds
  double age = 0; // Current age in seconds

  SparkleParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.lifespan,
  });

  void update() {
    position += velocity;
    age += 0.016; // Assuming 60fps (1/60 ≈ 0.016)

    // Reset particle if it's too old
    if (age > lifespan) {
      // Randomize new position (off-screen at the edges)
      final side = (position.dx + position.dy).round() % 4;
      switch (side) {
        case 0: // top
          position = Offset(position.dx, -size);
          break;
        case 1: // right
          position = Offset(500 + size, position.dy);
          break;
        case 2: // bottom
          position = Offset(position.dx, 800 + size);
          break;
        case 3: // left
          position = Offset(-size, position.dy);
          break;
      }
      age = 0;
    }
  }

  // Calculate opacity based on age and lifespan
  double get opacity {
    final fadeInDuration = lifespan * 0.2;
    final fadeOutStart = lifespan * 0.8;

    if (age < fadeInDuration) {
      // Fade in
      return age / fadeInDuration;
    } else if (age > fadeOutStart) {
      // Fade out
      return 1.0 - ((age - fadeOutStart) / (lifespan - fadeOutStart));
    }
    // Full opacity
    return 1.0;
  }
}

class SparkleParticlePainter extends CustomPainter {
  final List<SparkleParticle> sparkles;
  final bool darkMode;

  SparkleParticlePainter({
    required this.sparkles,
    required this.darkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Optional: Draw a subtle gradient background
    final Paint bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        darkMode
            ? [
                const Color(0xFF121212),
                const Color(0xFF1A1A1A),
              ]
            : [
                const Color(0xFFF8F8F8),
                const Color(0xFFF0F0F0),
              ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw node connections (lines between particles that are close enough)
    _drawConnections(canvas, size);

    // Draw sparkles
    for (final sparkle in sparkles) {
      final opacity = sparkle.opacity;
      final paint = Paint()
        ..color = sparkle.color.withOpacity(opacity * 0.7)
        ..style = PaintingStyle.fill
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round;

      // Draw the main sparkle
      canvas.drawCircle(
        sparkle.position,
        sparkle.size,
        paint,
      );

      // Draw a subtle glow
      canvas.drawCircle(
        sparkle.position,
        sparkle.size * 2,
        Paint()
          ..color = sparkle.color.withOpacity(opacity * 0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Draw a smaller bright center
      canvas.drawCircle(
        sparkle.position,
        sparkle.size * 0.4,
        Paint()
          ..color = Colors.white.withOpacity(opacity * 0.8)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawConnections(Canvas canvas, Size size) {
    const maxDistance = 100.0;

    for (int i = 0; i < sparkles.length; i++) {
      for (int j = i + 1; j < sparkles.length; j++) {
        final sparkle1 = sparkles[i];
        final sparkle2 = sparkles[j];

        final distance = (sparkle1.position - sparkle2.position).distance;

        if (distance < maxDistance) {
          // Opacity based on distance (closer = more visible)
          final opacity = 1 - (distance / maxDistance);

          // Average the colors of the two sparkles
          final color = Color.lerp(
            sparkle1.color,
            sparkle2.color,
            0.5,
          )!
              .withOpacity(opacity * 0.4);

          final paint = Paint()
            ..color = color
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;

          canvas.drawLine(sparkle1.position, sparkle2.position, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SparkleParticlePainter oldDelegate) => true;
}
