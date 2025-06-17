enum ContentType {
  image, // For notes that are images
  video, // For reels
  // textNote, // If you plan to have text-only notes later
}

// Helper to get string representation for Firestore
extension ContentTypeExtension on ContentType {
  String get name {
    switch (this) {
      case ContentType.image:
        return 'image';
      case ContentType.video:
        return 'video';
      // case ContentType.textNote:
      //   return 'textNote';
    }
  }
}
