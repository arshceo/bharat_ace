// lib/widgets/ai_quiz_system.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:convert';
import '../core/theme/app_theme.dart';
import '../core/models/study_task_model.dart';
import 'professional_card.dart' as widgets;

// AI Quiz Models
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

class QuizResult {
  final List<int> userAnswers;
  final List<QuizQuestion> questions;
  final String userSummary;
  final bool summaryApproved;
  final int score;

  QuizResult({
    required this.userAnswers,
    required this.questions,
    required this.userSummary,
    required this.summaryApproved,
    required this.score,
  });

  bool get isPassed =>
      score >= (questions.length * 0.7) && summaryApproved; // 70% pass rate
}

// AI Quiz Provider
final aiQuizProvider =
    StateNotifierProvider<AIQuizNotifier, AsyncValue<List<QuizQuestion>>>(
        (ref) {
  return AIQuizNotifier();
});

class AIQuizNotifier extends StateNotifier<AsyncValue<List<QuizQuestion>>> {
  AIQuizNotifier() : super(const AsyncValue.data([]));

  Future<void> generateQuiz(StudyTask task) async {
    state = const AsyncValue.loading();
    try {
      final model = ai.GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API']?.replaceAll('"', '') ?? '',
      );
      final prompt = '''
You are an expert educational content creator specializing in ${task.subject}. Create a comprehensive and engaging quiz that thoroughly tests understanding of "${task.topic}" from the chapter "${task.chapter}".

IMPORTANT: Return ONLY valid JSON with HTML content for beautiful rendering, no markdown formatting, no code blocks, no additional text.

{
  "questions": [
    {
      "question": "<div style='background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 15px; color: white; box-shadow: 0 8px 32px rgba(0,0,0,0.1);'><h3 style='margin: 0; font-size: 18px; font-weight: bold; margin-bottom: 10px;'>🧠 Question Text</h3><p style='margin: 0; font-size: 16px; line-height: 1.6;'>Clear, specific question that tests deep understanding with beautiful formatting</p></div>",
      "options": ["<span style='color: #2563eb; font-weight: 600;'>Option A</span>", "<span style='color: #2563eb; font-weight: 600;'>Option B</span>", "<span style='color: #2563eb; font-weight: 600;'>Option C</span>", "<span style='color: #2563eb; font-weight: 600;'>Option D</span>"],
      "correctAnswerIndex": 0,
      "explanation": "<div style='background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); padding: 20px; border-radius: 15px; color: white; margin: 10px 0;'><h4 style='margin: 0 0 10px 0; display: flex; align-items: center;'><span style='margin-right: 8px; font-size: 20px;'>💡</span>Why This Answer is Correct</h4><p style='margin: 0; line-height: 1.6; font-size: 15px;'>Detailed explanation with <strong>key concepts highlighted</strong> and <em style='color: #fef3c7;'>important terms emphasized</em> to help students understand and remember</p></div>"
    }
  ]
}

Requirements for Beautiful HTML Content:
- Use vibrant gradient backgrounds: linear-gradient(135deg, color1, color2)
- Add proper spacing with padding: 15-25px
- Use border-radius: 10-20px for rounded corners  
- Include emoji icons (🧠, 💡, ⚡, 🎯, 📚, 🔍, etc.) to make it engaging
- Use color-coded text: #2563eb for options, #10b981 for correct info, #ef4444 for warnings
- Add subtle shadows: box-shadow: 0 4px 20px rgba(0,0,0,0.1)
- Use proper typography hierarchy with h3, h4, p tags
- Make explanations educational with <strong> and <em> tags for emphasis
- Generate exactly 5 multiple choice questions
- Each question should test different aspects: conceptual understanding, application, analysis, and problem-solving
- Questions should be challenging but fair for the academic level
- Options should be plausible and avoid obvious incorrect answers
- Explanations should be educational and help students learn from mistakes
- Focus on ${task.subject} concepts related to ${task.topic}
- Include real-world applications where relevant
- Vary question difficulty from moderate to challenging

Return ONLY the JSON structure above with beautiful HTML formatting.
''';
      final content = [ai.Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text?.trim() ?? '';
      // Try to parse JSON robustly
      Map<String, dynamic>? jsonData;
      try {
        jsonData = jsonDecode(responseText);
      } catch (_) {
        // Fallback: try to extract JSON substring
        final jsonStart = responseText.indexOf('{');
        final jsonEnd = responseText.lastIndexOf('}') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonString = responseText.substring(jsonStart, jsonEnd);
          jsonData = jsonDecode(jsonString);
        } else {
          throw Exception('Could not parse quiz JSON.');
        }
      }
      final questions = (jsonData!['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList();
      state = AsyncValue.data(questions);
    } catch (e) {
      print('Error generating quiz: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> validateSummary(String summary, StudyTask task) async {
    try {
      final model = ai.GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API'] ?? '', // FIX: Use correct env key
      );

      final prompt = '''
You are an expert educator evaluating a student's understanding of "${task.topic}" from ${task.subject} subject.

Student Summary: "$summary"

Evaluate this summary comprehensively based on:

1. ACCURACY (25%): Are the facts and concepts correct?
2. COMPLETENESS (25%): Does it cover the key concepts of ${task.topic}?
3. UNDERSTANDING (25%): Does the student demonstrate genuine comprehension beyond memorization?
4. CLARITY (25%): Is the explanation well-structured and clearly communicated?

Scoring Guidelines:
- 9-10: Exceptional understanding with insightful connections
- 7-8: Good understanding with minor gaps or unclear explanations
- 5-6: Basic understanding but missing key concepts or significant errors
- 3-4: Limited understanding with major gaps or misconceptions
- 1-2: Minimal understanding, mostly incorrect or irrelevant

Return ONLY valid JSON:
{
  "score": 8,
  "approved": true,
  "feedback": "Detailed constructive feedback explaining strengths and areas for improvement, with specific suggestions for better understanding of ${task.topic}"
}

A summary must score at least 7 to be approved. Provide encouraging but honest feedback that helps the student improve.
''';

      final content = [ai.Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}') + 1;
      final jsonString = responseText.substring(jsonStart, jsonEnd);

      final jsonData = jsonDecode(jsonString);
      return jsonData['approved'] == true;
    } catch (e) {
      print('Error validating summary: $e');
      return false;
    }
  }
}

// AI Quiz Screen Widget
class AIQuizScreen extends ConsumerStatefulWidget {
  final StudyTask task;
  final VoidCallback onQuizPassed;
  final VoidCallback onQuizFailed;

  const AIQuizScreen({
    super.key,
    required this.task,
    required this.onQuizPassed,
    required this.onQuizFailed,
  });

  @override
  ConsumerState<AIQuizScreen> createState() => _AIQuizScreenState();
}

class _AIQuizScreenState extends ConsumerState<AIQuizScreen> {
  PageController _pageController = PageController();
  List<int> _userAnswers = [];
  // Removed unused _answerFeedback field
  TextEditingController _summaryController = TextEditingController();
  bool _isSubmitting = false;
  // Removed unused _currentQuestionIndex field

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiQuizProvider.notifier).generateQuiz(widget.task);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(aiQuizProvider);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.task.subject} Quiz',
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            Text(
              widget.task.topic ?? 'Study Topic',
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.gray600,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.white,
        elevation: 2,
        shadowColor: AppTheme.gray900.withOpacity(0.1),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppTheme.spaceMD),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMD,
                  vertical: AppTheme.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  'AI Generated',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: quizState.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Text(
                'Generating Your Quiz...',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                'AI is creating personalized questions for ${widget.task.topic ?? "your topic"}',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        error: (error, stack) => _buildErrorState(),
        data: (questions) {
          if (questions.isEmpty) {
            return _buildErrorState();
          }

          // Initialize user answers
          if (_userAnswers.length != questions.length) {
            _userAnswers = List.filled(questions.length, -1);
          }

          return PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...questions.asMap().entries.map((entry) =>
                  _buildQuestionPage(entry.value, entry.key, questions.length)),
              _buildSummaryPage(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: widgets.ProfessionalCard(
          color: AppTheme.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 40,
                    color: AppTheme.error,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Text(
                'Quiz Generation Failed',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                'Our AI couldn\'t generate the quiz right now. This might be due to network issues or high demand.',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back),
                      label: Text('Go Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.gray700,
                        side: BorderSide(color: AppTheme.gray300),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(aiQuizProvider.notifier)
                            .generateQuiz(widget.task);
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(
      QuizQuestion question, int questionIndex, int totalQuestions) {
    final isAnswered = _userAnswers[questionIndex] != -1;
    final selectedIndex = _userAnswers[questionIndex];
    final isCorrect =
        isAnswered && selectedIndex == question.correctAnswerIndex;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced progress indicator with statistics
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${questionIndex + 1} of $totalQuestions',
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMD,
                        vertical: AppTheme.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.gray100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Text(
                        '${((questionIndex + 1) / totalQuestions * 100).round()}%',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMD),
                LinearProgressIndicator(
                  value: (questionIndex + 1) / (totalQuestions + 1),
                  backgroundColor: AppTheme.gray200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 6,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceLG),

          // Question card with enhanced styling
          widgets.ProfessionalCard(
            color: AppTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.quiz_outlined,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Text(
                        'Question ${questionIndex + 1}',
                        style: AppTheme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceLG),
                Html(
                  data: question.question,
                  shrinkWrap: true,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    "div": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.all(0),
                    ),
                    "h3": Style(
                      color: AppTheme.gray900,
                      fontSize: FontSize(18),
                      fontWeight: FontWeight.bold,
                      margin: Margins.only(bottom: 10),
                    ),
                    "p": Style(
                      color: AppTheme.gray900,
                      fontSize: FontSize(16),
                      lineHeight: LineHeight(1.6),
                      margin: Margins.zero,
                    ),
                    "span": Style(
                      color: AppTheme.gray900,
                      fontSize: FontSize(16),
                    ),
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceLG),

          // Options list with enhanced styling
          ...List.generate(question.options.length, (optionIndex) {
            final isSelected = _userAnswers[questionIndex] == optionIndex;
            final isOptionCorrect = optionIndex == question.correctAnswerIndex;

            Color cardColor;
            Color borderColor;
            Color textColor;
            IconData? iconData;

            if (isAnswered) {
              if (isSelected) {
                if (isOptionCorrect) {
                  cardColor = AppTheme.success.withOpacity(0.1);
                  borderColor = AppTheme.success;
                  textColor = AppTheme.success;
                  iconData = Icons.check_circle;
                } else {
                  cardColor = AppTheme.error.withOpacity(0.1);
                  borderColor = AppTheme.error;
                  textColor = AppTheme.error;
                  iconData = Icons.cancel;
                }
              } else if (isOptionCorrect) {
                cardColor = AppTheme.success.withOpacity(0.05);
                borderColor = AppTheme.success.withOpacity(0.3);
                textColor = AppTheme.success;
                iconData = Icons.check_circle_outline;
              } else {
                cardColor = AppTheme.gray50;
                borderColor = AppTheme.gray200;
                textColor = AppTheme.gray600;
              }
            } else {
              if (isSelected) {
                cardColor = AppTheme.primary.withOpacity(0.1);
                borderColor = AppTheme.primary;
                textColor = AppTheme.primary;
              } else {
                cardColor = AppTheme.white;
                borderColor = AppTheme.gray300;
                textColor = AppTheme.gray900;
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
              child: GestureDetector(
                onTap: isAnswered
                    ? null
                    : () {
                        setState(() {
                          _userAnswers[questionIndex] = optionIndex;
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spaceLG),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(
                      color: borderColor,
                      width:
                          isSelected || (isAnswered && isOptionCorrect) ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected && !isAnswered)
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected || (isAnswered && isOptionCorrect)
                              ? borderColor
                              : AppTheme.gray200,
                        ),
                        child: Center(
                          child: iconData != null
                              ? Icon(
                                  iconData,
                                  color: AppTheme.white,
                                  size: 18,
                                )
                              : Text(
                                  String.fromCharCode(65 + optionIndex),
                                  style:
                                      AppTheme.textTheme.bodyMedium?.copyWith(
                                    color: isSelected
                                        ? AppTheme.white
                                        : AppTheme.gray600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMD),
                      Expanded(
                        child: Html(
                          data: question.options[optionIndex],
                          shrinkWrap: true,
                          style: {
                            "body": Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                            ),
                            "p": Style(
                              color: textColor,
                              fontSize: FontSize(16),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              margin: Margins.zero,
                            ),
                            "span": Style(
                              color: textColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: FontSize(16),
                            ),
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (isAnswered)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.spaceMD),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(AppTheme.spaceLG),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(
                      color: isCorrect
                          ? AppTheme.success.withOpacity(0.3)
                          : AppTheme.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                isCorrect
                                    ? Icons.emoji_emotions
                                    : Icons.lightbulb,
                                color: AppTheme.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceMD),
                          Expanded(
                            child: Text(
                              isCorrect
                                  ? 'Excellent! That\'s correct!'
                                  : 'Good attempt! Let\'s learn from this:',
                              style: AppTheme.textTheme.titleMedium?.copyWith(
                                color: isCorrect
                                    ? AppTheme.success
                                    : AppTheme.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: AppTheme.spaceMD),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceMD),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.success,
                                size: 20,
                              ),
                              const SizedBox(width: AppTheme.spaceXS),
                              Expanded(
                                child: Text(
                                  'Correct answer: ${question.options[question.correctAnswerIndex]}',
                                  style:
                                      AppTheme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spaceMD),
                      Html(
                        data: question.explanation,
                        shrinkWrap: true,
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                          "div": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.all(0),
                          ),
                          "h4": Style(
                            color: AppTheme.gray900,
                            fontSize: FontSize(16),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(bottom: 10),
                            display: Display.block,
                            alignment: Alignment.center,
                          ),
                          "p": Style(
                            color: AppTheme.gray900,
                            fontSize: FontSize(15),
                            lineHeight: LineHeight(1.6),
                            margin: Margins.zero,
                          ),
                          "strong": Style(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gray900,
                          ),
                          "em": Style(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.gray600,
                          ),
                          "span": Style(
                            color: AppTheme.gray900,
                            fontSize: FontSize(15),
                          ),
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

          const SizedBox(height: AppTheme.spaceLG),

          // Enhanced next button with better styling
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAnswered ? () => _nextQuestion() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                elevation: isAnswered ? 2 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    questionIndex == totalQuestions - 1
                        ? 'Continue to Summary'
                        : 'Next Question',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Icon(
                    questionIndex == totalQuestions - 1
                        ? Icons.edit_note
                        : Icons.arrow_forward,
                    color: AppTheme.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced progress completion indicator
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quiz Completed!',
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMD,
                          vertical: AppTheme.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Text(
                          '100%',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: AppTheme.gray200,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.success),
                    minHeight: 6,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Enhanced summary writing section
            widgets.ProfessionalCard(
              color: AppTheme.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.edit_note,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Write Your Summary',
                              style: AppTheme.textTheme.titleLarge?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'AI-Evaluated Learning Assessment',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      border: Border.all(color: AppTheme.info.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          color: AppTheme.info,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spaceXS),
                        Expanded(
                          child: Text(
                            'Write a comprehensive summary of "${widget.task.topic ?? "your learning"}". Our AI will evaluate your understanding, accuracy, and clarity.',
                            style: AppTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Enhanced text input area
            Container(
              height: 300, // Fixed height instead of Expanded
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: _summaryController.text.trim().length >= 50
                      ? AppTheme.success.withOpacity(0.5)
                      : AppTheme.gray300,
                  width: _summaryController.text.trim().length >= 50 ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gray900.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: AppTheme.gray600,
                        size: 16,
                      ),
                      const SizedBox(width: AppTheme.spaceXS),
                      Text(
                        'Summary Text',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceXS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _summaryController.text.trim().length >= 50
                              ? AppTheme.success.withOpacity(0.1)
                              : AppTheme.warning.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXS),
                        ),
                        child: Text(
                          '${_summaryController.text.trim().length}/50 min',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: _summaryController.text.trim().length >= 50
                                ? AppTheme.success
                                : AppTheme.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Expanded(
                    child: TextField(
                      controller: _summaryController,
                      maxLines: null,
                      expands: true,
                      onChanged: (value) =>
                          setState(() {}), // Update character count
                      decoration: InputDecoration(
                        hintText:
                            'Describe what you learned about ${widget.task.topic ?? "this topic"}...\n\nInclude:\n• Key concepts and definitions\n• How the concepts relate to each other\n• Real-world applications\n• Your understanding and insights',
                        border: InputBorder.none,
                        hintStyle: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.gray500,
                          height: 1.5,
                        ),
                      ),
                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: AppTheme.gray900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Enhanced submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isSubmitting || _summaryController.text.trim().length < 50
                        ? null
                        : _submitQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  elevation:
                      _summaryController.text.trim().length >= 50 ? 3 : 0,
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppTheme.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceMD),
                          Text(
                            'AI is evaluating...',
                            style: AppTheme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology,
                            color: AppTheme.white,
                          ),
                          const SizedBox(width: AppTheme.spaceMD),
                          Text(
                            'Submit for AI Evaluation',
                            style: AppTheme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextQuestion() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitQuiz() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final questions = ref.read(aiQuizProvider).value ?? [];

      // Calculate quiz score
      int correctAnswers = 0;
      for (int i = 0; i < questions.length; i++) {
        if (_userAnswers[i] == questions[i].correctAnswerIndex) {
          correctAnswers++;
        }
      }

      // Validate summary with AI
      final summaryApproved = await ref
          .read(aiQuizProvider.notifier)
          .validateSummary(_summaryController.text.trim(), widget.task);

      final result = QuizResult(
        userAnswers: _userAnswers,
        questions: questions,
        userSummary: _summaryController.text.trim(),
        summaryApproved: summaryApproved,
        score: correctAnswers,
      );

      // Show results and determine if passed
      _showResults(result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting quiz: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showResults(QuizResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and title
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: result.isPassed
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: Icon(
                    result.isPassed ? Icons.celebration : Icons.school,
                    size: 40,
                    color:
                        result.isPassed ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceLG),

              Text(
                result.isPassed ? 'Outstanding!' : 'Keep Learning!',
                style: AppTheme.textTheme.headlineSmall?.copyWith(
                  color: result.isPassed ? AppTheme.success : AppTheme.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: AppTheme.spaceMD),

              Text(
                result.isPassed
                    ? 'You\'ve demonstrated excellent understanding!'
                    : 'Learning is a journey. Let\'s review and improve!',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spaceLG),

              // Score display
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMD),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Quiz Score',
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXS),
                          Text(
                            '${result.score}/${result.questions.length}',
                            style: AppTheme.textTheme.titleLarge?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMD),
                      decoration: BoxDecoration(
                        color: result.summaryApproved
                            ? AppTheme.success.withOpacity(0.1)
                            : AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Summary',
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: result.summaryApproved
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXS),
                          Icon(
                            result.summaryApproved
                                ? Icons.check_circle
                                : Icons.pending,
                            color: result.summaryApproved
                                ? AppTheme.success
                                : AppTheme.warning,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spaceLG),

              // Content based on pass/fail
              Expanded(
                child: SingleChildScrollView(
                  child: result.isPassed
                      ? _buildPassedContent()
                      : _buildFailedContent(result),
                ),
              ),

              const SizedBox(height: AppTheme.spaceLG),

              // Action buttons
              Row(
                children: [
                  if (!result.isPassed)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Reset quiz for retry
                          setState(() {
                            _userAnswers =
                                List.filled(result.questions.length, -1);
                            _summaryController.clear();
                          });
                          _pageController.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Retry Quiz'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.warning,
                          side: BorderSide(color: AppTheme.warning),
                        ),
                      ),
                    ),
                  if (!result.isPassed) const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (result.isPassed) {
                          widget.onQuizPassed();
                        } else {
                          widget.onQuizFailed();
                        }
                      },
                      icon: Icon(
                          result.isPassed ? Icons.arrow_forward : Icons.book),
                      label: Text(
                          result.isPassed ? 'Continue' : 'Review Material'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: result.isPassed
                            ? AppTheme.success
                            : AppTheme.warning,
                        foregroundColor: AppTheme.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassedContent() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            color: AppTheme.success,
            size: 32,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Excellent work! You\'ve shown great understanding of the material.',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.success,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'You\'re ready to move on to the next topic. Keep up the excellent learning!',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.gray700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFailedContent(QuizResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: AppTheme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: AppTheme.info,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceXS),
              Expanded(
                child: Text(
                  'Review these concepts to strengthen your understanding:',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMD),
        ...List.generate(result.questions.length, (i) {
          final q = result.questions[i];
          final isCorrect = result.userAnswers[i] == q.correctAnswerIndex;

          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppTheme.success.withOpacity(0.05)
                  : AppTheme.warning.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: isCorrect
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.warning.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.help_outline,
                      color: isCorrect ? AppTheme.success : AppTheme.warning,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spaceXS),
                    Expanded(
                      child: Text(
                        'Q${i + 1}: ${q.question}',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Correct: ${q.options[q.correctAnswerIndex]}',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  q.explanation,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.gray600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _summaryController.dispose();
    super.dispose();
  }
}
