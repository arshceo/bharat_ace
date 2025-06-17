import 'dart:math';
import 'package:flutter/material.dart';

class CosmicBackground extends StatefulWidget {
  const CosmicBackground({super.key});

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _nebulaController;
  List<_Star> _stars = [];
  final int _numStars = 50;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(seconds: 100), // Slow continuous movement
      vsync: this,
    )..repeat();

    _nebulaController = AnimationController(
      duration: const Duration(seconds: 20), // Pulsing effect
      vsync: this,
    )..repeat(reverse: true);

    // Initialize stars after the first frame to get screen size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _generateStars(MediaQuery.of(context).size);
        setState(() {}); // Trigger a rebuild to draw stars
      }
    });
  }

  void _generateStars(Size screenSize) {
    _stars = List.generate(_numStars, (index) {
      return _Star(
        position: Offset(
          _random.nextDouble() * screenSize.width,
          _random.nextDouble() * screenSize.height,
        ),
        radius: _random.nextDouble() * 1.5 + 0.5, // Varying sizes
        opacity: _random.nextDouble() * 0.5 + 0.5, // Varying brightness
        parallaxFactor: _random.nextDouble() * 0.3 + 0.1, // For parallax
      );
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    _nebulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_starController, _nebulaController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _CosmicPainter(
            starAnimationValue: _starController.value,
            nebulaAnimationValue: _nebulaController.value,
            stars: _stars,
            random: _random,
            starControllerStatus:
                _starController.status, // <<<< PASS THE STATUS HERE
          ),
          child: Container(), // Takes full space
        );
      },
    );
  }
}

class _Star {
  Offset position;
  double radius;
  double opacity;
  double parallaxFactor; // Slower stars appear further away

  _Star({
    required this.position,
    required this.radius,
    required this.opacity,
    required this.parallaxFactor,
  });
}

final Paint _starPaint = Paint()..color = Colors.white; // Reusable star paint
final Paint _shootingStarPaint = Paint()
  ..color = Colors.yellowAccent
  ..strokeWidth = 2.0
  ..style = PaintingStyle.stroke;

class _CosmicPainter extends CustomPainter {
  final double starAnimationValue;
  final double nebulaAnimationValue;
  final List<_Star> stars;
  final Random random;
  final AnimationStatus starControllerStatus;

  final Paint _backgroundPaint = Paint(); // Initialize here or in constructor
  final Paint _nebulaPaint1 = Paint();
  final Paint _nebulaPaint2 = Paint();
  final Paint _starPaint = Paint(); // If color changes per star, this is fine
  final Paint _localShootingStarPaint =
      Paint(); // If it changes per instance of shooting star

  _CosmicPainter({
    required this.starAnimationValue,
    required this.nebulaAnimationValue,
    required this.stars,
    required this.random,
    required this.starControllerStatus, // <<<< ADD THIS
  }) {
    // Note: Shaders depending on 'size' MUST be created/updated in the paint method
    // or if the size changes. For now, we'll update them in paint().
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background Gradient - Create shader directly here
    _backgroundPaint.shader = LinearGradient(
      // ALWAYS RECREATE/UPDATE SHADER
      colors: [Colors.indigo[900]!, Colors.purple[800]!, Colors.black],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), _backgroundPaint);

    // Update and Draw Nebulae
    _nebulaPaint1
      ..shader = RadialGradient(
        colors: [
          Colors.purpleAccent.withOpacity(0.25 * nebulaAnimationValue),
          Colors.blueAccent.withOpacity(0.08 * nebulaAnimationValue),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.25, size.height * 0.3),
          radius: size.width * 0.4))
      ..blendMode = BlendMode.srcOver;

    _nebulaPaint2
      ..shader = RadialGradient(
        colors: [
          Colors.purpleAccent.withOpacity(0.25 * nebulaAnimationValue),
          Colors.blueAccent.withOpacity(0.08 * nebulaAnimationValue),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.75, size.height * 0.7),
          radius: size.width * 0.3))
      ..blendMode = BlendMode.srcOver;

    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.3),
        size.width * 0.4, _nebulaPaint1);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.7),
        size.width * 0.3, _nebulaPaint2);

    // Draw Stars
    for (var star in stars) {
      // Calculate parallax movement for each star
      double dx =
          star.position.dx + (starAnimationValue * 20 * star.parallaxFactor);
      double dy =
          star.position.dy + (starAnimationValue * 10 * star.parallaxFactor);

      // Twinkle effect: vary opacity with a sine wave based on animation and star index
      double twinkle =
          0.5 + 0.5 * sin(starAnimationValue * 2 * pi + stars.indexOf(star));
      double currentOpacity = (star.opacity * twinkle).clamp(0.1, 1.0);

      _starPaint.color = Colors.white.withOpacity(currentOpacity);
      canvas.drawCircle(Offset(dx, dy), star.radius, _starPaint);
    }

    // Optional: Shooting Star
    if (random.nextInt(120) == 0 &&
        starControllerStatus == AnimationStatus.forward) {
      _localShootingStarPaint // Use the member paint if properties are consistent
        ..color = Colors.yellowAccent.withOpacity(0.7)
        ..strokeWidth = random.nextDouble() * 1.5 + 1.0
        ..style = PaintingStyle.stroke;
      double startX = size.width * random.nextDouble();
      double startY = size.height * random.nextDouble() * 0.3;
      double length = size.width * (random.nextDouble() * 0.1 + 0.05);
      double angle = (random.nextDouble() - 0.5) * (pi / 4) + pi * 1.25;

      canvas.drawLine(
          Offset(startX, startY),
          Offset(startX + cos(angle) * length, startY + sin(angle) * length),
          _localShootingStarPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter oldDelegate) {
    // Only repaint if values that affect drawing have changed.
    // If size changes, Flutter handles that.
    return oldDelegate.starAnimationValue != starAnimationValue ||
        oldDelegate.nebulaAnimationValue != nebulaAnimationValue ||
        oldDelegate.starControllerStatus != starControllerStatus; // Added this
    // If 'stars' list content could change, you might need a deeper comparison or a version number.
  }
}
