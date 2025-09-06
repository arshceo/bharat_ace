import 'package:bharat_ace/widgets/syllabus_screen_widgets/subject_expansion_tile.dart';
import 'package:bharat_ace/widgets/syllabus_screen_widgets/subject_feedback_cards.dart';
import 'package:bharat_ace/widgets/syllabus_screen_widgets/subject_overall_progress_header.dart';
import 'package:bharat_ace/widgets/syllabus_screen_widgets/syllabus_loading_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Import Models and Providers ---
import 'package:bharat_ace/core/models/syllabus_models.dart';
import 'package:bharat_ace/core/providers/syllabus_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/core/providers/progress_provider.dart';
import 'package:bharat_ace/core/models/student_model.dart';

// --- Import App Theme & Widgets ---
import 'package:bharat_ace/core/theme/app_theme.dart';

class SyllabusScreen extends ConsumerWidget {
  const SyllabusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Syllabus> syllabusAsync = ref.watch(syllabusProvider);
    final AsyncValue<StudentModel?> studentAsync =
        ref.watch(studentDetailsProvider);
    final StudentModel? student = studentAsync.valueOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          student != null ? "Class ${student.grade} Syllabus" : "Syllabus",
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkTextPrimary
                : AppTheme.gray900,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
      ),
      body: syllabusAsync.when(
        loading: () => buildSyllabusLoadingState(context),
        error: (error, stackTrace) {
          print("Syllabus Screen Error: $error\n$stackTrace");
          return Center(
            child: buildSyllabusErrorCard(
              context,
              "Oops! Syllabus is on a short break.",
              error,
              () => ref.invalidate(syllabusProvider),
            ),
          );
        },
        data: (syllabus) {
          final subjectsMap = syllabus.subjects;
          if (subjectsMap.isEmpty) {
            return buildSyllabusInfoCard(
              context,
              "No Syllabus Yet!",
              "It looks like the syllabus for your class hasn't been uploaded. Please check back later.",
              Icons.menu_book_rounded,
              AppTheme.primary,
            );
          }
          final subjectNames = subjectsMap.keys.toList()..sort();

          // --- Dynamic Progress Calculation ---
          int totalOverallChapters = 0;
          int completedOverallChapters = 0;
          Map<
              String,
              ({
                int total,
                int completed,
                List<ChapterDetailed> allChapters
              })> subjectProgressData = {};

          for (final subjectName in subjectNames) {
            final subjectData = subjectsMap[subjectName]!;
            int totalChaptersInSubject = 0;
            int completedChaptersInSubject = 0;
            List<ChapterDetailed> allChaptersForSubject = [];

            void processChaptersList(
              List<ChapterDetailed> chapters,
              String progressContextSubjectName,
            ) {
              for (final chapter in chapters) {
                allChaptersForSubject
                    .add(chapter); // Collect all chapters for this main subject
                totalOverallChapters++;
                totalChaptersInSubject++;
                final chapterProgress = ref.watch(chapterProgressProvider((
                  subject: progressContextSubjectName,
                  chapterId: chapter.chapterId
                )));
                if (chapterProgress.valueOrNull?.currentLevel == "Mastered") {
                  completedOverallChapters++;
                  completedChaptersInSubject++;
                }
              }
            }

            if (subjectData.chapters.isNotEmpty) {
              processChaptersList(subjectData.chapters, subjectName);
            } else if (subjectData.subSubjects != null &&
                subjectData.subSubjects!.isNotEmpty) {
              subjectData.subSubjects!
                  .forEach((subSubjectKey, subSubjectDetail) {
                processChaptersList(subSubjectDetail.chapters, subSubjectKey);
              });
            }
            subjectProgressData[subjectName] = (
              total: totalChaptersInSubject,
              completed: completedChaptersInSubject,
              allChapters:
                  allChaptersForSubject // This list is for this main subject
            );
          }

          final double overallProgress = totalOverallChapters > 0
              ? completedOverallChapters / totalOverallChapters
              : 0.0;
          // --- End Progress Calculation ---

          return Column(
            children: [
              SyllabusOverallProgressHeader(
                overallProgress: overallProgress,
                textTheme: AppTheme.textTheme,
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: -0.1, duration: 400.ms, curve: Curves.easeOut),
              const Divider(height: 1, color: AppTheme.gray200, thickness: 1),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                  itemCount: subjectNames.length,
                  itemBuilder: (context, index) {
                    final subjectName = subjectNames[index];
                    final SubjectDetailed? subjectDetailed =
                        subjectsMap[subjectName];
                    final progressTuple = subjectProgressData[subjectName];

                    if (subjectDetailed == null || progressTuple == null) {
                      print(
                          "CRITICAL ERROR in SyllabusScreen itemBuilder: Data missing for subject '$subjectName'. "
                          "subjectDetailed is null: ${subjectDetailed == null}, "
                          "progressTuple is null: ${progressTuple == null}. "
                          "Skipping card for this subject.");
                      return const SizedBox.shrink();
                    }

                    return SubjectExpansionTile(
                      key: ValueKey(
                          'subject_tile_$subjectName'), // Unique key for SubjectExpansionTile
                      subjectName: subjectName,
                      subjectData: subjectDetailed,
                      textTheme: AppTheme.textTheme,
                      progressInfo: progressTuple,
                      itemIndex: index,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
