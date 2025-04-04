import 'chapter_model.dart';

class Subject {
  final String name;
  final List<Chapter> chapters;

  Subject({required this.name, required this.chapters});

  factory Subject.fromJson(String subjectName, dynamic json) {
    List<Chapter> chapterList = [];

    if (json is List) {
      chapterList =
          json.map((chapterName) => Chapter.fromJson(chapterName)).toList();
    }

    return Subject(name: subjectName, chapters: chapterList);
  }
}
