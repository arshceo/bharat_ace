class CourseMaterial {
  String subject;
  String chapter;
  String topic;
  String content; // AI-enhanced learning material
  List<String> previousYearQuestions;
  List<String> bestAnswers;

  CourseMaterial({
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.content,
    required this.previousYearQuestions,
    required this.bestAnswers,
  });

  Map<String, dynamic> toMap() => {
        "subject": subject,
        "chapter": chapter,
        "topic": topic,
        "content": content,
        "previousYearQuestions": previousYearQuestions,
        "bestAnswers": bestAnswers,
      };

  factory CourseMaterial.fromMap(Map<String, dynamic> map) => CourseMaterial(
        subject: map["subject"],
        chapter: map["chapter"],
        topic: map["topic"],
        content: map["content"],
        previousYearQuestions: List<String>.from(map["previousYearQuestions"]),
        bestAnswers: List<String>.from(map["bestAnswers"]),
      );
}
