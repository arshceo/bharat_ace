// lib/core/services/ai_content_service.dart
import 'package:bharat_ace/core/services/ai_chat_service.dart';
import 'package:bharat_ace/core/services/summarization_service.dart'
    show aiChatServiceProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Assuming AIChatService and its provider are defined as before
// final aiChatServiceProvider = Provider<AIChatService>((ref) => AIChatService());

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
  }) async {
    // **** CRITICAL: Prompt Engineering ****
    // This prompt needs extensive refinement and testing.
    String prompt = """
    Generate comprehensive yet easy-to-understand educational content for a Class $studentClass student ${board != null ? '(Board: $board)' : ''}.
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

    Generate the content now:
    """;

    try {
      print("AIContentService: Generating content for $topic...");
      // Use a NEW chat session or a method that doesn't rely on ongoing history for generation
      // For simplicity, we might still use the main chat service instance but understand
      // the conversation history might slightly influence generation if not managed.
      // A dedicated 'generate' function in AIChatService might be better long-term.
      String generatedContent = await _aiChatService
          .sendMessage(prompt); // Or a dedicated generation method
      print("AIContentService: Content generated.");
      return generatedContent
          .trim(); // Return the raw generated text (likely Markdown)
    } catch (e) {
      print("❌ AIContentService Error: $e");
      throw Exception(
          "Failed to generate content. Please try again."); // Rethrow for UI handling
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
  }) async {
    String prompt = """
      You are an expert tutor explaining concepts to a Class $studentClass student.
      Context: The student is learning about "$topic" in the chapter "$chapter" ($subject). They have already seen the following explanation:
      --- START CONTEXT ---
      $existingContent
      --- END CONTEXT ---

      Now, please answer the student's specific question clearly and concisely, relating it back to the context provided if possible.
      Student's Question: "$question"

      Answer:
      """;
    try {
      print("AIContentService: Answering question: $question");
      // Use the ongoing chat session or a dedicated Q&A method
      String answer = await _aiChatService.sendMessage(prompt);
      print("AIContentService: Answer generated.");
      return answer.trim();
    } catch (e) {
      print("❌ AIContentService Q&A Error: $e");
      return "Sorry, I encountered an issue answering that question. Please try rephrasing.";
    }
  }
}

// --- Riverpod Provider ---
final aiContentGenerationServiceProvider =
    Provider<AIContentGenerationService>((ref) {
  final aiChatService =
      ref.watch(aiChatServiceProvider); // Assumes provider exists
  return AIContentGenerationService(aiChatService);
});
