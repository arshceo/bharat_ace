// lib/screens/competitions/competitions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/professional_card.dart' as pc;

// Competition models
class Competition {
  final String id;
  final String title;
  final String description;
  final CompetitionType type;
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;
  final int maxParticipants;
  final String difficulty;
  final List<String> subjects;
  final String prize;
  final CompetitionStatus status;

  Competition({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.participantCount,
    required this.maxParticipants,
    required this.difficulty,
    required this.subjects,
    required this.prize,
    required this.status,
  });
}

enum CompetitionType { individual, team, group }

enum CompetitionStatus { upcoming, active, completed, registration }

// Mock data provider
final competitionsProvider = StateProvider<List<Competition>>((ref) => [
      Competition(
        id: '1',
        title: 'Mathematics Olympiad 2024',
        description:
            'Annual mathematics competition featuring challenging problems from algebra, geometry, and calculus.',
        type: CompetitionType.individual,
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        participantCount: 234,
        maxParticipants: 500,
        difficulty: 'Advanced',
        subjects: ['Mathematics', 'Algebra', 'Geometry'],
        prize: '₹50,000 + Certificate',
        status: CompetitionStatus.registration,
      ),
      Competition(
        id: '2',
        title: 'Science Quiz Championship',
        description:
            'Team-based science competition covering physics, chemistry, and biology topics.',
        type: CompetitionType.team,
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 12)),
        participantCount: 156,
        maxParticipants: 200,
        difficulty: 'Intermediate',
        subjects: ['Physics', 'Chemistry', 'Biology'],
        prize: '₹75,000 + Trophies',
        status: CompetitionStatus.registration,
      ),
      Competition(
        id: '3',
        title: 'General Knowledge Battle',
        description:
            'Fast-paced general knowledge competition with live leaderboards.',
        type: CompetitionType.group,
        startDate: DateTime.now().add(const Duration(hours: 2)),
        endDate: DateTime.now().add(const Duration(hours: 4)),
        participantCount: 89,
        maxParticipants: 100,
        difficulty: 'Beginner',
        subjects: ['General Knowledge', 'Current Affairs'],
        prize: '₹25,000 + Medals',
        status: CompetitionStatus.active,
      ),
    ]);

class CompetitionsScreen extends ConsumerStatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  ConsumerState<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends ConsumerState<CompetitionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: FadeIn(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Competitions',
                style: AppTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showCreateTeamDialog(),
            icon: Icon(Icons.group_add, color: AppTheme.primary),
            tooltip: 'Create Team',
          ),
          IconButton(
            onPressed: () => _showNotifications(),
            icon: Icon(Icons.notifications_outlined, color: AppTheme.gray600),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _buildFilterChips(),
              const SizedBox(height: 16),
              _buildTabBar(),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompetitionsList(competitions, CompetitionStatus.registration),
          _buildCompetitionsList(competitions, CompetitionStatus.active),
          _buildMyCompetitions(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showJoinCompetitionDialog(),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        icon: const Icon(Icons.add),
        label: const Text('Join Competition'),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Individual', 'Team', 'Group'];

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: AppTheme.gray100,
              selectedColor: AppTheme.primary.withOpacity(0.2),
              labelStyle: AppTheme.textTheme.bodySmall?.copyWith(
                color: isSelected ? AppTheme.primary : AppTheme.gray600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : AppTheme.gray300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppTheme.white,
        unselectedLabelColor: AppTheme.gray600,
        labelStyle: AppTheme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Upcoming'),
          Tab(text: 'Live'),
          Tab(text: 'My Competitions'),
        ],
      ),
    );
  }

  Widget _buildCompetitionsList(
      List<Competition> competitions, CompetitionStatus status) {
    final filteredCompetitions = competitions.where((comp) {
      if (status != comp.status) return false;
      if (_selectedFilter == 'All') return true;
      return comp.type.name.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    if (filteredCompetitions.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh competitions
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredCompetitions.length,
        itemBuilder: (context, index) {
          return FadeInUp(
            delay: (index * 100).ms,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildCompetitionCard(filteredCompetitions[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompetitionCard(Competition competition) {
    return pc.ProfessionalCard(
      color: AppTheme.white,
      onTap: () => _showCompetitionDetails(competition),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(competition.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCompetitionIcon(competition.type),
                  color: _getStatusColor(competition.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      competition.title,
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.gray900,
                      ),
                    ),
                    Text(
                      _getCompetitionTypeLabel(competition.type),
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(competition.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            competition.description,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.gray700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _buildCompetitionStats(competition),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.schedule,
                  _formatDate(competition.startDate),
                  AppTheme.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  Icons.emoji_events,
                  competition.prize,
                  AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareCompetition(competition),
                  icon: Icon(Icons.share, size: 16),
                  label: Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.gray600,
                    side: BorderSide(color: AppTheme.gray300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _joinCompetition(competition),
                  icon: Icon(_getActionIcon(competition), size: 16),
                  label: Text(_getActionLabel(competition)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getStatusColor(competition.status),
                    foregroundColor: AppTheme.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionStats(Competition competition) {
    return Row(
      children: [
        Flexible(
          child: _buildStatItem(
            Icons.people,
            '${competition.participantCount}/${competition.maxParticipants}',
            'Participants',
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: _buildStatItem(
            Icons.signal_cellular_alt,
            competition.difficulty,
            'Difficulty',
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: _buildStatItem(
            Icons.book,
            '${competition.subjects.length} Subjects',
            'Topics',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.gray500),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                label,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray500,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CompetitionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel(status),
        style: AppTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMyCompetitions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Competition History',
            style: AppTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No competitions yet!',
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join your first competition to start building your competitive portfolio.',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: Icon(Icons.explore),
                    label: Text('Explore Competitions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(CompetitionStatus status) {
    String title, description;
    IconData icon;

    switch (status) {
      case CompetitionStatus.registration:
        title = 'No upcoming competitions';
        description = 'Check back later for new competitions to join!';
        icon = Icons.upcoming;
        break;
      case CompetitionStatus.active:
        title = 'No live competitions';
        description = 'All competitions are currently offline.';
        icon = Icons.live_tv;
        break;
      default:
        title = 'No competitions found';
        description = 'Try adjusting your filters.';
        icon = Icons.search_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.gray400),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.gray600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(CompetitionStatus status) {
    switch (status) {
      case CompetitionStatus.upcoming:
        return AppTheme.info;
      case CompetitionStatus.active:
        return AppTheme.success;
      case CompetitionStatus.completed:
        return AppTheme.gray500;
      case CompetitionStatus.registration:
        return AppTheme.primary;
    }
  }

  String _getStatusLabel(CompetitionStatus status) {
    switch (status) {
      case CompetitionStatus.upcoming:
        return 'Upcoming';
      case CompetitionStatus.active:
        return 'Live';
      case CompetitionStatus.completed:
        return 'Completed';
      case CompetitionStatus.registration:
        return 'Open';
    }
  }

  IconData _getCompetitionIcon(CompetitionType type) {
    switch (type) {
      case CompetitionType.individual:
        return Icons.person;
      case CompetitionType.team:
        return Icons.group;
      case CompetitionType.group:
        return Icons.groups;
    }
  }

  String _getCompetitionTypeLabel(CompetitionType type) {
    switch (type) {
      case CompetitionType.individual:
        return 'Individual Competition';
      case CompetitionType.team:
        return 'Team Competition';
      case CompetitionType.group:
        return 'Group Competition';
    }
  }

  IconData _getActionIcon(Competition competition) {
    if (competition.status == CompetitionStatus.active) {
      return Icons.play_arrow;
    }
    return Icons.how_to_reg;
  }

  String _getActionLabel(Competition competition) {
    if (competition.status == CompetitionStatus.active) {
      return 'Join Now';
    }
    return 'Register';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    } else {
      return 'Starting soon';
    }
  }

  // Action methods
  void _showCreateTeamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Create Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Team Name',
                hintText: 'Enter your team name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Team Description',
                hintText: 'Describe your team',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Team created successfully!');
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinCompetitionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join Competition',
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Competition Code',
                hintText: 'Enter 6-digit code',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.qr_code_scanner),
                    label: Text('Scan QR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSuccessSnackBar('Joined competition successfully!');
                    },
                    child: Text('Join'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompetitionDetails(Competition competition) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CompetitionDetailsScreen(competition: competition),
      ),
    );
  }

  void _shareCompetition(Competition competition) {
    _showSuccessSnackBar('Competition link copied to clipboard!');
  }

  void _joinCompetition(Competition competition) {
    _showSuccessSnackBar('Successfully joined ${competition.title}!');
  }

  void _showNotifications() {
    _showSuccessSnackBar('No new notifications');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Competition Details Screen
class CompetitionDetailsScreen extends StatelessWidget {
  final Competition competition;

  const CompetitionDetailsScreen({super.key, required this.competition});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: Text(
          competition.title,
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.share),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.bookmark_border),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pc.ProfessionalCard(
              color: AppTheme.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    competition.description,
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            pc.ProfessionalCard(
              color: AppTheme.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Competition Details',
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Type', competition.type.name.toUpperCase()),
                  _buildDetailRow('Difficulty', competition.difficulty),
                  _buildDetailRow('Participants',
                      '${competition.participantCount}/${competition.maxParticipants}'),
                  _buildDetailRow('Prize', competition.prize),
                  _buildDetailRow('Subjects', competition.subjects.join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registered for ${competition.title}!'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        icon: Icon(Icons.how_to_reg),
        label: Text('Register Now'),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
