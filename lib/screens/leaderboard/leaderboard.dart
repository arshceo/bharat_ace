import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D0D3B), Color(0xFF3F0D7A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Trophies Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTrophy(Icons.emoji_events, Colors.grey, "2nd"),
                  const SizedBox(width: 20),
                  _buildTrophy(Icons.emoji_events, Colors.amber, "1st"),
                  const SizedBox(width: 20),
                  _buildTrophy(Icons.emoji_events, Colors.brown, "3rd"),
                ],
              ),
              const SizedBox(height: 20),
              // Streak Message
              BounceInDown(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.5, right: 4.0),
                  child: Text(
                    "Incredible! You maintained a 10-day streak last week. Keep dominating! 🚀",
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Leaderboard
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return _buildLeaderboardTile(index + 1,
                        "Student ${index + 1}", 1000 - (index * 100));
                  },
                ),
              ),
            ],
          ),
          // Sticky Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Level Up! 🚀 Keep pushing your limits!",
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      "Claim Rewards",
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophy(IconData icon, Color color, String rank) {
    return ElasticIn(
      child: Column(
        children: [
          Icon(icon, size: 50, color: color),
          Text(rank,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(int rank, String name, int score) {
    return FadeInLeft(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.purpleAccent, width: 2),
          borderRadius: BorderRadius.circular(15),
          color: Colors.white.withOpacity(0.05),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Text("#$rank",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber)),
            const SizedBox(width: 15),
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Text(name[0], style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Text("$score XP",
                style: const TextStyle(fontSize: 16, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
