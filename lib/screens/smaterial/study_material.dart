import 'package:bharat_ace/screens/smaterial/pdf_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class StudyMaterialsScreen extends ConsumerWidget {
  const StudyMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E0F47), Color(0xFF240E77)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildHeader(),
            _buildScrollableTabBar(context),
            Expanded(child: _buildMainContent()),
            _buildScrollableFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        FadeInDown(
          child: Text(
            "Study Smart, Not Hard! 🚀",
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search study materials...",
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableTabBar(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildTab("PDFs", context),
          _buildTab("AI Chatbot", context),
          _buildTab("Videos", context),
          _buildTab("Flashcards", context),
        ],
      ),
    );
  }

  Widget _buildTab(String title, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == "PDFs") {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PdfLearningScreen(
                      chapter: '',
                    )),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.lato(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionTitle("📌 Recommended Resources"),
          _buildStudyCard("Advanced AI Concepts", "PDF, Videos & Flashcards"),
          _buildSectionTitle("📂 My Study Materials"),
          _buildStudyCard("Deep Learning Basics", "Recently Accessed"),
          _buildSectionTitle("🔥 AI Flashcards & Quizzes"),
          _buildQuizSection(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStudyCard(String title, String subtitle) {
    return FadeInLeft(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: const Icon(Icons.book, color: Colors.white),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          subtitle:
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildQuizSection() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              "Take a quiz to unlock the next topic!",
              style: GoogleFonts.lato(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Start Quiz"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableFooter() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        children: [
          _buildFooterButton("💡 Need help?"),
          _buildFooterButton("📜 Summarize for me"),
          _buildFooterButton("🏆 Leaderboard"),
        ],
      ),
    );
  }

  Widget _buildFooterButton(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        onPressed: () {},
        child: Text(title, style: GoogleFonts.lato()),
      ),
    );
  }
}
