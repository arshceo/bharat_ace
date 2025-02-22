import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> tasks = [
    {"subject": "Math", "completed": true},
    {"subject": "Science", "completed": true},
    {"subject": "History", "completed": false},
    {"subject": "English", "completed": false},
    {"subject": "Computer", "completed": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Learning Path",
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B0032), Color(0xFF00000F)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopSection(),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: CustomPaint(
                      painter: SwirlyPathPainter(tasks),
                      child: Column(
                        children: tasks.asMap().entries.map((entry) {
                          int index = entry.key;
                          var task = entry.value;
                          return TaskNode(
                            subject: task["subject"],
                            completed: task["completed"],
                            index: index,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildFloatingNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _infoCard("XP", "2450", Icons.bolt, Colors.orange)),
          const SizedBox(width: 15),
          Expanded(
              child: _infoCard(
                  "Streak", "7 Days", Icons.local_fire_department, Colors.red)),
          const SizedBox(width: 15),
          Expanded(
              child: _infoCard(
                  "Achievements", "5", Icons.emoji_events, Colors.green)),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 5),
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          Text(title,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.green.shade700.withOpacity(0.9),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Icon(Icons.home, color: Colors.white, size: 30),
          Icon(Icons.school, color: Colors.white60, size: 30),
          Icon(Icons.emoji_events, color: Colors.white60, size: 30),
          Icon(Icons.person, color: Colors.white60, size: 30),
        ],
      ),
    );
  }
}

// 🎯 **Updated TaskNode: Now Follows the Path!**
class TaskNode extends StatelessWidget {
  final String subject;
  final bool completed;
  final int index;

  const TaskNode({
    required this.subject,
    required this.completed,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double offsetX = index % 2 == 0 ? -90 : 90;
    double leftPadding = offsetX > 0 ? offsetX : 0;
    double rightPadding = offsetX < 0 ? -offsetX : 0;

    return Padding(
      padding: EdgeInsets.only(
          top: 60, bottom: 60, left: leftPadding, right: rightPadding),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: completed ? Colors.green : Colors.grey.shade600,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: completed
                      ? Colors.greenAccent
                      : Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Icon(
            completed ? Icons.check : Icons.lock_outline,
            color: Colors.white,
            size: 40,
          ),
        ],
      ),
    );
  }
}

// 🎨 **Fixed Swirly Path Painter: Properly Connects Nodes**
class SwirlyPathPainter extends CustomPainter {
  final List<Map<String, dynamic>> tasks;
  SwirlyPathPainter(this.tasks);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white.withOpacity(0.5)
      ..strokeCap = StrokeCap.round;

    Path path = Path();
    double startX = size.width / 2;
    double startY = 80;
    double curveOffset = 90;

    for (int i = 0; i < tasks.length - 1; i++) {
      bool isCompleted = tasks[i]["completed"];
      paint.color = isCompleted ? Colors.greenAccent : Colors.white30;

      double endX = startX + (i % 2 == 0 ? curveOffset : -curveOffset);
      double endY = startY + 130;

      path.moveTo(startX, startY);
      path.quadraticBezierTo(startX, startY + 65, endX, endY);

      startX = endX;
      startY = endY;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
