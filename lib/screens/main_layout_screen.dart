// --- lib/screens/main_layout_screen.dart ---

import 'package:bharat_ace/screens/gifts_screen/presentations/screens/rewards_gallery_screen.dart';
import 'package:bharat_ace/screens/profile_screen.dart';
import 'package:bharat_ace/screens/syllabus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Screens for the tabs (Ensure paths are correct)
import 'package:bharat_ace/screens/home_screen/home_screen2.dart';

import '../widgets/home_screen_widgets/ai_chat_widget.dart'; // Or HomeScreenV4, etc.

// --- Import AiChatWidget and related classes/constants ---
// You'll need to ensure these paths are correct based on your project structure.
// Assuming AiChatWidget, ChatMessage, and GeminiService are defined/accessible
// from where HomeScreen2 is.
// If not, you might need to create a shared widgets/services directory.
// For this example, I'll assume AiChatWidget is defined in or imported by home_screen2.dart
// and HomeScreen2.surfaceDark etc. are accessible or we redefine them here.

// If AiChatWidget is defined in home_screen2.dart, it might be better to move it to its own file
// e.g., lib/widgets/ai_chat_widget.dart and import it here.
// For simplicity, I'll assume it's accessible. If not, you'll see an error.

// *** DEFINE bottomNavIndexProvider HERE ***
final bottomNavIndexProvider = StateProvider<int>((ref) {
  // Default selected index (e.g., 0 for Home)
  return 0;
});
// ****************************************

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  // --- Colors (These should ideally be in a central theme file) ---
  static const Color darkBg = Color(0xFF12121F);
  static const Color primaryPurple = Color(0xFF7E57C2); // From HomeScreen2
  static const Color accentCyan = Color(0xFF29B6F6); // From HomeScreen2
  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color surfaceLight =
      Color(0xFF2A2A3A); // From HomeScreen2 for AiChatWidget styling
  // --- End Colors ---

  // List of screen widgets corresponding to bottom nav indices
  final List<Widget> _screens = const [
    HomeScreen2(), // Index 0
    SyllabusScreen(), // Index 1
    RewardsGalleryScreen(), // Index 2
    ProfileScreen() // Index 3 - Use actual ProfileScreen
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the index from the provider defined above
    final int selectedIndex = ref.watch(bottomNavIndexProvider);

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
        floatingActionButton:
            _buildFABV5(context, ref), // Pass ref for AiChatWidget
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked);
  }

  // --- Bottom Nav Bar Builder ---
  Widget _buildBottomNavBarV5(
      BuildContext context, WidgetRef ref, int currentIndex) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 4,
      color: surfaceDark.withOpacity(0.95),
      padding: EdgeInsets.zero,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) =>
            ref.read(bottomNavIndexProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded), label: 'Syllabus'),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: 'Gifts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile')
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: accentCyan,
        unselectedItemColor: textSecondary.withOpacity(0.7),
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }

  // --- FAB Builder ---
  Widget _buildFABV5(BuildContext context, WidgetRef ref) {
    // Added WidgetRef
    return FloatingActionButton(
      onPressed: () {
        // --- UPDATED TO SHOW AiChatWidget ---
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          // Use colors defined in MainLayout or import from HomeScreen2
          backgroundColor: MainLayout
              .surfaceDark, // Or HomeScreen2.surfaceDark if accessible and preferred
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          builder: (BuildContext bottomSheetContext) {
            // AiChatWidget is a ConsumerStatefulWidget, so it manages its own provider consumption.
            // We pass null for 'item' to indicate a general chat session.
            // Make sure AiChatWidget is imported or accessible in this file's scope.
            return const AiChatWidget(item: null);
          },
        );
        // --- END UPDATED PART ---
      },
      backgroundColor: accentCyan,
      foregroundColor: darkBg,
      elevation: 4.0,
      shape: const CircleBorder(),
      heroTag: 'fab_main_layout_v5_general_ai_chat', // Ensure unique heroTag
      child: const Icon(Icons.support_agent_sharp),
    );
  }
} // End of MainLayout class

// IMPORTANT: AiChatWidget Definition
