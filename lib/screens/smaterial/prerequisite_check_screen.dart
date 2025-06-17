// lib/screens/smaterial/prerequisite_check_screen.dart
import 'package:bharat_ace/core/services/ai_content_service.dart';
import 'package:bharat_ace/core/services/summarization_service.dart'
    show aiChatServiceProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/providers/progress_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import '../../features/level_content/screens/level_content_screen.dart'; // For navigation

// New imports for Markdown to HTML
import 'package:markdown/markdown.dart' as md_parser;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:bharat_ace/core/utils/color_extensions.dart';
import 'package:google_fonts/google_fonts.dart';

class PrerequisiteCheckScreen extends ConsumerStatefulWidget {
  final String subject;
  final String chapterId;
  final ChapterDetailed chapterData;

  const PrerequisiteCheckScreen({
    super.key,
    required this.subject,
    required this.chapterId,
    required this.chapterData,
  });

  @override
  ConsumerState<PrerequisiteCheckScreen> createState() =>
      _PrerequisiteCheckScreenState();
}

class _PrerequisiteCheckScreenState
    extends ConsumerState<PrerequisiteCheckScreen> {
  bool _isLoading = false; // For overall screen actions like acknowledgement
  bool _isGeneratingExplanation = true; // Tracks AI content generation phase
  String _aiGeneratedExplanation = '';
  bool _dialogShownOnce =
      false; // To prevent dialog from re-showing automatically

  @override
  void initState() {
    super.initState();
    print("--- PrerequisiteCheckScreen initState ---");
    print("Chapter ID: ${widget.chapterId}");
    print("Chapter Title: ${widget.chapterData.chapterTitle}");
    print(
        "Received prerequisites (length: ${widget.chapterData.prerequisites.length}): ${widget.chapterData.prerequisites}");
    print("--- End PrerequisiteCheckScreen initState ---");
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    // If no prerequisites, acknowledge and proceed automatically.
    if (widget.chapterData.prerequisites.isEmpty) {
      print(
          "No prerequisites for ${widget.chapterData.chapterTitle}, proceeding automatically...");
      // Ensure state is updated to reflect no generation needed
      if (mounted) {
        setState(() {
          _isGeneratingExplanation = false;
        });
      }
      // Use WidgetsBinding.instance.addPostFrameCallback to ensure build context is ready for navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handlePrerequisiteAcknowledgement(context, true);
      });
      return;
    }

    // Prerequisites exist, start generating explanation.
    if (mounted) {
      setState(() {
        _isGeneratingExplanation = true;
        _aiGeneratedExplanation = ''; // Reset if re-entering
      });
    }

    final studentAsync = ref.read(studentDetailsProvider);
    final student = studentAsync.value;

    if (student == null) {
      if (mounted) {
        setState(() {
          _isGeneratingExplanation = false;
          _aiGeneratedExplanation = "Error: Student data not available.";
        });
        // Show dialog even if student data is not available, to display listed prerequisites
        _attemptShowDialog();
      }
      return;
    }

    final aiService =
        AIContentGenerationService(ref.read(aiChatServiceProvider));
    try {
      final result = await aiService.generatePrerequisiteExplanation(
        subject: widget.subject,
        chapterTitle: widget.chapterData.chapterTitle,
        prerequisites: widget.chapterData.prerequisites,
        studentClass: student.grade,
      );
      if (mounted) {
        setState(() {
          _aiGeneratedExplanation = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiGeneratedExplanation = "Error generating AI explanation: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingExplanation = false;
        });
        _attemptShowDialog();
      }
    }
  }

  void _attemptShowDialog() {
    // Show dialog only once automatically after data loading.
    // Subsequent shows must be via button tap.
    if (mounted &&
        !_dialogShownOnce &&
        widget.chapterData.prerequisites.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showPrerequisiteDialog();
          setState(() {
            _dialogShownOnce = true;
          });
        }
      });
    }
  }

  Future<void> _handlePrerequisiteAcknowledgement(
      BuildContext context, bool acknowledgedAndReady) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final studentAsync = ref.read(studentDetailsProvider);
    final student = studentAsync.value;

    if (student == null || student.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Error: Student not found. Cannot update progress.")),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    if (acknowledgedAndReady) {
      try {
        // Pass the new 'chapterHasPrerequisites' parameter
        await ref.read(progressProvider.notifier).markPrerequisitesAsChecked(
              studentId: student.id,
              subject: widget.subject,
              chapterId: widget.chapterId,
              chapterHasPrerequisites:
                  widget.chapterData.prerequisites.isNotEmpty, // <-- ADD THIS
            );

        // Refresh the progress to get the new currentLevel
        // Ensure you are using the stream provider correctly here.
        // '.future' is correct if you want to await the next emission after invalidation.
        final updatedProgress = await ref.refresh(chapterProgressStreamProvider(
            (subject: widget.subject, chapterId: widget.chapterId)).future);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Great! Let's begin the chapter."),
                backgroundColor: AppColors.greenSuccess),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LevelContentScreen(
                subject: widget.subject,
                chapterId: widget.chapterId,
                levelName: updatedProgress
                    .currentLevel, // This should now be "Prerequisites" if they existed
                chapterData: widget.chapterData,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating progress: $e")),
          );
          setState(() => _isLoading = false);
        }
      }
    } else {
      // User clicked "I Need to Review"
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Please ensure you're comfortable with the prerequisites before starting.")),
        );
        setState(() => _isLoading = false); // Reset loading state
      }
    }
  }

  void _showPrerequisiteDialog() {
    if (!mounted) return;

    // This check is now mostly a safeguard, primary logic is in _loadInitialData
    if (widget.chapterData.prerequisites.isEmpty && !_isGeneratingExplanation) {
      print(
          "Dialog: No prerequisites detected, should have auto-proceeded. This is a fallback.");
      _handlePrerequisiteAcknowledgement(context, true);
      return;
    }

    final bool hasErrorInExplanation =
        _aiGeneratedExplanation.startsWith("Error:");
    final String htmlExplanation =
        (_aiGeneratedExplanation.isNotEmpty && !hasErrorInExplanation)
            ? md_parser.markdownToHtml(
                _aiGeneratedExplanation,
                extensionSet: md_parser.ExtensionSet.gitHubWeb,
              )
            : _aiGeneratedExplanation; // Show error message directly

    showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Before You Start: '${widget.chapterData.chapterTitle}'",
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text("This chapter builds upon the following concepts:",
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              ...widget.chapterData.prerequisites.map((prereqText) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("• ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryAccent)),
                        Expanded(
                            child: Text(prereqText,
                                style:
                                    TextStyle(color: AppColors.textPrimary))),
                      ],
                    ),
                  )),
              const SizedBox(height: 15),
              Text("Are you familiar with these topics?",
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              if (_isGeneratingExplanation)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                      child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.secondaryAccent),
                  )),
                ),
              if (!_isGeneratingExplanation && htmlExplanation.isNotEmpty) ...[
                const Divider(height: 20, color: AppColors.cardLightBackground),
                Text(
                  hasErrorInExplanation
                      ? "AI Explanation Status:"
                      : "AI Explanation:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: HtmlWidget(
                    htmlExplanation,
                    textStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textPrimary),
                    customStylesBuilder: (element) {
                      if (element.localName == 'p') {
                        return {'margin-bottom': '8px', 'line-height': '1.5'};
                      }
                      if (element.localName == 'code') {
                        return {
                          'font-family':
                              GoogleFonts.firaCode().fontFamily ?? 'monospace',
                          'background-color': AppColors.darkBackground
                              .withOpacity(0.7)
                              .toCssRgbaString(),
                          'color': AppColors.primaryAccent.toCssRgbaString(),
                          'padding': '2px 6px',
                          'border-radius': '4px',
                          'font-size': '0.9em',
                        };
                      }
                      if (element.localName == 'pre') {
                        return {
                          'background-color': AppColors.darkBackground
                              .withOpacity(0.8)
                              .toCssRgbaString(),
                          'color': AppColors.textSecondary.toCssRgbaString(),
                          'padding': '12px',
                          'margin': '10px 0px',
                          'border-radius': '8px',
                          'overflow-x':
                              'auto', // Horizontal scroll for long code
                          'font-size': '0.9em',
                        };
                      }
                      if (element.localName == 'ul' ||
                          element.localName == 'ol') {
                        return {'padding-left': '20px'};
                      }
                      if (element.localName == 'li') {
                        return {'margin-bottom': '4px'};
                      }
                      return null;
                    },
                  ),
                ),
              ]
            ],
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: <Widget>[
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(ctx).pop(false); // Dialog returns false
                    _handlePrerequisiteAcknowledgement(context, false);
                  },
            child: const Text('I Need to Review'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor:
                  AppColors.darkBackground, // Or AppColors.textOnPrimary
            ),
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(ctx).pop(true); // Dialog returns true
                    _handlePrerequisiteAcknowledgement(context, true);
                  },
            child: const Text("Yes, I'm Ready"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          "Prerequisites: ${widget.chapterData.chapterTitle}",
          style: textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 1,
        automaticallyImplyLeading: false, // User must interact with dialog
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Center(
        child: (_isLoading ||
                (_isGeneratingExplanation &&
                    widget.chapterData.prerequisites.isNotEmpty))
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondaryAccent)),
                  const SizedBox(height: 24),
                  Text("Preparing prerequisites...",
                      style: textTheme.bodyLarge
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              )
            : Padding(
                // Content to show if not loading and dialog is not yet auto-shown or was dismissed
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_books_outlined,
                        size: 70,
                        color: AppColors.primaryAccent.withOpacity(0.8)),
                    const SizedBox(height: 24),
                    Text(
                      widget.chapterData.prerequisites.isEmpty
                          ? "No specific prerequisites listed. Getting chapter ready..." // Should auto-proceed
                          : "Please review the prerequisite concepts for '${widget.chapterData.chapterTitle}'.",
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                    if (widget.chapterData.prerequisites.isNotEmpty &&
                        !_isLoading) ...[
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.checklist_rtl_rounded),
                        label: const Text("Show Prerequisites"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryAccent,
                          foregroundColor: AppColors
                              .yellowHighlight, // Assuming you have a textOnAccent color
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          textStyle: textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isLoading || _isGeneratingExplanation
                            ? null
                            : _showPrerequisiteDialog,
                      )
                    ]
                  ],
                ),
              ),
      ),
    );
  }
}
