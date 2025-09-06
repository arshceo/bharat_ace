// lib/screens/analytics/study_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/study_session_manager.dart';
import '../../widgets/professional_card.dart' as widgets;

class StudyAnalyticsScreen extends ConsumerStatefulWidget {
  const StudyAnalyticsScreen({super.key});

  @override
  ConsumerState<StudyAnalyticsScreen> createState() =>
      _StudyAnalyticsScreenState();
}

class _StudyAnalyticsScreenState extends ConsumerState<StudyAnalyticsScreen> {
  Map<String, dynamic>? todayAnalytics;
  int weeklyStudyTime = 0;
  List<Map<String, dynamic>> recentSessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      isLoading = true;
    });

    try {
      final sessionNotifier = ref.read(studySessionProvider.notifier);
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Load today's analytics
      todayAnalytics = await sessionNotifier.getAnalyticsForDate(dateKey);

      // Load weekly study time
      weeklyStudyTime = await sessionNotifier.getWeeklyStudyTime();

      // Load recent sessions (last 7 days)
      final dates = await sessionNotifier.getAllAnalyticsDates();
      recentSessions.clear();

      for (String date in dates.take(7)) {
        final analytics = await sessionNotifier.getAnalyticsForDate(date);
        if (analytics != null && analytics['totalStudyTime'] > 0) {
          recentSessions.add(analytics);
        }
      }

      // Sort by date (most recent first)
      recentSessions.sort((a, b) => b['date'].compareTo(a['date']));
    } catch (e) {
      print('Error loading analytics: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: Text(
          'Study Analytics',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.gray900,
          ),
        ),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.gray700),
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: Icon(
              Icons.refresh,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayStats(),
                    const SizedBox(height: AppTheme.spaceLG),
                    _buildWeeklyOverview(),
                    const SizedBox(height: AppTheme.spaceLG),
                    _buildRecentSessions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTodayStats() {
    final studyTime = todayAnalytics?['totalStudyTime'] ?? 0;
    final sessions = todayAnalytics?['sessionsCompleted'] ?? 0;
    final tasks = todayAnalytics?['tasksCompleted'] ?? 0;
    final breaks = todayAnalytics?['breaksTaken'] ?? 0;

    return widgets.ProfessionalCard(
      color: AppTheme.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: AppTheme.primary, size: 24),
              const SizedBox(width: AppTheme.spaceMD),
              Text(
                'Today\'s Progress',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer,
                  label: 'Study Time',
                  value: '${studyTime}m',
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.play_circle,
                  label: 'Sessions',
                  value: '$sessions',
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.task_alt,
                  label: 'Tasks',
                  value: '$tasks',
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.coffee,
                  label: 'Breaks',
                  value: '$breaks',
                  color: AppTheme.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            value,
            style: AppTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    return widgets.ProfessionalCard(
      color: AppTheme.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: AppTheme.primary, size: 24),
              const SizedBox(width: AppTheme.spaceMD),
              Text(
                'This Week',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.1),
                  AppTheme.success.withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Column(
              children: [
                Text(
                  '${weeklyStudyTime}',
                  style: AppTheme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  'minutes studied',
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.gray700,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  '${(weeklyStudyTime / 60).toStringAsFixed(1)} hours total',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions() {
    return widgets.ProfessionalCard(
      color: AppTheme.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppTheme.primary, size: 24),
              const SizedBox(width: AppTheme.spaceMD),
              Text(
                'Recent Sessions',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),
          if (recentSessions.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 48,
                    color: AppTheme.gray400,
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Text(
                    'No study sessions yet',
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.gray600,
                    ),
                  ),
                  Text(
                    'Start your first session to see analytics!',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentSessions.map((session) => _buildSessionCard(session)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final date = DateTime.parse(session['date']);
    final studyTime = session['totalStudyTime'] ?? 0;
    final sessionsCount = session['sessionsCompleted'] ?? 0;
    final tasksCount = session['tasksCompleted'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(date),
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  '$sessionsCount sessions • $tasksCount tasks',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${studyTime}m',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}
