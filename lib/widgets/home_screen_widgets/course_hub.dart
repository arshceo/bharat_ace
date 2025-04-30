import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseHub extends ConsumerWidget {
  const CourseHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentDetailsProvider);

    if (student == null) {
      return const Center(
        child:
            CircularProgressIndicator(), // Show loading until data is fetched
      );
    }

    final subjects = student.enrolledSubjects;
    final className = student.grade; // Ensure className is retrieved

    return Card(
      color: Colors.indigo[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: const Text("📚 Course Hub",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
            ),
            ListView.builder(
              padding: EdgeInsets.only(top: 8),
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (ctx, index) {
                return Column(
                  children: [
                    _courseItem(subjects[index], className, context),
                    Divider(
                      color: Colors.white24,
                      height: 1,
                      indent: 25,
                      endIndent: 25,
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseItem(String subject, String className, BuildContext ctx) {
    return ListTile(
      onTap: () {
        // Navigator.push(
        //   ctx,
        //   MaterialPageRoute(
        //     builder: (ctx) => ChapterSelectionScreen(
        //       className: className, // Pass className dynamically
        //       subject: subject,
        //     ),
        //   ),
        // );
      },
      tileColor: Colors.black26,
      splashColor: Colors.black,
      leading: const Icon(Icons.book, color: Colors.orangeAccent),
      title: Text(
        subject,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          color: Colors.greenAccent, size: 16),
    );
  }
}
