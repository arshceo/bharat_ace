import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class DailyMissions extends StatefulWidget {
  const DailyMissions({super.key});

  @override
  _DailyMissionsState createState() => _DailyMissionsState();
}

class _DailyMissionsState extends State<DailyMissions>
    with SingleTickerProviderStateMixin {
  int completedMissions = 1;
  late ConfettiController _confettiController;
  late AnimationController _orbitController;
  List<TrailParticle> _trailParticles = [];

  final List<Mission> missions = [
    Mission("📖 Math", "Earn 50 XP"),
    Mission("🧪 Science", "Earn 30 XP"),
    Mission("💻 Coding", "Earn 40 XP"),
    Mission("🌎 History", "Earn 20 XP"),
    Mission("🎨 Art", "Earn 25 XP"),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));

    _orbitController =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..addListener(() {
            _updateTrailParticles();
          })
          ..repeat();
  }

  void _updateTrailParticles() {
    setState(() {
      _trailParticles.addAll(
        List.generate(missions.length, (index) {
          double angle = (index * pi / 3) + _orbitController.value * 2 * pi;
          double radius = 90 + (index * 35);
          return TrailParticle(
            position: Offset(
              MediaQuery.of(context).size.width / 2 + cos(angle) * radius,
              220 + sin(angle) * radius,
            ),
            color: HSVColor.fromAHSV(
              1.0,
              (_orbitController.value * 360) % 360,
              1.0,
              1.0,
            ).toColor(),
            lifespan: 15, // Extended lifespan for a better effect
          );
        }),
      );

      // Remove faded particles
      _trailParticles = _trailParticles
          .map((p) {
            p.lifespan = max(0, p.lifespan - 1);
            return p;
          })
          .where((p) => p.lifespan > 0)
          .toList();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildMissionGalaxy(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          "🚀 Mission Control",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _scoreItem("🏆 XP", "${completedMissions * 50}"),
            _scoreItem("💰 Coins", "${completedMissions * 10}"),
          ],
        ),
      ],
    );
  }

  Widget _scoreItem(String icon, String value) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  Widget _buildMissionGalaxy() {
    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Neon Particle Trail
          Positioned.fill(
            child: CustomPaint(
              painter: NeonTrailPainter(_trailParticles),
            ),
          ),

          // Black hole at the center
          Positioned(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.6),
                    blurRadius: 25,
                    spreadRadius: 12,
                  )
                ],
              ),
            ),
          ),

          // Orbiting Missions
          ...List.generate(missions.length, (index) {
            return AnimatedBuilder(
              animation: _orbitController,
              builder: (context, child) {
                double angle =
                    (index * pi / 3) + _orbitController.value * 2 * pi;
                double radius = 90 + (index * 35);
                return Positioned(
                  left: MediaQuery.of(context).size.width / 2 +
                      cos(angle) * radius -
                      30,
                  top: 220 + sin(angle) * radius - 30,
                  child: _missionPlanet(index, missions[index]),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _missionPlanet(int index, Mission mission) {
    bool isCompleted = index < completedMissions;
    bool isCurrent = index == completedMissions;

    return GestureDetector(
      onTap: isCurrent
          ? () {
              Future.delayed(Duration(milliseconds: 200), () {
                if (mounted) {
                  setState(() {
                    completedMissions++;
                    _confettiController.play();
                  });
                }
              });
            }
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing Planet Effect
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.greenAccent
                  : isCurrent
                      ? Colors.orangeAccent
                      : Colors.blueGrey,
              boxShadow: [
                if (isCurrent)
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.8),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
              ],
            ),
          ),
          // Mission Icon
          Positioned(
            child: Text(
              mission.task.substring(0, 2),
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          // Confetti on Completion
          if (isCurrent)
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2,
              numberOfParticles: 12,
              gravity: 0.3,
            ),
        ],
      ),
    );
  }
}

class Mission {
  final String task;
  final String reward;

  Mission(this.task, this.reward);
}

/// Particle Trail System
class TrailParticle {
  Offset position;
  Color color;
  int lifespan;

  TrailParticle({
    required this.position,
    required this.color,
    required this.lifespan,
  });
}

/// Custom Painter for Neon RGB Orbit Trail
class NeonTrailPainter extends CustomPainter {
  final List<TrailParticle> particles;

  NeonTrailPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = particle.color.withOpacity(particle.lifespan / 15);
      canvas.drawCircle(particle.position, 6, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
