// --- lib/screens/main_layout_screen.dart (Corrected - Provider Defined) ---

import 'package:bharat_ace/screens/syllabus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Screens for the tabs (Ensure paths are correct)
import 'package:bharat_ace/screens/home_screen/home_screen2.dart'; // Or HomeScreenV4, etc.

// *** DEFINE bottomNavIndexProvider HERE ***
final bottomNavIndexProvider = StateProvider<int>((ref) {
  // Default selected index (e.g., 0 for Home)
  return 0;
});
// ****************************************

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  // --- Colors (Move to AppTheme) ---
  static const Color darkBg = Color(0xFF12121F);
  static const Color primaryPurple = Color(0xFF8A2BE2);
  static const Color accentCyan = Color(0xFF00FFFF);
  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  // --- End Colors ---

  // List of screen widgets corresponding to bottom nav indices
  final List<Widget> _screens = const [
    HomeScreen2(), // Index 0
    SyllabusScreen(), // Index 1
    Placeholder(
        child: Center(child: Text("Progress (Placeholder)"))), // Index 2
    Placeholder(child: Center(child: Text("Profile (Placeholder)"))), // Index 3
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the index from the provider defined above
    final int selectedIndex = ref.watch(bottomNavIndexProvider);
    final ColorScheme colorScheme =
        Theme.of(context).colorScheme; // Use Theme if setup

    return Scaffold(
        backgroundColor: darkBg, // Use defined dark color
        extendBody: true, // Allows body content behind bottom nav bar
        body: IndexedStack(
          // Use IndexedStack to keep screen states
          index: selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavBarV5(
            context, ref, selectedIndex), // Pass necessary params
        floatingActionButton: _buildFABV5(context),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked);
  }

  // --- Bottom Nav Bar Builder ---
  Widget _buildBottomNavBarV5(
      BuildContext context, WidgetRef ref, int currentIndex) {
    // Ideally get colors from Theme.of(context).colorScheme if theme is applied
    return BottomAppBar(
      shape: const CircularNotchedRectangle(), notchMargin: 8.0, elevation: 4,
      color: surfaceDark.withOpacity(0.95), // Use defined dark surface color
      padding: EdgeInsets.zero,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        // Update the provider state when an item is tapped
        onTap: (index) =>
            ref.read(bottomNavIndexProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded), label: 'Syllabus'),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_rounded), label: 'Progress'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile')
        ],
        backgroundColor:
            Colors.transparent, // Make transparent to show BottomAppBar color
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: accentCyan, // Use defined accent color
        unselectedItemColor:
            textSecondary.withOpacity(0.7), // Use defined text color
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        showSelectedLabels: true, showUnselectedLabels: true,
      ),
    );
  }

  // --- FAB Builder ---
  Widget _buildFABV5(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Ask AI Feature (Not Implemented)"),
            duration: Duration(seconds: 1)));
      },
      // Use theme colors ideally, otherwise use defined constants
      backgroundColor: accentCyan,
      foregroundColor: darkBg,
      elevation: 4.0, // Slightly less elevation
      shape: const CircleBorder(),
      heroTag: 'fab_main_layout_v5',
      child: const Icon(Icons.support_agent_sharp), // Ensure unique tag
    );
  }
} // End of MainLayout class
