// lib/core/services/ai_content_service.dart
import 'package:bharat_ace/core/services/ai_chat_service.dart';
import 'package:bharat_ace/core/services/summarization_service.dart';
// If aiChatServiceProvider is in summarization_service.dart, ensure that file only exports the provider or move it.
// It's generally better to have providers in their own files or a central provider file.
// For this example, I'll assume aiChatServiceProvider is correctly accessible.
// import 'package:bharat_ace/core/services/summarization_service.dart' show aiChatServiceProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming AIChatService and its provider are defined.
// If aiChatServiceProvider is not directly in ai_chat_service.dart, ensure the import is correct.
// For example, if it's in a providers file:
// import 'package:bharat_ace/core/providers/ai_providers.dart';

class AIContentGenerationService {
  final AIChatService _aiChatService;

  AIContentGenerationService(this._aiChatService);

  // Generates educational content for a specific topic
  Future<String> generateTopicContent({
    required String subject,
    required String chapter,
    required String topic,
    required String studentClass, // e.g., "10"
    String? board, // e.g., "CBSE"
    String? complexityPreference, // Optional: "simple", "detailed"
    String? additionalPromptSegment, // Parameter for language, etc.
  }) async {
    String prompt = """
    Generate comprehensive yet easy-to-understand educational content for a Class $studentClass student ${board != null && board.isNotEmpty ? '(Board: $board)' : ''}.
    Topic: "$topic"
    Chapter: "$chapter"
    Subject: "$subject"

    Instructions:
    1. Explain the core concepts clearly and concisely.
    2. Use simple language suitable for the student's class level.
    3. Include relevant examples to illustrate the concepts.
    4. Provide memory aids (like mnemonics or analogies) where applicable.
    5. Structure the content logically with clear headings or sections if possible (use Markdown for basic formatting like **headings** or *italics*).
    6. Ensure accuracy and cover the essential aspects of the topic for this grade level.
    ${complexityPreference == 'simple' ? '7. Focus on a very basic overview.' : ''}
    ${complexityPreference == 'detailed' ? '7. Include more in-depth explanations and related concepts.' : ''}
    ${additionalPromptSegment != null && additionalPromptSegment.isNotEmpty ? '\nIMPORTANT: Generate the content specifically ${additionalPromptSegment.trim()}.' : ''}

    Generate the content now:
    """;
    // The line above integrates additionalPromptSegment

    try {
      print(
          "AIContentService: Generating content for $topic with prompt: $prompt");
      String generatedContent = await _aiChatService.sendMessage(prompt);
      print("AIContentService: Content generated.");
      return generatedContent.trim();
    } catch (e) {
      print("❌ AIContentService Error in generateTopicContent: $e");
      throw Exception(
          "Failed to generate content for $topic. Please try again.");
    }
  }

  Future<String> generatePrerequisiteExplanation({
    required String subject,
    required String chapterTitle,
    required List<String> prerequisites,
    required String studentClass,
    String? additionalPromptSegment, // Parameter for language, etc.
  }) async {
    if (prerequisites.isEmpty) {
      // If no specific prerequisites, generate a general foundational knowledge intro
      String prompt = """
        You are an AI tutor preparing a Class $studentClass student for the chapter "$chapterTitle" in $subject.
        Since no specific prerequisites are listed, provide a brief, encouraging introduction about the importance of foundational knowledge for this chapter.
        Keep it simple, friendly, and use Markdown for basic formatting.
        ${additionalPromptSegment != null && additionalPromptSegment.isNotEmpty ? '\nIMPORTANT: Generate this introduction specifically ${additionalPromptSegment.trim()}.' : ''}
        """;
      try {
        print(
            "AIContentService: Generating general prerequisite intro with prompt: $prompt");
        String explanation = await _aiChatService.sendMessage(prompt);
        print("AIContentService: General prerequisite intro generated.");
        return explanation.trim();
      } catch (e) {
        print("❌ AIContentService General Prerequisite Error: $e");
        throw Exception("Could not generate general prerequisite intro.");
      }
    }

    final prerequisiteList = prerequisites.join("\n- ");

    final prompt = """
    You are an AI tutor helping a Class $studentClass student prepare for the chapter "$chapterTitle" in $subject.

    Below are the prerequisites the student should be familiar with:
    - $prerequisiteList

    Please generate a brief and easy-to-understand overview that:
    1. Explains why these prerequisites are important for this chapter.
    2. Offers simple refreshers or definitions for each prerequisite.
    3. Uses friendly, student-appropriate language.
    ${additionalPromptSegment != null && additionalPromptSegment.isNotEmpty ? '\nIMPORTANT: Generate this explanation specifically ${additionalPromptSegment.trim()}.' : ''}

    Format the output using Markdown with short sections and bullet points if needed.
    """;
    // The line above integrates additionalPromptSegment

    try {
      print(
          "AIContentService: Generating prerequisite explanation with prompt: $prompt");
      String explanation = await _aiChatService.sendMessage(prompt);
      print("AIContentService: Prerequisite explanation generated.");
      return explanation.trim();
    } catch (e) {
      print("❌ AIContentService Prerequisite Error: $e");
      throw Exception("Could not generate prerequisite content.");
    }
  }

  // Generates an answer to a specific question within the topic's context
  Future<String> answerTopicQuestion({
    required String subject,
    required String chapter,
    required String topic,
    required String existingContent, // Provide context
    required String question,
    required String studentClass,
    String? additionalPromptSegment, // Parameter for language, etc.
  }) async {
    String prompt = """
      You are an expert tutor explaining concepts to a Class $studentClass student.
      Context: The student is learning about "$topic" in the chapter "$chapter" ($subject). They have already seen the following explanation:
      --- START CONTEXT ---
      $existingContent
      --- END CONTEXT ---

      Now, please answer the student's specific question clearly and concisely, relating it back to the context provided if possible.
      Student's Question: "$question"
      ${additionalPromptSegment != null && additionalPromptSegment.isNotEmpty ? '\nIMPORTANT: Answer the question specifically ${additionalPromptSegment.trim()}.' : ''}

      Answer:
      """;
    // The line above integrates additionalPromptSegment

    try {
      print(
          "AIContentService: Answering question: $question with prompt: $prompt");
      String answer = await _aiChatService.sendMessage(prompt);
      print("AIContentService: Answer generated.");
      return answer.trim();
    } catch (e) {
      print("❌ AIContentService Q&A Error: $e");
      // It's better to throw an exception so the UI can handle it,
      // rather than returning a fixed error string that might be displayed as AI content.
      throw Exception(
          "Sorry, I encountered an issue answering that question. Please try rephrasing.");
    }
  }
}

// --- Riverpod Provider ---
final aiContentGenerationServiceProvider =
    Provider<AIContentGenerationService>((ref) {
  // Ensure aiChatServiceProvider is correctly imported and available.
  // If AIChatService itself has dependencies, they should be resolved by its provider.
  final aiChatService = ref.watch(aiChatServiceProvider);
  return AIContentGenerationService(aiChatService);
});
