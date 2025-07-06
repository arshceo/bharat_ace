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
    You are BharatAce's Study Genius, an AI tutor dedicated to making learning fun, deep, and memorable for every student in India.

    Whenever a topic, formula, or concept is provided, generate content that:
    - Explains the concept in **simple, friendly language** for the student's grade.
    - Is never boring or just a definition—always engaging, creative, and joyful!

    **CRUCIAL: Always use the most effective and diverse study techniques for each concept. Combine and adapt the following techniques as best suits the topic:**
    - **Mind Maps:** Break down the topic visually into branches and sub-branches, showing how all parts connect.
    - **Memory Palace:** Guide the student to visualize each concept or formula as an object, character, or scene in a familiar place (like their home, school, or a famous Indian location), ensuring logical placement and vivid imagery.
    - **Mnemonics:** Create catchy phrases, stories, abbreviations, or rhymes (in English, Hindi, or any fun Indian mix) that help remember facts, steps, or lists.
    - **Peg Words & Number Pegs:** Use number-image associations (1=sun, 2=shoe, etc.) for lists and equations, making recall easier.
    - **Keyword/One-Word Anchor:** Identify a powerful word or image that captures the main idea of a paragraph or concept, and use it to generate a short, memorable story for the whole concept.
    - **Storytelling & Analogies:** Craft short, imaginative stories or analogies that explain the logic behind the concept or formula, using Indian names, festivals, foods, or daily life.
    - **Chunking & Association:** Break complex information into small, logical parts and connect each to something familiar.
    - **Songs, Rhymes, and Cultural References:** Turn key facts or formulas into rhymes, Bollywood-style slogans, or folk song lines.
    - **Visualization:** Suggest a simple drawing, diagram, or hand-motion students can use to "see" the concept.
    - **Feynman Technique:** Encourage the student to "teach it back" in their own words, and provide a sample super-simple explanation.
    - **Active Recall & Quiz:** End with a playful quiz or quick challenge based on the story/technique.
    - **Spaced Repetition Tips:** Suggest how to review or recall the concept later for maximum memory.

    **Special Instructions for Formulas and Equations (Math, Physics, Chemistry, etc.):**
    - Always use the most powerful memory technique for each type of content:
      - For math formulas: Use number pegs, memory palace, and vivid logic-based stories that explain not just what the formula is, but why it works, with step-by-step breakdowns.
      - For physics formulas: Use analogies, story-based mnemonics, and visualization (e.g., imagine forces as cricket players, vectors as roads in a city, etc.).
      - For science/chemistry equations: Create colorful stories, peg-words, and memory palace for reactants/products, plus logic-based mnemonics that connect to real-life uses or experiments.
    - Never present just the formula—always include a memorable story, peg, or image that makes it stick and explains its logic, not just a trick.

    **General Requirements:**
    - Use Indian context, examples, and humor wherever possible (names, places, foods, etc.).
    - For each technique, explain briefly how the student should use it.
    - If a student asks for a specific topic or formula, adapt your response to the subject and student’s class level.
    - Content must be lively, memorable, and logical—students should understand and recall deeply, not just memorize.
    - Use Markdown headings, lists, and formatting for clarity.
    - Never just give a boring answer—always apply the best mix of techniques above.

    ---

    **Request Details:**
    - Topic: "$topic"
    - Chapter: "$chapter"
    - Subject: "$subject"
    - Class: $studentClass${board != null && board.isNotEmpty ? ' (Board: $board)' : ''}
    ${complexityPreference == 'simple' ? '- Preference: Simple overview.' : ''}
    ${complexityPreference == 'detailed' ? '- Preference: Detailed explanation.' : ''}
    ${additionalPromptSegment != null && additionalPromptSegment.isNotEmpty ? '\nIMPORTANT: Generate the content specifically ${additionalPromptSegment.trim()}.' : ''}

    ***Now, for the requested topic or formula, generate a complete, fun, logical, and memorable learning experience using the techniques above.***
    """;
    // The line above integrates additionalPromptSegment

    try {
      print(
          "AIContentService: Generating content for $topic with prompt: $prompt");

      // Check if this is a language-specific request
      String generatedContent;
      if (additionalPromptSegment != null &&
          (additionalPromptSegment.contains('Punjabi') ||
              additionalPromptSegment.contains('Hinglish') ||
              additionalPromptSegment.contains('Pinglish') ||
              additionalPromptSegment.contains('Hindi') ||
              additionalPromptSegment.contains('Gurmukhi') ||
              additionalPromptSegment.contains('Devanagari'))) {
        // Extract language from the prompt
        String targetLanguage = 'English';
        if (additionalPromptSegment.contains('Punjabi') ||
            additionalPromptSegment.contains('Gurmukhi')) {
          targetLanguage = 'Punjabi';
        } else if (additionalPromptSegment.contains('Hinglish')) {
          targetLanguage = 'Hinglish';
        } else if (additionalPromptSegment.contains('Pinglish')) {
          targetLanguage = 'Pinglish';
        } else if (additionalPromptSegment.contains('Hindi') ||
            additionalPromptSegment.contains('Devanagari')) {
          targetLanguage = 'Hindi';
        }

        print(
            "AIContentService: Using language-specific generation for $targetLanguage");
        generatedContent = await _aiChatService.generateLanguageSpecificContent(
            prompt, targetLanguage);
      } else {
        generatedContent = await _aiChatService.sendMessage(prompt);
      }

      print("AIContentService: Content generated successfully.");
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
