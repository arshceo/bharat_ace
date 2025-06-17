// lib/widgets/home_screen_widgets/ai_spark_themes/book_magic_theme_display.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bharat_ace/core/models/daily_feed_item.dart'; // Assuming this is your model path

class BookMagicThemeDisplay extends StatefulWidget {
  final DailyFeedItem dailyFeedItem;
  final VoidCallback onTap;

  const BookMagicThemeDisplay({
    Key? key,
    required this.dailyFeedItem,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BookMagicThemeDisplay> createState() => _BookMagicThemeDisplayState();
}

class _BookMagicThemeDisplayState extends State<BookMagicThemeDisplay>
    with TickerProviderStateMixin {
  late AnimationController
      _butterflyController; // For overall butterfly movement and lifecycle
  late AnimationController _glowController;
  late List<_Butterfly> _butterflies;

  @override
  void initState() {
    super.initState();
    _butterflyController = AnimationController(
      duration: const Duration(seconds: 6), // Butterflies take longer to cycle
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _butterflies = List.generate(
        7,
        (index) =>
            _Butterfly.random(index / 7.0)); // Fewer, more detailed butterflies
  }

  @override
  void dispose() {
    _butterflyController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    const double visualHeight =
        180.0; // Slightly increased visual height for butterflies
    const double totalWidgetHeight = visualHeight + 100.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: totalWidgetHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors
                    .deepPurple.shade600, // Slightly lighter for more contrast
                Colors.indigo.shade700,
                Colors.purple.shade800
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(0.2), // Brighter shadow
                blurRadius: 15,
                spreadRadius: 2,
              )
            ]),
        child: Column(
          children: [
            SizedBox(
              height: visualHeight,
              width: double.infinity,
              child: AnimatedBuilder(
                animation:
                    Listenable.merge([_butterflyController, _glowController]),
                builder: (context, child) {
                  for (var butterfly in _butterflies) {
                    butterfly.update(_butterflyController.value);
                  }
                  return CustomPaint(
                    painter: BookMagicPainter(
                      glowValue: _glowController.value,
                      butterflies: _butterflies,
                      butterflyAnimationValue:
                          _butterflyController.value, // Pass for wing flapping
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
                          color: Colors.yellow.shade200, // Brighter title
                          fontWeight: FontWeight.bold,
                          shadows: [
                            const Shadow(blurRadius: 1, color: Colors.black26)
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
                          color: Colors.purple.shade100.withOpacity(0.85),
                          shadows: [
                            const Shadow(blurRadius: 1, color: Colors.black26)
                          ]),
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
                  color:
                      Colors.amber.shade200.withOpacity(0.8), // Brighter icon
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

class _Butterfly {
  Offset position; // Current position (normalized relative to book origin)
  double initialY;
  double initialX;
  double size; // Scale factor for the butterfly
  double opacity;
  Color color1; // For upper wings
  Color color2; // For lower wings or accents
  double flapSpeed;
  double flightPathAngle; // For slightly varied upward paths
  double swayFactor; // For horizontal swaying
  double rotation; // Slight body rotation

  // animationProgress is derived from the main controller in the update method
  // The `delayFactor` staggers the start of each butterfly's lifecycle
  double delayFactor;

  _Butterfly({
    required this.position,
    required this.initialY,
    required this.initialX,
    required this.size,
    required this.opacity,
    required this.color1,
    required this.color2,
    required this.flapSpeed,
    required this.flightPathAngle,
    required this.swayFactor,
    required this.rotation,
    required this.delayFactor,
  });

  factory _Butterfly.random(double delay) {
    final rand = Random();
    List<Color> wingColors1 = [
      Colors.pink.shade300,
      Colors.lightBlue.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.green.shade300,
    ];
    List<Color> wingColors2 = [
      Colors.pink.shade100,
      Colors.lightBlue.shade100,
      Colors.yellow.shade200,
      Colors.purple.shade100,
      Colors.lime.shade200,
    ];

    return _Butterfly(
      position: Offset(rand.nextDouble() * 0.6 - 0.3,
          0.05), // Start close to book center top
      initialX: rand.nextDouble() * 0.6 - 0.3,
      initialY: 0.05, // Start near the book's "surface"
      size: rand.nextDouble() * 0.03 +
          0.035, // Butterfly size relative to painter size
      opacity: 0.0, // Start invisible
      color1: wingColors1[rand.nextInt(wingColors1.length)],
      color2: wingColors2[rand.nextInt(wingColors2.length)],
      flapSpeed: rand.nextDouble() * 1.5 + 1.0, // Faster flapping
      flightPathAngle: (rand.nextDouble() - 0.5) *
          (pi / 9), // Slight angle (max 20 degrees L/R)
      swayFactor: (rand.nextDouble() - 0.5) * 0.3, // How much it sways
      rotation:
          (rand.nextDouble() - 0.5) * (pi / 12), // Slight initial body rotation
      delayFactor: delay,
    );
  }

  void update(double animationValue) {
    // Apply delay: animationProgress will be 0 until delay is passed
    double effectiveAnimationValue = (animationValue - delayFactor);
    if (effectiveAnimationValue < 0)
      effectiveAnimationValue += 1.0; // Wrap around for continuous loop

    // Lifecycle: fade in, fly up, fade out
    if (effectiveAnimationValue < 0.1) {
      // Fade in
      opacity = (effectiveAnimationValue / 0.1) * 0.9 +
          0.1; // Start with min opacity 0.1
    } else if (effectiveAnimationValue < 0.85) {
      // Visible flight
      opacity = 1.0;
    } else {
      // Fade out
      opacity = (1.0 - ((effectiveAnimationValue - 0.85) / 0.15)) * 0.9 + 0.1;
    }
    opacity = opacity.clamp(0.0, 1.0);

    // Flight path: upward with some sway
    double upwardMovement =
        effectiveAnimationValue * 1.2; // How far up it travels (normalized)
    double sway = sin(effectiveAnimationValue * pi * 3 + initialX * 10) *
        swayFactor *
        (0.2 + upwardMovement * 0.3); // Sway increases as it flies

    // Position relative to where butterflies emerge (book top center)
    // The Y is negative because we want them to fly upwards from the book.
    position = Offset(
        initialX + sway + sin(flightPathAngle) * upwardMovement * 0.5,
        initialY - cos(flightPathAngle) * upwardMovement);

    // Reset if completely faded or too far (though effectiveAnimationValue handles cycle)
    if (effectiveAnimationValue > 0.99 && opacity < 0.01) {
      final newButterfly =
          _Butterfly.random(delayFactor); // Keep same delay for this slot
      // Only copy properties that define its new random state
      this.position = newButterfly.position;
      this.initialX = newButterfly.initialX;
      this.initialY = newButterfly.initialY;
      this.size = newButterfly.size;
      this.color1 = newButterfly.color1;
      this.color2 = newButterfly.color2;
      this.flapSpeed = newButterfly.flapSpeed;
      this.flightPathAngle = newButterfly.flightPathAngle;
      this.swayFactor = newButterfly.swayFactor;
      this.rotation = newButterfly.rotation;
      // Opacity will be set by the lifecycle logic on next update
    }
  }
}

class BookMagicPainter extends CustomPainter {
  final double glowValue;
  final List<_Butterfly> butterflies;
  final double butterflyAnimationValue; // Overall animation for wing flapping

  BookMagicPainter(
      {required this.glowValue,
      required this.butterflies,
      required this.butterflyAnimationValue});

  void _drawButterfly(Canvas canvas, Size painterSize, _Butterfly butterfly) {
    if (butterfly.opacity <= 0.01) return; // Don't draw if invisible

    final Paint wingPaint1 = Paint()
      ..color = butterfly.color1.withOpacity(butterfly.opacity);
    final Paint wingPaint2 = Paint()
      ..color = butterfly.color2.withOpacity(butterfly.opacity * 0.8);
    final Paint bodyPaint = Paint()
      ..color = Colors.black54.withOpacity(butterfly.opacity);

    // Butterfly's actual size on canvas
    final double bSize = painterSize.width * butterfly.size;

    // Position on canvas (origin is top-left of CustomPaint)
    // butterfly.position.dx/dy are normalized relative to emergence point (book top center)
    // Emergence point: Offset(painterSize.width / 2, painterSize.height * 0.45)
    final Offset emergencePoint =
        Offset(painterSize.width / 2, painterSize.height * 0.45);
    final Offset canvasPos = Offset(
        emergencePoint.dx +
            butterfly.position.dx *
                (painterSize.width * 0.3), // Horizontal spread
        emergencePoint.dy +
            butterfly.position.dy *
                (painterSize.height * 0.5) // Vertical travel
        );

    canvas.save();
    canvas.translate(canvasPos.dx, canvasPos.dy);
    canvas.rotate(butterfly.rotation +
        sin(butterflyAnimationValue * pi * 4 + butterfly.initialX) *
            (pi / 18)); // Add slight rotation flutter

    // Wing flap animation: 0 (closed) to 1 (open) using a sine wave
    // The butterflyAnimationValue is the global one, butterfly.flapSpeed personalizes it.
    // Adding butterfly.initialX to sin creates phase difference for varied flapping.
    double flap = (sin(butterflyAnimationValue * 2 * pi * butterfly.flapSpeed +
                butterfly.initialX * 5) +
            1) /
        2; // 0 to 1
    flap = 0.2 + flap * 0.8; // Ensure wings don't fully close (0.2 to 1.0)

    // Body
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: bSize * 0.2, height: bSize * 0.8),
            Radius.circular(bSize * 0.1)),
        bodyPaint);

    // Wings
    // Path for a wing (e.g., upper left)
    Path createWingPath(bool isUpper, bool isLeft, double flapAmount) {
      final path = Path();
      double wingWidth = bSize * (isUpper ? 0.9 : 0.7);
      double wingHeight = bSize * (isUpper ? 0.8 : 0.6);
      double xSign = isLeft ? -1 : 1;

      // Base of wing (near body)
      path.moveTo(xSign * bSize * 0.05, isUpper ? -bSize * 0.1 : bSize * 0.15);

      // Outer curve (flapping part)
      // Control point's X is affected by flapAmount
      path.quadraticBezierTo(
          xSign * wingWidth * flapAmount,
          isUpper ? -wingHeight * 0.7 : wingHeight * 0.7, // CP1
          xSign * wingWidth * 0.8 * flapAmount,
          isUpper ? -wingHeight * 0.2 : wingHeight * 0.2); // Tip-ish

      // Inner curve (back to body)
      path.quadraticBezierTo(
          xSign * wingWidth * 0.3 * flapAmount,
          isUpper ? bSize * 0.05 : -bSize * 0.05, // CP2
          xSign * bSize * 0.05,
          isUpper ? -bSize * 0.1 : bSize * 0.15);

      path.close();
      return path;
    }

    // Draw 4 wings
    canvas.drawPath(createWingPath(true, true, flap), wingPaint1); // Upper Left
    canvas.drawPath(
        createWingPath(true, false, flap), wingPaint1); // Upper Right
    canvas.drawPath(createWingPath(false, true, flap * 0.9),
        wingPaint2); // Lower Left (slightly less flap)
    canvas.drawPath(
        createWingPath(false, false, flap * 0.9), wingPaint2); // Lower Right

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bookCenter = Offset(size.width / 2,
        size.height * 0.75); // Book a bit lower to give space for butterflies
    final bookWidth = size.width * 0.55; // Slightly larger book
    final bookHeight = bookWidth * 0.65;
    final pageThickness = bookHeight * 0.12;

    // Book Cover
    final coverPaint = Paint()..color = Colors.brown.shade800; // Darker cover
    final bookRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bookCenter, width: bookWidth, height: bookHeight),
      const Radius.circular(10), // More rounded
    );
    canvas.drawRRect(bookRect, coverPaint);

    // Pages - perspective illusion for an open book
    final pagePaint = Paint()..color = Colors.yellow.shade50; // Off-white pages
    Path leftPage = Path();
    leftPage.moveTo(bookCenter.dx - pageThickness * 0.3,
        bookCenter.dy - bookHeight / 2 + pageThickness * 0.2); // Top spine
    leftPage.lineTo(bookCenter.dx - bookWidth / 2 + pageThickness * 0.6,
        bookCenter.dy - bookHeight / 2 + pageThickness * 0.4); // Top outer left
    leftPage.lineTo(
        bookCenter.dx - bookWidth / 2 + pageThickness * 0.6,
        bookCenter.dy +
            bookHeight / 2 -
            pageThickness * 0.4); // Bottom outer left
    leftPage.lineTo(bookCenter.dx - pageThickness * 0.3,
        bookCenter.dy + bookHeight / 2 - pageThickness * 0.2); // Bottom spine
    leftPage.close();
    canvas.drawPath(leftPage, pagePaint);

    Path rightPage = Path();
    rightPage.moveTo(bookCenter.dx + pageThickness * 0.3,
        bookCenter.dy - bookHeight / 2 + pageThickness * 0.2); // Top spine
    rightPage.lineTo(
        bookCenter.dx + bookWidth / 2 - pageThickness * 0.6,
        bookCenter.dy -
            bookHeight / 2 +
            pageThickness * 0.4); // Top outer right
    rightPage.lineTo(
        bookCenter.dx + bookWidth / 2 - pageThickness * 0.6,
        bookCenter.dy +
            bookHeight / 2 -
            pageThickness * 0.4); // Bottom outer right
    rightPage.lineTo(bookCenter.dx + pageThickness * 0.3,
        bookCenter.dy + bookHeight / 2 - pageThickness * 0.2); // Bottom spine
    rightPage.close();
    canvas.drawPath(rightPage, pagePaint);

    // Spine detail
    final spinePaint = Paint()..color = Colors.brown.shade900;
    canvas.drawRect(
        Rect.fromLTWH(
            bookCenter.dx - pageThickness * 0.4,
            bookCenter.dy - bookHeight / 2 + pageThickness * 0.15,
            pageThickness * 0.8,
            bookHeight - pageThickness * 0.3),
        spinePaint);

    // Magic Glow from pages
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.amber.withOpacity(0.5 + glowValue * 0.3), // More intense glow
          Colors.yellow.withOpacity(0.3 + glowValue * 0.2),
          Colors.transparent
        ],
        stops: const [0.0, 0.4, 1.0], // Glow concentrated more
      ).createShader(Rect.fromCenter(
          center: Offset(bookCenter.dx,
              bookCenter.dy - bookHeight * 0.3), // Glow from book center
          width: bookWidth * 0.8, // Glow more contained to pages
          height: bookHeight * 0.5))
      ..maskFilter = MaskFilter.blur(
          BlurStyle.normal, 20 + glowValue * 15); // Stronger blur
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bookCenter.dx, bookCenter.dy - bookHeight * 0.3),
            width: bookWidth,
            height: bookHeight * 0.6),
        glowPaint);

    // Draw Butterflies
    for (var butterfly in butterflies) {
      _drawButterfly(canvas, size, butterfly);
    }
  }

  @override
  bool shouldRepaint(covariant BookMagicPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue ||
        oldDelegate.butterflyAnimationValue != butterflyAnimationValue ||
        butterflies.isNotEmpty; // Repaint if butterfly list exists
  }
}
