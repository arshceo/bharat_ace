import 'package:bharat_ace/widgets/home_screen_widgets/course_hub.dart';
import 'package:bharat_ace/widgets/home_screen_widgets/daily_missions.dart';
import 'package:bharat_ace/widgets/home_screen_widgets/home_screen_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/student_details_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(studentDetailsProvider.notifier).fetchStudentDetails());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(studentDetailsProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⚡ Animated Hacker-Style Header
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                "Welcome, ${student?.name ?? "Student"} 👋",
                style: GoogleFonts.orbitron(
                  textStyle: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "⚡ Keep up the streak & complete missions!",
              style: GoogleFonts.orbitron(
                textStyle: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),

            // 🎯 Daily Missions (Animated)
            DailyMissions(),
            const SizedBox(height: 20),

            // 📅 Upcoming Events
            const UpcomingEvents(),
            const SizedBox(height: 20),

            // 📚 Course Hub
            const CourseHub(),
            const SizedBox(height: 20),

            // 🏆 Leaderboard & XP System
            const Leaderboard(),
            const SizedBox(height: 20),

            // 🤖 AI-Powered Smart Tips
            const SmartTips(),
          ],
        ),
      ),
    );
  }
}
