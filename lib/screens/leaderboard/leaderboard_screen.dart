import 'dart:math';
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animate_do/animate_do.dart';

import '../../core/theme/app_theme.dart';
import '../../core/models/leaderboard_user.dart';
import '../../core/providers/home_providers.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _backgroundController;
  late AnimationController _heroController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _backgroundController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Stack(
        children: [
          // Modern Background with subtle gradient
          _buildModernBackground(size),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildCustomAppBar(context),

                // Hero Section
                _buildHeroSection(Theme.of(context).textTheme),

                // Tab Bar
                _buildTabBar(Theme.of(context).textTheme),

                // Tab Bar View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTopAchieversTab(),
                      _buildTopStreakTab(),
                      _buildTopCoinsTab(),
                      _buildRecentActivesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBackground(Size size) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.white,
            AppTheme.gray50,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'data:image/svg+xml,<svg width="60" height="60" xmlns="http://www.w3.org/2000/svg"><defs><pattern id="grid" width="60" height="60" patternUnits="userSpaceOnUse"><path d="M 60 0 L 0 0 0 60" fill="none" stroke="%23000" stroke-width="1"/></pattern></defs><rect width="100%" height="100%" fill="url(%23grid)"/></svg>',
                    ),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),
          ),

          // Floating gradient shapes
          ...List.generate(6, (index) {
            return AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                final double animationOffset = (index * 0.2) % 1.0;
                final double progress =
                    (_backgroundController.value + animationOffset) % 1.0;

                return Positioned(
                  left: (size.width * 0.1) + (progress * size.width * 0.8),
                  top: (size.height * 0.2) +
                      (sin((progress + index * 0.4) * 2 * pi) *
                          size.height *
                          0.2) +
                      (index * size.height * 0.1),
                  child: Container(
                    width: 80 + (index * 20),
                    height: 80 + (index * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          [
                            AppTheme.primary,
                            AppTheme.secondary,
                            AppTheme.success,
                            AppTheme.warning
                          ][index % 4]
                              .withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLG, vertical: AppTheme.spaceMD),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: AppTheme.gray200),
              boxShadow: AppTheme.cardShadow,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.gray700,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Leaderboard',
                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  'Compete with scholars worldwide',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMD,
              vertical: AppTheme.spaceXS,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.success, AppTheme.primary],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: AppTheme.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: AppTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildHeroSection(TextTheme textTheme) {
    return AnimatedBuilder(
      animation: _heroController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentPink.withOpacity(0.2),
                AppColors.primaryPurple.withOpacity(0.15),
                AppColors.accentCyan.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.accentPink.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPink.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Crown Animation
              Positioned(
                top: 30,
                right: 20,
                child: Transform.scale(
                  scale: 0.8 + (_heroController.value * 0.2),
                  child: Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.goldStar,
                          AppColors.goldStar.withOpacity(0.3),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Champions Arena',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 25,
                      ),
                    ).animate().fadeInLeft(duration: 800.ms, delay: 200.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Where legends are born and excellence is celebrated',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeInLeft(duration: 800.ms, delay: 400.ms),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildQuickStat('🏆', 'Top 100', 'Elite'),
                        const SizedBox(width: 16),
                        _buildQuickStat('🔥', 'Live', 'Updates'),
                        const SizedBox(width: 16),
                        _buildQuickStat('⚡', 'Real-time', 'Rankings'),
                      ],
                    ).animate().fadeInUp(duration: 800.ms, delay: 600.ms),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentPink.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentPink, AppColors.primaryPurple],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        tabs: [
          Tab(text: 'Top XP'),
          Tab(text: 'Streaks'),
          Tab(text: 'Wealth'),
          Tab(text: 'Active'),
        ],
      ),
    );
  }

  Widget _buildTopAchieversTab() {
    final leaderboardAsync = ref.watch(homeLeaderboardProvider);

    return leaderboardAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: min(users.length, 50),
          itemBuilder: (context, index) {
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              duration: const Duration(milliseconds: 600),
              child: _buildLeaderboardCard(
                user: users[index],
                rank: index + 1,
                statType: 'XP',
                statValue: '${users[index].xp}',
                statColor: AppColors.accentCyan,
              ),
            );
          },
        );
      },
      loading: () => _buildLoadingState(),
      error: (e, s) => _buildErrorState(),
    );
  }

  Widget _buildTopStreakTab() {
    final leaderboardAsync = ref.watch(homeLeaderboardProvider);

    return leaderboardAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return _buildEmptyState();
        }
        // Sort by streak (mock data - in real app you'd have streak data)
        final sortedUsers = List<LeaderboardUser>.from(users);
        sortedUsers
            .sort((a, b) => (b.xp % 100).compareTo(a.xp % 100)); // Mock streak

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: min(sortedUsers.length, 50),
          itemBuilder: (context, index) {
            final mockStreak = sortedUsers[index].xp % 100;
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              duration: const Duration(milliseconds: 600),
              child: _buildLeaderboardCard(
                user: sortedUsers[index],
                rank: index + 1,
                statType: 'Day Streak',
                statValue: '$mockStreak',
                statColor: Colors.orange,
              ),
            );
          },
        );
      },
      loading: () => _buildLoadingState(),
      error: (e, s) => _buildErrorState(),
    );
  }

  Widget _buildTopCoinsTab() {
    final leaderboardAsync = ref.watch(homeLeaderboardProvider);

    return leaderboardAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return _buildEmptyState();
        }
        // Sort by coins (mock data)
        final sortedUsers = List<LeaderboardUser>.from(users);
        sortedUsers
            .sort((a, b) => (b.xp ~/ 10).compareTo(a.xp ~/ 10)); // Mock coins

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: min(sortedUsers.length, 50),
          itemBuilder: (context, index) {
            final mockCoins = sortedUsers[index].xp ~/ 10;
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              duration: const Duration(milliseconds: 600),
              child: _buildLeaderboardCard(
                user: sortedUsers[index],
                rank: index + 1,
                statType: 'Coins',
                statValue: '$mockCoins',
                statColor: AppColors.goldStar,
              ),
            );
          },
        );
      },
      loading: () => _buildLoadingState(),
      error: (e, s) => _buildErrorState(),
    );
  }

  Widget _buildRecentActivesTab() {
    final leaderboardAsync = ref.watch(homeLeaderboardProvider);

    return leaderboardAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return _buildEmptyState();
        }
        // Shuffle for "recent actives" effect
        final shuffledUsers = List<LeaderboardUser>.from(users);
        shuffledUsers.shuffle();

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: min(shuffledUsers.length, 50),
          itemBuilder: (context, index) {
            final timeAgo =
                ['2m ago', '5m ago', '10m ago', '15m ago', '1h ago'][index % 5];
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              duration: const Duration(milliseconds: 600),
              child: _buildLeaderboardCard(
                user: shuffledUsers[index],
                rank: index + 1,
                statType: 'Last Seen',
                statValue: timeAgo,
                statColor: AppColors.accentGreen,
              ),
            );
          },
        );
      },
      loading: () => _buildLoadingState(),
      error: (e, s) => _buildErrorState(),
    );
  }

  Widget _buildLeaderboardCard({
    required LeaderboardUser user,
    required int rank,
    required String statType,
    required String statValue,
    required Color statColor,
  }) {
    final bool isTopThree = rank <= 3;
    final Color rankColor = rank == 1
        ? AppColors.goldStar
        : rank == 2
            ? Colors.grey[400]!
            : rank == 3
                ? Colors.amber[700]!
                : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTopThree
              ? [
                  statColor.withOpacity(0.15),
                  statColor.withOpacity(0.05),
                ]
              : [
                  AppColors.surfaceDark.withOpacity(0.8),
                  AppColors.surfaceDark.withOpacity(0.4),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTopThree
              ? statColor.withOpacity(0.3)
              : AppColors.primaryPurple.withOpacity(0.2),
          width: isTopThree ? 2 : 1,
        ),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: statColor.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // TODO: Show user profile
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: isTopThree
                        ? LinearGradient(
                            colors: [rankColor, rankColor.withOpacity(0.7)],
                          )
                        : null,
                    color: isTopThree ? null : AppColors.surfaceDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rankColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isTopThree)
                        Icon(
                          rank == 1
                              ? Icons.workspace_premium_rounded
                              : rank == 2
                                  ? Icons.military_tech_rounded
                                  : Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      if (!isTopThree)
                        Text(
                          '$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primaryPurple, AppColors.accentPink],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Level ${(user.xp ~/ 1000) + 1}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Stat
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      statValue,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statColor,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      statType,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.accentPink.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 50,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Champions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to claim your spot!',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 82,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: AppColors.surfaceDark.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      color: AppColors.surfaceDark.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 60,
                height: 40,
                color: AppColors.surfaceDark.withOpacity(0.5),
              ),
              const SizedBox(width: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to Load Leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(homeLeaderboardProvider);
            },
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPink,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
