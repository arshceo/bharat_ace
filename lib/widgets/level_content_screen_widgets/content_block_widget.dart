import 'dart:collection';

import 'package:bharat_ace/core/models/content_block_model.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/features/level_content/controllers/level_content_controller.dart';
import 'package:bharat_ace/features/level_content/providers/level_content_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// Import your models, providers, and AppColors
// ^^^ NOTE: You might need to adjust the path above if AppColors, ContentBlockType,
// and providers are defined elsewhere or if you move them to more central locations.
// For example, AppColors and ContentBlockType might be better in their own files.
// The providers (_highlightsProvider, _currentFontFamilyProvider, etc.) and
// levelContentControllerProvider are defined in level_content_screen.dart in your current setup.

// Helper to get themed text style - can be a top-level function or static method
TextTheme _getTextThemeWithFont(BuildContext context, String internalFontKey,
    double fontSizeMultiplier, Color defaultTextColor) {
  final TextTheme baseTextTheme = Theme.of(context).textTheme.apply(
        bodyColor: defaultTextColor,
        displayColor: defaultTextColor,
      );
  TextStyle? applyStyle(TextStyle? style) {
    if (style == null) return null;
    String googleFontsApiName;
    switch (internalFontKey) {
      case 'Roboto':
        googleFontsApiName = 'Roboto';
        break;
      case 'Lato':
        googleFontsApiName = 'Lato';
        break;
      case 'Merriweather':
        googleFontsApiName = 'Merriweather';
        break;
      case 'OpenSans':
        googleFontsApiName = 'Open Sans';
        break;
      case 'FiraCode':
        googleFontsApiName = 'Fira Code';
        break;
      case 'Nunito':
        googleFontsApiName = 'Nunito';
        break;
      case 'SourceSansPro':
        googleFontsApiName = 'Source Sans 3';
        break;
      default:
        googleFontsApiName = 'Roboto';
    }
    return GoogleFonts.getFont(googleFontsApiName,
        textStyle: style.copyWith(
            fontSize: (style.fontSize ?? 14.0) * fontSizeMultiplier));
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
      labelSmall: applyStyle(baseTextTheme.labelSmall));
}

class ContentBlockWidget extends ConsumerWidget {
  final ContentBlockModel block;
  final LevelContentArgs
      controllerArgs; // To access the correct controller instance
  final bool isBlockCurrentlySpokenByTTSGlobal;
  final TextRange? ttsGlobalHighlightRange;
  final int blockGlobalStartOffsetCleaned;

  const ContentBlockWidget({
    super.key,
    required this.block,
    required this.controllerArgs,
    required this.isBlockCurrentlySpokenByTTSGlobal,
    required this.ttsGlobalHighlightRange,
    required this.blockGlobalStartOffsetCleaned,
  });

  void _addSelectedTextToKeyNotes(
      BuildContext context, WidgetRef ref, String selectedTextValue) {
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
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Added to Key Notes!",
              style: TextStyle(color: AppColors.textPrimary)),
          backgroundColor: AppColors.greenSuccess,
          behavior: SnackBarBehavior.floating));
    }
  }

  int _getGlobalCleanedTextOffsetForTap(
      WidgetRef ref, ContentBlockModel tappedBlock, int rawTextTapOffset) {
    final controllerNotifier =
        ref.read(levelContentControllerProvider(controllerArgs).notifier);
    final blockOffsets =
        controllerNotifier.blockCleanedTextOffsetMap[tappedBlock.id];
    if (blockOffsets == null) return -1;

    final String rawBlockContent = tappedBlock.rawContent;
    final String cleanedBlockContent =
        controllerNotifier.cleanTextForTTS(rawBlockContent);

    if (rawBlockContent.isEmpty || cleanedBlockContent.isEmpty) {
      return blockOffsets.startCleaned;
    }
    double ratio = rawTextTapOffset /
        rawBlockContent.length.toDouble().clamp(1.0, double.infinity);
    int approxCleanedBlockOffset = (cleanedBlockContent.length * ratio).round();
    approxCleanedBlockOffset =
        approxCleanedBlockOffset.clamp(0, cleanedBlockContent.length);

    return blockOffsets.startCleaned + approxCleanedBlockOffset;
  }

  List<TextSpan> _buildTextSpansForDisplay(
      WidgetRef ref,
      String blockId,
      String blockRawText,
      TextStyle? baseStyle,
      TextRange? ttsGlobalHighlightRange,
      int blockGlobalStartOffsetCleaned,
      String blockCleanedTextForThisBlock) {
    final userHighlights =
        ref.watch(highlightsProvider); // Watch for user highlights
    final List<TextSpan> spans = [];
    if (blockRawText.isEmpty) return spans;

    List<({TextRange range, bool isUserHighlight, bool isTtsHighlight})>
        effectiveRanges = [];

    for (var sel in (userHighlights[blockId] ?? [])) {
      if (sel.start < sel.end) {
        effectiveRanges.add((
          range: TextRange(start: sel.start, end: sel.end),
          isUserHighlight: true,
          isTtsHighlight: false
        ));
      }
    }

    if (ttsGlobalHighlightRange != null &&
        blockCleanedTextForThisBlock.isNotEmpty) {
      int blockGlobalEndOffsetCleaned =
          blockGlobalStartOffsetCleaned + blockCleanedTextForThisBlock.length;
      if (ttsGlobalHighlightRange.start < blockGlobalEndOffsetCleaned &&
          ttsGlobalHighlightRange.end > blockGlobalStartOffsetCleaned) {
        int localTtsStartCleaned =
            (ttsGlobalHighlightRange.start - blockGlobalStartOffsetCleaned)
                .clamp(0, blockCleanedTextForThisBlock.length);
        int localTtsEndCleaned =
            (ttsGlobalHighlightRange.end - blockGlobalStartOffsetCleaned)
                .clamp(0, blockCleanedTextForThisBlock.length);

        if (localTtsStartCleaned < localTtsEndCleaned) {
          double startRatio = localTtsStartCleaned /
              blockCleanedTextForThisBlock.length
                  .toDouble()
                  .clamp(1.0, double.infinity);
          double endRatio = localTtsEndCleaned /
              blockCleanedTextForThisBlock.length
                  .toDouble()
                  .clamp(1.0, double.infinity);
          int approxRawStart = (blockRawText.length * startRatio)
              .round()
              .clamp(0, blockRawText.length);
          int approxRawEnd = (blockRawText.length * endRatio)
              .round()
              .clamp(0, blockRawText.length);

          if (approxRawStart < approxRawEnd) {
            effectiveRanges.add((
              range: TextRange(start: approxRawStart, end: approxRawEnd),
              isUserHighlight: false,
              isTtsHighlight: true
            ));
          }
        }
      }
    }

    effectiveRanges.sort((a, b) => a.range.start.compareTo(b.range.start));

    List<({TextRange range, bool isUserHighlight, bool isTtsHighlight})>
        mergedRanges = [];
    if (effectiveRanges.isNotEmpty) {
      mergedRanges.add(effectiveRanges.first);
      for (int i = 1; i < effectiveRanges.length; i++) {
        var current = effectiveRanges[i];
        var lastMerged = mergedRanges.last;
        if (current.range.start <= lastMerged.range.end) {
          mergedRanges[mergedRanges.length - 1] = (
            range: TextRange(
                start: lastMerged.range.start,
                end: current.range.end > lastMerged.range.end
                    ? current.range.end
                    : lastMerged.range.end),
            isUserHighlight:
                lastMerged.isUserHighlight || current.isUserHighlight,
            isTtsHighlight: lastMerged.isTtsHighlight || current.isTtsHighlight
          );
        } else {
          mergedRanges.add(current);
        }
      }
    }

    int currentRawPos = 0;
    for (var item in mergedRanges) {
      final range = item.range;
      if (range.start > currentRawPos) {
        spans.add(TextSpan(
            text: blockRawText.substring(currentRawPos, range.start),
            style: baseStyle));
      }
      TextStyle effectiveStyle = baseStyle ?? const TextStyle();
      Color? highlightBgColor;
      Color? highlightFgColor;
      if (item.isTtsHighlight) {
        highlightBgColor = AppColors.secondaryAccent.withOpacity(0.35);
        if (item.isUserHighlight) {
          highlightBgColor = AppColors.yellowHighlight.withOpacity(0.4);
        }
      } else if (item.isUserHighlight) {
        highlightBgColor = AppColors.yellowHighlight.withOpacity(0.6);
        highlightFgColor = AppColors.darkBackground.withOpacity(0.9);
      }
      effectiveStyle = effectiveStyle.copyWith(
          backgroundColor: highlightBgColor,
          color: highlightFgColor ?? effectiveStyle.color);
      spans.add(TextSpan(
          text: blockRawText.substring(
              range.start, range.end.clamp(range.start, blockRawText.length)),
          style: effectiveStyle));
      currentRawPos = range.end.clamp(0, blockRawText.length);
    }

    if (currentRawPos < blockRawText.length) {
      spans.add(TextSpan(
          text: blockRawText.substring(currentRawPos), style: baseStyle));
    }
    if (spans.isEmpty && blockRawText.isNotEmpty) {
      spans.add(TextSpan(text: blockRawText, style: baseStyle));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFontFamily = ref.watch(currentFontFamilyProvider);
    final fontSizeMultiplier = ref.watch(currentFontSizeMultiplierProvider);
    final textTheme = _getTextThemeWithFont(
        context, currentFontFamily, fontSizeMultiplier, AppColors.textPrimary);
    final controllerNotifier =
        ref.read(levelContentControllerProvider(controllerArgs).notifier);

    Widget buildRichTextWithTap(String rawBlockText, TextStyle? style) {
      String cleanedBlockText =
          controllerNotifier.cleanTextForTTS(rawBlockText);
      return GestureDetector(
          onTapUp: (details) {
            if (rawBlockText.isEmpty) return;
            final TextSpan span = TextSpan(text: rawBlockText, style: style);
            final TextPainter painter = TextPainter(
                text: span,
                textAlign: TextAlign.start,
                textDirection: TextDirection.ltr);
            final RenderBox? renderBox =
                context.findRenderObject() as RenderBox?;
            final double maxWidth = renderBox?.size.width ??
                MediaQuery.of(context).size.width - (2 * 12.0);
            painter.layout(minWidth: 0, maxWidth: maxWidth);

            try {
              final TextPosition textPosition =
                  painter.getPositionForOffset(details.localPosition);
              final int rawTextTapOffset =
                  textPosition.offset.clamp(0, rawBlockText.length);
              int globalCleanedTextTapOffset =
                  _getGlobalCleanedTextOffsetForTap(
                      ref, block, rawTextTapOffset);

              if (globalCleanedTextTapOffset != -1) {
                controllerNotifier.speakFromOffset(globalCleanedTextTapOffset);
              }
            } catch (e) {
              // Error
            }
          },
          child: SelectableText.rich(
              TextSpan(
                  children: _buildTextSpansForDisplay(
                      ref,
                      block.id,
                      rawBlockText,
                      style,
                      ttsGlobalHighlightRange,
                      blockGlobalStartOffsetCleaned,
                      cleanedBlockText)),
              textAlign: TextAlign.start,
              contextMenuBuilder: (context, editableTextState) {
            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: editableTextState.contextMenuAnchors,
              buttonItems: [
                ContextMenuButtonItem(
                  onPressed: () {
                    final selection =
                        editableTextState.textEditingValue.selection;
                    if (selection.isValid && !selection.isCollapsed) {
                      final selectedText = selection
                          .textInside(editableTextState.textEditingValue.text);
                      if (selectedText.isNotEmpty) {
                        _addSelectedTextToKeyNotes(context, ref, selectedText);
                      }
                    }
                    editableTextState.hideToolbar();
                  },
                  label: "Add to Key Notes",
                ),
              ],
            );
          }));
    }

    TextStyle? getBlockSpecificStyle() {
      switch (block.type) {
        case ContentBlockType.h1:
          return textTheme.headlineLarge;
        case ContentBlockType.h2:
          return textTheme.headlineMedium;
        case ContentBlockType.h3:
          return textTheme.headlineSmall;
        case ContentBlockType.h4:
          return textTheme.titleLarge;
        case ContentBlockType.h5:
          return textTheme.titleMedium;
        case ContentBlockType.h6:
          return textTheme.titleSmall;
        case ContentBlockType.paragraph:
          return textTheme.bodyLarge;
        case ContentBlockType.blockquote:
          return textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary.withOpacity(0.9));
        case ContentBlockType.unorderedListItem:
        case ContentBlockType.orderedListItem:
          return textTheme.bodyMedium;
        case ContentBlockType.codeBlock:
          final codeFontKey = ref.watch(currentFontFamilyProvider) == 'FiraCode'
              ? 'FiraCode'
              : 'RobotoMono';
          return GoogleFonts.getFont(
              codeFontKey == 'FiraCode' ? 'Fira Code' : 'Roboto Mono',
              textStyle: textTheme.bodySmall?.copyWith(
                backgroundColor: AppColors.darkBackground.withOpacity(0.7),
                color: AppColors.textPrimary.withOpacity(0.85),
                height: 1.45,
              ));
        default:
          return textTheme.bodyMedium;
      }
    }

    EdgeInsets getBlockSpecificPadding() {
      switch (block.type) {
        case ContentBlockType.h1:
          return const EdgeInsets.only(
              top: 24.0, bottom: 12.0, left: 4.0, right: 4.0);
        case ContentBlockType.h2:
          return const EdgeInsets.only(
              top: 20.0, bottom: 10.0, left: 4.0, right: 4.0);
        case ContentBlockType.h3:
          return const EdgeInsets.only(
              top: 16.0, bottom: 8.0, left: 4.0, right: 4.0);
        case ContentBlockType.h4:
        case ContentBlockType.h5:
        case ContentBlockType.h6:
          return const EdgeInsets.only(
              top: 12.0, bottom: 6.0, left: 4.0, right: 4.0);
        case ContentBlockType.paragraph:
          return const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0);
        case ContentBlockType.blockquote:
          return const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0);
        case ContentBlockType.unorderedListItem:
        case ContentBlockType.orderedListItem:
          return EdgeInsets.only(
              left: (block.listLevel * 20.0),
              top: 3.0,
              bottom: 3.0,
              right: 4.0);
        case ContentBlockType.codeBlock:
          return const EdgeInsets.symmetric(vertical: 8.0);
        case ContentBlockType.image:
          return const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0);
        case ContentBlockType.horizontalRule:
          return const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0);
        default:
          return const EdgeInsets.all(8.0);
      }
    }

    Widget contentWidget;
    BoxDecoration? ttsBlockHighlightDecoration;
    if (isBlockCurrentlySpokenByTTSGlobal) {
      ttsBlockHighlightDecoration = BoxDecoration(
        color: AppColors.secondaryAccent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(4),
      );
    }

    switch (block.type) {
      case ContentBlockType.h1:
      case ContentBlockType.h2:
      case ContentBlockType.h3:
      case ContentBlockType.h4:
      case ContentBlockType.h5:
      case ContentBlockType.h6:
      case ContentBlockType.paragraph:
        contentWidget =
            buildRichTextWithTap(block.rawContent, getBlockSpecificStyle());
        return Container(
            width: double.infinity,
            decoration: ttsBlockHighlightDecoration,
            padding: getBlockSpecificPadding(),
            child: contentWidget);

      case ContentBlockType.blockquote:
        contentWidget =
            buildRichTextWithTap(block.rawContent, getBlockSpecificStyle());
        return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: (ttsBlockHighlightDecoration ?? const BoxDecoration())
                .copyWith(
                    border: const Border(
                        left: BorderSide(
                            color: AppColors.primaryAccent, width: 4)),
                    color: ttsBlockHighlightDecoration?.color ??
                        AppColors.cardLightBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6)),
            child: contentWidget);

      case ContentBlockType.unorderedListItem:
        contentWidget =
            buildRichTextWithTap(block.rawContent, getBlockSpecificStyle());
        return Container(
            width: double.infinity,
            decoration: ttsBlockHighlightDecoration,
            padding: getBlockSpecificPadding(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: EdgeInsets.only(
                        right: 8.0,
                        top: (getBlockSpecificStyle()?.fontSize ?? 14) * 0.35),
                    child: Icon(Icons.circle,
                        size: (getBlockSpecificStyle()?.fontSize ?? 14) * 0.5,
                        color: AppColors.textSecondary)),
                Expanded(child: contentWidget),
              ],
            ));

      case ContentBlockType.orderedListItem:
        contentWidget =
            buildRichTextWithTap(block.rawContent, getBlockSpecificStyle());
        return Container(
            width: double.infinity,
            decoration: ttsBlockHighlightDecoration,
            padding: getBlockSpecificPadding(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text("${block.listMarker ?? ''} ",
                        style: getBlockSpecificStyle()
                            ?.copyWith(color: AppColors.textSecondary))),
                Expanded(child: contentWidget),
              ],
            ));

      case ContentBlockType.codeBlock:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
              color: AppColors.darkBackground.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.cardLightBackground.withOpacity(0.5),
                  width: 0.5)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(block.rawContent,
                style: getBlockSpecificStyle()),
          ),
        );

      case ContentBlockType.image:
        if (block.imageUrl != null && block.imageUrl!.isNotEmpty) {
          return Padding(
            padding: getBlockSpecificPadding(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                block.imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                      child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: AppColors.secondaryAccent,
                    strokeWidth: 2.0,
                  ));
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(12.0),
                    color: AppColors.cardLightBackground.withOpacity(0.3),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              color: AppColors.orangeWarning, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                              child: Text(
                                  block.imageAltText ?? "Image unavailable",
                                  style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary))),
                        ]),
                  );
                },
              ),
            ),
          );
        }
        return const SizedBox.shrink();

      case ContentBlockType.horizontalRule:
        return Padding(
          padding: getBlockSpecificPadding(),
          child: Divider(
              color: AppColors.textSecondary.withOpacity(0.25),
              height: 1,
              thickness: 1),
        );

      default:
        return Padding(
            padding: getBlockSpecificPadding(),
            child: Text("Unsupported block: ${block.type.name}",
                style: getBlockSpecificStyle()));
    }
  }
}
