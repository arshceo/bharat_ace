// lib/widgets/home_screen_widgets/ai_spark_themes/moon_theme_display.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bharat_ace/core/models/daily_feed_item.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';

class MoonThemeDisplay extends StatefulWidget {
  final DailyFeedItem dailyFeedItem;
  final VoidCallback onTap;

  const MoonThemeDisplay({
    Key? key,
    required this.dailyFeedItem,
    required this.onTap,
  }) : super(key: key);

  @override
  State<MoonThemeDisplay> createState() => _MoonThemeDisplayState();
}

class _MoonThemeDisplayState extends State<MoonThemeDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10), // For subtle star twinkle
      vsync: this,
    )..repeat();

    // Initialize stars (example)
    _stars = List.generate(
        30,
        (index) => _Star(
              position: Offset(Random().nextDouble(),
                  Random().nextDouble()), // Normalized 0-1
              radius: Random().nextDouble() * 1.5 + 0.5,
              opacity: Random().nextDouble() * 0.5 + 0.3,
              twinkleSpeed: Random().nextDouble() * 0.5 + 0.5,
            ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    const double visualHeight = 160.0;
    const double totalWidgetHeight = visualHeight + 100.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: totalWidgetHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ]),
        child: Column(
          children: [
            SizedBox(
              height: visualHeight,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: MoonAndStarsPainter(
                      animationValue: _controller.value,
                      stars: _stars,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.dailyFeedItem.title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.dailyFeedItem.content.split('.').first +
                          (widget.dailyFeedItem.content.contains('.')
                              ? "."
                              : ""),
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade300),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0, bottom: 8.0),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400.withOpacity(0.7),
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Star {
  Offset position; // Normalized 0-1
  double radius;
  double opacity;
  double twinkleSpeed; // Multiplier for twinkle effect

  _Star(
      {required this.position,
      required this.radius,
      required this.opacity,
      required this.twinkleSpeed});
}

class MoonAndStarsPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final List<_Star> stars;

  MoonAndStarsPainter({required this.animationValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Stars
    final starPaint = Paint()..color = Colors.white;
    for (var star in stars) {
      // Simple twinkle effect by varying opacity
      double currentOpacity = star.opacity *
          (0.7 + 0.3 * sin(animationValue * 2 * pi * star.twinkleSpeed));
      starPaint.color =
          Colors.white.withOpacity(currentOpacity.clamp(0.1, 1.0));
      canvas.drawCircle(
          Offset(star.position.dx * size.width, star.position.dy * size.height),
          star.radius,
          starPaint);
    }

    // Draw Moon (from previous example, slightly adapted)
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        min(size.width, size.height) / 3.5; // Moon a bit smaller to see stars

    final Paint moonPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.35, -0.35),
        radius: 0.75,
        colors: [
          const Color(0xFFFEFEFE),
          const Color(0xFFE0E0E0),
          const Color(0xFFC8C8C8),
          const Color(0xFFA0A0A0),
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, moonPaint);

    // Simplified Craters (adjust opacities if needed for dark background)
    _drawCrater(canvas, center, radius, Offset(0.25, 0.35), 0.15,
        Colors.black.withOpacity(0.30), Colors.white.withOpacity(0.08));
    _drawCrater(canvas, center, radius, Offset(-0.45, -0.25), 0.22,
        Colors.black.withOpacity(0.35), Colors.white.withOpacity(0.10));
    _drawCrater(canvas, center, radius, Offset(0.3, -0.5), 0.12,
        Colors.black.withOpacity(0.25), Colors.white.withOpacity(0.07));
  }

  void _drawCrater(
      Canvas canvas,
      Offset moonCenter,
      double moonRadius,
      Offset relativePos,
      double relativeSize,
      Color shadowColor,
      Color highlightColor) {
    final craterCenter = moonCenter +
        Offset(relativePos.dx * moonRadius, relativePos.dy * moonRadius);
    final craterRadius = moonRadius * relativeSize;

    final shadowPaint = Paint()..color = shadowColor;
    canvas.drawCircle(
        craterCenter.translate(craterRadius * 0.15, craterRadius * 0.15),
        craterRadius * 1.05,
        shadowPaint);

    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = craterRadius * 0.25;
    canvas.drawArc(
      Rect.fromCircle(
          center:
              craterCenter.translate(-craterRadius * 0.1, -craterRadius * 0.1),
          radius: craterRadius),
      pi * 1.25,
      pi * 0.5,
      false,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant MoonAndStarsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
