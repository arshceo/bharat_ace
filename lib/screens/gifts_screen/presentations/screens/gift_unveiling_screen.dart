import 'dart:math';

import 'package:bharat_ace/screens/gifts_screen/presentations/providers/rewards_providers.dart';
import 'package:bharat_ace/screens/gifts_screen/presentations/widgets/gift_unveiling/animated_character_widget.dart';
import 'package:bharat_ace/screens/gifts_screen/presentations/widgets/gift_unveiling/video_carousel_widget.dart';
import 'package:bharat_ace/screens/gifts_screen/presentations/widgets/rewards_gallery/cosmic_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GiftUnveilingScreen extends ConsumerStatefulWidget {
  // static const routeName = '/gift-unveiling'; // For named routes
  const GiftUnveilingScreen({super.key});

  @override
  ConsumerState<GiftUnveilingScreen> createState() =>
      _GiftUnveilingScreenState();
}

class _GiftUnveilingScreenState extends ConsumerState<GiftUnveilingScreen>
    with TickerProviderStateMixin {
  // late ConfettiController _confettiController;
  late AnimationController _customConfettiController;
  List<_ConfettiParticle> _confettiParticles = [];
  final Random _confettiRandom = Random();

  @override
  void initState() {
    super.initState();
    // _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _confettiController.play();
    // });
    // For custom confetti
    _customConfettiController = AnimationController(
      duration: const Duration(seconds: 3), // How long particles are active
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _confettiController.play();
      _launchCustomConfetti();
    });
  }

  void _launchCustomConfetti() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const int numberOfParticles = 30;

    _confettiParticles = List.generate(numberOfParticles, (index) {
      return _ConfettiParticle(
        initialPosition: Offset(
            screenWidth / 2, screenHeight * 0.2), // Blast from top-center
        initialVelocity: Offset(
          (_confettiRandom.nextDouble() - 0.5) * 500, // Horizontal spread
          (_confettiRandom.nextDouble() - 0.8) *
              600, // Mostly upwards initially
        ),
        color: Colors
            .primaries[_confettiRandom.nextInt(Colors.primaries.length)]
            .withOpacity(0.8 + _confettiRandom.nextDouble() * 0.2),
        size: _confettiRandom.nextDouble() * 8 + 4, // Size 4 to 12
        rotationSpeed:
            (_confettiRandom.nextDouble() - 0.5) * 2 * pi, // Radians per second
        shape: _confettiRandom.nextInt(3), // 0: rect, 1: circle, 2: triangle
        randomInstance: _confettiRandom, // Pass the random instance
      );
    });
    _customConfettiController.forward(from: 0.0);
  }

  @override
  void dispose() {
    // _confettiController.dispose();
    _customConfettiController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gift = ref.watch(selectedGiftForUnveilingProvider);
    final theme = Theme.of(context);

    if (gift == null) {
      // Should not happen if navigation is correct, but good to handle
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("No gift selected!")),
      );
    }

    // Simulate delivery days
    final deliveryDays = (gift.xpRequired / 500).ceil() + 3;

    return Scaffold(
      extendBodyBehindAppBar: true, // Make appbar transparent over background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          const CosmicBackground(),
          AnimatedBuilder(
              // For Custom Confetti
              animation: _customConfettiController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _confettiParticles,
                    animationValue: _customConfettiController.value, // 0 to 1
                    random: _confettiRandom,
                  ),
                  child:
                      const SizedBox.expand(), // Make painter cover the screen
                );
              }),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "CONGRATULATIONS!",
                    style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                        shadows: [
                          const Shadow(blurRadius: 10, color: Colors.amber)
                        ]),
                    textAlign: TextAlign.center,
                  ), //.animate().fadeIn(delay: 300.ms, duration: 700.ms).scale(begin: const Offset(0.5,0.5)),
                  const SizedBox(height: 10),
                  Text(
                    "You've Unlocked the", // Add student name here
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    gift.name,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: Colors.lightBlueAccent, fontSize: 28),
                    textAlign: TextAlign.center,
                  ), //.animate().fadeIn(delay: 700.ms, duration: 700.ms).slideY(begin: 0.2),
                  const SizedBox(height: 30),
                  AnimatedCharacterWidget(
                      giftName: gift.name,
                      deliveryDays: deliveryDays), // Pass data
                  const SizedBox(height: 30),
                  // Placeholder for actual gift image/3D model
                  Icon(gift.icon, size: 100, color: Colors.amberAccent),
                  const SizedBox(height: 30),
                  Text(
                    "Explore Your New Tool!",
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  VideoCarouselWidget(
                      videoUrls: gift.videoUrls), // Pass video URLs
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Back to Your Constellation"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  Offset initialPosition;
  Offset initialVelocity; // Pixels per second
  Color color;
  double size;
  double rotationSpeed; // Radians per second
  double initialRotation;
  int shape; // 0: rect, 1: circle, 2: triangle
  final double aspectRatio; // For rectangles

  _ConfettiParticle({
    required this.initialPosition,
    required this.initialVelocity,
    required this.color,
    required this.size,
    required this.rotationSpeed,
    required this.shape,
    required Random randomInstance,
  })  : aspectRatio =
            (shape == 0) ? (randomInstance.nextDouble() * 0.5 + 0.5) : 1.0,
        initialRotation = randomInstance.nextDouble() * 2 * pi;

  Offset getPositionAt(double time) {
    // time is 0 to 1 (animation progress)
    const gravity = 600.0; // Pixels per second^2
    final actualTime = time * 3.0; // Assuming 3s confetti duration
    return Offset(
      initialPosition.dx + initialVelocity.dx * actualTime,
      initialPosition.dy +
          initialVelocity.dy * actualTime +
          0.5 * gravity * actualTime * actualTime,
    );
  }

  double getRotationAt(double time) {
    final actualTime = time * 3.0;
    return initialRotation + rotationSpeed * actualTime;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double animationValue;
  final Random random; // Keep random for shape variation if needed

  final Paint _particlePaint = Paint(); // Cache the paint

  _ConfettiPainter({
    required this.particles,
    required this.animationValue,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final currentPosition = particle.getPositionAt(animationValue);
      final currentRotation = particle.getRotationAt(animationValue);
      final particleSize = particle.size *
          (1.0 - animationValue * 0.35); // Particles shrink a bit faster

      if (particleSize <= 0.5) continue; // Stop drawing if very small

      _particlePaint.color = particle.color.withOpacity(
          (1.0 - animationValue * 0.8).clamp(0.0, 1.0)); // Fade out faster

      // OPTIMIZATION: If particles don't need individual rotation,
      // or if many share the same rotation, you could batch canvas operations.
      // For now, individual transforms are kept.
      canvas.save();
      canvas.translate(currentPosition.dx, currentPosition.dy);
      canvas.rotate(currentRotation);

      switch (particle.shape) {
        case 0: // Rectangle
          // If random height per frame is too costly, make it part of _ConfettiParticle or use fixed aspect ratio
          canvas.drawRect(
              Rect.fromCenter(
                  center: Offset.zero,
                  width: particleSize,
                  height: particleSize *
                      particle.aspectRatio), // Pre-calculate aspectRatio
              _particlePaint);
          break;
        case 1: // Circle
          canvas.drawCircle(Offset.zero, particleSize / 2, _particlePaint);
          break;
        case 2: // Triangle
          // Consider caching Path objects per shape type if they are complex
          // For a simple triangle, recreating is often fine.
          Path triPath = Path();
          triPath.moveTo(0, -particleSize / 2);
          triPath.lineTo(particleSize / 2, particleSize / 2);
          triPath.lineTo(-particleSize / 2, particleSize / 2);
          triPath.close();
          canvas.drawPath(triPath, _particlePaint);
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
