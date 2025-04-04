import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

import '../kidlearning/kids_learning.dart';

// State management for XP points
final xpProvider = StateProvider<int>((ref) => 0);

class KidsHomeScreen extends ConsumerStatefulWidget {
  const KidsHomeScreen({super.key});

  @override
  _KidsHomeScreenState createState() => _KidsHomeScreenState();
}

class _KidsHomeScreenState extends ConsumerState<KidsHomeScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _controller;
  late Animation<double> _teddyAnimation;

  @override
  void initState() {
    super.initState();
    _playWelcomeSound();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);
    _teddyAnimation = Tween<double>(begin: -50, end: 50).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playWelcomeSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/hello_kids.mp3'));
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final xp = ref.watch(xpProvider);

    return Scaffold(
      backgroundColor: Color(0xFF010124),
      body: Stack(
        children: [
          OptimizedAnimatedBackground(),
          Positioned(
            top: 40,
            left: 20,
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.yellow, size: 40),
                SizedBox(width: 10),
                Text(
                  "XP: $xp",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                bottom: 50,
                left: MediaQuery.of(context).size.width / 2 +
                    _teddyAnimation.value,
                child: Image.asset("assets/avatars/teddy.png",
                    width: 120, height: 120),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLearningButton("📚 ABCs", Colors.redAccent,
                    navigate: true),
                _buildLearningButton("🔢 Numbers", Colors.blueAccent,
                    navigate: true),
                _buildLearningButton("🎨 Drawing", Colors.greenAccent,
                    navigate: true),
                _buildLearningButton("🎶 Rhymes", Colors.orangeAccent,
                    navigate: true),
                _buildLearningButton("🐶 Animals", Colors.purpleAccent,
                    navigate: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningButton(String text, Color color,
      {bool navigate = false}) {
    return GestureDetector(
      onTap: () {
        if (navigate) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KidsLearning()),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        width: 250,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 5, offset: Offset(2, 4))
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class OptimizedAnimatedBackground extends StatefulWidget {
  const OptimizedAnimatedBackground({super.key});

  @override
  _OptimizedAnimatedBackgroundState createState() =>
      _OptimizedAnimatedBackgroundState();
}

class _OptimizedAnimatedBackgroundState
    extends State<OptimizedAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Bubble> bubbles = List.generate(12, (_) => Bubble());

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 15))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade400],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: CustomPaint(
            painter: BubblePainter(_controller.value, bubbles),
            child: Container(),
          ),
        );
      },
    );
  }
}

class BubblePainter extends CustomPainter {
  final double animationValue;
  final List<Bubble> bubbles;

  BubblePainter(this.animationValue, this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    for (Bubble bubble in bubbles) {
      final double yPos =
          (size.height - (animationValue * size.height + bubble.startOffset)) %
              size.height;
      paint.color = bubble.color.withOpacity(0.5);
      canvas.drawCircle(Offset(bubble.xPosition, yPos), bubble.size, paint);
    }
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) => true;
}

class Bubble {
  double xPosition = Random().nextDouble() * 400;
  double size = Random().nextDouble() * 35 + 8;
  double startOffset = Random().nextDouble() * 600;
  Color color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
}
