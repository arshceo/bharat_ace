import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopicContentScreen extends StatefulWidget {
  final String chapter;
  final String topic;
  final Map<String, dynamic> contentData;

  const TopicContentScreen({
    Key? key,
    required this.chapter,
    required this.topic,
    required this.contentData,
  }) : super(key: key);

  @override
  _TopicContentScreenState createState() => _TopicContentScreenState();
}

class _TopicContentScreenState extends State<TopicContentScreen> {
  @override
  Widget build(BuildContext context) {
    // Extract the sections based on the topic
    var sections = widget.contentData['sections']
        .where((section) => section['title'] == widget.topic)
        .toList();

    if (sections.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.topic, style: GoogleFonts.lato()),
          backgroundColor: Color(0xFF240E77),
        ),
        body: Center(child: Text('No content available for this topic')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic, style: GoogleFonts.lato()),
        backgroundColor: Color(0xFF240E77),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: sections.length,
          itemBuilder: (context, index) {
            var section = sections[index];
            return SectionWidget(section: section);
          },
        ),
      ),
    );
  }
}

class SectionWidget extends StatelessWidget {
  final Map<String, dynamic> section;

  const SectionWidget({Key? key, required this.section}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            section['title'],
            style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Section Content
          ...List.generate(
            section['content'].length,
            (index) => Text(
              section['content'][index],
              style: GoogleFonts.lato(fontSize: 16),
            ),
          ),
          if (section['example'] != null) ...[
            const SizedBox(height: 12),
            Text(
              "Example: ${section['example']}",
              style:
                  GoogleFonts.lato(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
          if (section['mnemonic'] != null) ...[
            const SizedBox(height: 12),
            Text(
              "Mnemonic: ${section['mnemonic']}",
              style:
                  GoogleFonts.lato(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
          // Subsections (if any)
          if (section['subsections'] != null) ...[
            const SizedBox(height: 12),
            ...List.generate(
              section['subsections'].length,
              (subIndex) {
                var subsection = section['subsections'][subIndex];
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subsection['title'],
                        style: GoogleFonts.lato(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        subsection['content'].length,
                        (contentIndex) => Text(
                          subsection['content'][contentIndex],
                          style: GoogleFonts.lato(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
