import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/utils/text_theme_utils.dart';
import 'package:bharat_ace/core/utils/color_extensions.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md_parser;

class QACardWidget extends ConsumerWidget {
  final String question;
  final String answer;
  final String answerState; // 'thinking', 'success', 'error'

  const QACardWidget({
    super.key,
    required this.question,
    required this.answer,
    required this.answerState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String currentFontFamily = ref.watch(currentFontFamilyProvider);
    final double fontSizeMultiplier =
        ref.watch(currentFontSizeMultiplierProvider);
    final TextTheme textTheme =
        getTextThemeWithFont(context, currentFontFamily, fontSizeMultiplier);

    final String codeFontKey =
        ref.watch(currentFontFamilyProvider) == 'FiraCode'
            ? 'FiraCode'
            : 'RobotoMono';
    final String codeFontFamilyName =
        codeFontKey == 'FiraCode' ? 'Fira Code' : 'Roboto Mono';
    final String codeFontFamilyValue =
        GoogleFonts.getFont(codeFontFamilyName).fontFamily ?? 'monospace';
    final double bodySmallFontSize = (textTheme.bodySmall?.fontSize ?? 12.0);

    final String htmlAnswer = md_parser.markdownToHtml(
      answer,
      extensionSet: md_parser.ExtensionSet.gitHubWeb,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0, left: 4, right: 4),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.cardLightBackground.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: Icon(Icons.help_outline_rounded,
                    size: 22, color: AppColors.secondaryAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SelectableText(
                  // MODIFIED: Text to SelectableText
                  question,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(Icons.auto_awesome_outlined,
                    size: 22, color: AppColors.primaryAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: answerState == 'thinking'
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryAccent),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              // "Thinking..." message, likely not needed to be selectable
                              answer,
                              style: textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : HtmlWidget(
                        // This will be made selectable by SelectableRegion in parent screen
                        htmlAnswer,
                        textStyle: textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                          color: answerState == 'error'
                              ? AppColors.redFailure
                              : AppColors.textSecondary.withOpacity(0.95),
                        ),
                        customStylesBuilder: (element) {
                          // Your existing customStylesBuilder logic
                          if (element.localName == 'code') {
                            return {
                              'font-family': codeFontFamilyValue,
                              'background-color': AppColors.darkBackground
                                  .withOpacity(0.7)
                                  .toCssRgbaString(),
                              'color': AppColors.textPrimary
                                  .withOpacity(0.85)
                                  .toCssRgbaString(),
                              'font-size': '${bodySmallFontSize * 0.95}px',
                              'padding': '2px 4px',
                              'border-radius': '4px',
                            };
                          }
                          if (element.localName == 'pre' &&
                              element.children.isNotEmpty &&
                              element.children.first.localName == 'code') {
                            return {
                              'font-family': codeFontFamilyValue,
                              'background-color': AppColors.darkBackground
                                  .withOpacity(0.6)
                                  .toCssRgbaString(),
                              'padding': '12px',
                              'margin': '8px 0px',
                              'border-radius': '8px',
                              'overflow': 'auto',
                              'border':
                                  '0.5px solid ${AppColors.cardLightBackground.withOpacity(0.5).toCssRgbaString()}',
                              'font-size': '${bodySmallFontSize * 0.95}px',
                              'line-height': '1.45',
                            };
                          }
                          if (element.localName == 'blockquote') {
                            return {
                              'background-color': AppColors.darkBackground
                                  .withOpacity(0.3)
                                  .toCssRgbaString(),
                              'border-left':
                                  '3px solid ${AppColors.primaryAccent.withOpacity(0.6).toCssRgbaString()}',
                              'padding': '10px 10px 10px 16px',
                              'margin': '10px 0px',
                            };
                          }
                          if (element.localName == 'h1') {
                            return {
                              'font-size':
                                  '${textTheme.headlineSmall?.fontSize}px'
                            };
                          }
                          if (element.localName == 'h2') {
                            return {
                              'font-size': '${textTheme.titleLarge?.fontSize}px'
                            };
                          }
                          return null;
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
