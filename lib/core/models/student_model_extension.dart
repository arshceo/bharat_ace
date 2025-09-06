// lib/core/models/student_model_extension.dart
import 'package:bharat_ace/core/models/student_model.dart';

extension StudentModelExtension on StudentModel {
  // Add missing properties as getters that safely return null or default values
  int get avgFocusTime => 45; // Default value (45 minutes)
  int get totalStudyTime => 0; // Default to 0
  int get questionsAnswered => 0; // Default to 0
  int get accuracy => 0; // Default percentage
}
