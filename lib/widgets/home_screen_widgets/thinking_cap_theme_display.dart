// lib/widgets/home_screen_widgets/ai_spark_themes/thinking_cap_theme_display.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bharat_ace/core/models/daily_feed_item.dart';

class ThinkingCapThemeDisplay extends StatefulWidget {
  final DailyFeedItem dailyFeedItem;
  final VoidCallback onTap;

  const ThinkingCapThemeDisplay({
    Key? key,
    required this.dailyFeedItem,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ThinkingCapThemeDisplay> createState() =>
      _ThinkingCapThemeDisplayState();
}

class _ThinkingCapThemeDisplayState extends State<ThinkingCapThemeDisplay>
    with TickerProviderStateMixin {
  // Use TickerProviderStateMixin for multiple controllers
  late AnimationController _sparkleController;
  late AnimationController _glowController;
  late List<_Sparkle> _sparkles;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true); // Pulsating glow

    _sparkles = List.generate(15, (index) => _Sparkle.random());
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _glowController.dispose();
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
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade700, Colors.indigo.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.15),
                blurRadius: 10,
              )
            ]),
        child: Column(
          children: [
            SizedBox(
              height: visualHeight,
              width: double.infinity,
              child: AnimatedBuilder(
                animation:
                    Listenable.merge([_sparkleController, _glowController]),
                builder: (context, child) {
                  // Update sparkle positions/opacity based on _sparkleController.value
                  for (var sparkle in _sparkles) {
                    sparkle.update(_sparkleController.value);
                  }
                  return CustomPaint(
                    painter: ThinkingCapPainter(
                      glowValue: _glowController.value,
                      sparkles: _sparkles,
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
                          color: Colors.yellow.shade200,
                          fontWeight: FontWeight.bold),
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
                          ?.copyWith(color: Colors.blueGrey.shade200),
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
                  color: Colors.yellow.shade400.withOpacity(0.7),
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

class _Sparkle {
  Offset
      position; // Relative to the cap area (e.g., 0-1 for width, negative for above)
  double initialY;
  double radius;
  double opacity;
  Color color;
  double speed;

  _Sparkle(
      {required this.position,
      required this.radius,
      required this.opacity,
      required this.color,
      required this.speed,
      required this.initialY});

  factory _Sparkle.random() {
    final rand = Random();
    return _Sparkle(
      // Position around and above where the cap's lightbulb would be
      position: Offset(
          rand.nextDouble() * 0.6 - 0.3, // -0.3 to 0.3 horizontally
          rand.nextDouble() * -0.8 -
              0.1), // -0.1 to -0.9 vertically (above cap)
      initialY: rand.nextDouble() * -0.8 - 0.1,
      radius: rand.nextDouble() * 2.0 + 1.0,
      opacity: rand.nextDouble() * 0.5 + 0.3,
      color: [
        Colors.yellow.shade300,
        Colors.amber.shade200,
        Colors.white
      ][rand.nextInt(3)],
      speed: rand.nextDouble() * 0.3 + 0.1, // Slower rise
    );
  }

  void update(double animationValue) {
    // Rise and fade
    position = Offset(position.dx, initialY - (animationValue * speed));
    opacity =
        (1.0 - (animationValue * 1.2)).clamp(0.0, 1.0); // Fade out as it rises

    // Reset if it goes too far or fades out
    if (position.dy < -1.0 || opacity == 0.0) {
      final newSparkle = _Sparkle.random();
      position = newSparkle.position;
      initialY = newSparkle.initialY;
      radius = newSparkle.radius;
      opacity = newSparkle.opacity;
      color = newSparkle.color;
      speed = newSparkle.speed;
    }
  }
}

class ThinkingCapPainter extends CustomPainter {
  final double glowValue; // 0.0 to 1.0
  final List<_Sparkle> sparkles;

  ThinkingCapPainter({required this.glowValue, required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    final center =
        Offset(size.width / 2, size.height * 0.75); // Cap lower on screen
    final capBaseWidth = size.width * 0.35;
    final capHeight = size.height * 0.3;
    final bulbRadius = capBaseWidth * 0.3;

    // Cap Colors
    final capPaint = Paint()..color = Colors.blueGrey.shade500;
    final bulbGlassPaint = Paint()
      ..color = Colors.yellow.shade100.withOpacity(0.3 + glowValue * 0.3);
    final bulbFilamentPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow.shade500,
          Colors.amber.shade700.withOpacity(0.8 * glowValue),
        ],
        stops: [0.3, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(center.dx, center.dy - capHeight * 0.65),
          radius: bulbRadius * (0.5 + glowValue * 0.3))); // Pulsating filament

    // Draw Cap (simple mortarboard style)
    final capPath = Path();
    capPath.moveTo(center.dx - capBaseWidth / 2, center.dy); // Bottom left
    capPath.lineTo(center.dx + capBaseWidth / 2, center.dy); // Bottom right
    capPath.lineTo(center.dx + capBaseWidth / 2 * 0.8,
        center.dy - capHeight * 0.4); // Upper right
    capPath.lineTo(center.dx - capBaseWidth / 2 * 0.8,
        center.dy - capHeight * 0.4); // Upper left
    capPath.close();
    canvas.drawPath(capPath, capPaint);

    // Draw Lightbulb Base
    final bulbBaseRect = Rect.fromCenter(
        center: Offset(center.dx, center.dy - capHeight * 0.45),
        width: bulbRadius * 0.8,
        height: bulbRadius * 0.5);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bulbBaseRect, const Radius.circular(3)),
        Paint()..color = Colors.grey.shade700);

    // Draw Lightbulb Glass
    final bulbCenter =
        Offset(center.dx, center.dy - capHeight * 0.65 - bulbRadius * 0.3);
    canvas.drawCircle(bulbCenter, bulbRadius, bulbGlassPaint);
    // Draw Filament
    canvas.drawCircle(bulbCenter, bulbRadius * 0.6, bulbFilamentPaint);

    // Draw Sparkles (positioned relative to bulb)
    final sparkleOrigin = bulbCenter - Offset(0, bulbRadius); // Top of the bulb
    for (var sparkle in sparkles) {
      final paint = Paint()..color = sparkle.color.withOpacity(sparkle.opacity);
      // Sparkle position is normalized around (0,0) where 0 is bulb top, -1 is one bulb height above
      final sparklePos = Offset(
          sparkleOrigin.dx + sparkle.position.dx * (bulbRadius * 3),
          sparkleOrigin.dy +
              sparkle.position.dy * (bulbRadius * 2) // Y spread more
          );
      canvas.drawCircle(sparklePos, sparkle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ThinkingCapPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue ||
        sparkles
            .isNotEmpty; // Repaint if sparkles list changes (it will) or glow changes
  }
}
