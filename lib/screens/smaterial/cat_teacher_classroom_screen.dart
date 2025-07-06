// lib/screens/smaterial/cat_teacher_classroom_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' as math;

// Import necessary services and providers
import '../../core/services/ai_content_service.dart';
import '../../core/services/content_cache_service.dart';
import '../../core/providers/student_details_provider.dart';

// --- Enhanced State Management for AI Classroom ---
final _contentStateProvider = StateProvider.autoDispose<AsyncValue<String>>(
    (ref) => const AsyncValue.loading());
final _isTeachingProvider = StateProvider.autoDispose<bool>((ref) => false);
final _showGotItProvider = StateProvider.autoDispose<bool>((ref) => false);
final _isListeningProvider = StateProvider.autoDispose<bool>((ref) => false);
final _isAnsweringProvider = StateProvider.autoDispose<bool>((ref) => false);
final _boardContentProvider = StateProvider.autoDispose<String>((ref) => '');
final _teacherStateProvider =
    StateProvider.autoDispose<TeacherState>((ref) => TeacherState.welcome);
final _selectedLanguageProvider =
    StateProvider.autoDispose<String>((ref) => 'English');
final _showLanguageSelectionProvider =
    StateProvider.autoDispose<bool>((ref) => false);

enum TeacherState { welcome, teaching, listening, answering, encouraging }

class CatTeacherClassroomScreen extends ConsumerStatefulWidget {
  final String chapter;
  final String topic;
  final String subject;
  final String content;

  const CatTeacherClassroomScreen({
    Key? key,
    required this.chapter,
    required this.topic,
    required this.subject,
    required this.content,
  }) : super(key: key);

  @override
  ConsumerState<CatTeacherClassroomScreen> createState() =>
      _CatTeacherClassroomScreenState();
}

class _CatTeacherClassroomScreenState
    extends ConsumerState<CatTeacherClassroomScreen>
    with TickerProviderStateMixin {
  // Lightweight Animation Controllers for mobile performance
  late AnimationController _starsController;
  late AnimationController _welcomeController;
  late AnimationController _boardController;
  late AnimationController _teachingController;

  // AI Teaching System
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _questionController = TextEditingController();
  bool _speechEnabled = false;
  String _lastWords = "";
  Timer? _teachingTimer;
  Timer? _writingTimer;
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAIServices();
    _loadContentAndStartTeaching();
  }

  void _initializeAnimations() {
    // Single lightweight animation for moving stars
    _starsController = AnimationController(
      duration:
          const Duration(seconds: 20), // Slow movement for professional look
      vsync: this,
    )..repeat();

    // Welcome message animation
    _welcomeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Board entrance animation
    _boardController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Teaching animation for writing effect
    _teachingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Start the sequence
    _startWelcomeSequence();
  }

  Future<void> _initializeAIServices() async {
    // Initialize TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);

    // Initialize Speech Recognition
    try {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        _speechEnabled = await _speechToText.initialize(
          onError: (errorNotification) =>
              print('Speech Error: $errorNotification'),
          onStatus: (status) => print('Speech Status: $status'),
        );
      }
    } catch (e) {
      print('Speech initialization error: $e');
    }
  }

  Future<void> _loadContentAndStartTeaching() async {
    // Load content from cache or generate new
    final cacheService = ref.read(contentCacheServiceProvider);
    String? cachedContent = await cacheService.getCachedContent(widget.topic);

    if (cachedContent != null && cachedContent.isNotEmpty) {
      ref.read(_contentStateProvider.notifier).state =
          AsyncValue.data(cachedContent);
      _processContentForTeaching(cachedContent);
    } else {
      _generateFreshContent();
    }
  }

  Future<void> _generateFreshContent() async {
    try {
      final studentAsync = ref.read(studentDetailsProvider);
      final student = studentAsync.valueOrNull;

      if (student == null) {
        throw Exception("Student details not available");
      }

      final contentService = ref.read(aiContentGenerationServiceProvider);
      final selectedLanguage = ref.read(_selectedLanguageProvider);

      print('Generating fresh content for topic: ${widget.topic}');

      final generatedContent = await contentService.generateTopicContent(
        subject: widget.subject,
        chapter: widget.chapter,
        topic: widget.topic,
        studentClass: student.grade,
        board: student.board,
        complexityPreference: 'medium',
        additionalPromptSegment:
            'Explain this topic step by step in $selectedLanguage language with examples and clear explanations.',
      );

      print('Generated content length: ${generatedContent.length}');

      ref.read(_contentStateProvider.notifier).state =
          AsyncValue.data(generatedContent);

      // Cache the content
      final cacheService = ref.read(contentCacheServiceProvider);
      await cacheService.saveContentToCache(widget.topic, generatedContent);

      _processContentForTeaching(generatedContent);
    } catch (e, stack) {
      print('Error generating fresh content: $e');
      ref.read(_contentStateProvider.notifier).state =
          AsyncValue.error(e, stack);

      // Use fallback content if generation fails
      final fallbackContent = '''
      Welcome to our lesson on ${widget.topic}!
      
      ${widget.topic} is an important concept that we'll explore together.
      
      Let's start by understanding the basics of ${widget.topic}.
      
      We'll learn about the key principles and how they apply in real life.
      
      By the end of this lesson, you'll have a clear understanding of ${widget.topic}.
      
      Let's begin our journey of learning together!
      ''';

      _processContentForTeaching(fallbackContent);
    }
  }

  void _processContentForTeaching(String content) {
    // Convert markdown to plain text for better display
    final plainText = _markdownToPlainText(content);
    print(
        'Processing content for continuous teaching. Length: ${plainText.length}');

    // Safer content preview
    if (plainText.length > 200) {
      print('Content preview: ${plainText.substring(0, 200)}...');
    } else if (plainText.length > 0) {
      print('Content preview: $plainText');
    } else {
      print('Content is empty!');
    }

    // Start teaching after welcome sequence with full content
    Future.delayed(const Duration(seconds: 4), () {
      if (plainText.isNotEmpty && plainText.length > 100) {
        print('Starting continuous teaching with full content');
        _startContinuousTeaching(plainText);
      } else {
        print('No substantial content available, using comprehensive fallback');
        // Get selected language for fallback content
        final selectedLanguage = ref.read(_selectedLanguageProvider);
        String fallbackContent;

        if (selectedLanguage == 'Punjabi') {
          fallbackContent = '''
ਸਤ ਸ੍ਰੀ ਅਕਾਲ! ਅੱਜ ਅਸੀਂ ${widget.topic} ਬਾਰੇ ਸਿੱਖਾਂਗੇ।

${widget.topic} ਇੱਕ ਮਹੱਤਵਪੂਰਨ ਵਿਸ਼ਾ ਹੈ ਜੋ ${widget.subject} ਵਿੱਚ ਬਹੁਤ ਜ਼ਰੂਰੀ ਹੈ।

ਪਹਿਲਾਂ ਅਸੀਂ ਸਮਝਾਂਗੇ ਕਿ ${widget.topic} ਕੀ ਹੈ ਅਤੇ ਇਹ ਕਿਉਂ ਮਹੱਤਵਪੂਰਨ ਹੈ।

ਇਸ ਪਾਠ ਵਿੱਚ ਅਸੀਂ ${widget.topic} ਦੀਆਂ ਮੁੱਖ ਗੱਲਾਂ ਸਿੱਖਾਂਗੇ।

ਮਿਸਾਲਾਂ ਦੇ ਨਾਲ ਅਸੀਂ ਇਸ ਵਿਸ਼ੇ ਨੂੰ ਸਮਝਾਂਗੇ।

ਪਾਠ ਦੇ ਅੰਤ ਵਿੱਚ ਤੁਸੀਂ ${widget.topic} ਨੂੰ ਚੰਗੀ ਤਰ੍ਹਾਂ ਸਮਝ ਜਾਓਗੇ।

ਜੇ ਕੋਈ ਸਵਾਲ ਹੋਵੇ ਤਾਂ ਜ਼ਰੂਰ ਪੁੱਛਣਾ - ਅਸੀਂ ਮਿਲ ਕੇ ਸਿੱਖਾਂਗੇ!
          ''';
        } else if (selectedLanguage == 'Hinglish') {
          fallbackContent = '''
नमस्ते! आज हम ${widget.topic} के बारे में सीखेंगे।

${widget.topic} एक important topic है जो ${widget.subject} में बहुत जरूरी है।

पहले हम समझेंगे कि ${widget.topic} क्या है और यह क्यों important है।

इस lesson में हम ${widget.topic} की main concepts सीखेंगे।

Examples के साथ हम इस topic को समझेंगे।

Lesson के end में आप ${widget.topic} को अच्छी तरह समझ जाएंगे।

अगर कोई question हो तो जरूर पूछना - हम together सीखेंगे!
          ''';
        } else if (selectedLanguage == 'Pinglish') {
          fallbackContent = '''
ਸਤ ਸ੍ਰੀ ਅਕਾਲ! Today ਅਸੀਂ ${widget.topic} ਬਾਰੇ ਸਿੱਖਾਂਗੇ।

${widget.topic} ਇੱਕ important topic ਹੈ ਜੋ ${widget.subject} ਵਿੱਚ ਬਹੁਤ ਜ਼ਰੂਰੀ ਹੈ।

ਪਹਿਲਾਂ ਅਸੀਂ understand ਕਰਾਂਗੇ ਕਿ ${widget.topic} ਕੀ ਹੈ ਅਤੇ ਇਹ ਕਿਉਂ important ਹੈ।

ਇਸ lesson ਵਿੱਚ ਅਸੀਂ ${widget.topic} ਦੀਆਂ main concepts ਸਿੱਖਾਂਗੇ।

Examples ਦੇ ਨਾਲ ਅਸੀਂ ਇਸ topic ਨੂੰ ਸਮਝਾਂਗੇ।

Lesson ਦੇ end ਵਿੱਚ ਤੁਸੀਂ ${widget.topic} ਨੂੰ ਚੰਗੀ ਤਰ੍ਹਾਂ understand ਕਰ ਜਾਓਗੇ।

ਜੇ ਕੋਈ questions ਹੋਣ ਤਾਂ ਜ਼ਰੂਰ ਪੁੱਛਣਾ - ਅਸੀਂ together ਸਿੱਖਾਂਗੇ!
          ''';
        } else {
          fallbackContent = '''
Welcome to our comprehensive lesson on ${widget.topic}!

Today we will explore ${widget.topic} in detail and understand its importance in ${widget.subject}.

Let's start by understanding what ${widget.topic} means and why it's crucial for students to learn.

${widget.topic} is a fundamental concept that forms the building blocks for advanced topics in ${widget.subject}.

We'll cover the basic definitions, key concepts, and practical applications of ${widget.topic}.

Through this lesson, you'll learn how ${widget.topic} is used in real-world scenarios and everyday life.

Understanding ${widget.topic} will help you develop problem-solving skills and logical thinking.

Let's explore different aspects of ${widget.topic} with clear explanations and examples.

By the end of this lesson, you'll have a solid foundation in ${widget.topic} and be ready for more advanced concepts.

Remember to ask questions if anything is unclear - learning is a journey we take together!

Congratulations on completing this comprehensive lesson on ${widget.topic}!
          ''';
        }
        _startContinuousTeaching(fallbackContent);
      }
    });
  }

  String _markdownToPlainText(String markdown) {
    // Simple markdown to text conversion
    String text = markdown;
    text = text.replaceAll(RegExp(r'#+\s*'), ''); // Remove headers
    text = text.replaceAll(
        RegExp(r'\*\*(.*?)\*\*'), r'\1'); // Remove bold - use \1 instead of $1
    text = text.replaceAll(
        RegExp(r'\*(.*?)\*'), r'\1'); // Remove italic - use \1 instead of $1
    text = text.replaceAll(
        RegExp(r'`(.*?)`'), r'\1'); // Remove code - use \1 instead of $1
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n'); // Clean line breaks
    return text.trim();
  }

  void _startContinuousTeaching(String fullContent) {
    print('Starting continuous teaching with full content...');
    ref.read(_teacherStateProvider.notifier).state = TeacherState.teaching;
    ref.read(_isTeachingProvider.notifier).state = true;

    // Clear the board and start continuous writing
    ref.read(_boardContentProvider.notifier).state = '';

    Future.delayed(const Duration(seconds: 1), () {
      _startContinuousWriting(fullContent);
    });
  }

  void _startContinuousWriting(String content) {
    print('Starting continuous writing animation...');
    _writingTimer?.cancel();

    // Start speaking the content
    _speakContent(content);

    // Animate writing the full content continuously
    _animateFullContentWriting(content);
  }

  void _animateFullContentWriting(String text) {
    _writingTimer?.cancel();

    // Clean the text to remove any formatting issues
    text = text.replaceAll(RegExp(r'\$\d+'), ''); // Remove any $1, $2, etc.
    text = text.trim();

    if (text.isEmpty) {
      print('Warning: Text is empty after cleaning');
      _onFullContentComplete();
      return;
    }

    int charIndex = 0;
    int totalLength = text.length;

    // Writing speed - adjustable for readability
    const writingSpeed = Duration(milliseconds: 50);

    ref.read(_boardContentProvider.notifier).state = '';
    print('Starting to write ${totalLength} characters');

    _writingTimer = Timer.periodic(writingSpeed, (timer) {
      if (charIndex <= totalLength) {
        String currentText = text.substring(0, charIndex);

        // Add cursor effect while writing
        if (charIndex < totalLength) {
          currentText += '|';
        }

        ref.read(_boardContentProvider.notifier).state = currentText;
        charIndex++;
      } else {
        // Writing complete - remove cursor and show final text
        ref.read(_boardContentProvider.notifier).state = text;
        timer.cancel();
        print('Writing animation completed');

        // Show completion options only when everything is done
        _onFullContentComplete();
      }
    });
  }

  void _onFullContentComplete() {
    print('Full content writing completed');
    ref.read(_isTeachingProvider.notifier).state = false;

    // Wait a moment and then show completion buttons
    Future.delayed(const Duration(seconds: 2), () {
      _showCompletionOptions();
    });
  }

  void _showCompletionOptions() {
    ref.read(_showGotItProvider.notifier).state = true;
    _speakMotivation(
        "Excellent! You've completed the entire lesson on ${widget.topic}. Did you understand everything?");
  }

  Future<void> _speakContent(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  void _handleGotItResponse(bool understood) {
    ref.read(_showGotItProvider.notifier).state = false;
    final teacherState = ref.read(_teacherStateProvider);

    print(
        'Got It Response: understood=$understood, teacherState=$teacherState');

    if (understood) {
      if (teacherState == TeacherState.answering) {
        // We just answered a question, resume teaching
        _speakMotivation("Perfect! Let's continue with our lesson.");
        _resumeTeaching();
      } else {
        // Content is complete, wrap up the lesson
        _speakMotivation("Excellent! You've understood the lesson perfectly!");
        _completeLesson();
      }
    } else {
      _speakMotivation("No worries! Let me help you understand better.");
      _handleNeedHelp();
    }
  }

  void _resumeTeaching() {
    // For continuous content, we don't resume - the lesson was already completed
    ref.read(_teacherStateProvider.notifier).state = TeacherState.teaching;
    _speakMotivation(
        "The lesson is already complete. Do you have any questions about ${widget.topic}?");
  }

  void _handleNeedHelp() {
    // Offer to explain in simpler terms or ask for specific questions
    _speakMotivation(
        "What specific part would you like me to explain again? You can ask me a question.");

    // Enable question asking
    ref.read(_teacherStateProvider.notifier).state = TeacherState.listening;

    Future.delayed(const Duration(seconds: 3), () {
      // Show the buttons again if no question is asked
      ref.read(_showGotItProvider.notifier).state = true;
    });
  }

  void _completeLesson() {
    ref.read(_isTeachingProvider.notifier).state = false;
    ref.read(_teacherStateProvider.notifier).state = TeacherState.encouraging;
    ref.read(_boardContentProvider.notifier).state =
        "🎉 Congratulations! You've completed the lesson on ${widget.topic}!\n\nGreat job! Keep up the excellent work!";
    _speakMotivation(
        "Congratulations! You've completed the lesson! Great job!");
  }

  Future<void> _speakMotivation(String message) async {
    try {
      await _flutterTts.speak(message);
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  void _handleAskQuestion() {
    // Switch to listening mode
    ref.read(_teacherStateProvider.notifier).state = TeacherState.listening;
    ref.read(_showGotItProvider.notifier).state = false;

    // Stop any ongoing timers
    _writingTimer?.cancel();

    _speakMotivation("Yes! I'm here to help. What would you like to ask?");

    // Start listening for question
    _startListening();
  }

  void _startListening() {
    if (!_speechEnabled) return;

    ref.read(_isListeningProvider.notifier).state = true;
    _speechToText.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        if (result.finalResult) {
          _handleQuestion(_lastWords);
        }
      },
    );
  }

  void _handleQuestion(String question) {
    ref.read(_isListeningProvider.notifier).state = false;

    if (question.trim().isEmpty) {
      _speakMotivation("I didn't catch that. Could you please ask again?");
      return;
    }

    ref.read(_isAnsweringProvider.notifier).state = true;
    ref.read(_teacherStateProvider.notifier).state = TeacherState.answering;
    ref.read(_boardContentProvider.notifier).state =
        'Let me think about your question...';

    _answerQuestion(question);
  }

  Future<void> _answerQuestion(String question) async {
    try {
      final studentAsync = ref.read(studentDetailsProvider);
      final student = studentAsync.valueOrNull;
      final currentContentAsync = ref.read(_contentStateProvider);
      final currentContent = currentContentAsync.valueOrNull ?? '';

      if (student == null) {
        throw Exception("Student details not available");
      }

      final contentService = ref.read(aiContentGenerationServiceProvider);
      final answer = await contentService.answerTopicQuestion(
        subject: widget.subject,
        chapter: widget.chapter,
        topic: widget.topic,
        existingContent: currentContent,
        question: question,
        studentClass: student.grade,
      );
      ref.read(_isAnsweringProvider.notifier).state = false;

      // Display the answer on board
      ref.read(_boardContentProvider.notifier).state = answer;
      _speakContent(answer);

      // After answer, ask if they understand
      Future.delayed(Duration(milliseconds: answer.length * 10 + 2000), () {
        _askIfUnderstood();
      });
    } catch (e) {
      ref.read(_isAnsweringProvider.notifier).state = false;
      ref.read(_boardContentProvider.notifier).state =
          'Sorry, I had trouble answering your question. Please try again.';
      _speakMotivation("Sorry, I had trouble with that. Please ask again.");
    }
  }

  void _askIfUnderstood() {
    _speakMotivation("Does that answer your question?");

    // Create custom buttons for question follow-up
    Future.delayed(const Duration(seconds: 1), () {
      ref.read(_showGotItProvider.notifier).state = true;
    });
  }

  void _handleSimplifyContent() {
    // Regenerate content in simpler form
    _speakMotivation("Let me explain this in simpler terms.");

    // Clear the board and prepare for new content
    ref.read(_boardContentProvider.notifier).state = '';
    ref.read(_isTeachingProvider.notifier).state = false;

    // Generate simplified content
    _generateSimplifiedContent();
  }

  Future<void> _generateSimplifiedContent() async {
    try {
      final studentAsync = ref.read(studentDetailsProvider);
      final student = studentAsync.valueOrNull;

      if (student == null) {
        throw Exception("Student details not available");
      }

      final contentService = ref.read(aiContentGenerationServiceProvider);
      final selectedLanguage = ref.read(_selectedLanguageProvider);

      // Generate simplified content in the selected language
      final simplifiedContent = await contentService.generateTopicContent(
        subject: widget.subject,
        chapter: widget.chapter,
        topic: widget.topic,
        studentClass: student.grade,
        board: student.board,
        complexityPreference: 'simple',
        additionalPromptSegment:
            'Explain this topic in very simple terms with examples, in $selectedLanguage language.',
      );

      ref.read(_contentStateProvider.notifier).state =
          AsyncValue.data(simplifiedContent);

      // Process the simplified content and restart teaching
      _processContentForTeaching(simplifiedContent);
    } catch (e) {
      print('Error generating simplified content: $e');
      _speakMotivation("Let me try to explain this differently.");
      // For continuous content, we don't need to display chunks
      Future.delayed(const Duration(seconds: 2), () {
        ref.read(_showGotItProvider.notifier).state = true;
      });
    }
  }

  void _handleLanguageSelection() {
    ref.read(_showLanguageSelectionProvider.notifier).state = true;
  }

  void _selectLanguage(String language) {
    ref.read(_selectedLanguageProvider.notifier).state = language;
    ref.read(_showLanguageSelectionProvider.notifier).state = false;

    // Set TTS language and voice based on selection
    _setTTSLanguage(language);

    _speakMotivation("Great! I'll teach you in $language now.");

    // Regenerate content in the selected language
    _generateContentInLanguage(language);
  }

  Future<void> _setTTSLanguage(String language) async {
    try {
      switch (language) {
        case 'Punjabi':
        case 'Pinglish':
          await _flutterTts.setLanguage("pa-IN"); // Punjabi India
          break;
        case 'Hinglish':
          await _flutterTts.setLanguage("hi-IN"); // Hindi India
          break;
        default:
          await _flutterTts.setLanguage("en-US"); // English US
          break;
      }
    } catch (e) {
      print('Error setting TTS language: $e');
      // Fallback to English
      await _flutterTts.setLanguage("en-US");
    }
  }

  Future<void> _generateContentInLanguage(String language) async {
    try {
      final studentAsync = ref.read(studentDetailsProvider);
      final student = studentAsync.valueOrNull;

      if (student == null) {
        throw Exception("Student details not available");
      }

      final contentService = ref.read(aiContentGenerationServiceProvider);

      // Generate comprehensive content in the selected language
      String languagePrompt;
      switch (language) {
        case 'Punjabi':
          languagePrompt =
              'Generate the entire content in Punjabi using Gurmukhi script only. Do not use any English words or Latin script.';
          break;
        case 'Hinglish':
          languagePrompt =
              'Generate the content in Hinglish - a natural mix of Hindi (Devanagari script) and English words.';
          break;
        case 'Pinglish':
          languagePrompt =
              'Generate the content in Pinglish - a natural mix of Punjabi (Gurmukhi script) and English words.';
          break;
        default:
          languagePrompt = 'Generate the content in clear, simple English.';
      }

      final languageContent = await contentService.generateTopicContent(
        subject: widget.subject,
        chapter: widget.chapter,
        topic: widget.topic,
        studentClass: student.grade,
        board: student.board,
        complexityPreference: 'medium',
        additionalPromptSegment: languagePrompt,
      );

      print(
          'Generated content in $language, length: ${languageContent.length}');

      ref.read(_contentStateProvider.notifier).state =
          AsyncValue.data(languageContent);

      // Process the new content and restart teaching
      _processContentForTeaching(languageContent);
    } catch (e) {
      print('Error generating content in $language: $e');
      _speakMotivation("I'll continue in English for now.");
      // Use fallback content in the selected language
      _useFallbackContent(language);
    }
  }

  void _useFallbackContent(String language) {
    String fallbackContent;

    switch (language) {
      case 'Punjabi':
        fallbackContent = '''
ਸਤ ਸ੍ਰੀ ਅਕਾਲ! ਅੱਜ ਅਸੀਂ ${widget.topic} ਬਾਰੇ ਵਿਸਤਾਰ ਨਾਲ ਸਿੱਖਾਂਗੇ।

${widget.topic} ਇੱਕ ਬਹੁਤ ਮਹੱਤਵਪੂਰਨ ਵਿਸ਼ਾ ਹੈ ਜੋ ${widget.subject} ਵਿੱਚ ਬੁਨਿਆਦੀ ਗਿਆਨ ਪ੍ਰਦਾਨ ਕਰਦਾ ਹੈ।

ਪਹਿਲਾਂ ਅਸੀਂ ਸਮਝਾਂਗੇ ਕਿ ${widget.topic} ਕੀ ਹੈ ਅਤੇ ਇਸਦੀ ਪਰਿਭਾਸ਼ਾ ਕੀ ਹੈ।

ਫਿਰ ਅਸੀਂ ਇਸ ਵਿਸ਼ੇ ਦੇ ਮੁੱਖ ਨੁਕਤਿਆਂ ਅਤੇ ਸਿਧਾਂਤਾਂ ਬਾਰੇ ਜਾਣਾਂਗੇ।

ਮਿਸਾਲਾਂ ਦੇ ਜ਼ਰੀਏ ਅਸੀਂ ਇਸ ਵਿਸ਼ੇ ਨੂੰ ਹੋਰ ਸਪੱਸ਼ਟ ਤਰੀਕੇ ਨਾਲ ਸਮਝਾਂਗੇ।

ਪ੍ਰੈਕਟੀਕਲ ਲਾਗੂਕਰਨ ਅਤੇ ਰੋਜ਼ਾਨਾ ਜ਼ਿੰਦਗੀ ਵਿੱਚ ਇਸਦੀ ਉਪਯੋਗਤਾ ਬਾਰੇ ਸਿੱਖਾਂਗੇ।

ਪਾਠ ਦੇ ਅੰਤ ਵਿੱਚ ਤੁਸੀਂ ${widget.topic} ਦੀ ਸੰਪੂਰਨ ਸਮਝ ਪ੍ਰਾਪਤ ਕਰ ਲਓਗੇ।

ਜੇ ਕੋਈ ਸਵਾਲ ਹੋਵੇ ਤਾਂ ਬੇਝਿਜਕ ਪੁੱਛਣਾ - ਸਿੱਖਣਾ ਇੱਕ ਸਾਂਝਾ ਸਫ਼ਰ ਹੈ!

ਵਧਾਈਆਂ! ਤੁਸੀਂ ${widget.topic} ਦਾ ਸੰਪੂਰਨ ਪਾਠ ਪੂਰਾ ਕਰ ਲਿਆ ਹੈ।
        ''';
        break;
      case 'Hinglish':
        fallbackContent = '''
नमस्ते! आज हम ${widget.topic} के बारे में detail में सीखेंगे।

${widget.topic} एक बहुत important topic है जो ${widget.subject} में fundamental knowledge प्रदान करता है।

पहले हम समझेंगे कि ${widget.topic} क्या है और इसकी definition क्या है।

फिर हम इस topic के main points और principles के बारे में जानेंगे।

Examples के through हम इस topic को और clear तरीके से समझेंगे।

Practical applications और daily life में इसकी usefulness के बारे में सीखेंगे।

Lesson के end में आप ${widget.topic} की complete understanding प्राप्त कर लेंगे।

अगर कोई questions हों तो freely पूछना - learning एक shared journey है!

Congratulations! आपने ${widget.topic} का complete lesson finish कर लिया है।
        ''';
        break;
      case 'Pinglish':
        fallbackContent = '''
ਸਤ ਸ੍ਰੀ ਅਕਾਲ! Today ਅਸੀਂ ${widget.topic} ਬਾਰੇ detail ਵਿੱਚ ਸਿੱਖਾਂਗੇ।

${widget.topic} ਇੱਕ ਬਹੁਤ important topic ਹੈ ਜੋ ${widget.subject} ਵਿੱਚ fundamental knowledge ਪ੍ਰਦਾਨ ਕਰਦਾ ਹੈ।

ਪਹਿਲਾਂ ਅਸੀਂ understand ਕਰਾਂਗੇ ਕਿ ${widget.topic} ਕੀ ਹੈ ਅਤੇ ਇਸਦੀ definition ਕੀ ਹੈ।

ਫਿਰ ਅਸੀਂ ਇਸ topic ਦੇ main points ਅਤੇ principles ਬਾਰੇ ਜਾਣਾਂਗੇ।

Examples ਦੇ through ਅਸੀਂ ਇਸ topic ਨੂੰ ਹੋਰ clear ਤਰੀਕੇ ਨਾਲ ਸਮਝਾਂਗੇ।

Practical applications ਅਤੇ daily life ਵਿੱਚ ਇਸਦੀ usefulness ਬਾਰੇ ਸਿੱਖਾਂਗੇ।

Lesson ਦੇ end ਵਿੱਚ ਤੁਸੀਂ ${widget.topic} ਦੀ complete understanding ਪ੍ਰਾਪਤ ਕਰ ਲਓਗੇ।

ਜੇ ਕੋਈ questions ਹੋਣ ਤਾਂ freely ਪੁੱਛਣਾ - learning ਇੱਕ shared journey ਹੈ!

Congratulations! ਤੁਸੀਂ ${widget.topic} ਦਾ complete lesson finish ਕਰ ਲਿਆ ਹੈ।
        ''';
        break;
      default:
        fallbackContent = '''
Welcome to our comprehensive lesson on ${widget.topic}!

Today we will explore ${widget.topic} in detail and understand its importance in ${widget.subject}.

Let's start by understanding what ${widget.topic} means and why it's crucial for students to learn.

${widget.topic} is a fundamental concept that forms the building blocks for advanced topics in ${widget.subject}.

We'll cover the basic definitions, key concepts, and practical applications of ${widget.topic}.

Through this lesson, you'll learn how ${widget.topic} is used in real-world scenarios and everyday life.

Understanding ${widget.topic} will help you develop problem-solving skills and logical thinking.

Let's explore different aspects of ${widget.topic} with clear explanations and examples.

By the end of this lesson, you'll have a solid foundation in ${widget.topic} and be ready for more advanced concepts.

Remember to ask questions if anything is unclear - learning is a journey we take together!

Congratulations on completing this comprehensive lesson on ${widget.topic}!
        ''';
    }

    _processContentForTeaching(fallbackContent);
  }

  void _startWelcomeSequence() async {
    // Show welcome message first
    await Future.delayed(const Duration(milliseconds: 500));
    _welcomeController.forward();

    // Then show board after welcome message
    await Future.delayed(const Duration(milliseconds: 2000));
    _boardController.forward();
  }

  @override
  void dispose() {
    _starsController.dispose();
    _welcomeController.dispose();
    _boardController.dispose();
    _teachingController.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    _questionController.dispose();
    _teachingTimer?.cancel();
    _writingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentDetailsProvider);
    final studentName = studentAsync.valueOrNull?.name ?? 'Student';
    final showGotIt = ref.watch(_showGotItProvider);
    final isTeaching = ref.watch(_isTeachingProvider);
    final isListening = ref.watch(_isListeningProvider);
    final isAnswering = ref.watch(_isAnsweringProvider);
    final showLanguageSelection = ref.watch(_showLanguageSelectionProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Professional Classroom Background
          _buildProfessionalClassroomBackground(),

          // Motivational Welcome Message
          _buildWelcomeMessage(studentName),

          // Interactive Chalkboard with Content
          _buildInteractiveChalkboard(),

          // Control Buttons (Ask Question, Simplify, Language)
          _buildClassroomControls(),

          // "Got It?" Buttons
          if (showGotIt) _buildGotItButtons(),

          // Question Input (when listening)
          if (isListening) _buildQuestionInput(),

          // Language Selection (when requested)
          if (showLanguageSelection) _buildLanguageSelection(),

          // Teaching Status Indicators
          _buildTeachingStatusIndicators(isTeaching, isAnswering),
        ],
      ),
    );
  }

  Widget _buildProfessionalClassroomBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1426), // Deep dark blue - professional classroom
            Color(0xFF1A1D29), // Dark charcoal blue
            Color(0xFF0D1117), // GitHub dark theme inspired
            Color(0xFF161B22), // Deep professional gray
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Single layer: Lightweight moving stars
          _buildLightweightStars(),

          // Beautiful Green Chalkboard - Student Loving Design (with animation)
          AnimatedBuilder(
            animation: _boardController,
            builder: (context, child) {
              return Transform.scale(
                scale: _boardController.value,
                child: Opacity(
                  opacity: _boardController.value,
                  child: _buildBeautifulChalkboard(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLightweightStars() {
    return AnimatedBuilder(
      animation: _starsController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: LightweightStarsPainter(_starsController.value),
        );
      },
    );
  }

  Widget _buildBeautifulChalkboard() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.5,
        child: CustomPaint(
          painter: BeautifulChalkboardPainter(),
          child: Container(
            padding: EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chalkboard Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        widget.subject.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.yellow.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Ch. ${widget.chapter}',
                          style: TextStyle(
                            color: Colors.yellow.shade300,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 15),

                // Decorative chalk line
                Container(
                  height: 2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Main Topic Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Topic:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.topic,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 25),

                // Static message for initial board state
                Expanded(
                  child: Center(
                    child: Text(
                      "Let's begin our lesson!\nI'll write the content here as we learn together.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(String studentName) {
    return AnimatedBuilder(
      animation: _welcomeController,
      builder: (context, child) {
        return Opacity(
          opacity: _welcomeController.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _welcomeController.value) * -50),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.3),
                          Colors.blue.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "🌟 Welcome, $studentName! 🌟",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.purple.withOpacity(0.8),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveChalkboard() {
    final boardContent = ref.watch(_boardContentProvider);
    final isTeaching = ref.watch(_isTeachingProvider);

    return AnimatedBuilder(
      animation: _boardController,
      builder: (context, child) {
        return Transform.scale(
          scale: _boardController.value,
          child: Opacity(
            opacity: _boardController.value,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.5,
                margin: const EdgeInsets.only(top: 80),
                child: CustomPaint(
                  painter: InteractiveChalkboardPainter(
                    content: boardContent,
                    animationValue: _teachingController.value,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Board Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "AI Teacher Board",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isTeaching)
                              Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 16,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "Writing...",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        SizedBox(height: 20),
                        // Content Area - NO SCROLLING, only current chunk
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.topLeft,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              // Subtle inner shadow to simulate depth
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: -2,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: boardContent.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.auto_stories,
                                          color: Colors.white.withOpacity(0.4),
                                          size: 48,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "Ready to learn!\nContent will appear here as I teach.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.6),
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    padding: EdgeInsets.zero,
                                    child: AnimatedDefaultTextStyle(
                                      duration: Duration(milliseconds: 300),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        height: 1.8,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Text(boardContent),
                                    ),
                                  ),
                          ),
                        ),

                        // Bottom decorative line
                        Container(
                          height: 1,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassroomControls() {
    final isTeaching = ref.watch(_isTeachingProvider);
    final teacherState = ref.watch(_teacherStateProvider);
    final selectedLanguage = ref.watch(_selectedLanguageProvider);

    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.help_outline,
            label: "Ask Question",
            color: Colors.blue,
            onTap: teacherState != TeacherState.listening
                ? _handleAskQuestion
                : null,
          ),
          _buildControlButton(
            icon: Icons.auto_fix_high,
            label: "Simplify",
            color: Colors.orange,
            onTap: isTeaching ? _handleSimplifyContent : null,
          ),
          _buildControlButton(
            icon: Icons.language,
            label: selectedLanguage,
            color: Colors.purple,
            onTap: _handleLanguageSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(onTap != null ? 0.2 : 0.1),
          border: Border.all(
            color: color.withOpacity(onTap != null ? 0.6 : 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(onTap != null ? 1.0 : 0.5),
              size: 24,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(onTap != null ? 1.0 : 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGotItButtons() {
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGotItButton(
            label: "Got it! ✅",
            color: Colors.green,
            onTap: () => _handleGotItResponse(true),
          ),
          _buildGotItButton(
            label: "Need help🤔",
            color: Colors.orange,
            onTap: () => _handleGotItResponse(false),
          ),
        ],
      ),
    );
  }

  Widget _buildGotItButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: Colors.red, size: 24),
                const SizedBox(width: 10),
                Text(
                  "Listening... Ask your question!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _questionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Or type your question here...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    if (_questionController.text.trim().isNotEmpty) {
                      _handleQuestion(_questionController.text.trim());
                      _questionController.clear();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachingStatusIndicators(bool isTeaching, bool isAnswering) {
    final isListening = ref.watch(_isListeningProvider);
    final teacherState = ref.watch(_teacherStateProvider);

    return Positioned(
      top: 40,
      right: 20,
      child: Column(
        children: [
          if (teacherState == TeacherState.welcome)
            _buildStatusIndicator("Preparing Lesson 📚", Colors.blue),
          if (isTeaching) _buildStatusIndicator("Teaching 📝", Colors.green),
          if (isListening) _buildStatusIndicator("Listening 👂", Colors.purple),
          if (isAnswering) _buildStatusIndicator("Thinking 🤔", Colors.orange),
          if (teacherState == TeacherState.encouraging)
            _buildStatusIndicator("Celebrating 🎉", Colors.pink),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLanguageSelection() {
    final languages = ['English', 'Hindi', 'Punjabi', 'Hinglish', 'Pinglish'];

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.9),
              Colors.blue.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "🌍 Choose Your Language",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    ref.read(_showLanguageSelectionProvider.notifier).state =
                        false;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...languages.map((language) => _buildLanguageOption(language)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    final selectedLanguage = ref.watch(_selectedLanguageProvider);
    final isSelected = selectedLanguage == language;

    return GestureDetector(
      onTap: () => _selectLanguage(language),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: Colors.white,
            ),
            const SizedBox(width: 15),
            Text(
              language,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================
// LIGHTWEIGHT CUSTOM PAINTER
// ================================

class LightweightStarsPainter extends CustomPainter {
  final double animationValue;

  LightweightStarsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = math.Random(42); // Fixed seed for consistent positions

    // Create only 15 stars for optimal mobile performance
    for (int i = 0; i < 15; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      // Slow horizontal movement across the screen
      final x = (baseX + animationValue * size.width * 0.1) % size.width;
      final y = baseY;

      // Subtle twinkling effect
      final twinklePhase = (animationValue * 2 + i * 0.5) % 1.0;
      final brightness = 0.3 + (math.sin(twinklePhase * 2 * math.pi) + 1) * 0.2;

      // Professional white stars only
      paint.color = Colors.white.withOpacity(brightness);

      // Small, consistent size for performance
      final starSize = 1.5;

      // Simple circle stars for best performance
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ================================
// BEAUTIFUL CHALKBOARD PAINTER - UNIQUE PROFESSIONAL DESIGN
// ================================

class BeautifulChalkboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final strokePaint = Paint()..style = PaintingStyle.stroke;

    // Create unique hexagonal chalkboard with rounded corners
    final path = Path();
    final radius = 25.0;
    final cornerRadius = 15.0;

    // Start creating the unique shape - modified hexagon with elegant curves
    path.moveTo(radius + cornerRadius, 0);

    // Top edge with gentle curve
    path.lineTo(size.width * 0.8 - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width * 0.8, cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Upper right slanted edge
    path.lineTo(size.width - cornerRadius, size.height * 0.25);
    path.arcToPoint(
      Offset(size.width, size.height * 0.25 + cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Right edge
    path.lineTo(size.width, size.height * 0.75 - cornerRadius);
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height * 0.75),
      radius: Radius.circular(cornerRadius),
    );

    // Lower right slanted edge
    path.lineTo(size.width * 0.8, size.height - cornerRadius);
    path.arcToPoint(
      Offset(size.width * 0.8 - cornerRadius, size.height),
      radius: Radius.circular(cornerRadius),
    );

    // Bottom edge
    path.lineTo(radius + cornerRadius, size.height);
    path.arcToPoint(
      Offset(radius, size.height - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Lower left slanted edge
    path.lineTo(0, size.height * 0.75);
    path.arcToPoint(
      Offset(cornerRadius, size.height * 0.75 - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Left edge
    path.lineTo(cornerRadius, size.height * 0.25 + cornerRadius);
    path.arcToPoint(
      Offset(0, size.height * 0.25),
      radius: Radius.circular(cornerRadius),
    );

    // Upper left slanted edge
    path.lineTo(radius, cornerRadius);
    path.arcToPoint(
      Offset(radius + cornerRadius, 0),
      radius: Radius.circular(cornerRadius),
    );

    path.close();

    // Draw the main chalkboard background with premium gradient
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Color(0xFF2E5A3E), // Rich forest green center
        Color(0xFF1E4530), // Medium forest green
        Color(0xFF0F2A1F), // Deep forest green
        Color(0xFF081A12), // Very dark forest green edges
      ],
      stops: [0.0, 0.4, 0.8, 1.0],
    );

    paint.shader =
        gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    // Draw premium wooden frame with multiple layers
    // Outer frame (dark brown)
    strokePaint.color = Color(0xFF654321); // Dark brown
    strokePaint.strokeWidth = 12;
    canvas.drawPath(path, strokePaint);

    // Middle frame (medium brown)
    strokePaint.color = Color(0xFF8B4513); // Saddle brown
    strokePaint.strokeWidth = 8;
    canvas.drawPath(path, strokePaint);

    // Inner frame (light brown)
    strokePaint.color = Color(0xFFD2691E); // Peru brown
    strokePaint.strokeWidth = 4;
    canvas.drawPath(path, strokePaint);

    // Add elegant corner decorations
    paint.color = Color(0xFFFFD700); // Gold
    paint.style = PaintingStyle.fill;

    // Corner decorations - stylized academic symbols
    _drawAcademicCornerDecoration(canvas, Offset(40, 40), 15, paint);
    _drawAcademicCornerDecoration(
        canvas, Offset(size.width - 40, 40), 15, paint);
    _drawAcademicCornerDecoration(
        canvas, Offset(40, size.height - 40), 15, paint);
    _drawAcademicCornerDecoration(
        canvas, Offset(size.width - 40, size.height - 40), 15, paint);

    // Add premium chalk holder with realistic details
    final chalkHolderPath = Path();
    final holderY = size.height - 30;
    final holderWidth = size.width * 0.6;
    final holderX = (size.width - holderWidth) / 2;

    chalkHolderPath.moveTo(holderX, holderY);
    chalkHolderPath.lineTo(holderX + holderWidth, holderY);
    chalkHolderPath.lineTo(holderX + holderWidth - 10, holderY + 15);
    chalkHolderPath.lineTo(holderX + 10, holderY + 15);
    chalkHolderPath.close();

    // Draw chalk holder with gradient
    final holderGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFCD853F), Color(0xFF8B4513)],
    );
    paint.shader = holderGradient
        .createShader(Rect.fromLTWH(holderX, holderY, holderWidth, 15));
    canvas.drawPath(chalkHolderPath, paint);

    // Add realistic chalk pieces with shadows
    paint.shader = null;
    final chalkColors = [
      Colors.white,
      Color(0xFFFFF8DC), // Cream
      Color(0xFFFFB6C1), // Light pink
      Color(0xFF87CEEB), // Sky blue
      Color(0xFFFFE4B5), // Light yellow
    ];

    for (int i = 0; i < 5; i++) {
      final chalkX = holderX + 20 + i * (holderWidth - 40) / 4;
      final chalkY = holderY + 3;

      // Draw chalk shadow
      paint.color = Colors.black.withOpacity(0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chalkX + 2, chalkY + 2, holderWidth * 0.12, 8),
          Radius.circular(4),
        ),
        paint,
      );

      // Draw chalk piece
      paint.color = chalkColors[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chalkX, chalkY, holderWidth * 0.12, 8),
          Radius.circular(4),
        ),
        paint,
      );

      // Add chalk highlight
      paint.color = chalkColors[i].withOpacity(0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chalkX + 1, chalkY + 1, holderWidth * 0.08, 2),
          Radius.circular(1),
        ),
        paint,
      );
    }

    // Add subtle chalk dust texture
    paint.color = Colors.white.withOpacity(0.05);
    paint.style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final dustX = random.nextDouble() * size.width;
      final dustY = random.nextDouble() * size.height;
      canvas.drawCircle(
          Offset(dustX, dustY), random.nextDouble() * 2 + 1, paint);
    }

    // Add professional grid lines (very subtle)
    strokePaint.color = Colors.white.withOpacity(0.08);
    strokePaint.strokeWidth = 0.5;

    // Horizontal lines
    for (double y = 80; y < size.height - 80; y += 40) {
      canvas.drawLine(
        Offset(60, y),
        Offset(size.width - 60, y),
        strokePaint,
      );
    }

    // Add academic-style border pattern
    strokePaint.color = Colors.white.withOpacity(0.15);
    strokePaint.strokeWidth = 2;

    final innerBorderPath = Path();
    innerBorderPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(25, 25, size.width - 50, size.height - 50),
        Radius.circular(12),
      ),
    );
    canvas.drawPath(innerBorderPath, strokePaint);
  }

  void _drawAcademicCornerDecoration(
      Canvas canvas, Offset center, double radius, Paint paint) {
    // Draw academic laurel wreath-style decoration
    paint.color = Color(0xFFFFD700).withOpacity(0.8);

    // Outer circle
    canvas.drawCircle(center, radius, paint);

    // Inner circle with different shade
    paint.color = Color(0xFFDDD700);
    canvas.drawCircle(center, radius * 0.7, paint);

    // Academic symbol (book/scroll)
    paint.color = Color(0xFF8B4513);
    final bookRect = Rect.fromCenter(
      center: center,
      width: radius * 0.8,
      height: radius * 0.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bookRect, Radius.circular(2)),
      paint,
    );

    // Book spine
    paint.color = Color(0xFF654321);
    canvas.drawLine(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.2),
      Offset(center.dx - radius * 0.3, center.dy + radius * 0.2),
      Paint()
        ..strokeWidth = 2
        ..color = Color(0xFF654321),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class InteractiveChalkboardPainter extends CustomPainter {
  final String content;
  final double animationValue;

  InteractiveChalkboardPainter({
    required this.content,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw chalkboard background with beautiful design
    paint.color = const Color(0xFF0D4F3C); // Deep forest green
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    canvas.drawRRect(boardRect, paint);

    // Draw wooden frame
    paint.color = const Color(0xFF8B4513); // Saddle brown
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 15;
    canvas.drawRRect(boardRect, paint);

    // Draw inner frame details
    paint.strokeWidth = 3;
    paint.color = const Color(0xFFCD853F); // Peru
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(15),
    );
    canvas.drawRRect(innerRect, paint);

    // Add some texture lines on the board
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white.withOpacity(0.1);
    for (int i = 0; i < 8; i++) {
      final y = (size.height / 8) * (i + 1);
      canvas.drawLine(
        Offset(30, y),
        Offset(size.width - 30, y),
        paint..strokeWidth = 1,
      );
    }

    // Add corner decorations
    paint.color = const Color(0xFFFFD700); // Gold
    paint.style = PaintingStyle.fill;
    _drawCornerDecoration(canvas, Offset(20, 20), 8);
    _drawCornerDecoration(canvas, Offset(size.width - 20, 20), 8);
    _drawCornerDecoration(canvas, Offset(20, size.height - 20), 8);
    _drawCornerDecoration(canvas, Offset(size.width - 20, size.height - 20), 8);
  }

  void _drawCornerDecoration(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);

    paint.color = const Color(0xFFDDD700);
    canvas.drawCircle(center, radius * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
