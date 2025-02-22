import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

void main() {
  runApp(ProviderScope(child: KidsLearning()));
}

class KidsLearning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'ComicSans'),
      home: KidsLearningScreen(),
    );
  }
}

class KidsLearningScreen extends ConsumerStatefulWidget {
  @override
  _KidsLearningScreenState createState() => _KidsLearningScreenState();
}

class _KidsLearningScreenState extends ConsumerState<KidsLearningScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _controller;
  late Animation<double> _mascotAnimation;
  late AnimationController _bubbleController;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _playWelcomeSound();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);

    _mascotAnimation = Tween<double>(begin: -30, end: 30).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _bubbleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _waveAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _bubbleController.dispose();
    _waveController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playWelcomeSound() async {
    await _audioPlayer.play(AssetSource('audio/hello_kids.mp3'));
  }

  void _playSuccessSound() async {
    await _audioPlayer.play(AssetSource('audio/great_job.mp3'));
    _waveController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InteractiveAnimatedBackground(controller: _bubbleController),
          Positioned(
            top: 40,
            left: 20,
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.yellow, size: 40),
                SizedBox(width: 10),
                Text("XP: 100",
                    style: TextStyle(fontSize: 22, color: Colors.white)),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_controller, _waveController]),
            builder: (context, child) {
              return Positioned(
                bottom: 50,
                left: MediaQuery.of(context).size.width / 2 +
                    _mascotAnimation.value,
                child: Transform.rotate(
                  angle: _waveAnimation.value * pi / 180,
                  child: Image.asset("assets/avatars/teddy.png",
                      width: 120, height: 120),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLearningButton("🎤 Tap & Learn", Colors.redAccent),
                _buildLearningButton("🖐️ Drag & Drop", Colors.blueAccent),
                _buildLearningButton("✏️ Trace & Write", Colors.greenAccent),
                _buildLearningButton("🎙️ Speak & Learn", Colors.orangeAccent),
                _buildLearningButton("📖 Story Mode", Colors.purpleAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningButton(String text, Color color) {
    return GestureDetector(
      onTap: () => _playSuccessSound(),
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

class InteractiveAnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  InteractiveAnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
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
            painter: BubblePainter(controller.value),
            child: Container(),
          ),
        );
      },
    );
  }
}

class BubblePainter extends CustomPainter {
  final double animationValue;
  BubblePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    Random random = Random();

    for (int i = 0; i < 20; i++) {
      double x = random.nextDouble() * size.width;
      double y =
          (size.height - (animationValue * size.height + i * 50)) % size.height;
      double radius = random.nextDouble() * 20 + 10;
      paint.color = Colors.primaries[random.nextInt(Colors.primaries.length)]
          .withOpacity(0.5);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) => true;
}
