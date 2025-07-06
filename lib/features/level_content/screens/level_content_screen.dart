import 'dart:async';
import 'dart:collection'; // For SplayTreeMap
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/widgets/level_content_screen_widgets/content_block_widget.dart';
import 'package:bharat_ace/widgets/level_content_screen_widgets/custom_selection_controls.dart';
import 'package:bharat_ace/widgets/level_content_screen_widgets/level_content_app_bar_actions.dart';
import 'package:bharat_ace/widgets/level_content_screen_widgets/level_content_error_ui.dart';
import 'package:bharat_ace/widgets/level_content_screen_widgets/level_content_loading_ui.dart';
import 'package:bharat_ace/widgets/level_content_screen_widgets/qa_card_widget.dart';
import 'package:bharat_ace/widgets/level_content_screen_widgets/qa_input_bar_widget.dart';
import 'package:bharat_ace/widgets/level_content_screen_widgets/test_knowledge_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Core imports
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/models/content_block_model.dart';
import 'package:bharat_ace/core/services/content_cache_service.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/utils/text_theme_utils.dart';

// Feature-specific imports
import '../controllers/level_content_controller.dart';
import '../providers/level_content_providers.dart';

// Other screen imports
import 'package:bharat_ace/screens/smaterial/completion_trap_screen.dart';

// --- XP SYSTEM IMPORTS ---
import 'package:bharat_ace/core/constants/xp_values.dart';
import 'package:bharat_ace/core/providers/xp_provider.dart';
import 'package:bharat_ace/core/providers/xp_overlay_provider.dart'; // NEW
import 'package:bharat_ace/widgets/common/xp_earned_overlay_widget.dart'; // NEW
// --- END XP SYSTEM IMPORTS ---

class LevelContentScreen extends ConsumerStatefulWidget {
  final String subject;
  final String chapterId;
  final String levelName;
  final ChapterDetailed chapterData;

  const LevelContentScreen({
    super.key,
    required this.subject,
    required this.chapterId,
    required this.levelName,
    required this.chapterData,
  });

  @override
  ConsumerState<LevelContentScreen> createState() => _LevelContentScreenState();
}

class _LevelContentScreenState extends ConsumerState<LevelContentScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isAssessingButtonLoading = false;
  bool _isChatBoxVisible = false;

  LevelContentArgs get _controllerArgs => (
        subject: widget.subject,
        chapterId: widget.chapterId,
        levelName: widget.levelName,
        chapterData: widget.chapterData
      );

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initSpeech();
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _speechToText.stop();
    // It's good practice to also hide overlay if screen is disposed
    // although the timer in provider should handle it.
    Future.microtask(() => ref.read(xpOverlayProvider.notifier).hideOverlay());
    super.dispose();
  }
// In _LevelContentScreenState class:

// (Remove or comment out the old SharedPreferences-based xpProvider if it was defined in this file)

  Future<void> _awardXp(int amount, String reasonMessage,
      {String? subMessage}) async {
    if (!mounted || amount <= 0) return;

    // Call StudentDetailsNotifier to update global XP in Firestore and local StudentModel
    // Awaiting ensures the StudentModel state update might be processed before overlay,
    // which helps if other parts of the UI depend on the immediate new total XP.
    await ref.read(studentDetailsNotifierProvider.notifier).addXp(amount);

    // Show the visual XP earned overlay
    ref.read(xpOverlayProvider.notifier).showOverlay(
          amount: amount,
          message: reasonMessage,
          subMessage: subMessage,
        );
    print(
        "XP Awarded (via StudentDetailsNotifier): $amount for '$reasonMessage'");
  }

  // --- Action Handlers ---
  void _handleClearCacheActual() {
    // ... (no changes needed here for XP)
    final currentTargetLanguage = ref.read(targetLanguageProvider);
    final cacheService = ref.read(contentCacheServiceProvider);
    final String baseCacheKeyForController =
        "${_controllerArgs.subject}_${_controllerArgs.chapterId}_${_controllerArgs.levelName}";
    final String languageNameForCacheKey = currentTargetLanguage.name;
    final String fullCacheKeyToClear =
        "${baseCacheKeyForController}_$languageNameForCacheKey";

    print("SCREEN: Attempting to clear cache for key: $fullCacheKeyToClear");

    cacheService.clearCacheForTopic(fullCacheKeyToClear).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Cache for this level (${currentTargetLanguage.name}) cleared. Regenerating...")));
        ref
            .read(levelContentControllerProvider(_controllerArgs).notifier)
            .loadOrGenerateLevelContent(
                forceRegenerate: true, language: currentTargetLanguage);
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error clearing cache: $e")));
      }
    });
  }

  void _handleRegenerate() {
    // ... (no changes needed here for XP)
    ref.read(qaHistoryProvider.notifier).state = [];
    ref
        .read(levelContentControllerProvider(_controllerArgs).notifier)
        .loadOrGenerateLevelContent(forceRegenerate: true);
  }

  void _handleSimplify() {
    // ... (no changes needed here for XP)
    ref.read(qaHistoryProvider.notifier).state = [];
    ref
        .read(levelContentControllerProvider(_controllerArgs).notifier)
        .loadOrGenerateLevelContent(
            forceRegenerate: true, complexity: 'simple');
  }

  void _changeLanguage(TargetLanguage newLanguage) {
    // ... (no changes needed here for XP)
    ref.read(targetLanguageProvider.notifier).state = newLanguage;
    ref.read(qaHistoryProvider.notifier).state = [];
    ref
        .read(levelContentControllerProvider(_controllerArgs).notifier)
        .loadOrGenerateLevelContent(
            forceRegenerate: true, language: newLanguage);
  }

  void _scrollToBottom() {
    // ... (no changes here)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        double extraScroll = _isChatBoxVisible ? 80.0 : 0.0;
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 200 + extraScroll,
            duration: 300.ms,
            curve: Curves.easeOut);
      }
    });
  }

  void _addSelectedTextToKeyNotes(String selectedTextValue) {
    if (selectedTextValue.trim().isEmpty) return;
    const String genericBlockIdForKeyNotes = "lesson_notes";
    ref.read(keyNotesProvider.notifier).update((state) {
      final SplayTreeMap<String, List<String>> newState =
          SplayTreeMap.from(state);
      final List<String> blockKeyNotes =
          List.from(newState[genericBlockIdForKeyNotes] ?? []);
      if (!blockKeyNotes.contains(selectedTextValue)) {
        blockKeyNotes.add(selectedTextValue);
      }
      newState[genericBlockIdForKeyNotes] = blockKeyNotes;
      return newState;
    });

    if (mounted) {
      _awardXp(
          XpValues.addToKeyNotes, "Key Note Saved!"); // No await needed usually
      // Original SnackBar can be removed if overlay is preferred
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Added to Key Notes!",
              style: TextStyle(color: AppColors.textPrimary)),
          backgroundColor:
              AppColors.cardBackground, // Less prominent than XP green
          behavior: SnackBarBehavior.floating));
    }
  }

  // --- Speech Recognition Methods ---
  // ... (no changes here for XP)
  Future<void> _initSpeech() async {
    if (!mounted) return;
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      try {
        _speechEnabled = await _speechToText.initialize(
          onError: (err) {/* print('Speech recognition error: $err'); */},
          onStatus: (stat) {
            if (mounted &&
                stat != stt.SpeechToText.listeningStatus &&
                ref.read(isListeningProvider)) {
              ref.read(isListeningProvider.notifier).state = false;
            }
          },
        );
        if (!_speechEnabled && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Speech recognition not available.")));
        }
      } catch (e) {
        _speechEnabled = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Could not initialize speech recognition.")));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone permission denied.")));
      }
    }
    if (mounted) setState(() {});
  }

  void _startListening() async {
    // ... (no changes here)
    if (!_speechEnabled || _speechToText.isListening || !mounted) return;
    ref.read(isListeningProvider.notifier).state = true;
    try {
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            _questionController.text = result.recognizedWords;
            _questionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _questionController.text.length));
            if (result.finalResult) {
              ref.read(isListeningProvider.notifier).state = false;
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: ref.read(targetLanguageProvider) == TargetLanguage.hindi
            ? "hi_IN"
            : "en_IN",
      );
    } catch (e) {
      if (mounted) {
        ref.read(isListeningProvider.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not start voice input.")));
      }
    }
  }

  void _stopListening() async {
    // ... (no changes here)
    if (!_speechToText.isListening || !mounted) return;
    try {
      await _speechToText.stop();
    } catch (e) {/* print("Error stopping speech listener: $e"); */}
    if (mounted) ref.read(isListeningProvider.notifier).state = false;
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    _questionController.clear();
    if (mounted) FocusScope.of(context).unfocus();

    // Award XP - can be fire-and-forget for UI responsiveness or await if needed
    _awardXp(XpValues.askQuestion,
        "Curiosity Rewarded!"); // No await needed if overlay is primary

    await ref
        .read(levelContentControllerProvider(_controllerArgs).notifier)
        .answerQuestion(question);
    _scrollToBottom();
  }

  // --- Assessment Method ---
  Future<void> _handleAssessment() async {
    if (_isAssessingButtonLoading || !mounted) return;
    setState(() => _isAssessingButtonLoading = true);

    final bool? summaryPassed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CompletionTrapScreen(
          subjectName: widget.subject,
          chapterId: widget.chapterId,
          levelName: widget.levelName,
          chapterData: widget.chapterData,
        ),
      ),
    );
    if (!mounted) return;

    if (summaryPassed == true) {
      // Determine XP for this specific level
      int xpForThisLevel;
      String levelCompletionMessage = "Level '${widget.levelName}' Cleared!";
      String levelTypeSubMessage = ""; // More specific message for the overlay

      final String currentLevelNameLower = widget.levelName.toLowerCase();

      // Get all level names from chapterData to identify if current is last
      final List<String> allLevelNamesLower = widget.chapterData.levels
          .map((l) => l.levelName.toLowerCase())
          .toList();
      final int currentLevelIndex =
          allLevelNamesLower.indexOf(currentLevelNameLower);
      final bool isLastLevel = currentLevelIndex != -1 &&
          currentLevelIndex == allLevelNamesLower.length - 1;
      final bool isPrerequisitesLevel =
          currentLevelNameLower == 'prerequisites' ||
              currentLevelNameLower == 'prerequisite';

      if (isPrerequisitesLevel) {
        xpForThisLevel = XpValues.prerequisiteLevelCompletion;
        levelTypeSubMessage = "Prerequisites Understood!";
      } else if (currentLevelNameLower == 'advanced' || isLastLevel) {
        // 'advanced' or identified as the last one
        xpForThisLevel = XpValues.advancedLevelCompletion;
        levelTypeSubMessage = "Advanced Concepts Aced!";
      } else {
        xpForThisLevel = XpValues.regularLevelCompletion;
        levelTypeSubMessage = "Great Progress!";
      }

      // Award XP for completing THIS specific level
      // This await is important to ensure XP is processed before popping.
      await _awardXp(
        xpForThisLevel,
        levelCompletionMessage,
        subMessage: levelTypeSubMessage,
      );

      Navigator.of(context)
          .pop(true); // Pop LevelContentScreen, indicating success
    } else {
      setState(() => _isAssessingButtonLoading = false);
      if (summaryPassed == false) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("Review the material and try the assessment again.")));
      }
    }
  }

  // --- Build Methods ---
  Widget _buildInteractiveContentBody(
      BuildContext context,
      List<ContentBlockModel> contentBlocks,
      List<Map<String, String>> qaHistory,
      TextTheme contentTextTheme) {
    // ... (no changes here)
    final ttsGlobalHighlight = ref.watch(ttsHighlightRangeProvider);
    // final controllerNotifier = ref.read(levelContentControllerProvider(_controllerArgs).notifier); // Not used directly here anymore

    final List<Widget> allDisplayableItems = [];
    allDisplayableItems.addAll(contentBlocks.asMap().entries.map((entry) {
      int idx = entry.key;
      ContentBlockModel block = entry.value;
      final blockSpecificCleanedOffsets = ref
          .read(levelContentControllerProvider(_controllerArgs).notifier)
          .blockCleanedTextOffsetMap[block.id];
      bool isBlockCurrentlySpoken = false;

      if (ttsGlobalHighlight != null && blockSpecificCleanedOffsets != null) {
        if (ttsGlobalHighlight.start < blockSpecificCleanedOffsets.endCleaned &&
            ttsGlobalHighlight.end > blockSpecificCleanedOffsets.startCleaned) {
          isBlockCurrentlySpoken = true;
        }
      }

      return ContentBlockWidget(
        key: ValueKey(block.id),
        block: block,
        controllerArgs: _controllerArgs,
        isBlockCurrentlySpokenByTTSGlobal: isBlockCurrentlySpoken,
        ttsGlobalHighlightRange: ttsGlobalHighlight,
        blockGlobalStartOffsetCleaned:
            blockSpecificCleanedOffsets?.startCleaned ?? 0,
      ).animate().fadeIn(delay: (50 * idx).ms, duration: 400.ms).slideY(
          begin: 0.05, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
    }));

    if (qaHistory.isNotEmpty) {
      allDisplayableItems.add(Padding(
        padding:
            const EdgeInsets.only(top: 30.0, bottom: 10.0, left: 8, right: 8),
        child: Text(
          "Doubts & Discussions",
          style: contentTextTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryAccent,
          ),
        ),
      ).animate().fadeIn(delay: (contentBlocks.length * 50).ms));

      allDisplayableItems.addAll(qaHistory.asMap().entries.map((entry) {
        int idx = entry.key;
        Map<String, String> qa = entry.value;
        return QACardWidget(
          key: ValueKey("qa_card_${qa['q']?.hashCode}_${qa['a']?.hashCode}"),
          question: qa['q']!,
          answer: qa['a']!,
          answerState: qa['state']!,
        )
            .animate()
            .fadeIn(
                delay: ((contentBlocks.length + idx) * 50).ms, duration: 350.ms)
            .slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
      }));
    }

    allDisplayableItems.add(const SizedBox(height: 220));

    return SelectableRegion(
      focusNode: FocusNode(),
      selectionControls: KeyNotesSelectionControls(
          onAddToKeyNotes: _addSelectedTextToKeyNotes),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        children: allDisplayableItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ContentBlockModel>> contentState =
        ref.watch(levelContentControllerProvider(_controllerArgs));
    final String currentFontFamily = ref.watch(currentFontFamilyProvider);
    final double fontSizeMultiplier =
        ref.watch(currentFontSizeMultiplierProvider);

    final studentAsyncValue = ref
        .watch(studentDetailsProvider); // NEW: Watch AsyncValue<StudentModel?>
    final totalXp =
        studentAsyncValue.valueOrNull?.xp ?? 0; // NEW: Get XP from StudentModel
    final xpOverlay = ref.watch(xpOverlayProvider); // Watch overlay state

    final TextTheme appBarTextTheme =
        getTextThemeWithFont(context, currentFontFamily, 1.0);
    final TextTheme contentTextTheme =
        getTextThemeWithFont(context, currentFontFamily, fontSizeMultiplier);

    final bool showFab =
        contentState.hasValue && (contentState.value?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          "${widget.levelName}: ${widget.chapterData.chapterTitle}",
          style: appBarTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: (appBarTextTheme.titleLarge?.fontSize ?? 18) *
                  fontSizeMultiplier.clamp(0.9, 1.1)),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 2,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          // --- XP Display in AppBar ---
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded,
                    color: AppColors.goldColor,
                    size: 20), // Use your gold color
                const SizedBox(width: 4),
                Text(
                  '$totalXp XP',
                  style: appBarTextTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // --- End XP Display ---
          ...buildLevelContentAppBarActions(
            // Spread existing actions
            context: context,
            ref: ref,
            controllerArgs: _controllerArgs,
            chapterData: widget.chapterData,
            contentState: contentState,
            onRegenerate: _handleRegenerate,
            onSimplify: _handleSimplify,
            onClearCache: _handleClearCacheActual,
            onLanguageSelected: _changeLanguage,
          ),
        ],
      ),
      // --- Wrap body with Stack for Overlay ---
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: contentState.when(
                  loading: () => const LevelContentLoadingUI(),
                  error: (err, st) => LevelContentErrorUI(
                    error: err,
                    stackTrace: st,
                    controllerArgs: _controllerArgs,
                    onRetry: () => ref
                        .read(levelContentControllerProvider(_controllerArgs)
                            .notifier)
                        .loadOrGenerateLevelContent(forceRegenerate: true),
                  ),
                  data: (blocks) {
                    return blocks.isEmpty
                        ? Center(
                            child: Text(
                              "No content available for this section yet.",
                              style: contentTextTheme.bodyLarge
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        : _buildInteractiveContentBody(context, blocks,
                            ref.watch(qaHistoryProvider), contentTextTheme);
                  },
                ),
              ),
              if (_isChatBoxVisible)
                QAInputBar(
                  controller: _questionController,
                  speechEnabled: _speechEnabled,
                  isListening: ref.watch(isListeningProvider),
                  isAnswering: ref.watch(isAnsweringProvider),
                  onSend: _askQuestion,
                  onStartListening: _startListening,
                  onStopListening: _stopListening,
                ),
              if (contentState.hasValue &&
                  (contentState.value?.isNotEmpty ?? false))
                TestKnowledgeButton(
                  isLoading: _isAssessingButtonLoading,
                  onPressed: _handleAssessment,
                ),
            ],
          ),
          // --- XP Earned Overlay ---
          if (xpOverlay.isVisible &&
              xpOverlay.amount != null &&
              xpOverlay.message != null)
            XpEarnedOverlayWidget(
              amount: xpOverlay.amount!,
              message: xpOverlay.message!,
              subMessage: xpOverlay.subMessage,
            ),
        ],
      ),
      // --- End Stack for Overlay ---
      floatingActionButton: showFab
          ? Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom +
                      16 +
                      (_isChatBoxVisible ? 74 : 0) +
                      ((contentState.hasValue &&
                              (contentState.value?.isNotEmpty ?? false))
                          ? 78
                          : 0)),
              child: FloatingActionButton(
                heroTag: "level_content_chat_fab", // Add unique heroTag
                onPressed: () {
                  setState(() {
                    _isChatBoxVisible = !_isChatBoxVisible;
                    if (_isChatBoxVisible) {
                      _scrollToBottom();
                    } else {
                      FocusScope.of(context).unfocus();
                    }
                  });
                },
                backgroundColor: AppColors.secondaryAccent,
                foregroundColor: AppColors.textPrimary,
                child: Icon(
                  _isChatBoxVisible
                      ? Icons.close_rounded
                      : Icons.chat_bubble_outline_rounded,
                  size: 28,
                ),
                tooltip: _isChatBoxVisible ? "Close Chat" : "Ask a Question",
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
