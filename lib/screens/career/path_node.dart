enum NodeType {
  education,
  milestone,
  career,
}

class PathNode {
  final String id;
  final String title;
  final String description;
  final NodeType type;
  final Map<String, String> details;

  PathNode({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.details,
  });
}
