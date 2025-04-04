import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- IMPORT User type

// Import your ACTUAL providers and models
import 'package:bharat_ace/core/providers/auth_provider.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/core/models/student_model.dart';

// Import the PLACEHOLDER providers and models (Ensure path is correct)
import '../../widgets/home_screen_widgets/placeholder_providers.dart'; // You need this file from previous examples

// Provider for Bottom Navigation Index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// --- Helper Widget to Trigger Fetch ---
class StudentDetailsInitializer extends ConsumerWidget {
  final Widget child;
  const StudentDetailsInitializer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      // Use User? from firebase_auth
      final User? user = next.valueOrNull; // User? type
      if (user != null) {
        final currentDetails = ref.read(studentDetailsProvider);
        if (currentDetails == null || currentDetails.id != user.uid) {
          print(
              "Initializer: Auth state changed, user logged in. Fetching student details...");
          // Use read method for notifier
          ref.read(studentDetailsProvider.notifier).fetchStudentDetails();
        }
      } else {
        print("Initializer: Auth state changed, user logged out.");
        // Optional: ref.read(studentDetailsProvider.notifier).clearDetails(); if you add such a method
      }
    });

    // Trigger fetch on initial build if needed
    final User? user = ref.watch(authStateProvider).valueOrNull; // User? type
    final StudentModel? studentDetails = ref.watch(studentDetailsProvider);
    if (user != null && studentDetails == null) {
      // Use Future.microtask to avoid calling notifier during build
      Future.microtask(() {
        // Check again inside microtask as state might change rapidly
        if (ref.read(studentDetailsProvider) == null) {
          print("Initializer: Triggering initial fetch in microtask.");
          ref.read(studentDetailsProvider.notifier).fetchStudentDetails();
        }
      });
    }

    return child;
  }
}

// --- Main Home Screen Widget ---
class HomeScreen2 extends ConsumerWidget {
  const HomeScreen2({super.key});

  // --- Helper Methods --- (Copied from previous full version)
  IconData _getIconForContext(String context) {
    switch (context.toLowerCase()) {
      case 'science':
        return Icons.science_outlined;
      case 'math':
        return Icons.calculate_outlined;
      case 'history':
        return Icons.history_edu_outlined;
      case 'english':
        return Icons.translate_outlined;
      case 'physics':
        return Icons.thermostat_outlined;
      case 'chemistry':
        return Icons.biotech_outlined;
      case 'test':
        return Icons.assignment_turned_in_outlined;
      case 'assignment':
        return Icons.edit_document;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.test:
        return Colors.redAccent;
      case EventType.assignment:
        return Colors.blueAccent;
      case EventType.announcement:
        return Colors.green;
    }
  }
  // --- End Helper Methods ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Size size = MediaQuery.of(context).size;
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    final navIndex = ref.watch(bottomNavIndexProvider);

    return StudentDetailsInitializer(
      // Wrap with Initializer
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Container(
          decoration: BoxDecoration(
            /* Gradient */
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.1),
                accentColor.withOpacity(0.1),
                Colors.white,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(context, ref), // Uses original provider
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(studentDetailsProvider.notifier)
                          .fetchStudentDetails();
                      ref.invalidate(dailyQuestProvider);
                      ref.invalidate(leaderboardSnippetProvider);
                      ref.invalidate(classProgressProvider);
                      ref.invalidate(upcomingEventsProvider);
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      children: [
                        _buildDailyQuestCard(context, ref), // Uses placeholder
                        const SizedBox(height: 20),
                        _buildStatsRow(context, ref), // Uses placeholder
                        const SizedBox(height: 20),
                        _buildUpcomingEventsSection(
                            context, ref), // Uses placeholder
                        const SizedBox(height: 20),
                        _buildXpIndicator(
                            context, ref), // Uses original provider
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(context, ref, navIndex),
        floatingActionButton: _buildFAB(context, accentColor),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // --- AppBar Widget (Uses ORIGINAL studentDetailsProvider) ---
  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final StudentModel? student = ref.watch(studentDetailsProvider);
    final activeStudentsAsync =
        ref.watch(activeStudentsProvider); // Placeholder
    final bool isLoading = student == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Avatar
          isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: const CircleAvatar(
                      radius: 24, backgroundColor: Colors.white))
              : CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.7),
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : student.email.isNotEmpty
                            ? student.email[0].toUpperCase()
                            : '?',
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 120, height: 18, color: Colors.white),
                          const SizedBox(height: 4),
                          Container(width: 90, height: 14, color: Colors.white)
                        ]))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Hello, ${student.name.isNotEmpty ? student.name.split(' ').first : student.email.split('@').first}!",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800]),
                          overflow: TextOverflow.ellipsis),
                      Text("Let's make today count!",
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
          ),
          // Active Students Chip (Placeholder)
          activeStudentsAsync.when(
            data: (count) => Chip(
                avatar: Icon(Icons.group_outlined,
                    size: 16, color: Colors.green[700]),
                label: Text("$count Active",
                    style: TextStyle(fontSize: 11, color: Colors.green[800])),
                backgroundColor: Colors.green.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                visualDensity: VisualDensity.compact,
                side: BorderSide.none),
            loading: () => const SizedBox(width: 60, height: 24),
            error: (e, s) => const SizedBox.shrink(),
          ),
          // Logout Button
          IconButton(
            icon: Icon(Icons.logout, color: Colors.grey[600]),
            tooltip: "Logout",
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  // --- XP Indicator Widget (Uses ORIGINAL studentDetailsProvider) ---
  Widget _buildXpIndicator(BuildContext context, WidgetRef ref) {
    final StudentModel? student = ref.watch(studentDetailsProvider);
    if (student == null) return _buildShimmerCard(height: 80, borderRadius: 12);

    const int xpPerLevelBase = 500;
    const double levelMultiplier = 1.2; // Customize these
    int currentLevel = 1;
    int xpForCurrentLevelStart = 0;
    int xpForNextLevel = xpPerLevelBase;
    int cumulativeXp = 0;
    while (student.xp >= cumulativeXp + xpForNextLevel) {
      cumulativeXp += xpForNextLevel;
      currentLevel++;
      xpForNextLevel =
          (xpPerLevelBase * (currentLevel - 1) * levelMultiplier).toInt() +
              xpPerLevelBase;
    }
    xpForCurrentLevelStart = cumulativeXp;
    int xpInCurrentLevel = student.xp - xpForCurrentLevelStart;
    int totalXpNeededForThisLevel = xpForNextLevel;
    double progress = (totalXpNeededForThisLevel > 0)
        ? (xpInCurrentLevel / totalXpNeededForThisLevel).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Level $currentLevel",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor)),
            Tooltip(
                message: "Total Experience Points",
                child: Text("${student.xp} XP",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500))),
          ]),
          const SizedBox(height: 8),
          if (totalXpNeededForThisLevel > 0)
            LinearPercentIndicator(
              percent: progress,
              lineHeight: 12.0,
              backgroundColor: Colors.grey[300],
              progressColor: Colors.amber,
              barRadius: const Radius.circular(6),
              animation: true,
              center: Text(
                  "$xpInCurrentLevel / $totalXpNeededForThisLevel XP to Level ${currentLevel + 1}",
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500)),
            )
          else
            Text("Max Level Reached!",
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ]),
      ),
    );
  }

  // --- Daily Quest Card Widget (Uses PLACEHOLDER provider - Full Implementation) ---
  Widget _buildDailyQuestCard(BuildContext context, WidgetRef ref) {
    final questAsync = ref.watch(dailyQuestProvider); // Uses placeholder
    final Color primaryColor = Theme.of(context).primaryColor;
    return questAsync.when(
      data: (quest) {
        if (quest == null) {
          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(children: [
                Icon(Icons.celebration_outlined,
                    color: Colors.orangeAccent, size: 30),
                const SizedBox(width: 15),
                Expanded(
                    child: Text("Nice! No main quest today. Explore or revise!",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700])))
              ]),
            ),
          );
        }
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {/* TODO: Navigate */},
            child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor.withOpacity(0.8), primaryColor])),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(_getIconForContext(quest.subjectIcon),
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text("TODAY'S QUEST",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text("+${quest.xpReward} XP",
                          style: TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold))
                    ]),
                    const SizedBox(height: 8),
                    Text(quest.title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(quest.description,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: LinearPercentIndicator(
                              percent: quest.progress,
                              lineHeight: 10.0,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              progressColor: Colors.yellowAccent,
                              barRadius: const Radius.circular(5),
                              animation: true)),
                      const SizedBox(width: 12),
                      Text("${(quest.progress * 100).toInt()}%",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14))
                    ]),
                    const SizedBox(height: 8),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                            onPressed: () {/* TODO: Navigate */},
                            icon: const Icon(Icons.arrow_forward,
                                size: 18, color: Colors.white),
                            label: const Text("Start Quest",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                backgroundColor: Colors.white.withOpacity(0.15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20))))),
                  ]),
            ),
          ),
        );
      },
      loading: () => _buildShimmerCard(height: 180),
      error: (e, s) => _buildErrorCard("Couldn't load today's quest.",
          () => ref.invalidate(dailyQuestProvider)),
    );
  }

  // --- Stats Row Widget (Uses PLACEHOLDER providers - Full Implementation) ---
  Widget _buildStatsRow(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: ref.watch(leaderboardSnippetProvider).when(
                data: (snippet) => _buildStatCard(
                    context: context,
                    title: "Your Rank",
                    value:
                        snippet.yourRank != null ? "#${snippet.yourRank}" : "-",
                    subtitle: "/ ${snippet.totalStudents} Students",
                    icon: Icons.leaderboard_outlined,
                    color: Colors.orangeAccent,
                    onTap: () {/* TODO: Navigate */}),
                loading: () => _buildShimmerCard(height: 100),
                error: (e, s) => _buildErrorCard("Rank unavailable",
                    () => ref.invalidate(leaderboardSnippetProvider),
                    height: 100, isSmall: true),
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ref.watch(classProgressProvider).when(
                data: (progress) => _buildStatCard(
                    context: context,
                    title: "Class Progress",
                    value:
                        "${(progress.syllabusCompletionPercent * 100).toInt()}%",
                    subtitle: "Syllabus Covered",
                    icon: Icons.school_outlined,
                    color: Colors.lightBlueAccent,
                    progress: progress.syllabusCompletionPercent,
                    onTap: () {/* TODO: Navigate */}),
                loading: () => _buildShimmerCard(height: 100),
                error: (e, s) => _buildErrorCard("Progress error",
                    () => ref.invalidate(classProgressProvider),
                    height: 100, isSmall: true),
              ),
        ),
      ],
    );
  }

  // Reusable Stat Card for the Row (Full Implementation)
  Widget _buildStatCard(
      {required BuildContext context,
      required String title,
      required String value,
      required String subtitle,
      required IconData icon,
      required Color color,
      double? progress,
      VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(children: [
              if (progress != null)
                SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularPercentIndicator(
                        radius: 20.0,
                        lineWidth: 4.0,
                        percent: progress,
                        center: Icon(icon, size: 18, color: color),
                        progressColor: color,
                        backgroundColor: color.withOpacity(0.2),
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true))
              else
                CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[850])),
                    Text(subtitle,
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]))
                  ]))
            ])),
      ),
    );
  }

  // --- Upcoming Events Section Widget (Uses PLACEHOLDER provider - Full Implementation) ---
  Widget _buildUpcomingEventsSection(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Upcoming Events",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800])),
      const SizedBox(height: 12),
      eventsAsync.when(
        data: (events) {
          if (events.isEmpty)
            return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                    child: Row(children: [
                      Icon(Icons.event_available_outlined, color: Colors.grey),
                      SizedBox(width: 12),
                      Text("No upcoming events right now.",
                          style: TextStyle(color: Colors.grey))
                    ])));
          events.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          return Column(children: [
            ...events
                .take(3)
                .map((event) => _buildEventItemTile(context, event))
                .toList(),
            if (events.length > 3)
              Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          child: const Text("View All"),
                          onPressed: () {/* TODO: Navigate */})))
          ]);
        },
        loading: () => Column(children: [
          _buildShimmerCard(height: 60, borderRadius: 10),
          const SizedBox(height: 8),
          _buildShimmerCard(height: 60, borderRadius: 10),
          const SizedBox(height: 8),
          _buildShimmerCard(height: 60, borderRadius: 10)
        ]),
        error: (e, s) => _buildErrorCard("Couldn't load events.",
            () => ref.invalidate(upcomingEventsProvider)),
      ),
    ]);
  }

  // List Tile for a single event (Full Implementation)
  Widget _buildEventItemTile(BuildContext context, EventItem event) {
    final now = DateTime.now();
    final difference = event.dueDate.difference(now);
    String timeDifference;
    Color timeColor = Colors.grey[600]!;
    FontWeight timeWeight = FontWeight.normal;
    if (difference.isNegative) {
      timeDifference = "Past Due";
      timeColor = Colors.redAccent;
      timeWeight = FontWeight.w500;
    } else if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        timeDifference = "${difference.inMinutes} min left";
        timeColor = Colors.orangeAccent[700]!;
        timeWeight = FontWeight.bold;
      } else {
        timeDifference = "${difference.inHours} hr left";
        timeColor = Colors.orangeAccent;
        timeWeight = FontWeight.w500;
      }
    } else if (difference.inDays < 2) {
      timeDifference =
          "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} left";
      timeColor = Colors.blueAccent;
    } else {
      timeDifference = DateFormat('E, MMM d').format(event.dueDate);
    }
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
          leading: CircleAvatar(
              radius: 18,
              backgroundColor: _getEventColor(event.type).withOpacity(0.15),
              child: Icon(_getIconForContext(event.type.name),
                  size: 18, color: _getEventColor(event.type))),
          title: Text(event.title,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          subtitle: event.subject != null
              ? Text(event.subject!, style: const TextStyle(fontSize: 13))
              : null,
          trailing: Text(timeDifference,
              style: TextStyle(
                  fontSize: 12, color: timeColor, fontWeight: timeWeight)),
          onTap: () {/* TODO: Navigate */},
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 12)),
    );
  }

  // --- Shimmer Loading Placeholder Widget (Full Implementation) ---
  Widget _buildShimmerCard({required double height, double borderRadius = 15}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
          height: height,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius))),
    );
  }

  // --- Error Card Widget (Full Implementation) ---
  Widget _buildErrorCard(String message, VoidCallback onRetry,
      {double? height, bool isSmall = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.red[50],
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: height,
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: isSmall ? 24 : 30),
            SizedBox(height: isSmall ? 4 : 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.red[700], fontSize: isSmall ? 12 : 14)),
            SizedBox(height: isSmall ? 2 : 4),
            Text("Tap to retry",
                style: TextStyle(
                    color: Colors.red[700],
                    fontSize: isSmall ? 10 : 12,
                    fontWeight: FontWeight.w500))
          ])),
        ),
      ),
    );
  }

  // --- Bottom Navigation Bar (Full Implementation) ---
  Widget _buildBottomNavBar(
      BuildContext context, WidgetRef ref, int currentIndex) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(bottomNavIndexProvider.notifier).state =
            index, // Update state on tap
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined), label: 'Plan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Progress'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile')
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[500],
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        backgroundColor: Colors.white,
      ),
    );
  }

  // --- Floating Action Button (FAB) ---
  Widget _buildFAB(BuildContext context, Color accentColor) {
    return FloatingActionButton.extended(
      onPressed: () {
        /* TODO: Navigate to Ask Doubt Screen */
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Ask AI Feature (Not Implemented)"),
            duration: Duration(seconds: 1)));
      },
      icon: const Icon(Icons.support_agent_outlined),
      label: const Text("Ask AI"),
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
      heroTag: 'fab_ask_doubt_v3_original_provider', // Ensure unique tag
    );
  }
}
