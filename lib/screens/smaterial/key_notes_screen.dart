// --- lib/screens/smaterial/key_notes_screen.dart ---

import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bharat_ace/core/providers/settings_providers.dart'
    as settings; // <-- ADD PREFIX
import 'package:bharat_ace/features/level_content/screens/level_content_screen.dart'
    show AppColors, TtsState; // For AppColors and TtsState enum
import 'package:flutter_tts/flutter_tts.dart';

// Local providers for this screen's TTS state
final _keyNotesScreenTtsStateProvider =
    StateProvider<TtsState>((ref) => TtsState.stopped);
final _keyNotesScreenSpeakingNoteIndexProvider =
    StateProvider<int?>((ref) => null);

class KeyNotesScreen extends ConsumerStatefulWidget {
  final Map<String, List<String>> initialKeyNotes;
  final String chapterTitle;
  final String
      fontFamily; // Passed for consistency with LevelContentScreen's current font
  final double fontSizeMultiplier; // Passed for consistency

  const KeyNotesScreen({
    super.key,
    required this.initialKeyNotes,
    required this.chapterTitle,
    required this.fontFamily,
    required this.fontSizeMultiplier,
  });

  @override
  ConsumerState<KeyNotesScreen> createState() => _KeyNotesScreenState();
}

class _KeyNotesScreenState extends ConsumerState<KeyNotesScreen> {
  late Map<String, List<String>> _currentKeyNotes;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _currentKeyNotes = Map.from(widget.initialKeyNotes);
    _initTts();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setSharedInstance(true);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      flutterTts.setStartHandler(() {
        if (mounted) {
          ref.read(_keyNotesScreenTtsStateProvider.notifier).state =
              TtsState.playing;
        }
      });
      flutterTts.setCompletionHandler(() {
        if (mounted) {
          ref.read(_keyNotesScreenTtsStateProvider.notifier).state =
              TtsState.stopped;
          ref.read(_keyNotesScreenSpeakingNoteIndexProvider.notifier).state =
              null;
        }
      });
      flutterTts.setErrorHandler((msg) {
        if (mounted) {
          ref.read(_keyNotesScreenTtsStateProvider.notifier).state =
              TtsState.error;
          ref.read(_keyNotesScreenSpeakingNoteIndexProvider.notifier).state =
              null;
          print("KeyNotes TTS Error: $msg");
          _showErrorSnackbar("TTS Error: Could not read note.");
        }
      });
    } catch (e) {
      print("KeyNotes TTS Init Error: $e");
      if (mounted) {
        ref.read(_keyNotesScreenTtsStateProvider.notifier).state =
            TtsState.error;
      }
    }
  }

  Future<void> _speakNote(String text, int noteIndex) async {
    await _stopSpeakingNote();
    if (text.trim().isEmpty) return;

    ref.read(_keyNotesScreenSpeakingNoteIndexProvider.notifier).state =
        noteIndex;
    ref.read(_keyNotesScreenTtsStateProvider.notifier).state =
        TtsState.buffering;

    final currentContentLang =
        ref.read(settings.targetLanguageProvider); // <-- USE GLOBAL PROVIDER
    String ttsLangCode = "en-US";
    switch (currentContentLang) {
      case TargetLanguage.hindi:
        ttsLangCode = "hi-IN";
        break;
      case TargetLanguage.punjabiEnglish:
      case TargetLanguage.hinglish:
        ttsLangCode = "en-IN"; // Good general Indian English accent
        break;
      case TargetLanguage.english: // Default case
      default:
        ttsLangCode = "en-US";
    }

    try {
      await flutterTts.setLanguage(ttsLangCode);
      var result = await flutterTts.speak(text);
      if (result != 1) {
        if (mounted) {
          ref.read(_keyNotesScreenTtsStateProvider.notifier).state =
              TtsState.error;
          ref.read(_keyNotesScreenSpeakingNoteIndexProvider.notifier).state =
              null;
        }
      }
    } catch (e) {
      print("KeyNotes TTS speak error: $e");
      if (mounted) {
        ref.read(_keyNotesScreenTtsStateProvider.notifier).state =
            TtsState.error;
        ref.read(_keyNotesScreenSpeakingNoteIndexProvider.notifier).state =
            null;
      }
    }
  }

  Future<void> _stopSpeakingNote() async {
    try {
      var result = await flutterTts.stop();
      if (result == 1 && mounted) {
        ref.read(_keyNotesScreenTtsStateProvider.notifier).state =
            TtsState.stopped;
        ref.read(_keyNotesScreenSpeakingNoteIndexProvider.notifier).state =
            null;
      }
    } catch (e) {
      print("KeyNotes TTS stop error: $e");
    }
  }

  TextTheme _getTextThemeWithFont(
      BuildContext context, String fontFamilyName, double sizeMultiplier) {
    final TextTheme baseTextTheme = Theme.of(context).textTheme.apply(
        bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary);
    TextStyle? applyStyle(TextStyle? style) {
      if (style == null) return null;
      String googleFontFamilyName = fontFamilyName;
      if (fontFamilyName == "FiraCode") googleFontFamilyName = "Fira Code";
      if (fontFamilyName == "OpenSans") googleFontFamilyName = "Open Sans";
      if (fontFamilyName == "SourceSansPro") {
        googleFontFamilyName = "Source Sans Pro";
      }
      return GoogleFonts.getFont(googleFontFamilyName,
          textStyle: style.copyWith(
              fontSize: (style.fontSize ?? 14.0) * sizeMultiplier));
    }

    return baseTextTheme.copyWith(
      displayLarge: applyStyle(baseTextTheme.displayLarge),
      displayMedium: applyStyle(baseTextTheme.displayMedium),
      displaySmall: applyStyle(baseTextTheme.displaySmall),
      headlineLarge: applyStyle(baseTextTheme.headlineLarge),
      headlineMedium: applyStyle(baseTextTheme.headlineMedium),
      headlineSmall: applyStyle(baseTextTheme.headlineSmall),
      titleLarge: applyStyle(baseTextTheme.titleLarge),
      titleMedium: applyStyle(baseTextTheme.titleMedium),
      titleSmall: applyStyle(baseTextTheme.titleSmall),
      bodyLarge: applyStyle(baseTextTheme.bodyLarge),
      bodyMedium: applyStyle(baseTextTheme.bodyMedium),
      bodySmall: applyStyle(baseTextTheme.bodySmall),
      labelLarge: applyStyle(baseTextTheme.labelLarge),
      labelMedium: applyStyle(baseTextTheme.labelMedium),
      labelSmall: applyStyle(baseTextTheme.labelSmall),
    );
  }

  void _deleteNote(String blockId, String noteToDelete) {
    setState(() {
      _currentKeyNotes[blockId]?.remove(noteToDelete);
      if (_currentKeyNotes[blockId]?.isEmpty ?? false) {
        _currentKeyNotes.remove(blockId);
      }
    });
    // For persistent deletion, notify the global provider if you implement one:
    // ref.read(globalKeyNotesProvider.notifier).removeNote(blockId, noteToDelete);
    _showSuccessSnackbar("Note deleted!");
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(message, style: const TextStyle(color: AppColors.textPrimary)),
      backgroundColor: AppColors.greenSuccess,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
    ));
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(message, style: const TextStyle(color: AppColors.textPrimary)),
      backgroundColor: AppColors.redFailure,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = _getTextThemeWithFont(
        context, widget.fontFamily, widget.fontSizeMultiplier);
    final List<({String blockId, String noteText, int globalIndex})>
        flatNotesWithContext = [];
    int globalIdx = 0;
    _currentKeyNotes.forEach((blockId, notes) {
      for (var note in notes) {
        flatNotesWithContext
            .add((blockId: blockId, noteText: note, globalIndex: globalIdx++));
      }
    });

    final ttsState = ref.watch(_keyNotesScreenTtsStateProvider);
    final speakingNoteIndex =
        ref.watch(_keyNotesScreenSpeakingNoteIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text("Key Notes: ${widget.chapterTitle}",
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.cardBackground.withOpacity(0.85),
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cardBackground,
                AppColors.darkBackground.withAlpha(210)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (flatNotesWithContext.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_outlined,
                  color: AppColors.textSecondary),
              tooltip: "Share All Notes",
              onPressed: () {
                String allNotesText = flatNotesWithContext
                    .map((n) => "📌 ${n.noteText}")
                    .join("\n\n");
                Clipboard.setData(ClipboardData(
                    text:
                        "Key Notes for ${widget.chapterTitle}:\n\n$allNotesText"));
                _showSuccessSnackbar("All notes copied to clipboard!");
              },
            ).animate().fadeIn(delay: 200.ms).shimmer(
                duration: 1200.ms,
                color: AppColors.primaryAccent.withOpacity(0.3))
        ],
      ),
      body: flatNotesWithContext.isEmpty
          ? _buildEmptyState(textTheme)
          : ListView.separated(
              // Using ListView.separated for a divider
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              itemCount: flatNotesWithContext.length,
              separatorBuilder: (context, index) => Divider(
                color: AppColors.cardLightBackground.withOpacity(0.3),
                height: 20,
                thickness: 0.5,
              ),
              itemBuilder: (context, index) {
                final noteContext = flatNotesWithContext[index];
                final bool isThisNoteSpeaking =
                    speakingNoteIndex == noteContext.globalIndex;
                final bool isBufferingThisNote =
                    isThisNoteSpeaking && ttsState == TtsState.buffering;
                final bool isPlayingThisNote =
                    isThisNoteSpeaking && ttsState == TtsState.playing;

                return Material(
                  // Wrap with Material for InkWell splash
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {/* Future: Edit note or view context */},
                    borderRadius: BorderRadius.circular(12),
                    splashColor: AppColors.primaryAccent.withOpacity(0.1),
                    highlightColor: AppColors.primaryAccent.withOpacity(0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 12.0, top: 4.0),
                                child: Icon(Icons.push_pin_rounded,
                                    color: AppColors.yellowHighlight
                                        .withOpacity(0.9),
                                    size: 22),
                              ),
                              Expanded(
                                child: SelectableText(
                                  noteContext.noteText,
                                  style: textTheme.bodyLarge?.copyWith(
                                      height: 1.65,
                                      color: AppColors.textPrimary
                                          .withOpacity(0.95)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isBufferingThisNote)
                                const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.secondaryAccent)))
                              else
                                _buildActionButton(
                                    icon: isPlayingThisNote
                                        ? Icons.stop_circle_outlined
                                        : Icons.volume_up_outlined,
                                    label: isPlayingThisNote ? "Stop" : "Read",
                                    color: isPlayingThisNote
                                        ? AppColors.redFailure
                                        : AppColors.secondaryAccent,
                                    onPressed: () {
                                      if (isPlayingThisNote) {
                                        _stopSpeakingNote();
                                      } else {
                                        _speakNote(noteContext.noteText,
                                            noteContext.globalIndex);
                                      }
                                    },
                                    textTheme: textTheme),
                              const SizedBox(width: 4),
                              _buildActionButton(
                                  icon: Icons.copy_all_outlined,
                                  label: "Copy",
                                  color: AppColors.textSecondary,
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: noteContext.noteText));
                                    _showSuccessSnackbar("Note copied!");
                                  },
                                  textTheme: textTheme),
                              const SizedBox(width: 4),
                              _buildActionButton(
                                  icon: Icons.delete_outline_rounded,
                                  label: "Delete",
                                  color: AppColors.redFailure.withOpacity(0.8),
                                  onPressed: () => _showDeleteConfirmation(
                                      context, textTheme, noteContext),
                                  textTheme: textTheme),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                )
                    .animate(delay: (70 * index).ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOutSine);
              },
            ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onPressed,
      required TextTheme textTheme}) {
    return TextButton.icon(
      icon: Icon(icon, size: 18, color: color),
      label: Text(label,
          style: textTheme.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w500)),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero, // To make it compact
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TextTheme textTheme,
      ({String blockId, String noteText, int globalIndex}) noteContext) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Delete Note?",
            style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          // <-- WRAP CONTENT WITH SingleChildScrollView
          child: Text(
              "This key note will be permanently removed. This action cannot be undone. Are you sure you wish to proceed?",
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("CANCEL",
                style: textTheme.labelLarge
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              _deleteNote(noteContext.blockId, noteContext.noteText);
              Navigator.pop(dialogContext);
            },
            child: Text("DELETE",
                style: textTheme.labelLarge?.copyWith(
                    color: AppColors.redFailure, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: SingleChildScrollView(
        // <-- WRAP EMPTY STATE CONTENT
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories_outlined,
                  size: 90, color: AppColors.primaryAccent.withOpacity(0.7)),
              const SizedBox(height: 28),
              Text("Your Personal Study Compendium",
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Text(
                  "Craft your knowledge base. Highlight crucial points in lessons and add them here to create your focused revision guide.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.85),
                      height: 1.6)),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text("Explore Lessons",
                    style: textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryAccent,
                  foregroundColor: AppColors.textPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 3,
                ),
              )
            ],
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutBack),
        ),
      ),
    );
  }
}
