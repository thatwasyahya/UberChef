// lib/screens/main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  final List<String> _titles = ['Recherche', 'Historique', 'Messages', 'Profil'];

  final List<Widget> _pages = const [
    SearchPage(),
    HistoriquePage(),
    MessagesPage(),
    ProfilePage(userId: 1),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  // Vérifier s'il y a des messages non lus
  bool _hasUnreadMessages() {
    // À implémenter: logique pour vérifier les messages non lus
    return false; // Désactivé pour l'instant
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomAppBar(
        elevation: 0,
        notchMargin: 10,
        shape: const CircularNotchedRectangle(),
        color: Colors.white,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.search_rounded, 'Recherche'),
              _buildNavItem(1, Icons.history_rounded, 'Historique'),
              const SizedBox(width: 60), // Espace pour le FAB
              _buildNavItem(2, Icons.message_rounded, 'Messages'),
              _buildProfileNavItem(3, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    final Color itemColor = isSelected ? Colors.deepOrange : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: Colors.deepOrange.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(top: isSelected ? 0 : 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    color: itemColor,
                    size: isSelected ? 28 : 24,
                  ),
                  // Badge de notification pour l'onglet Messages
                  if (index == 2 && _hasUnreadMessages())
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            if (!isSelected)
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: itemColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(int index, String label) {
    final bool isSelected = _currentIndex == index;
    final Color itemColor = isSelected ? Colors.deepOrange : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: Colors.deepOrange.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.deepOrange, width: 2)
                    : null,
              ),
              padding: const EdgeInsets.all(2),
              child: const CircleAvatar(
                radius: 12,
                backgroundImage: AssetImage('assets/profile_placeholder.png'),
              ),
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
              )
            else
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: itemColor,
                  fontWeight: FontWeight.w500,
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _titles[_currentIndex],
            key: ValueKey<String>(_titles[_currentIndex]),
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.filter_list),
              color: Colors.grey[700],
              onPressed: () {
                // Afficher les filtres de recherche
              },
            ),
          if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              color: Colors.grey[700],
              onPressed: () {
                // Ouvrir les paramètres
              },
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        elevation: 6,
        splashColor: Colors.orange[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () {
          // Effet visuel au clic
          HapticFeedback.mediumImpact();

          // Navigation vers la page d'ajout d'offre
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