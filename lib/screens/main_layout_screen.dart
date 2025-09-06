// --- lib/screens/main_layout_screen.dart ---

import 'package:bharat_ace/screens/profile_screen_new.dart';
import 'package:bharat_ace/screens/syllabus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Screens for the tabs
import 'package:bharat_ace/screens/home_screen/home_screen_backup.dart';
import 'package:bharat_ace/screens/competitions/competitions_screen.dart';
import 'package:bharat_ace/screens/exam_succeed/exam_succeed_screen.dart';
import '../widgets/home_screen_widgets/ai_chat_widget.dart';

// Import the new theme system and providers
import 'package:bharat_ace/core/theme/app_theme.dart';
import 'package:bharat_ace/core/providers/feature_toggle_provider.dart';

// *** Navigation Provider ***
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  // Get screens based on feature toggle status
  List<Widget> _getScreens(bool extraFeaturesEnabled) {
    return [
      const HomeScreen2(), // Index 0
      const SyllabusScreen(), // Index 1
      extraFeaturesEnabled
          ? const CompetitionsScreen() // Index 2 with features enabled
          : const ExamSucceedScreen(), // Index 2 with features disabled
      const ProfileScreen() // Index 3
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectedIndex = ref.watch(bottomNavIndexProvider);
    // Watch the feature toggle state
    final bool extraFeaturesEnabled = ref.watch(featureToggleProvider);
    // Get screens based on feature toggle
    final screens = _getScreens(extraFeaturesEnabled);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar:
          _buildBottomNavBar(context, ref, selectedIndex, extraFeaturesEnabled),
      floatingActionButton: _buildFAB(context, ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // --- Modern Bottom Navigation Bar ---
  Widget _buildBottomNavBar(
      BuildContext context, WidgetRef ref, int currentIndex,
      [bool extraFeaturesEnabled = false]) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCard
            : AppTheme.white,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLG)),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ]
            : [
                BoxShadow(
                  color: AppTheme.gray900.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 0,
        color: Colors.transparent,
        padding: EdgeInsets.zero,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0, currentIndex, ref),
              _buildNavItem(
                  Icons.menu_book_rounded, 'Syllabus', 1, currentIndex, ref),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(
                  extraFeaturesEnabled
                      ? Icons.emoji_events_rounded
                      : Icons.school_rounded,
                  extraFeaturesEnabled ? 'Competitions' : 'Exam Tips',
                  2,
                  currentIndex,
                  ref),
              _buildNavItem(
                  Icons.person_rounded, 'Profile', 3, currentIndex, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, int currentIndex, WidgetRef ref) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => ref.read(bottomNavIndexProvider.notifier).state = index,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSM,
          vertical: AppTheme.spaceXS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.textTheme.labelSmall?.copyWith(
                color: isSelected ? AppTheme.primary : AppTheme.gray400,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Modern AI Assistant FAB ---
  Widget _buildFAB(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppTheme.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXL),
              ),
            ),
            builder: (BuildContext bottomSheetContext) {
              return const AiChatWidget(item: null);
            },
          );
        },
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.white,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        heroTag: 'main_ai_chat_fab',
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 28,
        ),
      ),
    );
  }
}
