import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/utils/text_theme_utils.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';

class QAInputBar extends ConsumerWidget {
  final TextEditingController controller;
  final bool speechEnabled;
  final bool isListening;
  final bool isAnswering;
  final VoidCallback onSend;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  const QAInputBar({
    super.key,
    required this.controller,
    required this.speechEnabled,
    required this.isListening,
    required this.isAnswering,
    required this.onSend,
    required this.onStartListening,
    required this.onStopListening,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String currentFontFamily = ref.watch(currentFontFamilyProvider);
    final double fontSizeMultiplier =
        ref.watch(currentFontSizeMultiplierProvider);
    final TextTheme textTheme =
        getTextThemeWithFont(context, currentFontFamily, fontSizeMultiplier);

    return SafeArea(
      top: false, // Only consider bottom safe area
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        margin:
            const EdgeInsets.fromLTRB(12, 8, 12, 0), // Margin from screen edges
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isAnswering,
                style: textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: isListening
                      ? "Listening intently..."
                      : "Ask your Guru anything...",
                  hintStyle: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: isAnswering ? null : (_) => onSend(),
              ),
            ),
            if (speechEnabled)
              IconButton(
                icon: Icon(
                  isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                  size: 26,
                ),
                color: isListening
                    ? AppColors.secondaryAccent
                    : AppColors.textSecondary.withOpacity(0.8),
                onPressed: isAnswering
                    ? null
                    : (isListening ? onStopListening : onStartListening),
              ),
            IconButton(
              icon: isAnswering
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.secondaryAccent),
                    )
                  : Icon(Icons.send_rounded,
                      size: 26,
                      color: controller.text.trim().isEmpty && !isAnswering
                          ? AppColors.textSecondary.withOpacity(0.5)
                          : AppColors.secondaryAccent),
              onPressed:
                  isAnswering || controller.text.trim().isEmpty ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}
