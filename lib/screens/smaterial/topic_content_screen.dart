// --- lib/screens/smaterial/topic_content_screen.dart (Complete & Corrected) ---

import 'package:animate_do/animate_do.dart' show FadeIn;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // To render generated markdown
import 'package:speech_to_text/speech_to_text.dart'; // For voice input
import 'package:permission_handler/permission_handler.dart'; // For mic permission

// Import necessary providers and services (Ensure paths are correct)
import '../../core/services/ai_content_service.dart';
import '../../core/services/content_cache_service.dart';
import '../../core/providers/student_details_provider.dart'; // Needed for class/board context

// --- State Management for this Screen ---
// State for the main content (loading, data, error)
final _topicContentStateProvider =
    StateProvider.autoDispose<AsyncValue<String>>((ref) => const AsyncValue
        .loading()); // autoDispose cleans up when screen is left

// State for voice input listening status
final _isListeningProvider = StateProvider.autoDispose<bool>((ref) => false);

// State for loading indicator when answering a question
final _isAnsweringProvider = StateProvider.autoDispose<bool>((ref) => false);

// State for Q&A history
final _qaHistoryProvider = StateProvider.autoDispose<List<Map<String, String>>>(
    (ref) => []); // List of {'q': question, 'a': answer}

// --- Main Widget ---
class TopicContentScreen extends ConsumerStatefulWidget {
  final String chapter;
  final String topic;
  final String subject; // Subject is now required

  const TopicContentScreen({
    super.key,
    required this.chapter,
    required this.topic,
    required this.subject,
    // Removed sectionData - content is generated/fetched internally
  });

  @override
  ConsumerState<TopicContentScreen> createState() => _TopicContentScreenState();
}

class _TopicContentScreenState extends ConsumerState<TopicContentScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = ""; // Holds words recognized by speech recognizer

  @override
  void initState() {
    super.initState();
    _initializeServicesAndLoadContent();
  }

  // Helper to run async init tasks
  void _initializeServicesAndLoadContent() async {
    // Initialize speech *after* the first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initSpeech(); // Request permission and initialize speech
      // Trigger content load after speech init (or concurrently if desired)
      if (mounted) {
        // Check if still mounted after async gap
        _loadOrGenerateContent();
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  /// Initializes speech recognition & requests permission
  Future<void> _initSpeech() async {
    if (!mounted) return; // Avoid operations if widget is disposed
    print("Initializing Speech Recognition...");
    try {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        _speechEnabled = await _speechToText.initialize(
            onError: (errorNotification) =>
                print('Speech Init Error: $errorNotification'),
            onStatus: (status) {
              print('Speech Status: $status');
              // Automatically stop listening state if speech service stops unexpectedly
              if (mounted &&
                  status != SpeechToText.listeningStatus &&
                  ref.read(_isListeningProvider)) {
                ref.read(_isListeningProvider.notifier).state = false;
              }
            });
        if (!_speechEnabled && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Speech recognition not available/enabled.")));
        } else {
          print("Speech Recognition Initialized: $_speechEnabled");
        }
      } else {
        print('Microphone permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Microphone permission needed.")));
        }
      }
    } catch (e) {
      print("Exception initializing speech: $e");
      _speechEnabled = false; // Ensure it's false on error
    }
    // Update the UI if needed after init completes
    if (mounted) setState(() {});
  }

  /// Starts listening for speech input
  void _startListening() async {
    if (!_speechEnabled || _speechToText.isListening) return;
    print("Starting speech listening...");
    ref.read(_isListeningProvider.notifier).state =
        true; // Update state *before* async call
    setState(() {
      _lastWords = "";
    }); // Clear previous words

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            // Update text field continuously with recognized words
            _lastWords = result.recognizedWords;
            _questionController.text = _lastWords;
            // Move cursor to end
            _questionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _questionController.text.length));
            print("Recognized: $_lastWords");
            // Check if speech recognition finished
            if (result.finalResult) {
              if (mounted) {
                ref.read(_isListeningProvider.notifier).state = false;
              }
            }
          }
        },
        listenFor: const Duration(seconds: 20), // Listen for up to 20 seconds
        pauseFor:
            const Duration(seconds: 3), // Stop if user pauses for 3 seconds
        partialResults: true, // Get results as they come
        localeId: "en_IN", // Specify locale if needed (e.g., Indian English)
        cancelOnError: true, // Stop listening if an error occurs
        listenMode: ListenMode.confirmation, // Example mode
      );
      // Note: The 'listening' state might update via the onStatus callback in _initSpeech
    } catch (e) {
      print("Error starting speech recognition: $e");
      if (mounted) {
        ref.read(_isListeningProvider.notifier).state =
            false; // Reset state on error
      }
    }
    // setState required to update the mic icon potentially
    if (mounted) setState(() {});
  }

  /// Stops listening for speech input
  void _stopListening() async {
    if (!_speechEnabled || !_speechToText.isListening) return;
    print("Stopping speech listening...");
    try {
      await _speechToText.stop();
    } catch (e) {
      print("Error stopping speech recognition: $e");
    } finally {
      if (mounted) {
        ref.read(_isListeningProvider.notifier).state =
            false; // Ensure state is updated
      }
      if (mounted) setState(() {}); // Update UI if needed
    }
  }

  /// Loads content from cache or generates it using AI.
  /// `forceRegenerate`: Skips cache check.
  /// `complexity`: Hint for regeneration ('simple', 'detailed').
  Future<void> _loadOrGenerateContent(
      {bool forceRegenerate = false, String? complexity}) async {
    if (!mounted) return;
    ref.read(_topicContentStateProvider.notifier).state =
        const AsyncValue.loading(); // Show loading
    ref.read(_qaHistoryProvider.notifier).state = []; // Clear Q&A

    final cacheService =
        ref.read(contentCacheServiceProvider); // Read cache service
    final String? cachedContent = forceRegenerate
        ? null
        : await cacheService.getCachedContent(
            widget.subject, widget.chapter, widget.topic);

    if (cachedContent != null && cachedContent.isNotEmpty) {
      print("Content loaded from cache.");
      if (mounted) {
        ref.read(_topicContentStateProvider.notifier).state =
            AsyncValue.data(cachedContent);
      }
    } else {
      print(forceRegenerate
          ? "Regenerating content..."
          : "Generating content...");
      final student = ref.read(studentDetailsProvider); // Get student details
      if (student == null || student.grade.isEmpty) {
        if (mounted) {
          ref.read(_topicContentStateProvider.notifier).state =
              AsyncValue.error("Student details missing.", StackTrace.current);
        }
        return;
      }

      try {
        final contentService = ref.read(
            aiContentGenerationServiceProvider); // Read generation service
        final generatedContent = await contentService.generateTopicContent(
          subject: widget.subject,
          chapter: widget.chapter,
          topic: widget.topic,
          studentClass: student.grade,
          board: student.board,
          complexityPreference: complexity,
        );
        if (mounted) {
          // Save to cache asynchronously (don't wait for it)
          cacheService.saveContentToCache(
              widget.subject, widget.chapter, widget.topic, generatedContent);
          // Update state with generated content
          ref.read(_topicContentStateProvider.notifier).state =
              AsyncValue.data(generatedContent);
        }
      } catch (e, stack) {
        if (mounted) {
          ref.read(_topicContentStateProvider.notifier).state =
              AsyncValue.error(e, stack);
        }
      }
    }
  }

  /// Handles asking a question about the current topic.
  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    final currentContentAsync = ref.read(_topicContentStateProvider);
    final currentContent =
        currentContentAsync.valueOrNull; // Get current content safely
    if (currentContent == null) {
      /* Show error: content not loaded */ return;
    }
    final student = ref.read(studentDetailsProvider);
    if (student == null) {
      /* Show error: student details missing */ return;
    }

    _questionController.clear();
    if (mounted) FocusScope.of(context).unfocus();
    ref.read(_isAnsweringProvider.notifier).state = true;
    // Add question optimistically with "Thinking..." answer
    ref.read(_qaHistoryProvider.notifier).update((state) => [
          ...state,
          {'q': question, 'a': 'Thinking...'}
        ]);
    // Scroll down after adding question
    _scrollToBottom();

    try {
      final contentService = ref.read(aiContentGenerationServiceProvider);
      final answer = await contentService.answerTopicQuestion(
        subject: widget.subject,
        chapter: widget.chapter,
        topic: widget.topic,
        existingContent: currentContent,
        question: question,
        studentClass: student.grade,
      );
      // Update the last history entry with the real answer
      ref.read(_qaHistoryProvider.notifier).update((state) {
        var updatedHistory = List<Map<String, String>>.from(state);
        if (updatedHistory.isNotEmpty) {
          updatedHistory.last = {'q': question, 'a': answer};
        }
        return updatedHistory;
      });
    } catch (e) {
      /* Update last history entry with error message */
      ref.read(_qaHistoryProvider.notifier).update((state) {
        var updatedHistory = List<Map<String, String>>.from(state);
        if (updatedHistory.isNotEmpty) {
          updatedHistory.last = {
            'q': question,
            'a': 'Sorry, error getting answer.'
          };
        }
        return updatedHistory;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: $e"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) ref.read(_isAnsweringProvider.notifier).state = false;
      _scrollToBottom(); // Scroll down after answer/error
    }
  }

  // Helper function to scroll the ListView to the bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<String> contentState =
        ref.watch(_topicContentStateProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isListening = ref.watch(_isListeningProvider);
    final bool isAnswering = ref.watch(_isAnsweringProvider);
    final List<Map<String, String>> qaHistory = ref.watch(_qaHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic,
            style: textTheme.titleLarge?.copyWith(fontSize: 18),
            overflow: TextOverflow.ellipsis),
        actions: [
          // Refresh / Regenerate Button (Combined)
          contentState.maybeWhen(
            loading: () => const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
            orElse: () => PopupMenuButton<String>(
                // Keep Popup for other options
                icon: const Icon(Icons.more_vert),
                tooltip: "More Options",
                onSelected: (value) {
                  if (value == 'regenerate') {
                    _loadOrGenerateContent(forceRegenerate: true);
                  } else if (value == 'simplify')
                    _loadOrGenerateContent(
                        forceRegenerate: true, complexity: 'simple');
                  else if (value == 'clear_cache')
                    ref
                        .read(contentCacheServiceProvider)
                        .clearCacheForTopic(
                            widget.subject, widget.chapter, widget.topic)
                        .then(
                            (_) => _loadOrGenerateContent()); // Add clear cache
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                          value: 'regenerate',
                          child: Row(children: [
                            Icon(Icons.refresh, size: 18),
                            SizedBox(width: 8),
                            Text('Regenerate')
                          ])),
                      const PopupMenuItem<String>(
                          value: 'simplify',
                          child: Row(children: [
                            Icon(Icons.lightbulb_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Simplify')
                          ])),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                          value: 'clear_cache',
                          child: Row(children: [
                            Icon(Icons.delete_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Clear Cache')
                          ])),
                    ]),
          ),
        ],
      ),
      body: Column(
        // Use Column for Content + Input Bar
        children: [
          Expanded(
            child: ListView(
              // Main scrollable area for content and Q&A history
              controller: _scrollController, // Attach controller
              padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 0), // Padding for content
              children: [
                // --- Generated Content Section ---
                contentState.when(
                  data: (content) => FadeIn(
                    // Add subtle fade-in
                    child: MarkdownBody(
                      data: content, selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(
                              Theme.of(context))
                          .copyWith(
                              /* ... styles ... */ p:
                                  textTheme.bodyLarge?.copyWith(height: 1.5),
                              h1: textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              h2: textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              h3: textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              code: GoogleFonts.firaCode(
                                  backgroundColor: colorScheme
                                      .surfaceContainerHighest)), // Example code style
                    ),
                  ),
                  loading: () => Center(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 64.0),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text("Generating Content...",
                                style: textTheme.bodyMedium)
                          ]))),
                  error: (error, stack) => Center(
                      child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.error_outline,
                                color: colorScheme.error, size: 40),
                            const SizedBox(height: 10),
                            Text(
                                "Error generating content:\n${error.toString()}",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colorScheme.error)),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                                onPressed: _loadOrGenerateContent,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Retry"))
                          ]))),
                ),
                // --- Q&A History Section ---
                if (qaHistory.isNotEmpty) ...[
                  const Divider(height: 40, thickness: 1),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text("Questions & Answers",
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold))),
                  ...qaHistory
                      .map((qa) => _buildQACard(context, qa['q']!, qa['a']!)),
                  const SizedBox(height: 20), // Space at the bottom of list
                ]
              ],
            ),
          ),

          // --- Q&A Input Bar ---
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 8.0,
                  top: 8.0,
                  bottom: 8.0), // Adjusted padding
              decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                      top: BorderSide(
                          color: colorScheme.outline.withOpacity(0.5)))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController, enabled: !isAnswering,
                      decoration: InputDecoration(
                          hintText: isListening
                              ? "Listening..."
                              : "Ask about \"${widget.topic}\"",
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10)),
                      textInputAction:
                          TextInputAction.send, // Change action to send
                      onSubmitted: isAnswering
                          ? null
                          : (_) => _askQuestion(), // Send on submit
                      maxLines: 1, // Single line input
                    ),
                  ),
                  // Voice Input Button
                  if (_speechEnabled)
                    IconButton(
                      icon: Icon(isListening
                          ? Icons.mic_off
                          : Icons.mic), // Use filled mic when listening
                      color: isListening
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      tooltip:
                          isListening ? "Stop listening" : "Ask with voice",
                      onPressed: isAnswering
                          ? null
                          : (isListening ? _stopListening : _startListening),
                    ),
                  // Send Button
                  IconButton(
                    icon: isAnswering
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded), // Rounded send icon
                    color: colorScheme.primary, tooltip: "Ask Question",
                    onPressed:
                        isAnswering || _questionController.text.trim().isEmpty
                            ? null
                            : _askQuestion, // Disable if answering or empty
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Q&A Card Widget
  Widget _buildQACard(BuildContext context, String question, String answer) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
        // Use container instead of Padding for background later?
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Question
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(Icons.help_outline_rounded,
                    size: 18, color: colorScheme.primary)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(question,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)))
          ]),
          const SizedBox(height: 8),
          // Answer
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(width: 26), // Indent answer slightly
            Expanded(
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: answer == 'Thinking...'
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                            const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 8),
                            Text(answer, style: textTheme.bodyMedium)
                          ])
                        : FadeIn(
                            child: MarkdownBody(
                                data: answer,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                        Theme.of(context))
                                    .copyWith(
                                        p: textTheme.bodyMedium
                                            ?.copyWith(height: 1.4),
                                        code: GoogleFonts.firaCode(
                                            backgroundColor: colorScheme
                                                .surfaceContainerHighest)))) // Render answer as Markdown
                    ))
          ])
        ]));
  }
}
