import 'package:flutter/material.dart';
// class DailyMissions extends StatelessWidget {
//   const DailyMissions({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: Colors.blueGrey[900],
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("🎯 Daily Missions",
//                 style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white)),
//             const SizedBox(height: 10),
//             _missionItem(
//                 "Complete Math Assignment", "Earn 50 XP", Colors.greenAccent),
//             _missionItem(
//                 "Revise Science Notes", "Earn 30 XP", Colors.blueAccent),
//             _missionItem(
//                 "Practice Coding Problems", "Earn 40 XP", Colors.orangeAccent),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _missionItem(String task, String reward, Color glowColor) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(Icons.bolt, color: glowColor),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(task,
//                 style: const TextStyle(fontSize: 16, color: Colors.white)),
//           ),
//           Text(reward,
//               style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.greenAccent)),
//         ],
//       ),
//     );
//   }
// }

class UpcomingEvents extends StatelessWidget {
  const UpcomingEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📅 Upcoming Events",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            _eventItem("Math Test", "Feb 25, 10:00 AM"),
            _eventItem("Science Exam", "March 5, 9:00 AM"),
            _eventItem("Coding Bootcamp", "March 10, 2:00 PM"),
          ],
        ),
      ),
    );
  }

  Widget _eventItem(String title, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
          Text(date,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent)),
        ],
      ),
    );
  }
}

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.teal[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🏆 Leaderboard",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            _leaderboardItem("Alice", "1200 XP"),
            _leaderboardItem("Bob", "1100 XP"),
            _leaderboardItem("Charlie", "1050 XP"),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardItem(String name, String xp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
          Text(xp,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent)),
        ],
      ),
    );
  }
}

class SmartTips extends StatefulWidget {
  const SmartTips({super.key});

  @override
  _SmartTipsState createState() => _SmartTipsState();
}

class _SmartTipsState extends State<SmartTips>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentTipIndex = 0;

  final List<String> tips = [
    "🔹 Study in short, focused sessions with breaks (Pomodoro Technique).",
    "🔹 Revise concepts using active recall & spaced repetition.",
    "🔹 Practice past papers to understand exam patterns.",
    "🔹 Stay hydrated & take short walks to refresh your brain.",
    "🔹 Teach a concept to someone else to reinforce your understanding.",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🤖 AI Smart Tips",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: PageView.builder(
                controller: _pageController,
                itemCount: tips.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentTipIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _currentTipIndex == index
                          ? Colors.blueAccent
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        tips[index],
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
