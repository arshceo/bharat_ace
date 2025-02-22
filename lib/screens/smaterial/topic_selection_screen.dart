import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'topic_content_screen.dart';

class TopicSelectionScreen extends ConsumerWidget {
  final String chapter;
  const TopicSelectionScreen({super.key, required this.chapter});

  // Load content from assets (JSON format)
  Future<Map<String, dynamic>> loadContent(String chapter) async {
    try {
      String jsonString = await rootBundle.loadString('');
      Map<String, dynamic> contentData = jsonDecode(jsonString);
      return contentData;
    } catch (e) {
      // print("Error loading content for chapter $chapter: $e");
      throw Exception("Failed to load content");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chapter: $chapter'),
        backgroundColor: Color(0xFF240E77),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadContent(chapter), // Load chapter content from assets
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading content'));
          }

          Map<String, dynamic> contentData = snapshot.data!;

          // Extract topics from the sections inside the contentData
          List<String> topics = contentData['sections']
              .map<String>((section) => section['title'] as String)
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(
                      "Select Topic",
                      style: GoogleFonts.lato(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    String topic = topics[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to topic content screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopicContentScreen(
                              chapter: chapter,
                              topic: topic,
                              contentData:
                                  contentData, // Pass the entire section data
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(topic),
                        subtitle: Text("Progress: 0%"), // Update progress later
                        leading: Icon(Icons.menu_book),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
