import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedCharacterWidget extends StatefulWidget {
  final String giftName;
  final int deliveryDays;

  const AnimatedCharacterWidget({
    super.key,
    required this.giftName,
    required this.deliveryDays,
  });

  @override
  State<AnimatedCharacterWidget> createState() =>
      _AnimatedCharacterWidgetState();
}

class _AnimatedCharacterWidgetState extends State<AnimatedCharacterWidget>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _idleController; // For subtle movements
  late AnimationController _talkController; // For "talking" animation

  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  String _displayedMessage = "";
  int _currentMessageCharIndex = 0;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _idleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _talkController = AnimationController(
      duration: const Duration(milliseconds: 150), // Fast for mouth movement
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _entryController.forward().whenComplete(() {
      _startTypingMessage();
    });
  }

  void _startTypingMessage() {
    final fullMessage =
        "WOWZERS! You've unlocked the ${widget.giftName}! Our star-couriers estimate it'll reach your Earth-base in about ${widget.deliveryDays} cosmic rotations (days)!";
    _currentMessageCharIndex = 0;
    _displayedMessage = "";

    Future.doWhile(() async {
      if (_currentMessageCharIndex < fullMessage.length) {
        await Future.delayed(const Duration(milliseconds: 40)); // Typing speed
        if (!mounted) return false; // Stop if widget is disposed

        setState(() {
          _displayedMessage += fullMessage[_currentMessageCharIndex];
          if (fullMessage[_currentMessageCharIndex] != ' ') {
            // Animate mouth on non-space chars
            _talkController.forward().then((_) {
              if (mounted) _talkController.reverse();
            });
          }
        });
        _currentMessageCharIndex++;
        return true; // Continue
      }
      return false; // Stop
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _idleController.dispose();
    _talkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge(
              [_entryController, _idleController, _talkController]),
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SizedBox(
                  width: 150,
                  height: 180, // Increased height for body + text
                  child: CustomPaint(
                    painter: _CharacterPainter(
                      idleAnimValue: _idleController.value,
                      talkAnimValue: _talkController.value,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.7)),
          ),
          child: Text(
            _displayedMessage,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.white, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final double idleAnimValue; // 0.0 to 1.0 (for bobbing, etc.)
  final double talkAnimValue; // 0.0 to 1.0 (for mouth movement)
  final Paint _bodyPaint = Paint()..style = PaintingStyle.fill;
  final Paint _eyePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;
  final Paint _pupilPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black;
  final Paint _beakPaint = Paint()..style = PaintingStyle.fill;
  final Paint _wingPaint = Paint()..style = PaintingStyle.fill;
  final Path _beakPath = Path(); // Reusable path object
  _CharacterPainter({required this.idleAnimValue, required this.talkAnimValue});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bodyYOffset = sin(idleAnimValue * 2 * pi) * 5;
    final bodyRadius = size.width * 0.4;

    _bodyPaint.color = Colors.deepPurple[300]!;
    canvas.drawCircle(
        Offset(center.dx, center.dy + bodyYOffset), bodyRadius, _bodyPaint);

    final eyeRadius = bodyRadius * 0.3;
    canvas.drawCircle(
        Offset(center.dx - bodyRadius * 0.35,
            center.dy - bodyRadius * 0.1 + bodyYOffset),
        eyeRadius,
        _eyePaint);
    canvas.drawCircle(
        Offset(center.dx + bodyRadius * 0.35,
            center.dy - bodyRadius * 0.1 + bodyYOffset),
        eyeRadius,
        _eyePaint);

    final pupilRadius = eyeRadius * 0.5;
    canvas.drawCircle(
        Offset(center.dx - bodyRadius * 0.35,
            center.dy - bodyRadius * 0.1 + bodyYOffset),
        pupilRadius,
        _pupilPaint);
    canvas.drawCircle(
        Offset(center.dx + bodyRadius * 0.35,
            center.dy - bodyRadius * 0.1 + bodyYOffset),
        pupilRadius,
        _pupilPaint);

    _beakPaint.color = Colors.orangeAccent;
    _beakPath.reset(); // Reset path before redefining
    final beakTopY = center.dy + bodyRadius * 0.25 + bodyYOffset;
    final beakWidth = bodyRadius * 0.3;
    final mouthOpenFactor = talkAnimValue * (bodyRadius * 0.15);
    _beakPath.moveTo(center.dx - beakWidth / 2, beakTopY);
    _beakPath.lineTo(center.dx + beakWidth / 2, beakTopY);
    _beakPath.lineTo(center.dx, beakTopY + bodyRadius * 0.2 + mouthOpenFactor);
    _beakPath.close();
    canvas.drawPath(_beakPath, _beakPaint);

    _wingPaint.color = Colors.deepPurple[400]!;
    final wingWidth = bodyRadius * 0.3;
    final wingHeight = bodyRadius * 0.6;
    canvas.drawOval(
        Rect.fromLTWH(center.dx - bodyRadius * 0.8, center.dy + bodyYOffset,
            wingWidth, wingHeight),
        _wingPaint);
    canvas.drawOval(
        Rect.fromLTWH(center.dx + bodyRadius * 0.8 - wingWidth,
            center.dy + bodyYOffset, wingWidth, wingHeight),
        _wingPaint);
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) {
    return oldDelegate.idleAnimValue != idleAnimValue ||
        oldDelegate.talkAnimValue != talkAnimValue;
  }
}
