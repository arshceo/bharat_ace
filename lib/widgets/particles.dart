// Particle Background Effect
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});

  @override
  _ParticleBackgroundState createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 10));
    _controller.play(); // Start particles effect automatically
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ConfettiWidget(
        confettiController: _controller,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: true, // Infinite effect
        colors: [Colors.white, Colors.pinkAccent, Colors.deepPurpleAccent],
        gravity: 0.05, // Slow falling effect
      ),
    );
  }
}
