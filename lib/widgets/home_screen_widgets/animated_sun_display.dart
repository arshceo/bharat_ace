import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bharat_ace/core/models/daily_feed_item.dart';
import 'package:bharat_ace/core/theme/app_colors.dart'; // Ensure this path is correct

class AnimatedSunDisplay extends StatefulWidget {
  final DailyFeedItem dailyFeedItem;
  final VoidCallback onTap;

  const AnimatedSunDisplay({
    Key? key,
    required this.dailyFeedItem,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedSunDisplay> createState() => _AnimatedSunDisplayState();
}

class _AnimatedSunDisplayState extends State<AnimatedSunDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimationOuter;
  late Animation<double> _rotationAnimationInner;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30), // Slower, more majestic rotation
      vsync: this,
    )..repeat();

    _rotationAnimationOuter = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _rotationAnimationInner = Tween<double>(begin: 0, end: -2 * pi).animate(
      // Rotate opposite direction
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    // Define heights: sun visual part and total widget height
    const double sunVisualHeight = 160.0;
    const double totalWidgetHeight =
        sunVisualHeight + 100.0; // + space for text

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: totalWidgetHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            // A very dark blue, almost black, for a space-like feel
            color: const Color(0xFF0A0F1A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orangeAccent.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ]),
        child: Column(
          children: [
            // --- Animated Sun Visual ---
            SizedBox(
              height: sunVisualHeight,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SunPainter(
                      rotationAngleOuter: _rotationAnimationOuter.value,
                      rotationAngleInner: _rotationAnimationInner.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
            // --- AI Spark Text Content ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 10), // Reduced top padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.dailyFeedItem.title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                          // Adjusted size
                          color: Colors.yellow.shade100,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            const Shadow(
                                blurRadius: 3,
                                color: Colors.black87,
                                offset: Offset(1, 1))
                          ]),
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
                      style: textTheme.bodySmall?.copyWith(
                          // Adjusted size
                          color: Colors.orange.shade100.withOpacity(0.9),
                          shadows: [
                            const Shadow(
                                blurRadius: 2,
                                color: Colors.black54,
                                offset: Offset(1, 1))
                          ]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // --- Tap Indicator ---
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0, bottom: 8.0),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.orange.shade200.withOpacity(0.7),
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

// --- SunPainter ---
class SunPainter extends CustomPainter {
  final double rotationAngleOuter;
  final double rotationAngleInner;

  SunPainter(
      {required this.rotationAngleOuter, required this.rotationAngleInner});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final coreRadius = min(size.width, size.height) / 5.5; // Adjusted core size

    // --- Sun Core Glow (background blur) ---
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow.shade700.withOpacity(0.5),
          Colors.orange.shade900.withOpacity(0.3),
          Colors.red.shade900.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.1, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(
          center: center, radius: coreRadius * 2.5)) // Larger glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20); // More blur
    canvas.drawCircle(center, coreRadius * 2.5, glowPaint);

    // --- Sun Core (Main Orb) ---
    final Paint corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow.shade300, // Brightest yellow
          Colors.amber.shade600,
          Colors.orange.shade800,
          Colors.deepOrange.shade900, // Deepest orange/red
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, corePaint);

    // --- Sun Rays/Flares ---
    final Paint rayPaintOuter = Paint()
      ..shader = LinearGradient(
        // Gradient for rays
        colors: [
          Colors.orange.shade500.withOpacity(0.9),
          Colors.yellow.shade600.withOpacity(0.7)
        ],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, coreRadius * 0.5, coreRadius * 1.8))
      ..style = PaintingStyle.fill;

    final Paint rayPaintInner = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.yellow.shade400.withOpacity(0.85),
          Colors.amber.shade300.withOpacity(0.65)
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, coreRadius * 0.4, coreRadius * 1.5))
      ..style = PaintingStyle.fill;

    const int numRays = 9; // Number of rays for each set

    // Outer Rays
    final double rayLengthOuter = coreRadius * 1.8;
    final double rayBaseWidthOuter = coreRadius * 0.5;
    for (int i = 0; i < numRays; i++) {
      final angle = (2 * pi / numRays) * i + rotationAngleOuter;
      _drawRay(canvas, center, angle, coreRadius * 0.85, rayLengthOuter,
          rayBaseWidthOuter, rayPaintOuter);
    }

    // Inner Rays (slightly smaller, different rotation)
    final double rayLengthInner = coreRadius * 1.5;
    final double rayBaseWidthInner = coreRadius * 0.4;
    for (int i = 0; i < numRays; i++) {
      final angle = (2 * pi / numRays) * (i + 0.5) +
          rotationAngleInner; // Offset and different rotation
      _drawRay(canvas, center, angle, coreRadius * 0.9, rayLengthInner,
          rayBaseWidthInner, rayPaintInner);
    }
  }

  void _drawRay(Canvas canvas, Offset center, double angle, double startRadius,
      double length, double baseWidth, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final Path path = Path();
    double outerRadius = startRadius + length; // Tip of the flare
    double midRadius =
        startRadius + length * 0.55; // Mid-point for curve control

    // Bottom-left base of the flare (relative to rotated canvas origin)
    path.moveTo(startRadius, -baseWidth * 0.25);

    // Curve to the tip (left side of flare)
    path.quadraticBezierTo(
        midRadius,
        -baseWidth * 0.6, // Control point for outer left curve
        outerRadius,
        0 // Tip of the flare
        );

    // Curve from tip back to base (right side of flare)
    path.quadraticBezierTo(
        midRadius,
        baseWidth * 0.6, // Control point for outer right curve
        startRadius,
        baseWidth * 0.25 // Bottom-right base of the flare
        );

    // Connect back to start for a closed, thicker base if desired, or just close.
    // This creates a slightly more bulbous base.
    path.quadraticBezierTo(
        startRadius * 0.95, 0, startRadius, -baseWidth * 0.25);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SunPainter oldDelegate) {
    return oldDelegate.rotationAngleOuter != rotationAngleOuter ||
        oldDelegate.rotationAngleInner != rotationAngleInner;
  }
}
