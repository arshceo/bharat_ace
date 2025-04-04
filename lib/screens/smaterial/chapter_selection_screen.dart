import 'package:bharat_ace/core/models/chapter_model.dart';
import 'package:bharat_ace/loader/json_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'topic_selection_screen.dart';

class ChapterSelectionScreen extends ConsumerStatefulWidget {
  final String className;
  final String subject;

  const ChapterSelectionScreen(
      {super.key, required this.className, required this.subject});

  @override
  ConsumerState<ChapterSelectionScreen> createState() =>
      _ChapterSelectionScreenState();
}

class _ChapterSelectionScreenState
    extends ConsumerState<ChapterSelectionScreen> {
  late Future<List<Chapter>> _chaptersFuture;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = JSONLoader.loadChapters(widget.className, widget.subject);
  }

  @override
  Widget build(BuildContext context) {
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
            Expanded(child: _buildChapterList()),
            // _buildFooter(),
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
            "🚀 Unlock Your Potential!",
            style: GoogleFonts.lato(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        FadeInDown(
          delay: const Duration(milliseconds: 300),
          child: Text(
            "📖 Each Chapter is a Step Closer to Mastery!",
            style: GoogleFonts.lato(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.white70),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildChapterList() {
    return FutureBuilder<List<Chapter>>(
      future: _chaptersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const Center(
            child: Text("No chapters available",
                style: TextStyle(color: Colors.white)),
          );
        }

        List<Chapter> chapters = snapshot.data!;

        return ListView.builder(
          physics: BouncingScrollPhysics(),
          // ✅ FIXED: ListView directly returned
          padding: const EdgeInsets.all(8),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];

            return FadeInLeft(
              child: GestureDetector(
                onTap: chapter.unlocked
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TopicSelectionScreen(chapter: chapter.title),
                          ),
                        );
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          color: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: Icon(Icons.menu_book,
                                color: chapter.unlocked
                                    ? Colors.white
                                    : Colors.grey),
                            title: Text(
                              "${chapter.title} (${chapter.progress}%)",
                              style: TextStyle(
                                  color: chapter.unlocked
                                      ? Colors.white
                                      : Colors.grey),
                            ),
                            subtitle: chapter.unlocked
                                ? LinearProgressIndicator(
                                    value: chapter.progress / 100,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation(
                                        Colors.green),
                                  )
                                : null,
                            trailing: chapter.unlocked
                                ? const Icon(Icons.arrow_forward_ios,
                                    color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                      if (!chapter.unlocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock,
                                    color: Colors.white, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  "Pass the quiz to unlock",
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 10, color: Colors.white)
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
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
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purpleAccent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      child: Text(title, style: GoogleFonts.lato(color: Colors.white)),
    );
  }
}
