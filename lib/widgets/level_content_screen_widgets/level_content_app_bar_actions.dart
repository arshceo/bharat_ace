import 'package:bharat_ace/widgets/level_content_screen_widgets/language_selection_bottom_sheet.dart';
import 'package:bharat_ace/widgets/level_content_screen_widgets/popup_menu_item_widget.dart';
import 'package:bharat_ace/widgets/level_content_screen_widgets/reader_settings_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';
import 'package:bharat_ace/features/level_content/controllers/level_content_controller.dart';
import 'package:bharat_ace/screens/smaterial/key_notes_screen.dart'; // Adjust path

List<Widget> buildLevelContentAppBarActions({
  required BuildContext context,
  required WidgetRef ref,
  required LevelContentArgs controllerArgs,
  required ChapterDetailed chapterData,
  required AsyncValue<List<dynamic>>
      contentState, // Can be List<ContentBlockModel>
  required VoidCallback onRegenerate,
  required VoidCallback onSimplify,
  required VoidCallback onClearCache,
  required Function(TargetLanguage)
      onLanguageSelected, // For the language sheet
}) {
  final ttsPlayState = ref.watch(ttsStateProvider);
  final String? currentSpeakingIdVal = ref.watch(currentSpeakingIdProvider);
  final bool isFullContentSpeaking =
      currentSpeakingIdVal == "full_content_audio";
  final String currentFontFamily = ref.watch(currentFontFamilyProvider);
  final double fontSizeMultiplier =
      ref.watch(currentFontSizeMultiplierProvider);

  return [
    // TTS Button
    if (contentState.hasValue &&
        (contentState.value?.isNotEmpty ?? false) &&
        !(isFullContentSpeaking && ttsPlayState == TtsState.buffering))
      IconButton(
        icon: Icon(
          isFullContentSpeaking && ttsPlayState == TtsState.playing
              ? Icons.stop_circle_outlined
              : Icons.volume_up_outlined,
          color: isFullContentSpeaking && ttsPlayState == TtsState.playing
              ? AppColors.redFailure
              : AppColors.secondaryAccent,
          size: 26,
        ),
        tooltip: isFullContentSpeaking && ttsPlayState == TtsState.playing
            ? "Stop Reading"
            : "Read Aloud",
        onPressed: () {
          final controllerNotifier =
              ref.read(levelContentControllerProvider(controllerArgs).notifier);
          if (isFullContentSpeaking && ttsPlayState == TtsState.playing) {
            controllerNotifier.stopTts();
          } else {
            controllerNotifier.speakFullContent();
          }
        },
      ),
    // TTS Buffering Indicator
    if (isFullContentSpeaking && ttsPlayState == TtsState.buffering)
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.secondaryAccent)),
      ),
    // Key Notes Button
    IconButton(
      icon: const Icon(Icons.notes_rounded, color: AppColors.textSecondary),
      tooltip: "View Key Notes",
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => KeyNotesScreen(
                      initialKeyNotes: ref.read(keyNotesProvider),
                      chapterTitle: chapterData.chapterTitle,
                      fontFamily: currentFontFamily,
                      fontSizeMultiplier: fontSizeMultiplier,
                    )));
      },
    ),
    // Language Button
    IconButton(
      icon: const Icon(Icons.translate_rounded, color: AppColors.textSecondary),
      tooltip: "Change Language",
      onPressed: () =>
          showLanguageSelectionSheet(context, ref, onLanguageSelected),
    ),
    // Reader Settings Button
    IconButton(
      icon: const Icon(Icons.font_download_outlined,
          color: AppColors.textSecondary),
      tooltip: "Reader Settings",
      onPressed: () => showReaderSettingsBottomSheet(context),
    ),
    // Loading Indicator for Content
    if (contentState.isLoading &&
        !(isFullContentSpeaking && ttsPlayState == TtsState.buffering))
      const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.secondaryAccent)),
      )
    // More Options Popup
    else if (!contentState.isLoading)
      PopupMenuButton<String>(
        icon:
            const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
        tooltip: "More Options",
        enabled: contentState.hasValue &&
            (contentState.value?.isNotEmpty ??
                false), // Enable only if content loaded
        color: AppColors.cardBackground,
        itemBuilder: (context) => [
          PopupMenuItem<String>(
              value: 'regenerate',
              child: buildAppPopupMenuItem(
                  context,
                  Icons.refresh_rounded,
                  "Regenerate Content",
                  AppColors.primaryAccent,
                  currentFontFamily)),
          PopupMenuItem<String>(
              value: 'simplify',
              child: buildAppPopupMenuItem(
                  context,
                  Icons.lightbulb_outline_rounded,
                  "Simplify Content",
                  AppColors.secondaryAccent,
                  currentFontFamily)),
          const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
              value: 'clear_cache',
              child: buildAppPopupMenuItem(
                  context,
                  Icons.delete_sweep_outlined,
                  "Clear Cached Content",
                  AppColors.orangeWarning,
                  currentFontFamily)),
        ],
        onSelected: (value) {
          if (value == 'regenerate')
            onRegenerate();
          else if (value == 'simplify')
            onSimplify();
          else if (value == 'clear_cache') onClearCache();
        },
      ),
  ];
}
