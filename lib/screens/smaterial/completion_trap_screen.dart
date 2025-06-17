// lib/screens/smaterial/completion_trap_screen.dart
import 'package:bharat_ace/core/models/student_model.dart' show StudentModel;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/providers/progress_provider.dart';
import 'package:bharat_ace/core/services/gemini_service.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';

class CompletionTrapScreen extends ConsumerStatefulWidget {
  final String subjectName;
  final String chapterId;
  final String levelName; // Current level being completed
  final ChapterDetailed chapterData;

  const CompletionTrapScreen({
    super.key,
    required this.subjectName,
    required this.chapterId,
    required this.levelName,
    required this.chapterData,
  });

  @override
  ConsumerState<CompletionTrapScreen> createState() =>
      _CompletionTrapScreenState();
}

class _CompletionTrapScreenState extends ConsumerState<CompletionTrapScreen> {
  final _summaryController = TextEditingController();
  bool _isLoading = false;
  String? _feedbackMessageText;
  bool _summaryPassed = false;

  // CORRECTED: Ensure this matches the string used in LevelContentController (singular)
  bool get _isPrerequisiteLevel =>
      widget.levelName.toLowerCase() == 'prerequisite';

  Future<void> _submitSummary() async {
    final studentSummaryText = _summaryController.text.trim();
    if (studentSummaryText.isEmpty) {
      setState(() {
        _feedbackMessageText = _isPrerequisiteLevel
            ? "Please note down at least one key point you recall."
            : "Please enter a summary.";
        _summaryPassed = false;
        _isLoading = false; // Ensure isLoading is false here
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _feedbackMessageText = null;
    });

    SummaryEvaluation evaluation;
    try {
      // This ref.read() itself could throw if GeminiService constructor fails (e.g. API key)
      final geminiService = ref.read(geminiEvaluationServiceProvider);

      final List<String> topicsForEvaluation = _isPrerequisiteLevel
          ? widget.chapterData.prerequisites
          : widget.chapterData.coreTopics;

      final String contextTitle =
          "${widget.chapterData.chapterTitle} - ${widget.levelName}";

      print(
          "Submitting to Gemini: isPrereq=$_isPrerequisiteLevel, summary='${studentSummaryText.substring(0, studentSummaryText.length > 50 ? 50 : studentSummaryText.length)}...'");

      evaluation = await geminiService.evaluateStudentSummary(
        studentSummary: studentSummaryText,
        coreTopics: topicsForEvaluation,
        chapterOrLevelTitle: contextTitle,
        isPrerequisiteSummary: _isPrerequisiteLevel,
      );
    } catch (e, s) {
      print("Error during Gemini Service call or initialization: $e\n$s");
      setState(() {
        _isLoading = false;
        _feedbackMessageText =
            "An error occurred while evaluating: ${e.toString()}. Please check your API key or network and try again.";
        _summaryPassed = false;
      });
      return; // Exit if Gemini call failed
    }

    // This setState is crucial and should be reached if the try block above succeeds.
    setState(() {
      _isLoading = false; // Set isLoading false after Gemini evaluation
      _feedbackMessageText = evaluation.feedback;
      _summaryPassed = evaluation.passed;
    });

    if (_summaryPassed) {
      final AsyncValue<StudentModel?> studentAsync =
          ref.read(studentDetailsProvider);
      final StudentModel? student =
          studentAsync.valueOrNull; // Get StudentModel?
      final String? studentId = student?.id; // Then get id
      if (studentId == null || studentId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Error: Student not identified. Cannot save progress."),
                backgroundColor: Colors.red),
          );
        }
        // _isLoading is already false here, no need to setState unless changing other UI based on this error
        return;
      }

      // Optionally, set _isLoading to true again for the saving phase if you want a visual indicator for it
      setState(() {
        _isLoading =
            true; // For "Fantastic! Saving progress..." and disabling back button
      });

      try {
        await ref.read(progressProvider.notifier).updateLevelCompletion(
              studentId: studentId,
              subject: widget.subjectName,
              chapterId: widget.chapterId,
              levelNameCompleted: widget.levelName,
              allChapterLevels:
                  widget.chapterData.levels.map((l) => l.levelName).toList(),
              chapterTitle: widget
                  .chapterData.chapterTitle, // <-- PASS CHAPTER TITLE HERE
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    _feedbackMessageText ?? "Great! Level progress saved."),
                backgroundColor: Colors.green),
          );
          // "Fantastic! Saving progress..." text is visible due to _isLoading = true & _summaryPassed = true
          // Button is hidden because _summaryPassed = true
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
            // If not mounted, no need to change _isLoading, as the screen is gone.
            // If still mounted (e.g., pop failed for some reason), ensure _isLoading is false.
            else if (_isLoading) {
              // This case is unlikely if pop succeeds, but good for robustness.
              // However, directly calling setState here after an async gap without checking mounted again is risky.
              // The pop should handle leaving the screen.
            }
          });
        }
      } catch (e, s) {
        print("Error saving progress: $e\n$s");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Error saving progress: $e"),
                backgroundColor: Colors.red),
          );
        }
        setState(() {
          _isLoading = false; // CRITICAL: Reset isLoading on save error
        });
      }
    } else {
      // Summary did NOT pass, _isLoading is already false from after Gemini eval
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_feedbackMessageText ??
                  "Please review your input and try again."),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine dynamic texts based on whether it's a prerequisite level
    final String instructionText = _isPrerequisiteLevel
        ? "You've reviewed the prerequisites for '${widget.chapterData.chapterTitle}'.\n\nTo ensure you've got the basics, please briefly note down 1-2 key things you recall or understood from the prerequisite material:"
        : "You've reached the end of '${widget.levelName}' for '${widget.chapterData.chapterTitle}'.\n\nTo ensure you've grasped the key concepts, please summarize what you've just learned in 2-3 bullet points or a short paragraph:";

    final String hintTextFieldText = _isPrerequisiteLevel
        ? "What do you remember? (e.g., a key term, a main idea)"
        : "Your summary here...\n- Point 1\n- Point 2 (Optional)\n- Point 3 (Optional)";

    Widget hintSection = const SizedBox.shrink();
    if (_isPrerequisiteLevel) {
      if (widget.chapterData.prerequisites.isNotEmpty) {
        hintSection = Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            "Hint: Think about topics like: ${widget.chapterData.prerequisites.take(2).join(', ')}${widget.chapterData.prerequisites.length > 2 ? '...' : ''}",
            style:
                TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        );
      } else {
        hintSection = Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            "Hint: Mention any general concepts or terms you recall from the prerequisite information.",
            style:
                TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        );
      }
    } else if (widget.chapterData.coreTopics.isNotEmpty) {
      hintSection = Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          "Hint: Try to touch upon topics like: ${widget.chapterData.coreTopics.take(3).join(', ')}${widget.chapterData.coreTopics.length > 3 ? '...' : ''}",
          style:
              TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${_isPrerequisiteLevel ? 'Recall Check' : 'Summarize'}: ${widget.chapterData.chapterTitle} - ${widget.levelName}"),
        automaticallyImplyLeading: !(_summaryPassed && _isLoading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CORRECTED: Use the dynamic instructionText as the primary instruction
            Text(
              instructionText,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            hintSection, // Display the dynamic hint section
            TextField(
              controller: _summaryController,
              maxLines: _isPrerequisiteLevel ? 5 : 7,
              minLines: _isPrerequisiteLevel ? 3 : 4,
              decoration: InputDecoration(
                hintText: hintTextFieldText,
                border: const OutlineInputBorder(),
              ),
              enabled: !_isLoading &&
                  !_summaryPassed, // Disable if loading OR if already passed and awaiting pop
            ),
            const SizedBox(height: 20),
            if (_isLoading &&
                !_summaryPassed) // Show spinner only when initially loading Gemini
              const Center(child: CircularProgressIndicator())
            else if (_isLoading &&
                _summaryPassed) // Show "Fantastic! Saving progress..."
              Padding(
                padding: const EdgeInsets.only(top: 0.0), // Adjusted padding
                child: Column(
                  // Wrap in column for spinner + text
                  children: [
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 10),
                    Text(
                      "Fantastic! Saving progress...",
                      style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (!_summaryPassed) // Show button only if not passed and not loading
              ElevatedButton(
                onPressed: _submitSummary,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(_isPrerequisiteLevel
                    ? "Submit & Continue"
                    : "Submit Summary & Complete Level"),
              ),
            if (_feedbackMessageText != null &&
                !_isLoading) // Show feedback only when not loading
              Padding(
                // Added Padding for feedback
                padding: const EdgeInsets.only(top: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _summaryPassed
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _summaryPassed
                            ? Colors.green.shade600
                            : Colors.orange.shade600),
                  ),
                  child: Text(
                    _feedbackMessageText!,
                    style: TextStyle(
                        color: _summaryPassed
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
