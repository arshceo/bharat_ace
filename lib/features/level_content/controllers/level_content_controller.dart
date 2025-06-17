// lib/features/level_content/controllers/level_content_controller.dart
import 'dart:async';
import 'package:flutter/material.dart'; // For TextRange
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Core imports (adjust paths if your structure differs)
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/models/content_block_model.dart';
import 'package:bharat_ace/core/services/ai_content_service.dart';
import 'package:bharat_ace/core/services/content_cache_service.dart';
import 'package:bharat_ace/core/services/markdown_parser_service.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';

// Feature-specific providers
import '../providers/level_content_providers.dart';

// Arguments for the LevelContentController
typedef LevelContentArgs = ({
  String subject,
  String chapterId,
  String levelName,
  ChapterDetailed chapterData
});

class LevelContentController
    extends StateNotifier<AsyncValue<List<ContentBlockModel>>> {
  final String levelCacheKeyBase;
  final String subject;
  final String chapterId;
  final String levelName;
  final ChapterDetailed chapterData;
  final Ref ref;
  final FlutterTts flutterTts = FlutterTts();

  List<String> _textChunks = [];
  int _currentChunkIndex = 0;
  final Map<String, ({int startCleaned, int endCleaned})>
      _blockCleanedTextOffsetMap = {};

  // Public getter for the screen to access this map
  Map<String, ({int startCleaned, int endCleaned})>
      get blockCleanedTextOffsetMap => _blockCleanedTextOffsetMap;

  LevelContentController(this.levelCacheKeyBase, this.subject, this.chapterId,
      this.levelName, this.chapterData, this.ref)
      : super(const AsyncValue.loading()) {
    _initTts();
    loadOrGenerateLevelContent();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // Public method for the screen to use
  String cleanTextForTTS(String rawText) => _cleanTextForTTS(rawText);

  String _cleanTextForTTS(String rawText) {
    String cleaned = rawText;
    cleaned = cleaned.replaceAll(RegExp(r'#+\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'(\*\*|__)(.*?)\1'), r'$2');
    cleaned = cleaned.replaceAll(RegExp(r'(\*|_)(.*?)\1'), r'$2');
    cleaned = cleaned.replaceAll(RegExp(r'~~(.*?)~~'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'---\s*'), ' . ');
    cleaned = cleaned.replaceAll(RegExp(r'>\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'!\[.*?\]\(.*?\)\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[(.*?)\]\(.*?\)\s*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'`{1,3}(.*?)`{1,3}'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  void _updateAndMapCurrentSpokenText(List<ContentBlockModel>? blocks) {
    _blockCleanedTextOffsetMap.clear();
    if (blocks != null && blocks.isNotEmpty) {
      StringBuffer combinedCleanedTextBuffer = StringBuffer();
      int currentGlobalCleanedOffset = 0;

      for (var block in blocks) {
        if (block.type != ContentBlockType.image &&
            block.type != ContentBlockType.horizontalRule &&
            block.type != ContentBlockType.codeBlock &&
            block.rawContent.trim().isNotEmpty) {
          String cleanedBlockContent = _cleanTextForTTS(block.rawContent);
          if (cleanedBlockContent.isNotEmpty) {
            if (combinedCleanedTextBuffer.isNotEmpty) {
              combinedCleanedTextBuffer
                  .write("\n\n"); // Separator for distinct blocks
              currentGlobalCleanedOffset += 2;
            }
            _blockCleanedTextOffsetMap[block.id] = (
              startCleaned: currentGlobalCleanedOffset,
              endCleaned:
                  currentGlobalCleanedOffset + cleanedBlockContent.length
            );
            combinedCleanedTextBuffer.write(cleanedBlockContent);
            currentGlobalCleanedOffset += cleanedBlockContent.length;
          } else {
            _blockCleanedTextOffsetMap[block.id] = (
              startCleaned:
                  currentGlobalCleanedOffset, // Still map empty blocks
              endCleaned: currentGlobalCleanedOffset
            );
          }
        } else {
          // For non-textual blocks or empty raw content
          _blockCleanedTextOffsetMap[block.id] = (
            startCleaned: currentGlobalCleanedOffset,
            endCleaned: currentGlobalCleanedOffset
          );
        }
      }
      final fullText = combinedCleanedTextBuffer.toString();
      ref.read(currentSpokenTextProvider.notifier).state = fullText;
    } else {
      ref.read(currentSpokenTextProvider.notifier).state = "";
    }
  }

  List<String> _splitTextIntoChunks(String text, {int chunkSize = 2000}) {
    if (text.isEmpty) return [];
    List<String> chunks = [];
    int textLength = text.length;
    for (int i = 0; i < textLength;) {
      int end = i + chunkSize;
      if (end >= textLength) {
        end = textLength;
      } else {
        int lastGoodBreak = -1;
        int searchStartForBreaks =
            (i + chunkSize * 2 / 3).round().clamp(i, end - 1);

        int doubleNewline = text.lastIndexOf('\n\n', end - 1);
        if (doubleNewline > i &&
            doubleNewline < end &&
            doubleNewline >= searchStartForBreaks) {
          lastGoodBreak = doubleNewline + 2;
        }

        if (lastGoodBreak == -1) {
          int singleNewline = text.lastIndexOf('\n', end - 1);
          if (singleNewline > i &&
              singleNewline < end &&
              singleNewline >= searchStartForBreaks) {
            lastGoodBreak = singleNewline + 1;
          }
        }

        if (lastGoodBreak == -1) {
          int lastPeriod = text.lastIndexOf('.', end - 1);
          if (lastPeriod > i &&
              lastPeriod < end &&
              lastPeriod >= searchStartForBreaks) {
            lastGoodBreak = lastPeriod + 1;
          }
        }

        if (lastGoodBreak > i && lastGoodBreak <= end) {
          end = lastGoodBreak;
        } else {
          int fallbackDoubleNewline = text.lastIndexOf('\n\n', end - 1);
          if (fallbackDoubleNewline > i && fallbackDoubleNewline < end) {
            lastGoodBreak = fallbackDoubleNewline + 2;
          } else {
            int fallbackSingleNewline = text.lastIndexOf('\n', end - 1);
            if (fallbackSingleNewline > i && fallbackSingleNewline < end) {
              lastGoodBreak = fallbackSingleNewline + 1;
            } else {
              int fallbackPeriod = text.lastIndexOf('.', end - 1);
              if (fallbackPeriod > i && fallbackPeriod < end) {
                lastGoodBreak = fallbackPeriod + 1;
              }
            }
          }
          if (lastGoodBreak > i && lastGoodBreak <= end) end = lastGoodBreak;
        }
      }
      String chunk = text.substring(i, end).trim();
      if (chunk.isNotEmpty) chunks.add(chunk);
      i = end;
    }
    return chunks;
  }

  Future<void> _speakCurrentChunk() async {
    if (_currentChunkIndex >= _textChunks.length || !mounted) {
      ref.read(ttsStateProvider.notifier).state = TtsState.stopped;
      ref.read(currentSpeakingIdProvider.notifier).state = null;
      ref.read(ttsRestartOffsetProvider.notifier).state = 0;
      return;
    }
    final chunkToSpeak = _textChunks[_currentChunkIndex];
    try {
      var result = await flutterTts.speak(chunkToSpeak);
      if (result != 1 && mounted) {
        ref.read(ttsStateProvider.notifier).state = TtsState.error;
        ref.read(currentSpeakingIdProvider.notifier).state = null;
      }
    } catch (e) {
      if (mounted) {
        ref.read(ttsStateProvider.notifier).state = TtsState.error;
        ref.read(currentSpeakingIdProvider.notifier).state = null;
      }
    }
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setSharedInstance(true);
      await flutterTts.setSpeechRate(0.45);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      flutterTts.setStartHandler(() {
        if (mounted) {
          ref.read(ttsStateProvider.notifier).state = TtsState.playing;
        }
      });

      flutterTts.setCompletionHandler(() {
        if (!mounted) return;
        final currentSpeakingIdVal = ref.read(currentSpeakingIdProvider);
        if (currentSpeakingIdVal == "full_content_audio" &&
            _currentChunkIndex < _textChunks.length - 1) {
          _currentChunkIndex++;
          _speakCurrentChunk();
        } else {
          ref.read(ttsStateProvider.notifier).state = TtsState.stopped;
          ref.read(currentSpeakingIdProvider.notifier).state = null;
          ref.read(ttsHighlightRangeProvider.notifier).state = null;
          ref.read(ttsRestartOffsetProvider.notifier).state = 0;
          _textChunks = [];
          _currentChunkIndex = 0;
        }
      });

      flutterTts.setErrorHandler((msg) {
        if (mounted) {
          ref.read(ttsStateProvider.notifier).state = TtsState.error;
          ref.read(currentSpeakingIdProvider.notifier).state = null;
          ref.read(ttsHighlightRangeProvider.notifier).state = null;
          ref.read(ttsRestartOffsetProvider.notifier).state = 0;
        }
      });

      flutterTts.setProgressHandler(
          (String utteranceText, int localStart, int localEnd, String word) {
        if (!mounted) return;
        final String fullCleanedOriginalText =
            ref.read(currentSpokenTextProvider);
        if (fullCleanedOriginalText.isEmpty ||
            _textChunks.isEmpty ||
            _currentChunkIndex >= _textChunks.length) {
          return;
        }

        int globalBaseOffsetForThisSeries = ref.read(ttsRestartOffsetProvider);
        int accumulatedLengthOfPreviousChunksInThisSeries = 0;
        for (int i = 0; i < _currentChunkIndex; i++) {
          if (i < _textChunks.length) {
            // Safety check
            accumulatedLengthOfPreviousChunksInThisSeries +=
                _textChunks[i].length;
          }
        }

        int globalHighlightStart = globalBaseOffsetForThisSeries +
            accumulatedLengthOfPreviousChunksInThisSeries +
            localStart;
        int globalHighlightEnd = globalBaseOffsetForThisSeries +
            accumulatedLengthOfPreviousChunksInThisSeries +
            localEnd;

        if (globalHighlightStart <= globalHighlightEnd &&
            globalHighlightEnd <= fullCleanedOriginalText.length) {
          if (localStart < localEnd) {
            // Prefer explicit start/end from TTS
            ref.read(ttsHighlightRangeProvider.notifier).state =
                TextRange(start: globalHighlightStart, end: globalHighlightEnd);
          } else if (localStart == localEnd && word.isNotEmpty) {
            // Fallback to word if start == end
            int estimatedEnd = globalHighlightStart + word.length;
            if (estimatedEnd <= fullCleanedOriginalText.length) {
              ref.read(ttsHighlightRangeProvider.notifier).state =
                  TextRange(start: globalHighlightStart, end: estimatedEnd);
            }
          }
        }
      });
    } catch (e) {
      if (mounted) ref.read(ttsStateProvider.notifier).state = TtsState.error;
    }
  }

  Future<void> speakFullContent() async {
    await stopTts();
    final String fullCleanedText = ref.read(currentSpokenTextProvider);

    if (fullCleanedText.trim().isEmpty) {
      if (mounted) {
        ref.read(ttsStateProvider.notifier).state = TtsState.stopped;
      }
      return;
    }
    ref.read(ttsRestartOffsetProvider.notifier).state =
        0; // Start from beginning

    _textChunks = _splitTextIntoChunks(fullCleanedText, chunkSize: 2000);
    _currentChunkIndex = 0;

    if (_textChunks.isEmpty) {
      if (mounted) {
        ref.read(ttsStateProvider.notifier).state = TtsState.stopped;
        ref.read(currentSpeakingIdProvider.notifier).state = null;
      }
      return;
    }
    const String fullContentAudioId = "full_content_audio";
    ref.read(currentSpeakingIdProvider.notifier).state = fullContentAudioId;
    ref.read(ttsStateProvider.notifier).state = TtsState.buffering;

    final currentLang = ref.read(targetLanguageProvider);
    String ttsLangCode = "en-US";
    switch (currentLang) {
      case TargetLanguage.hindi:
        ttsLangCode = "hi-IN";
        break;
      case TargetLanguage.punjabiEnglish:
      case TargetLanguage.hinglish:
        ttsLangCode = "en-IN";
        break;
      default: // TargetLanguage.english
        ttsLangCode = "en-US";
    }

    try {
      await flutterTts.setLanguage(ttsLangCode);
      await _speakCurrentChunk();
    } catch (e) {
      if (mounted) {
        ref.read(ttsStateProvider.notifier).state = TtsState.error;
        ref.read(currentSpeakingIdProvider.notifier).state = null;
      }
    }
  }

  Future<void> speakFromOffset(int globalTargetOffset) async {
    await stopTts();
    final String fullCleanedText = ref.read(currentSpokenTextProvider);

    if (fullCleanedText.isEmpty ||
        globalTargetOffset >= fullCleanedText.length) {
      // Cannot speak from this offset
      if (mounted) ref.read(ttsStateProvider.notifier).state = TtsState.stopped;
      return;
    }

    ref.read(ttsRestartOffsetProvider.notifier).state = globalTargetOffset;
    String textToStartSpeakingFrom =
        fullCleanedText.substring(globalTargetOffset);
    _textChunks =
        _splitTextIntoChunks(textToStartSpeakingFrom, chunkSize: 2000);
    _currentChunkIndex = 0;

    if (_textChunks.isEmpty) {
      if (mounted) ref.read(ttsStateProvider.notifier).state = TtsState.stopped;
      return;
    }

    const String fullContentAudioId =
        "full_content_audio"; // Re-using the same ID
    ref.read(currentSpeakingIdProvider.notifier).state = fullContentAudioId;
    ref.read(ttsStateProvider.notifier).state = TtsState.buffering;

    final currentLang = ref.read(targetLanguageProvider);
    String ttsLangCode = "en-US";
    switch (currentLang) {
      case TargetLanguage.hindi:
        ttsLangCode = "hi-IN";
        break;
      case TargetLanguage.punjabiEnglish:
      case TargetLanguage.hinglish:
        ttsLangCode = "en-IN";
        break;
      default:
        ttsLangCode = "en-US";
    }
    try {
      await flutterTts.setLanguage(ttsLangCode);
      await _speakCurrentChunk();
    } catch (e) {
      if (mounted) {
        ref.read(ttsStateProvider.notifier).state = TtsState.error;
        ref.read(currentSpeakingIdProvider.notifier).state = null;
      }
    }
  }

  Future<void> stopTts() async {
    try {
      var result = await flutterTts.stop();
      if (result == 1 && mounted) {
        ref.read(ttsStateProvider.notifier).state = TtsState.stopped;
        ref.read(currentSpeakingIdProvider.notifier).state = null;
        ref.read(ttsHighlightRangeProvider.notifier).state = null;
        ref.read(ttsRestartOffsetProvider.notifier).state = 0;
        _textChunks = [];
        _currentChunkIndex = 0;
      }
    } catch (e) {
      // Handle or log error if necessary
    }
  }

  List<Topic> _getTopicsForCurrentLevel() {
    final levelData = chapterData.levels.firstWhere(
        (lvl) => lvl.levelName == levelName,
        orElse: () => Level(
            levelName: levelName, // Default empty level if not found
            learningObjectives: [],
            topics: [],
            assessmentCriteria:
                AssessmentCriteria.fromJson({}))); // Provide default
    return levelData.topics;
  }
// lib/features/level_content/controllers/level_content_controller.dart
// ...

  Future<void> loadOrGenerateLevelContent({
    bool forceRegenerate = false,
    String? complexity,
    TargetLanguage? language, // This parameter is nullable
  }) async {
    final student = ref.read(studentDetailsProvider);
    final userClassLevel = student.value?.grade ?? '6';

    // --- MODIFICATION START ---
    // Ensure currentTargetLanguage is non-nullable.
    // targetLanguageProvider should ideally be non-nullable.
    final TargetLanguage currentTargetLanguage =
        language ?? ref.read(targetLanguageProvider);
    // --- MODIFICATION END ---

    if (!mounted) return;
    state = const AsyncValue.loading();
    await stopTts();

    String languagePromptSegment = "";
    switch (currentTargetLanguage) {
      // Now safe to use without null check
      case TargetLanguage.punjabiEnglish:
        languagePromptSegment =
            " in Punjabi and English (mixed, like commonly spoken)";
        break;
      case TargetLanguage.hindi:
        languagePromptSegment = " in clear Hindi";
        break;
      case TargetLanguage.hinglish:
        languagePromptSegment = " in Hinglish (colloquial Hindi-English mix)";
        break;
      default: // TargetLanguage.english
        languagePromptSegment = "";
    }

    // --- MODIFICATION: currentTargetLanguage is now guaranteed non-null ---
    final String currentLevelCacheKey =
        "${levelCacheKeyBase}_${currentTargetLanguage.name}";
    // ---

    // Note: levelCacheKeyBase is "${subject}_${chapterId}_${levelName}"

    // --- MODIFICATION: currentTargetLanguage is now guaranteed non-null ---
    print(
        "CONTROLLER: Using cache key: $currentLevelCacheKey for $subject, $chapterId, $levelName, ${currentTargetLanguage.name}");
    // ---

    try {
      List<ContentBlockModel>? parsedBlocks;
      bool fromCache = false;

      if (!forceRegenerate) {
        final String? cachedContentString = await ref
            .read(contentCacheServiceProvider)
            .getCachedContent(currentLevelCacheKey);
        if (cachedContentString != null && cachedContentString.isNotEmpty) {
          parsedBlocks = parseMarkdownToBlocks(cachedContentString);
          fromCache = true;
          print(
              "CONTROLLER: Content loaded from CACHE for $currentLevelCacheKey");
        } else {
          print(
              "CONTROLLER: No cache found for $currentLevelCacheKey or cache empty.");
        }
      } else {
        print(
            "CONTROLLER: Force regenerating, skipping cache for $currentLevelCacheKey.");
      }

      if (!fromCache) {
        print("CONTROLLER: Generating new content for $currentLevelCacheKey.");
        final contentService = ref.read(aiContentGenerationServiceProvider);
        String rawMarkdownContent;

        if (levelName.toLowerCase() == 'prerequisites') {
          final content = await contentService.generatePrerequisiteExplanation(
              subject: subject,
              chapterTitle: chapterData.chapterTitle,
              prerequisites: chapterData.prerequisites,
              studentClass: userClassLevel,
              additionalPromptSegment:
                  "Explain these prerequisites$languagePromptSegment.");
          String title = chapterData.prerequisites.isNotEmpty
              ? "# Prerequisites for ${chapterData.chapterTitle}"
              : "# Foundational Knowledge for ${chapterData.chapterTitle}";
          rawMarkdownContent = "$title\n\n$content";
        } else {
          final topicsInLevel = _getTopicsForCurrentLevel();
          if (topicsInLevel.isEmpty) {
            rawMarkdownContent =
                "## Content Coming Soon!\n\nWe're working on the $levelName level$languagePromptSegment.";
          } else {
            StringBuffer combinedContentString = StringBuffer();
            combinedContentString
                .writeln("# $levelName Level: ${chapterData.chapterTitle}\n");
            if (chapterData.description.isNotEmpty) {
              combinedContentString.writeln("> ${chapterData.description}\n");
            }

            for (final topic in topicsInLevel) {
              String topicContent = await contentService.generateTopicContent(
                  subject: subject,
                  chapter: chapterData.chapterTitle,
                  topic: topic.topicTitle,
                  studentClass: userClassLevel,
                  board: student.value?.board ?? '',
                  complexityPreference: complexity ?? levelName.toLowerCase(),
                  additionalPromptSegment:
                      "Explain this topic$languagePromptSegment.");
              combinedContentString
                  .writeln("## ${topic.topicTitle}\n$topicContent\n\n---\n");
            }
            rawMarkdownContent = combinedContentString.toString().trim();
          }
        }
        parsedBlocks = parseMarkdownToBlocks(rawMarkdownContent);
        await ref
            .read(contentCacheServiceProvider)
            .saveContentToCache(currentLevelCacheKey, rawMarkdownContent);
        print(
            "CONTROLLER: New content saved to CACHE for $currentLevelCacheKey");
      }

      if (mounted && parsedBlocks != null) {
        state = AsyncValue.data(parsedBlocks);
        _updateAndMapCurrentSpokenText(parsedBlocks);
      } else if (mounted && parsedBlocks == null) {
        state = AsyncValue.error(
            "Failed to load or generate content.", StackTrace.current);
        _updateAndMapCurrentSpokenText(null);
      }
    } catch (e, stack) {
      if (mounted) state = AsyncValue.error(e, stack);
      print("CONTROLLER: Error in loadOrGenerateLevelContent: $e \n$stack");
      ref.read(currentSpokenTextProvider.notifier).state = "";
      _blockCleanedTextOffsetMap.clear();
    }
  }

// ... rest of the controller
  Future<void> answerQuestion(String question) async {
    if (question.trim().isEmpty) return;
    final studentDetails = ref.read(studentDetailsProvider);
    final userClassLevel = studentDetails.value?.grade ?? '6';

    if (studentDetails.value == null) {
      // Handle case where student details are not available
      ref.read(qaHistoryProvider.notifier).update((h) => [
            ...h,
            {
              'q': question,
              'a': 'Student details needed to provide a tailored answer.',
              'state': 'error'
            }
          ]);
      return;
    }

    ref.read(isAnsweringProvider.notifier).state = true;
    // Add question immediately with "thinking" state
    final thinkingEntry = {
      'q': question,
      'a': 'Guru is thinking...',
      'state': 'thinking'
    };
    ref.read(qaHistoryProvider.notifier).update((h) => [...h, thinkingEntry]);

    final currentTargetLanguage = ref.read(targetLanguageProvider);
    String languageQAPromptSegment = "";
    switch (currentTargetLanguage) {
      case TargetLanguage.punjabiEnglish:
        languageQAPromptSegment =
            " Please answer in Punjabi and English (mixed).";
        break;
      case TargetLanguage.hindi:
        languageQAPromptSegment = " Please answer in Hindi.";
        break;
      case TargetLanguage.hinglish:
        languageQAPromptSegment = " Please answer in Hinglish.";
        break;
      default: // English
        break;
    }

    // Get current content as context for better answers
    String currentContentContext =
        "Regarding $levelName of ${chapterData.chapterTitle}:\n${ref.read(currentSpokenTextProvider)}";

    try {
      final contentService = ref.read(aiContentGenerationServiceProvider);
      final answer = await contentService.answerTopicQuestion(
          subject: subject,
          chapter: chapterData.chapterTitle,
          topic: levelName, // Use levelName as the broad topic for QA
          existingContent: currentContentContext, // Provide more context
          question: question,
          studentClass: userClassLevel,
          additionalPromptSegment: languageQAPromptSegment);

      // Update the "thinking" entry with the actual answer
      ref.read(qaHistoryProvider.notifier).update((h) {
        final list = List<Map<String, String>>.from(h);
        final index = list.indexWhere(
            (item) => item['q'] == question && item['state'] == 'thinking');
        if (index != -1) {
          list[index] = {'q': question, 'a': answer, 'state': 'answered'};
        } else {
          // Should not happen if "thinking" entry was added
          list.add({'q': question, 'a': answer, 'state': 'answered'});
        }
        return list;
      });
    } catch (e) {
      ref.read(qaHistoryProvider.notifier).update((h) {
        final list = List<Map<String, String>>.from(h);
        final index = list.indexWhere(
            (item) => item['q'] == question && item['state'] == 'thinking');
        if (index != -1) {
          list[index] = {
            'q': question,
            'a': 'Sorry, an error occurred: ${e.toString()}',
            'state': 'error'
          };
        } else {
          list.add({
            'q': question,
            'a': 'Sorry, an error occurred: ${e.toString()}',
            'state': 'error'
          });
        }
        return list;
      });
    } finally {
      if (mounted) ref.read(isAnsweringProvider.notifier).state = false;
    }
  }
}

// Provider for the LevelContentController
final levelContentControllerProvider = StateNotifierProvider.autoDispose.family<
    LevelContentController,
    AsyncValue<List<ContentBlockModel>>,
    LevelContentArgs>(
  (ref, args) => LevelContentController(
      "${args.subject}_${args.chapterId}_${args.levelName}", // Cache key base
      args.subject,
      args.chapterId,
      args.levelName,
      args.chapterData,
      ref),
);
