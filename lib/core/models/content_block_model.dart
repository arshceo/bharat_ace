// lib/core/models/content_block_model.dart

enum ContentBlockType {
  h1,
  h2,
  h3,
  h4,
  h5,
  h6,
  paragraph,
  codeBlock,
  blockquote,
  orderedListItem,
  unorderedListItem,
  image,
  horizontalRule,
}

class ContentBlockModel {
  final String id;
  final ContentBlockType type;
  final String rawContent;
  final int listLevel;
  final String? listMarker;
  final String? codeLanguage;
  final String? imageUrl;
  final String? imageAltText;

  ContentBlockModel({
    required this.id,
    required this.type,
    required this.rawContent,
    this.listLevel = 0,
    this.listMarker,
    this.codeLanguage,
    this.imageUrl,
    this.imageAltText,
  });
}
