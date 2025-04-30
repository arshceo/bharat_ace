// lib/core/services/summarization_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_chat_service.dart'; // Your existing AI chat service

class SummarizationService {
  final AIChatService _aiChatService;

  SummarizationService(this._aiChatService);

  /// Generates a summary for the given text content using the AI model.
  Future<String> summarizeContent(String contentToSummarize) async {
    if (contentToSummarize.trim().isEmpty) {
      return "Nothing to summarize.";
    }

    // ** Define the Prompt **
    // This is crucial for getting good results. You'll need to experiment.
    // Keep it concise and clear for the MVP.
    final String prompt = """
    Please summarize the following text in simple, student-friendly language. 
    Focus on the key concepts and main points. Keep the summary concise, ideally under 100 words. 
    Do not add any introductory or concluding phrases like "Here is the summary:".

    Text to Summarize:
    ---
    $contentToSummarize
    ---
    Summary:
    """;

    try {
      print("SummarizationService: Sending content to AI for summarization...");
      // Use the existing AIChatService's sendMessage method
      // Note: This uses the ongoing chat session. For pure summarization,
      // you might consider a separate non-session-based call if the API supports it,
      // or starting a new session just for summarization if needed.
      // For MVP, using the existing session is likely fine.
      final String summary = await _aiChatService.sendMessage(prompt);
      print("SummarizationService: Summary received.");
      return summary;
    } catch (e) {
      print("❌ SummarizationService Error: $e");
      return "Sorry, I couldn't generate a summary at this time. Please try again.";
    }
  }
}

// --- Riverpod Provider for the Service ---

// Provider for AIChatService (assuming it's not already provided elsewhere)
// If it IS provided elsewhere (e.g., ai_chat_provider.dart), use that provider instead.
final aiChatServiceProvider = Provider<AIChatService>((ref) {
  return AIChatService(); // Assumes constructor needs no args or uses dotenv internally
});

// Provider for SummarizationService
final summarizationServiceProvider = Provider<SummarizationService>((ref) {
  // Inject the AIChatService instance
  final aiChatService = ref.watch(aiChatServiceProvider);
  return SummarizationService(aiChatService);
});
