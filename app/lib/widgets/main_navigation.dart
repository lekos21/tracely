import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/cards_screen.dart';
import '../screens/facts_screen.dart';
import '../services/firebase_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const CardsScreen(),
    const FactsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFFFFFFF).withOpacity(0.4),
                    width: 1,
                  ),
                ),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: const Text(
                  'tracely',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937), // darker gray-800
                    letterSpacing: -0.5,
                  ),
                ),
                actions: [
                  // Enhanced profile button with gradient chip
                  PopupMenuButton<String>(
                    tooltip: 'Account',
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF472B6), Color(0xFFFB923C)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF472B6).withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF1F2937),
                          size: 20,
                        ),
                      ),
                    ),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await FirebaseService().signOut();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFBEB), // amber-50
              Color(0xFFFDF2F8), // pink-50
              Color(0xFFFEF3E2), // orange-50
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A4A4A).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.style_outlined,
                  activeIcon: Icons.style_rounded,
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.bookmark_outline_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final bool isSelected = _currentIndex == index;
    
    // Use the same gradient as the header icon (pink to orange)
    const gradient = LinearGradient(
      colors: [Color(0xFFF472B6), Color(0xFFFB923C)], // pink-400 to orange-400
    );
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFF472B6).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isSelected ? activeIcon : icon,
            key: ValueKey(isSelected),
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            size: 24,
          ),
        ),
      ),
    );
  }
}
