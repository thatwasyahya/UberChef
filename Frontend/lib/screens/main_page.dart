// lib/screens/main_page.dart
import 'package:flutter/material.dart';

import 'search_page.dart';
import 'historique_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import 'add_offer_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // We use indexes: 0=Search, 1=Historique, 2=Messages, 3=Profile.
  // The center FAB (Add) is handled separately.
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SearchPage(),
    HistoriquePage(),
    MessagesPage(),
    ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.black,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.search,
                size: _currentIndex == 0 ? 32.0 : 28.0,
              ),
              color: Colors.orange,
              onPressed: () => _onTabTapped(0),
            ),
            IconButton(
              icon: Icon(
                Icons.history,
                size: _currentIndex == 1 ? 32.0 : 28.0,
              ),
              color: Colors.orange,
              onPressed: () => _onTabTapped(1),
            ),
            const SizedBox(width: 48), // space for FAB.
            IconButton(
              icon: const Icon(Icons.message),
              color: Colors.orange,
              onPressed: () => _onTabTapped(2),
            ),
            GestureDetector(
              onTap: () => _onTabTapped(3),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: AssetImage('assets/profile_placeholder.png'),
                  // Replace with the user's profile picture if available.
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          // Replace 1 with your current logged-in user's id.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddOfferPage(userId: 1)),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
