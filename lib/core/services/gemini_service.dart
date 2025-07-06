// lib/core/services/gemini_service.dart
import 'dart:convert'; // For json.decode
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Structured result from Gemini
class SummaryEvaluation {
  final bool passed;
  final String feedback;
  final List<String> identifiedTopics;
  final bool isVague;
  final bool mentionsCoreTopics;

  SummaryEvaluation({
    required this.passed,
    required this.feedback,
    this.identifiedTopics = const [],
    this.isVague = false,
    this.mentionsCoreTopics = false,
  });

  factory SummaryEvaluation.fromJson(Map<String, dynamic> json) {
    return SummaryEvaluation(
      passed: json['passed'] as bool? ?? false,
      feedback:
          json['reasoning'] as String? ?? 'No detailed feedback provided.',
      identifiedTopics: List<String>.from(
          json['identified_topics_from_summary'] as List? ?? []),
      isVague: json['is_vague'] as bool? ?? false,
      mentionsCoreTopics: json['mentions_core_topics'] as bool? ?? false,
    );
  }

  // Fallback if JSON parsing fails or model doesn't strictly adhere
  factory SummaryEvaluation.fromFallback(String rawText,
      {bool forPrerequisite = false}) {
    // For prerequisites, be more lenient in fallback
    bool makeshiftPass = rawText.toLowerCase().contains("pass") ||
        rawText.toLowerCase().contains("good") ||
        rawText.toLowerCase().contains("excellent") ||
        rawText.toLowerCase().contains("recall") ||
        rawText.toLowerCase().contains("mentioned") ||
        (forPrerequisite &&
            rawText.trim().isNotEmpty &&
            rawText.length > 10); // Very lenient for prereq if any text

    return SummaryEvaluation(
      passed: makeshiftPass,
      feedback:
          "Evaluation: $rawText (AI response might not be in expected JSON format. Automatic fallback applied.)",
    );
  }
}

class GeminiService {
  late final GenerativeModel _model;
  late final GenerativeModel _chatModel;
  final String _apiKey;

  GeminiService() : _apiKey = dotenv.env['GEMINI_API'] ?? '' {
    // Ensure your .env key is GEMINI_API_KEY or adjust here
    if (_apiKey.isEmpty) {
      throw Exception(
          "GEMINI_API_KEY not found in .env file. Please ensure it's set.");
    }
    _model = GenerativeModel(
      // Use a model that supports JSON output well, like 1.5 Flash or Pro
      // model: 'gemini-1.5-pro-latest', // For best quality JSON adherence
      model:
          'gemini-1.5-flash-latest', // Faster and often sufficient for structured output
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: "application/json", // Crucial for JSON output
        temperature: 0.2, // Lower temperature for more deterministic evaluation
        // maxOutputTokens: 300, // Adjust if responses are truncated
      ),
      // safetySettings: ... // Consider adding safety settings if needed
    );
    _chatModel = GenerativeModel(
      // model: 'gemini-1.5-pro-latest', // Or 'gemini-pro' for chat
      model: 'gemini-1.5-flash-latest', // Often good for chat too
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7, // More creative for chat
        maxOutputTokens: 1000,
      ),
      // safetySettings: ... // Consider adding safety settings if needed
    );
  }

  Future<SummaryEvaluation> evaluateStudentSummary({
    required String studentSummary,
    required List<String>
        coreTopics, // For prerequisites, these will be the prerequisite strings
    required String chapterOrLevelTitle,
    bool isPrerequisiteSummary = false, // New parameter
  }) async {
    final coreTopicsString =
        coreTopics.isEmpty ? "Not specified" : coreTopics.join(", ");

    // Ensure studentSummary is not excessively long to avoid issues
    final sanitizedSummary = studentSummary.trim().substring(
        0,
        studentSummary.trim().length > 1500 // Increased slightly
            ? 1500
            : studentSummary.trim().length);

    if (sanitizedSummary.isEmpty) {
      return SummaryEvaluation(
          passed: false, feedback: "Summary cannot be empty.");
    }

    String prompt;

    if (isPrerequisiteSummary) {
      prompt = """
      You are an AI assistant evaluating a student's recall of prerequisite material for a section titled "$chapterOrLevelTitle".
      The prerequisite topics/concepts provided to the student were: $coreTopicsString. (If "Not specified", it means general foundational knowledge was expected to be recalled).
      The student was asked to briefly note down 1-2 key things they recall or understood from the prerequisite material.

      Student's Input:
      "$sanitizedSummary"

      Please evaluate the student's input based on these criteria:
      1. Engagement: Does the input indicate the student engaged with the prerequisite material at all? Even a brief, relevant mention is positive.
      2. Recall: Does the student mention or clearly allude to ANY of the listed prerequisite topics/concepts, or any plausible foundational concept if prerequisites were "Not specified"?
      3. Specificity: Is the input reasonably specific for a quick recall, or overly generic (e.g., "I learned important things", "it was good")? Avoid penalizing for brevity if it's specific.

      The goal is a LIGHTWEIGHT check for basic engagement and recall. Be VERY LENIENT for prerequisites.
      If the student mentions anything relevant to the prerequisites or foundational knowledge, even vaguely or very briefly, it should PASS.
      The student is NOT expected to provide a detailed summary here, just a sign they read something.
      
      Provide your evaluation STRICTLY in the following JSON format:
      {
        "passed": <boolean>, 
        "reasoning": "<string: Brief, encouraging feedback. If false, gently suggest reviewing prerequisites again. Be positive even on a pass.>",
        "identified_topics_from_summary": ["<string: list of prerequisite topics/concepts identified in the input, if any. Keep it short or empty if nothing specific was identified. Don't list the student's entire summary here.>"],
        "is_vague": <boolean>, 
        "mentions_core_topics": <boolean> 
      }

      Details for JSON fields:
      - "passed": true if there's ANY indication of engagement with the prerequisite content.
      - "reasoning": For prerequisite pass: "Good recall!", "Thanks for sharing your key takeaways on the prerequisites!", "Looks like you got the basics!". For prereq fail (rare, only if completely irrelevant or empty): "Please take another look at the prerequisite material and note down a key point or two."
      - "identified_topics_from_summary": Only list actual prerequisite terms if clearly identifiable.
      - "is_vague": true ONLY if the input is extremely generic like "I learned stuff" or "it was okay" with no specifics.
      - "mentions_core_topics": true if they mentioned any prerequisite keyword, or if "coreTopicsString" is "Not specified" and their input seems somewhat relevant to learning foundational knowledge.

      Your entire response MUST be only the JSON object, without any leading/trailing text or markdown backticks.
      """;
    } else {
      // Existing prompt for regular summaries
      prompt = """
      You are an AI assistant evaluating a student's summary for a section titled "$chapterOrLevelTitle".
      The core topics for this section are: $coreTopicsString.
      The student was asked to summarize what they learned in 2-3 bullet points or a short paragraph.

      Student's Summary:
      "$sanitizedSummary"

      Please evaluate the summary based on these criteria:
      1. Core Topic Coverage: Does the summary mention or clearly allude to the core topics? (If core topics are specified).
      2. Clarity and Specificity: Is the summary clear, specific, and demonstrates understanding, or is it too vague (e.g., "I learned a lot")?
      3. Plausibility: Does it sound like genuine understanding of the material?
      
      Provide your evaluation STRICTLY in the following JSON format:
      {
        "passed": <boolean>,
        "reasoning": "<string: Brief explanation of why it passed or failed. If false, provide constructive feedback. If true, positive reinforcement.>",
        "identified_topics_from_summary": ["<string: list of core topics identified in summary. Do not list student's entire summary here.>"],
        "is_vague": <boolean>,
        "mentions_core_topics": <boolean> 
      }

      Details for JSON fields for regular summary:
      - "passed": true ONLY if the summary is genuinely good, reflects understanding, and covers some core aspects.
      - "reasoning": Be specific. E.g., "Great summary! You clearly covered [topic A] and [topic B]." or "Your summary is a bit too general. Try to include specific concepts like [topic C] from the material."
      - "is_vague": true if the summary lacks specific details from the content.
      - "mentions_core_topics": true if specific core topics are identifiable in the summary. If coreTopicsString is "Not specified", evaluate "mentions_core_topics" as true if the summary is specific and relevant, otherwise false.
      
      Be reasonably strict for regular summaries. The goal is to ensure the student has processed and can articulate key learnings.
      If the summary is very short, generic, or clearly misses the essence (as implied by core topics), it should NOT pass.
      Your entire response MUST be only the JSON object, without any leading/trailing text or markdown backticks.
      """;
    }

    try {
      print(
          "--- Gemini Service: Sending Prompt for ${isPrerequisiteSummary ? 'Prerequisite' : 'Regular'} Summary ---");
      // print("Prompt: $prompt"); // Uncomment for debugging the exact prompt

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        print("Gemini Raw Response for Summary Eval: ${response.text}");
        try {
          String jsonText = response.text!;
          // Robust stripping of markdown backticks for JSON
          if (jsonText.startsWith("```json")) {
            jsonText = jsonText.substring(7);
            if (jsonText.endsWith("```")) {
              jsonText = jsonText.substring(0, jsonText.length - 3);
            }
          } else if (jsonText.startsWith("```")) {
            // Handles just ``` at start
            jsonText = jsonText.substring(3);
            if (jsonText.endsWith("```")) {
              jsonText = jsonText.substring(0, jsonText.length - 3);
            }
          }

          final jsonData = json.decode(jsonText.trim());
          return SummaryEvaluation.fromJson(jsonData);
        } catch (e) {
          print(
              "Failed to parse Gemini response as JSON for summary: $e. Raw: ${response.text}");
          // Pass the isPrerequisiteSummary flag to the fallback for more lenient fallback for prerequisites
          return SummaryEvaluation.fromFallback(response.text!,
              forPrerequisite: isPrerequisiteSummary);
        }
      } else {
        print("Gemini response was null for summary evaluation.");
        return SummaryEvaluation(
            passed: false,
            feedback: "AI could not generate a response. Please try again.");
      }
    } catch (e) {
      print("Error calling Gemini API for summary evaluation: $e");
      if (e is GenerativeAIException && e.message.contains('SAFETY')) {
        return SummaryEvaluation(
            passed: false,
            feedback:
                "Your summary triggered a safety filter. Please rephrase and try again.");
      }
      return SummaryEvaluation(
          passed: false,
          feedback:
              "Error communicating with AI: $e. Please check your connection or API key.");
    }
  }

  Stream<String> generateChatResponseStream(String prompt,
      {required List<Content> history}) async* {
    try {
      // Use the _chatModel for chat interactions
      final chatSession = _chatModel.startChat(history: history);
      final responseStream =
          chatSession.sendMessageStream(Content.text(prompt));

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        } else if (chunk.promptFeedback?.blockReason != null) {
          final reason = chunk.promptFeedback!.blockReason.toString();
          print("Gemini Safety Block (Chat): $reason");
          yield "[Blocked by safety settings: ${reason.split('.').last}]";
          return;
        }
      }
    } catch (e) {
      print("Gemini API Error (generateChatResponseStream): $e");
      if (e is GenerativeAIException &&
          e.message.contains('candidates not found')) {
        yield "I'm not sure how to respond to that. Could you try asking differently?";
      } else {
        yield "Error: Could not get AI response. ($e)";
      }
    }
  }
}

// Provider for this service
final geminiEvaluationServiceProvider =
    Provider<GeminiService>((ref) => GeminiService());
