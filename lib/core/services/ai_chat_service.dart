import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatService {
  late final GenerativeModel _model;

  AIChatService() {
    _model = GenerativeModel(
      model:
          'gemini-2.0-flash-exp', // More powerful model for better language support
      apiKey: dotenv.env['GEMINI_API']!,
      systemInstruction: Content.text(
          "You are an educational AI that can teach in multiple languages including English, Hindi, Punjabi (Gurmukhi script), Hinglish (Hindi+English mix), and Pinglish (Punjabi+English mix). When asked to generate content in a specific language, respond entirely in that language with proper script and vocabulary."),
    );
  }

  Future<String> sendMessage(String message) async {
    final content = Content.text(message);
    final response = await _model.generateContent([content]);
    return response.text ?? "I'm not sure how to respond.";
  }

  // Specialized method for language-specific content generation
  Future<String> generateLanguageSpecificContent(
      String prompt, String language) async {
    String languageInstruction;

    switch (language.toLowerCase()) {
      case 'punjabi':
        languageInstruction = """
CRITICAL: You MUST respond ENTIRELY in Punjabi using Gurmukhi script (ਪੰਜਾਬੀ). 
Do NOT use any English words or Latin script. Use only Gurmukhi script.
Examples: ਸਿੱਖਿਆ, ਪਾਠ, ਜਾਣਕਾਰੀ, ਮਹੱਤਵਪੂਰਨ, ਸਮਝਣਾ
""";
        break;
      case 'hinglish':
        languageInstruction = """
CRITICAL: You MUST respond in Hinglish (Hindi + English mix).
Mix Hindi words written in Devanagari script with English words.
Example: "आज हम computer के बारे में सीखेंगे। यह एक important topic है।"
""";
        break;
      case 'pinglish':
        languageInstruction = """
CRITICAL: You MUST respond in Pinglish (Punjabi Gurmukhi + English mix).
Mix Punjabi words in Gurmukhi script with English words.
Example: "ਅੱਜ ਅਸੀਂ computer ਬਾਰੇ ਸਿੱਖਾਂਗੇ। ਇਹ ਇੱਕ important topic ਹੈ।"
""";
        break;
      case 'hindi':
        languageInstruction = """
CRITICAL: You MUST respond ENTIRELY in Hindi using Devanagari script.
Do NOT use any English words. Use only Hindi vocabulary and Devanagari script.
""";
        break;
      default:
        languageInstruction = "Respond in clear, simple English.";
    }

    final fullPrompt = """
$languageInstruction

USER REQUEST: $prompt

Remember: Follow the language instruction precisely. Your entire response must match the specified language format.
""";

    final content = Content.text(fullPrompt);
    final response = await _model.generateContent([content]);
    return response.text ?? "Unable to generate response.";
  }
}
