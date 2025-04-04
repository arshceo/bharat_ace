import 'package:bharat_ace/screens/home_screen/home_screen2.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen2(),
    Placeholder(), // Subjects Screen
    Placeholder(), // Assignments Screen
    Placeholder(), // Profile Screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(55, 132, 67, 252),
        body: _screens[_selectedIndex],
        bottomNavigationBar: CustomNavBar());
  }
}

class CyberpunkNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CyberpunkNavbar(
      {super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.greenAccent.withOpacity(0.5), width: 2),
        ),
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.green.withOpacity(0.3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey[700],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: "Hack"),
          BottomNavigationBarItem(
              icon: Icon(Icons.book_online), label: "Learn"),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: "Play"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.transparent,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home, color: Color(0xFF7219F8)),
            Icon(Icons.school, color: Colors.black45),
            FloatingActionButton(
              backgroundColor: Colors.greenAccent,
              onPressed: () {},
              child: const Icon(Icons.play_arrow, color: Colors.black),
            ),
            Icon(Icons.leaderboard, color: Colors.white54),
            Icon(Icons.settings, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
