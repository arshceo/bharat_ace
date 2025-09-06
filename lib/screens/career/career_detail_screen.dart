import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'path_node.dart';
import 'resources_tab.dart';
import 'job_market_tab.dart';

class CareerDetailScreen extends StatefulWidget {
  final String careerId;
  final Map<String, dynamic> careerData;

  const CareerDetailScreen({
    required this.careerId,
    required this.careerData,
    super.key,
  });

  @override
  State<CareerDetailScreen> createState() => _CareerDetailScreenState();
}

class _CareerDetailScreenState extends State<CareerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showFloatingActionButton = false;

  // For path animation
  bool _pathAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Start path animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _pathAnimationComplete = true;
        });
      }
    });
  }

  void _handleTabChange() {
    // This ensures the tab index is always valid
    if (!mounted) return;

    if (_tabController.index >= _tabController.length) {
      _tabController.animateTo(0);
    }

    // Add state rebuild only if needed
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure tab controller has the correct number of tabs
    if (_tabController.length != 6) {
      _tabController.dispose();
      _tabController = TabController(length: 6, vsync: this);
      _tabController.addListener(_handleTabChange);
    }
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showFloatingActionButton) {
      setState(() {
        _showFloatingActionButton = true;
      });
    } else if (_scrollController.offset <= 200 && _showFloatingActionButton) {
      setState(() {
        _showFloatingActionButton = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F8);
    final textColor = isDark ? Colors.white : Colors.black;
    final accentColor = const Color(0xFFFFD700); // Golden color
    final title = widget.careerData['title'] as String? ?? 'Unknown Career';
    final icon = widget.careerData['icon'] as String? ?? '💼';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // App Bar with career title
              SliverAppBar(
                pinned: true,
                expandedHeight: 200,
                centerTitle: true, // Center the title
                title: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20, // Slightly larger
                  ),
                ),
                backgroundColor:
                    isDark ? const Color(0xFF1A1A1A) : Colors.white,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: accentColor),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  // Remove title from here since it's now in the appbar
                  centerTitle: true,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background gradient with career icon
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF2C2C2C),
                                    const Color(0xFF1A1A1A),
                                  ]
                                : [
                                    Colors.white,
                                    const Color(0xFFF0F0F0),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      // Career icon with shimmer effect
                      Center(
                        child: Text(
                          icon,
                          style: const TextStyle(fontSize: 72),
                        )
                            .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true))
                            .shimmer(
                                duration: 2000.ms,
                                color: accentColor.withAlpha(100))
                            .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1.1, 1.1),
                                duration: 3000.ms),
                      ),

                      // Bottom shadow overlay
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                backgroundColor.withOpacity(0),
                                backgroundColor,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: accentColor,
                  unselectedLabelColor: textColor.withOpacity(0.5),
                  indicatorColor: accentColor,
                  tabs: const [
                    Tab(text: 'OVERVIEW'),
                    Tab(text: 'PATHWAY'),
                    Tab(text: 'SKILLS'),
                    Tab(text: 'GROWTH'),
                    Tab(text: 'RESOURCES'),
                    Tab(text: 'MARKET'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            physics: const ClampingScrollPhysics(), // Prevent overscrolling
            children: [
              // Tab 1: Overview
              _buildOverviewTab(accentColor, textColor, isDark),

              // Tab 2: Pathway
              _buildPathwayTab(accentColor, textColor, isDark),

              // Tab 3: Skills
              _buildSkillsTab(accentColor, textColor, isDark),

              // Tab 4: Career Growth
              _buildCareerGrowthTab(accentColor, textColor, isDark),

              // Tab 5: Learning Resources
              _buildResourcesTab(accentColor, textColor, isDark),

              // Tab 6: Job Market
              _buildJobMarketTab(accentColor, textColor, isDark),
            ],
          ),
        ),
      ),
      floatingActionButton: _showFloatingActionButton
          ? FloatingActionButton(
              backgroundColor: accentColor,
              child: const Icon(Icons.arrow_upward, color: Colors.black),
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            )
          : null,
    );
  }

  Widget _buildOverviewTab(Color accentColor, Color textColor, bool isDark) {
    final description = widget.careerData['description'] as String? ??
        'No description available';
    final category =
        widget.careerData['category'] as String? ?? 'Uncategorized';

    // Extract overview information
    Map<String, String> overviewPoints = {};
    if (widget.careerData['overview'] is Map<String, dynamic>) {
      final overview = widget.careerData['overview'] as Map<String, dynamic>;
      overview.forEach((key, value) {
        if (value is String) {
          overviewPoints[key.replaceAll('_', ' ')] = value;
        }
      });
    }

    // Get salary information
    Map<String, String> salaryInfo = {};
    if (widget.careerData['salary_info'] is Map<String, dynamic>) {
      final salaryData =
          widget.careerData['salary_info'] as Map<String, dynamic>;
      final currency = salaryData['currency'] as String? ?? 'INR';

      if (salaryData['entry_level'] is Map) {
        final entry = salaryData['entry_level'] as Map<String, dynamic>;
        salaryInfo['Entry Level'] =
            '$currency ${entry['min']?.toString() ?? "0"}-${entry['max']?.toString() ?? "0"} per ${entry['per'] ?? 'annum'}';
      }

      if (salaryData['mid_level'] is Map) {
        final mid = salaryData['mid_level'] as Map<String, dynamic>;
        salaryInfo['Mid Level'] =
            '$currency ${mid['min']?.toString() ?? "0"}-${mid['max']?.toString() ?? "0"} per ${mid['per'] ?? 'annum'}';
      }

      if (salaryData['senior_level'] is Map) {
        final senior = salaryData['senior_level'] as Map<String, dynamic>;
        salaryInfo['Senior Level'] =
            '$currency ${senior['min']?.toString() ?? "0"}-${senior['max']?.toString() ?? "0"} per ${senior['per'] ?? 'annum'}';
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description card
        Card(
          elevation: 4,
          shadowColor: accentColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About this Career',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: accentColor.withOpacity(0.2),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 20),

        // Overview info
        Card(
          elevation: 4,
          shadowColor: accentColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Career Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...overviewPoints.entries.map((entry) {
                  return _buildInfoRow(
                    entry.key.toUpperCase(),
                    entry.value,
                    _getIconForOverviewPoint(entry.key),
                    textColor,
                    accentColor,
                  );
                }),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 20),

        // Salary information
        Card(
          elevation: 4,
          shadowColor: accentColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salary Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...salaryInfo.entries.map((entry) {
                  return _buildInfoRow(
                    entry.key,
                    entry.value,
                    Icons.currency_rupee,
                    textColor,
                    accentColor,
                  );
                }),
                if (salaryInfo.isEmpty)
                  Text(
                    'Salary information not available',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildPathwayTab(Color accentColor, Color textColor, bool isDark) {
    // Extract academic roadmap
    final academicRoadmap =
        widget.careerData['academic_roadmap'] as Map<String, dynamic>? ?? {};

    // Collect nodes for the visualization
    final List<PathNode> pathNodes = [];

    // High school nodes
    if (academicRoadmap['high_school'] is Map<String, dynamic>) {
      final highSchool = academicRoadmap['high_school'] as Map<String, dynamic>;

      if (highSchool['class_10'] is Map<String, dynamic>) {
        final class10 = highSchool['class_10'] as Map<String, dynamic>;
        pathNodes.add(
          PathNode(
            id: 'class_10',
            title: 'Class 10',
            description: 'Foundation year',
            type: NodeType.education,
            details: {
              'Subjects': _formatListOrString(class10['subjects']),
              'Target Percentage':
                  class10['percentage_target'] as String? ?? 'N/A',
              'Activities': _formatListOrString(class10['activities']),
            },
          ),
        );
      }

      if (highSchool['class_11_12'] is Map<String, dynamic>) {
        final class1112 = highSchool['class_11_12'] as Map<String, dynamic>;
        pathNodes.add(
          PathNode(
            id: 'class_11_12',
            title: 'Class 11-12',
            description: class1112['stream'] as String? ?? 'High School',
            type: NodeType.education,
            details: {
              'Stream': class1112['stream'] as String? ?? 'N/A',
              'Core Subjects': _formatListOrString(class1112['core_subjects']),
              'Target Percentage':
                  class1112['percentage_target'] as String? ?? 'N/A',
              'Exams': _formatListOrString(class1112['competitive_exams']),
              'Activities': _formatListOrString(class1112['activities']),
            },
          ),
        );
      }
    }

    // Undergraduate nodes
    if (academicRoadmap['undergraduate'] is Map<String, dynamic>) {
      final undergraduate =
          academicRoadmap['undergraduate'] as Map<String, dynamic>;

      if (undergraduate['degree_options'] is List) {
        final degreeOptions = undergraduate['degree_options'] as List;
        for (int i = 0; i < degreeOptions.length && i < 3; i++) {
          final option = degreeOptions[i] as Map<String, dynamic>;
          pathNodes.add(
            PathNode(
              id: 'undergrad_$i',
              title: option['degree'] as String? ?? 'Undergraduate',
              description: '${option['duration'] as String? ?? '3-4 years'}',
              type: NodeType.education,
              details: {
                'Duration': option['duration'] as String? ?? 'N/A',
                'Top Colleges': _formatListOrString(
                    option['top_colleges'] ?? option['colleges']),
                'Admission': option['admission_process'] as String? ?? 'N/A',
                'Fees': option['fee_range'] as String? ?? 'N/A',
              },
            ),
          );
          if (i == 0) break; // Only show the first option by default
        }
      }

      if (undergraduate['year_wise_focus'] is Map<String, dynamic>) {
        final yearWiseFocus =
            undergraduate['year_wise_focus'] as Map<String, dynamic>;
        yearWiseFocus.forEach((year, focus) {
          if (focus is List) {
            pathNodes.add(
              PathNode(
                id: 'year_$year',
                title: year.replaceAll('_', ' ').toUpperCase(),
                description: 'Focus areas',
                type: NodeType.milestone,
                details: {
                  'Focus Areas': _formatListOrString(focus),
                },
              ),
            );
          }
        });
      }
    }

    // Postgraduate nodes
    if (academicRoadmap['postgraduate'] is Map<String, dynamic>) {
      final postgraduate =
          academicRoadmap['postgraduate'] as Map<String, dynamic>;

      if (postgraduate['options'] is List) {
        final options = postgraduate['options'] as List;
        for (int i = 0; i < options.length && i < 2; i++) {
          final option = options[i] as Map<String, dynamic>;
          pathNodes.add(
            PathNode(
              id: 'postgrad_$i',
              title: option['degree'] as String? ?? 'Postgraduate',
              description:
                  '${option['duration'] as String? ?? '1-2 years'} (Optional)',
              type: NodeType.education,
              details: {
                'Duration': option['duration'] as String? ?? 'N/A',
                'Entrance': option['entrance'] as String? ?? 'N/A',
                'Specializations':
                    _formatListOrString(option['specializations']),
                'Countries': _formatListOrString(option['countries']),
              },
            ),
          );
          if (i == 0) break; // Only show the first option by default
        }
      }
    }

    // Practical career stages
    if (widget.careerData['skill_roadmap'] is Map<String, dynamic>) {
      final skillRoadmap =
          widget.careerData['skill_roadmap'] as Map<String, dynamic>;

      skillRoadmap.forEach((level, data) {
        if (data is Map<String, dynamic>) {
          pathNodes.add(
            PathNode(
              id: 'skill_$level',
              title: level.toUpperCase(),
              description: 'Professional Development',
              type: NodeType.career,
              details: {
                'Duration': data['duration'] as String? ?? 'N/A',
              },
            ),
          );
        }
      });
    }

    // If the path is empty, add a placeholder
    if (pathNodes.isEmpty) {
      pathNodes.add(
        PathNode(
          id: 'placeholder',
          title: 'Start Your Journey',
          description: 'Education and career planning',
          type: NodeType.education,
          details: {},
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Career Pathway',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 8),

          Text(
            'Follow this step-by-step guide to achieve your dream career',
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: 32),

          // Interactive pathway visualization
          Expanded(
            child: _buildPathwayVisualization(
              pathNodes,
              accentColor,
              textColor,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathwayVisualization(
    List<PathNode> nodes,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        final isLast = index == nodes.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline with connecting lines
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getNodeColor(node.type, accentColor),
                    boxShadow: [
                      BoxShadow(
                        color: _getNodeColor(node.type, accentColor)
                            .withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getNodeIcon(node.type),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 100, // Height of connection line
                    color: _pathAnimationComplete
                        ? _getNodeColor(node.type, accentColor).withOpacity(0.5)
                        : Colors.transparent,
                  ).animate(target: _pathAnimationComplete ? 1 : 0).fadeIn(
                      duration: 500.ms,
                      delay: Duration(milliseconds: 300 * math.max(0, index))),
              ],
            ),

            const SizedBox(width: 16),

            // Node content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Node card
                  Card(
                    elevation: 3,
                    shadowColor:
                        _getNodeColor(node.type, accentColor).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getNodeIcon(node.type),
                                color: _getNodeColor(node.type, accentColor),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  node.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _getNodeColor(node.type, accentColor),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            node.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Node details
                          ...node.details.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Spacer below the card
                  if (!isLast) const SizedBox(height: 70),
                ],
              ),
            )
                .animate()
                .fadeIn(
                    delay: Duration(milliseconds: 200 * math.max(0, index)),
                    duration: 500.ms)
                .slideX(begin: 0.1, end: 0),
          ],
        );
      },
    );
  }

  Widget _buildSkillsTab(Color accentColor, Color textColor, bool isDark) {
    // Extract required skills
    Map<String, List<dynamic>> skills = {
      'technical': [],
      'soft': [],
    };

    if (widget.careerData['required_skills'] is Map<String, dynamic>) {
      final requiredSkills =
          widget.careerData['required_skills'] as Map<String, dynamic>;

      // Get technical skills
      if (requiredSkills['technical_skills'] is List) {
        skills['technical'] = requiredSkills['technical_skills'] as List;
      }

      // Get soft skills
      if (requiredSkills['soft_skills'] is List) {
        skills['soft'] = requiredSkills['soft_skills'] as List;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Technical skills section
        Text(
          'Technical Skills',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ).animate().fadeIn(duration: 500.ms),

        const SizedBox(height: 16),

        if (skills['technical']!.isNotEmpty)
          ...skills['technical']!
              .map((skill) => _buildSkillCard(
                  skill, accentColor, textColor, isDark, 'technical'))
              .toList()
        else
          Text(
            'No technical skills information available',
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),

        const SizedBox(height: 24),

        // Soft skills section
        Text(
          'Soft Skills',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        const SizedBox(height: 16),

        if (skills['soft']!.isNotEmpty)
          ...skills['soft']!
              .map((skill) => _buildSkillCard(
                  skill, accentColor, textColor, isDark, 'soft'))
              .toList()
        else
          Text(
            'No soft skills information available',
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildSkillCard(
    dynamic skill,
    Color accentColor,
    Color textColor,
    bool isDark,
    String skillType,
  ) {
    if (skill is! Map<String, dynamic>) return const SizedBox();

    final skillName = skill['skill'] as String? ?? 'Unknown Skill';
    final importance = skill['importance'] as String? ?? 'Medium';
    final details = skill['details'] as List<dynamic>? ?? [];
    final learningTime = skill['learning_time'] as String?;

    final Color importanceColor = _getImportanceColor(importance);

    return Card(
      elevation: 3,
      shadowColor: importanceColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: importanceColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill name and importance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    skillName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: importanceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    importance,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: importanceColor,
                    ),
                  ),
                ),
              ],
            ),

            if (learningTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Learning time: $learningTime',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Details list if available
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Related Topics:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: details.map((detail) {
                  if (detail is! String) return const SizedBox();
                  return Chip(
                    label: Text(
                      detail,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    backgroundColor: importanceColor.withOpacity(0.1),
                    side: BorderSide(
                      color: importanceColor.withOpacity(0.3),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCareerGrowthTab(
      Color accentColor, Color textColor, bool isDark) {
    // Extract salary info for career progression
    final List<Map<String, dynamic>> careerLevels = [];

    if (widget.careerData['salary_info'] is Map<String, dynamic>) {
      final salaryInfo =
          widget.careerData['salary_info'] as Map<String, dynamic>;
      final currency = salaryInfo['currency'] as String? ?? 'INR';

      if (salaryInfo['entry_level'] is Map<String, dynamic>) {
        final entry = salaryInfo['entry_level'] as Map<String, dynamic>;
        careerLevels.add({
          'level': 'Entry Level',
          'experience': '0-2 years',
          'min': entry['min'],
          'max': entry['max'],
          'avg': entry['average'],
          'per': entry['per'] ?? 'annum',
          'currency': currency,
        });
      }

      if (salaryInfo['mid_level'] is Map<String, dynamic>) {
        final mid = salaryInfo['mid_level'] as Map<String, dynamic>;
        careerLevels.add({
          'level': 'Mid Level',
          'experience': '3-5 years',
          'min': mid['min'],
          'max': mid['max'],
          'avg': mid['average'],
          'per': mid['per'] ?? 'annum',
          'currency': currency,
        });
      }

      if (salaryInfo['senior_level'] is Map<String, dynamic>) {
        final senior = salaryInfo['senior_level'] as Map<String, dynamic>;
        careerLevels.add({
          'level': 'Senior Level',
          'experience': '5-10 years',
          'min': senior['min'],
          'max': senior['max'],
          'avg': senior['average'],
          'per': senior['per'] ?? 'annum',
          'currency': currency,
        });
      }

      // Check for additional career levels
      salaryInfo.forEach((key, value) {
        if (key != 'currency' &&
            key != 'entry_level' &&
            key != 'mid_level' &&
            key != 'senior_level') {
          if (value is Map<String, dynamic>) {
            careerLevels.add({
              'level': key
                  .split('_')
                  .map((word) =>
                      word.substring(0, 1).toUpperCase() + word.substring(1))
                  .join(' '),
              'experience': '10+ years',
              'min': value['min'],
              'max': value['max'],
              'avg': value['average'],
              'per': value['per'] ?? 'annum',
              'currency': currency,
            });
          }
        }
      });
    }

    if (careerLevels.isEmpty) {
      careerLevels.addAll([
        {
          'level': 'Entry Level',
          'experience': '0-2 years',
          'description': 'Starting position with supervised work',
        },
        {
          'level': 'Mid Level',
          'experience': '3-5 years',
          'description': 'Increased responsibility and independence',
        },
        {
          'level': 'Senior Level',
          'experience': '5-10 years',
          'description': 'Leadership roles with strategic contributions',
        },
        {
          'level': 'Expert/Specialist',
          'experience': '10+ years',
          'description': 'Top-tier position with industry recognition',
        },
      ]);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Career Growth Path',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ).animate().fadeIn(duration: 500.ms),

        const SizedBox(height: 8),

        Text(
          'Your career progression and earning potential',
          style: TextStyle(
            fontSize: 16,
            color: textColor.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        const SizedBox(height: 32),

        // Career progression visualization
        _buildCareerProgressionChart(
            careerLevels, accentColor, textColor, isDark),

        const SizedBox(height: 32),

        // Career level details
        ...careerLevels.asMap().entries.map((entry) {
          final index = entry.key;
          final level = entry.value;

          return _buildCareerLevelCard(level, index, careerLevels.length,
              accentColor, textColor, isDark);
        }),
      ],
    );
  }

  Widget _buildCareerProgressionChart(
    List<Map<String, dynamic>> levels,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      height: 220, // Increased from 200 to 220
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 8), // Reduced bottom padding
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:
            MainAxisSize.min, // Make the column take minimum required space
        children: [
          Text(
            'Salary Progression',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8), // Reduced from 16 to 8
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: levels.asMap().entries.map((entry) {
                final index = entry.key;
                final level = entry.value;

                // Calculate bar height based on average salary or position
                double heightFactor;
                if (level.containsKey('avg') && level['avg'] != null) {
                  final avgValues = levels
                      .map((l) => (l['avg'] as num?) ?? 0)
                      .where((val) => val > 0)
                      .toList();
                  final maxAvg = avgValues.isNotEmpty
                      ? avgValues.reduce((a, b) => math.max(a, b))
                      : 1;
                  heightFactor = ((level['avg'] as num?) ?? 0) / maxAvg;
                } else {
                  // If no salary data, use position in progression
                  heightFactor = (index + 1) / levels.length;
                }

                // Make sure the smallest bar is still visible
                heightFactor = 0.2 + (heightFactor * 0.8);

                final barColor = _getGradientColor(index, levels.length);

                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 90 *
                            heightFactor, // Further reduced height from 100 to 90
                        margin: const EdgeInsets.symmetric(
                            horizontal:
                                4), // Reduced horizontal margin from 6 to 4
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              barColor,
                              barColor.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(
                              delay: Duration(
                                  milliseconds: 300 * math.max(0, index)))
                          .slideY(
                              begin: 1,
                              end: 0,
                              delay: Duration(
                                  milliseconds: 300 * math.max(0, index)),
                              duration: 600.ms),
                      const SizedBox(height: 4), // Reduced spacing from 8 to 4
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 50),
                        child: Text(
                          level['level'].split(' ')[0],
                          style: TextStyle(
                            fontSize:
                                8, // Further reduced font size from 9 to 8
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildCareerLevelCard(
    Map<String, dynamic> level,
    int index,
    int totalLevels,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    final levelName = level['level'] as String;
    final experience = level['experience'] as String;
    final description = level['description'] as String?;
    final barColor = _getGradientColor(index, totalLevels);

    // Prepare salary information if available
    String salaryText = '';
    if (level.containsKey('min') &&
        level.containsKey('max') &&
        level['min'] != null &&
        level['max'] != null) {
      final currency = level['currency'] as String? ?? '';
      final per = level['per'] as String? ?? 'annum';
      salaryText = '$currency ${level['min']}-${level['max']} per $per';
    }

    return Card(
      elevation: 3,
      shadowColor: barColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: barColor,
              width: 5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    levelName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      experience,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: barColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (description != null) ...[
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (salaryText.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: barColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Typical Salary: $salaryText',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
        delay: Duration(milliseconds: 200 * math.max(0, index)),
        duration: 500.ms);
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    Color textColor,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: accentColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.6),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatListOrString(dynamic data) {
    if (data is List) {
      return data.map((item) => item.toString()).join(', ');
    } else if (data is String) {
      return data;
    }
    return 'N/A';
  }

  IconData _getIconForOverviewPoint(String key) {
    switch (key.toLowerCase()) {
      case 'demand level':
        return Icons.trending_up;
      case 'growth projection':
        return Icons.timeline;
      case 'job security':
        return Icons.security;
      case 'work environment':
        return Icons.business_center;
      case 'stress level':
        return Icons.psychology;
      default:
        return Icons.info_outline;
    }
  }

  IconData _getNodeIcon(NodeType type) {
    switch (type) {
      case NodeType.education:
        return Icons.school;
      case NodeType.milestone:
        return Icons.flag;
      case NodeType.career:
        return Icons.work;
    }
  }

  Color _getNodeColor(NodeType type, Color defaultColor) {
    switch (type) {
      case NodeType.education:
        return Colors.blue;
      case NodeType.milestone:
        return Colors.green;
      case NodeType.career:
        return Colors.purple;
    }
  }

  // Tab 5: Resources - implements learning resources and certifications
  Widget _buildResourcesTab(Color accentColor, Color textColor, bool isDark) {
    try {
      return ResourcesTab.build(
          widget.careerData, accentColor, textColor, isDark);
    } catch (e) {
      // Fallback widget in case of error
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Could not load resources information',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      );
    }
  }

  // Tab 6: Job Market - implements job market information and more
  Widget _buildJobMarketTab(Color accentColor, Color textColor, bool isDark) {
    try {
      return JobMarketTab.build(
          widget.careerData, accentColor, textColor, isDark);
    } catch (e) {
      // Fallback widget in case of error
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Could not load job market information',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      );
    }
  }

  Color _getImportanceColor(String importance) {
    switch (importance.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getGradientColor(int index, int total) {
    final colors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
    ];

    // Ensure we don't go out of bounds
    final colorIndex = (index % colors.length);
    return colors[colorIndex];
  }
}
