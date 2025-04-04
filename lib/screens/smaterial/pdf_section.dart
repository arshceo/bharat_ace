import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'chapter_selection_screen.dart'; // Import Chapter Selection Screen

class PdfLearningScreen extends ConsumerWidget {
  const PdfLearningScreen({super.key, required String chapter});

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
            Expanded(child: _buildSubjectSelection(context)), // Pass context
            _buildFooter(),
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
            "📚 Select Your Subject",
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSubjectSelection(BuildContext context) {
    List<String> subjects = ["Mathematics", "Physics", "Biology", "Chemistry"];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        return FadeInLeft(
          child: GestureDetector(
            onTap: () {
              // Navigate to ChapterSelectionScreen when a subject is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChapterSelectionScreen(
                    className: '8',
                    subject: 'math',
                  ),
                ),
              );
            },
            child: Card(
              color: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.white),
                title: Text(subjects[index],
                    style: const TextStyle(color: Colors.white)),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFooterButton("🔥 XP: 1200"),
          _buildFooterButton("🏆 Leaderboard"),
        ],
      ),
    );
  }

  Widget _buildFooterButton(String title) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(title, style: GoogleFonts.lato()),
    );
  }
}
