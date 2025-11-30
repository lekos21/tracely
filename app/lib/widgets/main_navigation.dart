import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/cards_screen.dart';
import '../screens/facts_screen.dart';
import '../screens/profile_screen.dart';

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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFFBEB).withOpacity(0.95), // amber-50 with high opacity
                    const Color(0xFFFDF2F8).withOpacity(0.95), // pink-50 with high opacity
                    const Color(0xFFFEF3E2).withOpacity(0.95), // orange-50 with high opacity
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFF472B6).withOpacity(0.2), // pink accent border
                    width: 1.5,
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
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
                            color: const Color(0xFFF472B6).withAlpha(64),
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
              color: const Color(0xFF4A4A4A).withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 48, // Reduced from 64 to 48
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4), // Reduced vertical padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.chat_outlined,
                  activeIcon: Icons.chat,
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.lightbulb_outline,
                  activeIcon: Icons.lightbulb,
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.bookmark_outline,
                  activeIcon: Icons.bookmark,
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
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSelected 
            ? ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFF472B6), Color(0xFFFB923C)], // pink to orange gradient
                ).createShader(bounds),
                child: Icon(
                  activeIcon,
                  key: ValueKey(isSelected),
                  color: Colors.white,
                  size: 26,
                ),
              )
            : Icon(
                icon,
                key: ValueKey(isSelected),
                color: const Color(0xFF6B7280), // Gray when not selected
                size: 26,
              ),
        ),
      ),
    );
  }
}
