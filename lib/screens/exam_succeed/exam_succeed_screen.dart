// lib/screens/exam_succeed/exam_succeed_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/professional_card.dart' as widgets;

/// A screen that shows strategies for excelling in exams for each subject
class ExamSucceedScreen extends ConsumerStatefulWidget {
  const ExamSucceedScreen({super.key});

  @override
  ConsumerState<ExamSucceedScreen> createState() => _ExamSucceedScreenState();
}

class _ExamSucceedScreenState extends ConsumerState<ExamSucceedScreen> {
  // Subject data with strategies
  final List<Map<String, dynamic>> subjects = [
    {
      'name': 'Mathematics',
      'icon': Icons.calculate_outlined,
      'color': Colors.blue,
      'strategies': [
        'Practice solving different problem types daily',
        'Focus on understanding concepts, not just formulas',
        'Create formula cheat sheets for quick reference',
        'Break down complex problems into smaller steps',
        'Show all your working to earn method marks',
        'Always verify your answers with estimations'
      ],
      'examTips':
          'Start with questions you find easier to build confidence. Manage your time well - don\'t spend too long on any single problem.'
    },
    {
      'name': 'Science',
      'icon': Icons.science_outlined,
      'color': Colors.green,
      'strategies': [
        'Draw diagrams to explain processes and concepts',
        'Use precise scientific terminology in answers',
        'Connect theoretical knowledge with practical applications',
        'Emphasize cause-and-effect relationships',
        'Support answers with relevant examples',
        'Organize longer answers with clear structure'
      ],
      'examTips':
          'Read questions carefully to identify exactly what scientific knowledge is being tested. Pay attention to command words like "describe", "explain", or "evaluate".'
    },
    {
      'name': 'English',
      'icon': Icons.menu_book_outlined,
      'color': Colors.purple,
      'strategies': [
        'Plan your essays before writing',
        'Use strong topic sentences to start paragraphs',
        'Include relevant quotations as evidence',
        'Analyze language techniques and their effects',
        'Develop clear arguments with supporting details',
        'Proofread your work for grammar and spelling'
      ],
      'examTips':
          'Allocate time for planning, writing, and reviewing. Quality writing with proper structure is better than quantity.'
    },
    {
      'name': 'History',
      'icon': Icons.history_edu_outlined,
      'color': Colors.brown,
      'strategies': [
        'Organize events chronologically',
        'Analyze causes and consequences of historical events',
        'Support arguments with specific evidence',
        'Consider different perspectives and interpretations',
        'Make connections between historical periods',
        'Address historical significance in your answers'
      ],
      'examTips':
          'Remember to analyze sources critically. Consider origin, purpose, value, and limitations of historical evidence.'
    },
    {
      'name': 'Geography',
      'icon': Icons.public_outlined,
      'color': Colors.teal,
      'strategies': [
        'Use appropriate geographical terminology',
        'Incorporate data analysis and interpretation',
        'Include labeled diagrams and maps where relevant',
        'Connect human and physical geography concepts',
        'Discuss environmental impacts and sustainability',
        'Support points with case studies and examples'
      ],
      'examTips':
          'Use the resources provided carefully - maps, graphs, and images contain valuable information needed to answer questions fully.'
    },
    {
      'name': 'Computer Science',
      'icon': Icons.computer_outlined,
      'color': Colors.indigo,
      'strategies': [
        'Use pseudocode to plan programming solutions',
        'Trace algorithms step-by-step to check logic',
        'Draw diagrams for complex data structures',
        'Explain technical concepts with clear examples',
        'Show your working for binary/hexadecimal calculations',
        'Link theoretical concepts to real-world applications'
      ],
      'examTips':
          'When coding, focus on algorithm efficiency and proper syntax. For theory questions, use technical vocabulary precisely.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Exam Success Strategies',
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkTextPrimary
                : AppTheme.gray900,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro card
            Builder(builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : AppTheme.cardShadow,
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.gray200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ace Your Exams',
                            style: AppTheme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select a subject to discover proven strategies for scoring full marks and mastering exam techniques.',
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.gray700,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            // Subject grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(
                    bottom: 16), // Add bottom padding for better spacing
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio:
                      0.95, // Reduced from 1.1 to 0.95 to give more vertical space
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return _buildSubjectCard(
                    subject['name'],
                    subject['icon'],
                    subject['color'],
                    subject['strategies'],
                    subject['examTips'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(
    String name,
    IconData icon,
    Color color,
    List<String> strategies,
    String examTips,
  ) {
    return InkWell(
      onTap: () =>
          _showSubjectStrategies(name, icon, color, strategies, examTips),
      borderRadius: BorderRadius.circular(16),
      child: Builder(builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          padding: const EdgeInsets.all(12), // Reduced padding from 16 to 12
          child: Column(
            mainAxisSize: MainAxisSize.min, // Make column take minimum space
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.all(10), // Reduced padding from 12 to 10
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: color, size: 28), // Reduced size from 32 to 28
              ),
              const SizedBox(height: 8), // Reduced height from 12 to 8
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name,
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.gray900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 2), // Reduced height from 4 to 2
              Text(
                'View Strategies',
                style: TextStyle(
                  fontSize: 10, // Reduced fontSize from 12 to 10
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showSubjectStrategies(
    String subject,
    IconData icon,
    Color color,
    List<String> strategies,
    String examTips,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppTheme.darkBorder : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject,
                              style: AppTheme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.gray900,
                              ),
                            ),
                            Text(
                              'Exam Success Strategies',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Answer strategies section
                      Text(
                        'Answer Writing Strategies',
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...strategies.map(
                          (strategy) => _buildStrategyItem(strategy, color)),
                      const SizedBox(height: 24),

                      // Exam tips section
                      Text(
                        'Exam Day Tips',
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, color: color),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pro Tips',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Builder(builder: (context) {
                                final isDark = Theme.of(context).brightness ==
                                    Brightness.dark;
                                return Text(
                                  examTips,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.gray800,
                                  ),
                                );
                              }),
                            ]),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Practice section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.7),
                        color.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Want to Practice?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Apply these strategies to sample questions and improve your exam performance.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to practice questions
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Practice questions coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Practice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.darkCard
                                  : Colors.white,
                          foregroundColor: color,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _buildStrategyItem(String strategy, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: color,
            size: 12,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Text(
              strategy,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.gray800,
              ),
            );
          }),
        ),
      ],
    ),
  );
}
