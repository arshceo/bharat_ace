import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatService {
  late final ChatSession _chatSession;

  AIChatService() {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash-lite',
      apiKey: dotenv.env['GEMINI_API']!,
    );
    _chatSession = model.startChat(); // 🔥 Creates a chat session
  }

  Future<String> sendMessage(String message) async {
    final content = Content.text(message);

    final response = await _chatSession.sendMessage(content);

    return response.text ?? "I'm not sure how to respond.";
  }
}
