// lib/widgets/home_screen_widgets/ai_spark_themes/rocket_theme_display.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bharat_ace/core/models/daily_feed_item.dart';

class RocketThemeDisplay extends StatefulWidget {
  final DailyFeedItem dailyFeedItem;
  final VoidCallback onTap;

  const RocketThemeDisplay({
    Key? key,
    required this.dailyFeedItem,
    required this.onTap,
  }) : super(key: key);

  @override
  State<RocketThemeDisplay> createState() => _RocketThemeDisplayState();
}

class _RocketThemeDisplayState extends State<RocketThemeDisplay>
    with TickerProviderStateMixin {
  late AnimationController _rocketController;
  late AnimationController _flameController;
  late List<_StarParticle> _stars;

  @override
  void initState() {
    super.initState();
    _rocketController = AnimationController(
      duration: const Duration(seconds: 3), // Rocket bobbing
      vsync: this,
    )..repeat(reverse: true);

    _flameController = AnimationController(
      duration: const Duration(milliseconds: 150), // Fast flame flicker
      vsync: this,
    )..repeat(reverse: true);

    _stars = List.generate(40, (index) => _StarParticle.random());
  }

  @override
  void dispose() {
    _rocketController.dispose();
    _flameController.dispose();
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
              colors: [
                const Color(0xFF141E30),
                const Color(0xFF243B55)
              ], // Deep space blue
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
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
                    Listenable.merge([_rocketController, _flameController]),
                builder: (context, child) {
                  for (var star in _stars) {
                    star.update(_rocketController.value); // Stars scroll slowly
                  }
                  return CustomPaint(
                    painter: RocketPainter(
                      rocketBobValue: _rocketController.value,
                      flameValue: _flameController.value,
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
                          color: Colors.lightBlue.shade100,
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
                  color: Colors.lightBlue.shade300.withOpacity(0.7),
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

class _StarParticle {
  Offset position; // Normalized 0-1
  double initialY;
  double radius;
  double opacity;
  double speed;

  _StarParticle(
      {required this.position,
      required this.radius,
      required this.opacity,
      required this.speed,
      required this.initialY});

  factory _StarParticle.random() {
    final rand = Random();
    return _StarParticle(
      position:
          Offset(rand.nextDouble(), rand.nextDouble()), // Random across screen
      initialY: rand.nextDouble(),
      radius: rand.nextDouble() * 1.2 + 0.3,
      opacity: rand.nextDouble() * 0.6 + 0.2,
      speed: rand.nextDouble() * 0.05 + 0.02, // Slow scroll speed
    );
  }

  void update(double animationValue) {
    // animationValue here is just a trigger, not directly used for pos
    position =
        Offset(position.dx, (initialY + speed) % 1.0); // Scroll down and wrap
    initialY = position.dy; // Update initialY for next frame's calculation
  }
}

class RocketPainter extends CustomPainter {
  final double rocketBobValue; // 0.0 to 1.0 (for up/down movement)
  final double flameValue; // 0.0 to 1.0 (for flame flicker)
  final List<_StarParticle> stars;

  RocketPainter(
      {required this.rocketBobValue,
      required this.flameValue,
      required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Stars
    final starPaint = Paint()..color = Colors.white;
    for (var star in stars) {
      starPaint.color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(
          Offset(star.position.dx * size.width, star.position.dy * size.height),
          star.radius,
          starPaint);
    }

    final rocketHeight = size.height * 0.6;
    final rocketWidth = rocketHeight * 0.35;
    final bobOffset =
        sin(rocketBobValue * pi) * (size.height * 0.03); // Smooth bobbing
    final center = Offset(
        size.width / 2, size.height / 2 - rocketHeight * 0.1 + bobOffset);

    // Rocket Body
    final bodyPaint = Paint()..color = Colors.blueGrey.shade300;
    final bodyPath = Path();
    bodyPath.moveTo(center.dx, center.dy - rocketHeight / 2); // Nose cone tip
    bodyPath.quadraticBezierTo(
        // Left side curve
        center.dx - rocketWidth * 0.8,
        center.dy - rocketHeight * 0.1,
        center.dx - rocketWidth / 2,
        center.dy + rocketHeight / 2 * 0.7); // Mid body left
    bodyPath.lineTo(center.dx - rocketWidth / 2,
        center.dy + rocketHeight / 2); // Bottom left base
    bodyPath.lineTo(center.dx + rocketWidth / 2,
        center.dy + rocketHeight / 2); // Bottom right base
    bodyPath.lineTo(center.dx + rocketWidth / 2,
        center.dy + rocketHeight / 2 * 0.7); // Mid body right
    bodyPath.quadraticBezierTo(
        // Right side curve
        center.dx + rocketWidth * 0.8,
        center.dy - rocketHeight * 0.1,
        center.dx,
        center.dy - rocketHeight / 2); // Nose cone tip
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Window
    final windowPaint = Paint()
      ..color = Colors.lightBlue.shade700.withOpacity(0.8);
    canvas.drawCircle(Offset(center.dx, center.dy - rocketHeight * 0.15),
        rocketWidth * 0.25, windowPaint);
    final windowHighlightPaint = Paint()
      ..color = Colors.lightBlue.shade200.withOpacity(0.5);
    canvas.drawCircle(
        Offset(center.dx - rocketWidth * 0.05,
            center.dy - rocketHeight * 0.15 - rocketWidth * 0.05),
        rocketWidth * 0.08,
        windowHighlightPaint);

    // Fins
    final finPaint = Paint()..color = Colors.red.shade700;
    final finPathLeft = Path();
    finPathLeft.moveTo(
        center.dx - rocketWidth / 2 * 0.8, center.dy + rocketHeight * 0.2);
    finPathLeft.lineTo(
        center.dx - rocketWidth * 1.1, center.dy + rocketHeight * 0.55);
    finPathLeft.lineTo(
        center.dx - rocketWidth / 2 * 0.9, center.dy + rocketHeight * 0.48);
    finPathLeft.close();
    canvas.drawPath(finPathLeft, finPaint);

    final finPathRight = Path();
    finPathRight.moveTo(
        center.dx + rocketWidth / 2 * 0.8, center.dy + rocketHeight * 0.2);
    finPathRight.lineTo(
        center.dx + rocketWidth * 1.1, center.dy + rocketHeight * 0.55);
    finPathRight.lineTo(
        center.dx + rocketWidth / 2 * 0.9, center.dy + rocketHeight * 0.48);
    finPathRight.close();
    canvas.drawPath(finPathRight, finPaint);

    // Flame
    final flameBaseY = center.dy + rocketHeight / 2;
    final flamePath = Path();
    final flameHeight = rocketHeight * 0.4 +
        (sin(flameValue * 2 * pi) * rocketHeight * 0.08); // Pulsating height
    final flameWidth = rocketWidth * 0.6 +
        (cos(flameValue * 2 * pi + pi / 3) *
            rocketWidth *
            0.1); // Pulsating width

    flamePath.moveTo(center.dx - flameWidth / 2 * 0.7, flameBaseY); // Left base
    flamePath.quadraticBezierTo(
        center.dx - flameWidth * 0.2,
        flameBaseY + flameHeight * 0.6, // Control for left curve
        center.dx,
        flameBaseY + flameHeight); // Tip
    flamePath.quadraticBezierTo(
        center.dx + flameWidth * 0.2,
        flameBaseY + flameHeight * 0.6, // Control for right curve
        center.dx + flameWidth / 2 * 0.7,
        flameBaseY); // Right base
    flamePath.close();

    final flamePaintOuter = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.5, 0.8),
        colors: [
          Colors.orange.shade600.withOpacity(0.8),
          Colors.red.shade800.withOpacity(0.6)
        ],
        radius: 0.8,
      ).createShader(Rect.fromLTWH(
          center.dx - flameWidth / 2, flameBaseY, flameWidth, flameHeight));
    canvas.drawPath(flamePath, flamePaintOuter);

    final flamePaintInner = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.5, 0.9),
        colors: [
          Colors.yellow.shade400.withOpacity(0.9),
          Colors.orange.shade400.withOpacity(0.7)
        ],
        radius: 0.6,
      ).createShader(Rect.fromLTWH(center.dx - flameWidth * 0.6 / 2, flameBaseY,
          flameWidth * 0.6, flameHeight * 0.8));
    canvas.drawPath(
        flamePath, flamePaintInner); // Draw on top, slightly smaller
  }

  @override
  bool shouldRepaint(covariant RocketPainter oldDelegate) {
    return oldDelegate.rocketBobValue != rocketBobValue ||
        oldDelegate.flameValue != flameValue ||
        stars.isNotEmpty;
  }
}
