class Chapter {
  final String title;
  final bool unlocked;
  final int progress;

  Chapter(
      {required this.title, required this.unlocked, required this.progress});

  factory Chapter.fromJson(String chapterName) {
    return Chapter(
      title: chapterName,
      unlocked: false, // By default, chapters are locked
      progress: 0, // By default, progress is 0
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "unlocked": unlocked,
      "progress": progress,
    };
  }
}
