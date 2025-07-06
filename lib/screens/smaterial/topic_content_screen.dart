// lib/screens/smaterial/topic_content_screen.dart

import 'package:animate_do/animate_do.dart' show FadeIn;
import 'package:bharat_ace/core/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

// New imports
import 'package:markdown/markdown.dart' as md_parser;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:bharat_ace/core/theme/app_colors.dart'; // Assuming AppColors are used for styling
import 'package:bharat_ace/core/utils/color_extensions.dart'; // Your color extension

// Import necessary providers and services
import '../../core/services/ai_content_service.dart';
import '../../core/services/content_cache_service.dart';
import '../../core/providers/student_details_provider.dart';

// --- State Management for this Screen ---
final _topicContentStateProvider =
    StateProvider.autoDispose<AsyncValue<String>>(
        (ref) => const AsyncValue.loading());
final _isListeningProvider = StateProvider.autoDispose<bool>((ref) => false);
final _isAnsweringProvider = StateProvider.autoDispose<bool>((ref) => false);
final _qaHistoryProvider =
    StateProvider.autoDispose<List<Map<String, String>>>((ref) => []);

// --- Main Widget ---
class TopicContentScreen extends ConsumerStatefulWidget {
  final String chapter;
  final String topic;
  final String subject;

  const TopicContentScreen({
    super.key,
    required this.chapter,
    required this.topic,
    required this.subject,
  });

  @override
  ConsumerState<TopicContentScreen> createState() => _TopicContentScreenState();
}

class _TopicContentScreenState extends ConsumerState<TopicContentScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = "";
  @override
  void initState() {
    super.initState();
    _initializeServicesAndLoadContent();
  }

  void _initializeServicesAndLoadContent() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _initSpeech();
        if (mounted) {
          _loadOrGenerateContent();
        }
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

  Future<void> _initSpeech() async {
    if (!mounted) return;
    print("Initializing Speech Recognition...");
    try {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        _speechEnabled = await _speechToText.initialize(
            onError: (errorNotification) =>
                print('Speech Init Error: $errorNotification'),
            onStatus: (status) {
              print('Speech Status: $status');
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
      _speechEnabled = false;
    }
    if (mounted) setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled || _speechToText.isListening || !mounted) return;
    print("Starting speech listening...");
    ref.read(_isListeningProvider.notifier).state = true;
    setState(() {
      _lastWords = "";
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            _lastWords = result.recognizedWords;
            _questionController.text = _lastWords;
            _questionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _questionController.text.length));
            print("Recognized: $_lastWords");
            if (result.finalResult) {
              if (mounted) {
                ref.read(_isListeningProvider.notifier).state = false;
              }
            }
          }
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: "en_IN",
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      print("Error starting speech recognition: $e");
      if (mounted) ref.read(_isListeningProvider.notifier).state = false;
    }
    if (mounted) setState(() {});
  }

  void _stopListening() async {
    if (!_speechEnabled || !_speechToText.isListening || !mounted) return;
    print("Stopping speech listening...");
    try {
      await _speechToText.stop();
    } catch (e) {
      print("Error stopping speech recognition: $e");
    } finally {
      if (mounted) {
        ref.read(_isListeningProvider.notifier).state = false;
        setState(() {});
      }
    }
  }

  Future<void> _loadOrGenerateContent(
      {bool forceRegenerate = false, String? complexity}) async {
    if (!mounted) return;
    ref.read(_topicContentStateProvider.notifier).state =
        const AsyncValue.loading();
    ref.read(_qaHistoryProvider.notifier).state = [];

    final cacheService = ref.read(contentCacheServiceProvider);
    final String? cachedContent = forceRegenerate
        ? null
        : await cacheService.getCachedContent(widget.topic);

    if (cachedContent != null && cachedContent.isNotEmpty) {
      print("Content loaded from cache for ${widget.topic}.");
      if (mounted) {
        ref.read(_topicContentStateProvider.notifier).state =
            AsyncValue.data(cachedContent);
      }
    } else {
      print(forceRegenerate
          ? "Regenerating content for ${widget.topic}..."
          : "Generating content for ${widget.topic}...");
      final AsyncValue<StudentModel?> studentAsync =
          ref.read(studentDetailsProvider);
      final StudentModel? student = studentAsync.valueOrNull;

      if (student == null) {
        print(
            "TopicContentScreen: Student details are null. Cannot generate content.");
        if (mounted) {
          ref.read(_topicContentStateProvider.notifier).state =
              AsyncValue.error(
                  "Student details not available.", StackTrace.current);
        }
        return;
      }
      if (student.grade.isEmpty) {
        print(
            "TopicContentScreen: Student grade is empty. Cannot generate content tailored to grade.");
        if (mounted) {
          ref.read(_topicContentStateProvider.notifier).state =
              AsyncValue.error(
                  "Student grade information is missing.", StackTrace.current);
        }
        return;
      }

      try {
        final contentService = ref.read(aiContentGenerationServiceProvider);
        print(
            "Generating content with class: ${student.grade}, board: ${student.board ?? "Not specified"}");
        final generatedContent = await contentService.generateTopicContent(
          subject: widget.subject,
          chapter: widget.chapter,
          topic: widget.topic,
          studentClass: student.grade,
          board: student.board,
          complexityPreference: complexity,
        );
        if (mounted) {
          cacheService.saveContentToCache(widget.topic, generatedContent);
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

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || !mounted) return;

    final currentContentAsync = ref.read(_topicContentStateProvider);
    final currentContent = currentContentAsync.valueOrNull;
    if (currentContent == null || currentContent.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Content not loaded yet to ask a question."),
            backgroundColor: Colors.orange));
      }
      return;
    }

    final AsyncValue<StudentModel?> studentAsync =
        ref.read(studentDetailsProvider);
    final StudentModel? student = studentAsync.valueOrNull;
    if (student == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Student details missing. Cannot process question."),
            backgroundColor: Colors.red));
      }
      return;
    }
    if (student.grade.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Student grade is missing. Cannot tailor answer."),
            backgroundColor: Colors.orange));
      }
      return;
    }

    _questionController.clear();
    if (mounted) FocusScope.of(context).unfocus();
    ref.read(_isAnsweringProvider.notifier).state = true;
    ref.read(_qaHistoryProvider.notifier).update((state) => [
          ...state,
          {'q': question, 'a': 'Thinking...'}
        ]);
    _scrollToBottom();

    try {
      final contentService = ref.read(aiContentGenerationServiceProvider);
      print("Answering question with student class: ${student.grade}");
      final answer = await contentService.answerTopicQuestion(
        subject: widget.subject,
        chapter: widget.chapter,
        topic: widget.topic,
        existingContent: currentContent,
        question: question,
        studentClass: student.grade,
      );
      if (mounted) {
        ref.read(_qaHistoryProvider.notifier).update((state) {
          var updatedHistory = List<Map<String, String>>.from(state);
          if (updatedHistory.isNotEmpty &&
              updatedHistory.last['q'] == question) {
            updatedHistory.last = {'q': question, 'a': answer};
          }
          return updatedHistory;
        });
      }
    } catch (e) {
      if (mounted) {
        ref.read(_qaHistoryProvider.notifier).update((state) {
          var updatedHistory = List<Map<String, String>>.from(state);
          if (updatedHistory.isNotEmpty &&
              updatedHistory.last['q'] == question) {
            updatedHistory.last = {
              'q': question,
              'a': 'Sorry, an error occurred while getting an answer.'
            };
          }
          return updatedHistory;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error getting answer: ${e.toString()}"),
            backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) ref.read(_isAnsweringProvider.notifier).state = false;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print("🔧 TopicContentScreen BUILD: Cat teacher button should be VISIBLE!");
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
          contentState.maybeWhen(
            loading: () => const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
            orElse: () => PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: "More Options",
                onSelected: (value) {
                  if (value == 'regenerate') {
                    _loadOrGenerateContent(forceRegenerate: true);
                  } else if (value == 'simplify')
                    // ignore: curly_braces_in_flow_control_structures
                    _loadOrGenerateContent(
                        forceRegenerate: true, complexity: 'simple');
                  else if (value == 'clear_cache')
                    ref
                        .read(contentCacheServiceProvider)
                        .clearCacheForTopic(widget.topic)
                        .then((_) => _loadOrGenerateContent());
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
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              children: [
                contentState.when(
                  data: (content) {
                    final htmlContent = md_parser.markdownToHtml(
                      content,
                      extensionSet: md_parser.ExtensionSet.gitHubWeb,
                    );
                    return FadeIn(
                      child: HtmlWidget(
                        // Use HtmlWidget for main content
                        htmlContent,
                        textStyle: textTheme.bodyLarge?.copyWith(height: 1.5),
                        customStylesBuilder: (element) {
                          // Basic styling for HtmlWidget, expand as needed
                          if (element.localName == 'h1') {
                            return {
                              'font-size':
                                  '${textTheme.headlineMedium?.fontSize}px',
                              'font-weight': 'bold'
                            };
                          }
                          if (element.localName == 'h2') {
                            return {
                              'font-size':
                                  '${textTheme.headlineSmall?.fontSize}px',
                              'font-weight': 'bold'
                            };
                          }
                          if (element.localName == 'h3') {
                            return {
                              'font-size':
                                  '${textTheme.titleLarge?.fontSize}px',
                              'font-weight': 'bold'
                            };
                          }
                          if (element.localName == 'code') {
                            return {
                              'font-family':
                                  GoogleFonts.firaCode().fontFamily ??
                                      'monospace',
                              'background-color': colorScheme
                                  .surfaceContainerHighest
                                  .toCssRgbaString(),
                              // Assuming AppColors were similar to theme colors
                              'padding': '2px 4px', 'border-radius': '4px',
                            };
                          }
                          if (element.localName == 'pre' &&
                              element.children.isNotEmpty &&
                              element.children.first.localName == 'code') {
                            return {
                              'background-color': colorScheme.surfaceVariant
                                  .toCssRgbaString(), // Slightly different background for pre
                              'padding': '12px', 'margin': '8px 0px',
                              'border-radius': '8px', 'overflow': 'auto',
                              'border':
                                  '1px solid ${colorScheme.outlineVariant.toCssRgbaString()}',
                            };
                          }
                          return null;
                        },
                      ),
                    );
                  },
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
                                onPressed: () => _loadOrGenerateContent(),
                                icon: const Icon(Icons.refresh),
                                label: const Text("Retry"))
                          ]))),
                ),
                if (qaHistory.isNotEmpty) ...[
                  const Divider(height: 40, thickness: 1),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text("Questions & Answers",
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold))),
                  ...qaHistory
                      .map((qa) => _buildQACard(context, qa['q']!, qa['a']!)),
                  const SizedBox(height: 20),
                ]
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 8.0, top: 8.0, bottom: 8.0),
              decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                      top: BorderSide(
                          color: colorScheme.outline.withOpacity(0.5)))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      enabled: !isAnswering,
                      decoration: InputDecoration(
                          hintText: isListening
                              ? "Listening..."
                              : "Ask about \"${widget.topic}\"",
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10)),
                      textInputAction: TextInputAction.send,
                      onSubmitted: isAnswering ? null : (_) => _askQuestion(),
                      maxLines: 1,
                    ),
                  ),
                  if (_speechEnabled)
                    IconButton(
                      icon: Icon(isListening ? Icons.mic_off : Icons.mic),
                      color: isListening
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      tooltip:
                          isListening ? "Stop listening" : "Ask with voice",
                      onPressed: isAnswering
                          ? null
                          : (isListening ? _stopListening : _startListening),
                    ),
                  IconButton(
                    icon: isAnswering
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    color: colorScheme.primary,
                    tooltip: "Ask Question",
                    onPressed:
                        isAnswering || _questionController.text.trim().isEmpty
                            ? null
                            : _askQuestion,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQACard(BuildContext context, String question, String answer) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Convert Markdown answer to HTML
    final String htmlAnswer = md_parser.markdownToHtml(
      answer,
      extensionSet: md_parser.ExtensionSet.gitHubWeb,
    );

    return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(width: 26),
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
                            child: HtmlWidget(
                              // Use HtmlWidget for answer
                              htmlAnswer,
                              textStyle:
                                  textTheme.bodyMedium?.copyWith(height: 1.4),
                              customStylesBuilder: (element) {
                                // Basic styling for HtmlWidget, expand as needed
                                if (element.localName == 'code') {
                                  return {
                                    'font-family':
                                        GoogleFonts.firaCode().fontFamily ??
                                            'monospace',
                                    'background-color': colorScheme
                                        .surfaceContainerHighest
                                        .toCssRgbaString(),
                                    'padding': '2px 4px',
                                    'border-radius': '4px',
                                  };
                                }
                                if (element.localName == 'pre' &&
                                    element.children.isNotEmpty &&
                                    element.children.first.localName ==
                                        'code') {
                                  return {
                                    'background-color': colorScheme
                                        .surfaceVariant
                                        .toCssRgbaString(),
                                    'padding': '12px',
                                    'margin': '8px 0px',
                                    'border-radius': '8px',
                                    'overflow': 'auto',
                                    'border':
                                        '1px solid ${colorScheme.outlineVariant.toCssRgbaString()}',
                                  };
                                }
                                return null;
                              },
                            ),
                          )))
          ])
        ]));
  }
}
