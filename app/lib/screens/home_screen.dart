import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/card_preloader.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _factController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _showSuccess = false;
  bool _isInputFocused = false;
  late AnimationController _successAnimationController;
  late Animation<double> _successAnimation;
  late AnimationController _floatingAnimationController;
  late List<AnimationController> _heartAnimationControllers;

  @override
  void initState() {
    super.initState();
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Initialize heart animations
    _heartAnimationControllers = List.generate(8, (index) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 3000 + (math.Random().nextInt(2000))),
        vsync: this,
      );
      Future.delayed(Duration(milliseconds: index * 500), () {
        if (mounted) controller.repeat();
      });
      return controller;
    });
    
    _focusNode.addListener(() {
      setState(() {
        _isInputFocused = _focusNode.hasFocus;
      });
    });
    
    // Start preloading cards in the background for better UX
    Future.microtask(() {
      CardPreloader().preloadCards();
    });
  }

  @override
  void dispose() {
    _factController.dispose();
    _focusNode.dispose();
    _successAnimationController.dispose();
    _floatingAnimationController.dispose();
    for (var controller in _heartAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submitFact() {
    if (_factController.text.trim().isEmpty) return;

    final factText = _factController.text.trim();
    
    // Optimistic UI: Show immediate success feedback
    _factController.clear();
    _focusNode.unfocus();
    
    setState(() {
      _showSuccess = true;
      _isLoading = false;
    });
    
    // Start success animation immediately
    _successAnimationController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _successAnimationController.reverse();
          setState(() {
            _showSuccess = false;
          });
        }
      });
    });
    
    // Handle server call asynchronously in background
    _submitFactToServer(factText);
  }
  
  Future<void> _submitFactToServer(String factText) async {
    try {
      final result = await FirebaseService().saveFact(factText);
      
      // Only show error if the call failed
      if (result['success'] != true) {
        _showError(result['message'] ?? 'Failed to save fact. Please try again.');
      }
      // If successful, do nothing - user already saw success feedback
    } catch (e) {
      _showError('Network error. Your fact may not have been saved.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF7ED), // orange-50
              Color(0xFFFDF2F8), // pink-50  
              Color(0xFFFEF3E2), // peach-100
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: 80,
              left: 40,
              child: AnimatedBuilder(
                animation: _floatingAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      math.sin(_floatingAnimationController.value * 2 * math.pi) * 10,
                      math.cos(_floatingAnimationController.value * 2 * math.pi) * 5,
                    ),
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFBCFE8).withOpacity(0.3), // pink-200/30
                            const Color(0xFFFED7AA).withOpacity(0.3), // orange-200/30
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 160,
              right: 64,
              child: AnimatedBuilder(
                animation: _floatingAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      math.cos(_floatingAnimationController.value * 2 * math.pi + 1) * 8,
                      math.sin(_floatingAnimationController.value * 2 * math.pi + 1) * 6,
                    ),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFDBA74).withOpacity(0.2), // orange-300/20
                            const Color(0xFFF9A8D4).withOpacity(0.2), // pink-300/20
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 128,
              left: MediaQuery.of(context).size.width * 0.25,
              child: AnimatedBuilder(
                animation: _floatingAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      math.sin(_floatingAnimationController.value * 2 * math.pi + 2) * 12,
                      math.cos(_floatingAnimationController.value * 2 * math.pi + 2) * 8,
                    ),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFECDD3).withOpacity(0.25), // peach-200/25
                            const Color(0xFFFBCFE8).withOpacity(0.25), // pink-200/25
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 80,
              right: 32,
              child: AnimatedBuilder(
                animation: _floatingAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      math.cos(_floatingAnimationController.value * 2 * math.pi + 3) * 6,
                      math.sin(_floatingAnimationController.value * 2 * math.pi + 3) * 10,
                    ),
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFED7AA).withOpacity(0.3), // orange-200/30
                            const Color(0xFFFBCFE8).withOpacity(0.3), // pink-200/30
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Floating hearts animation
            ...List.generate(8, (index) {
              final random = math.Random(index);
              return Positioned(
                left: random.nextDouble() * MediaQuery.of(context).size.width,
                top: random.nextDouble() * MediaQuery.of(context).size.height,
                child: AnimatedBuilder(
                  animation: _heartAnimationControllers[index],
                  builder: (context, child) {
                    return Opacity(
                      opacity: (math.sin(_heartAnimationControllers[index].value * 2 * math.pi) + 1) / 2 * 0.2,
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFF9A8D4), // pink-300
                        size: 16,
                      ),
                    );
                  },
                ),
              );
            }),
            
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Add some top spacing
                      SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                      
                      // Hero Text
                      Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFFF97316)], // pink-500 to orange-500
                            ).createShader(bounds),
                            child: const Text(
                              'Never forget the\nlittle things',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Store memories, preferences, and ideas. Let AI help you be the most thoughtful partner ever.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF6B7280), // gray-600
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Input Section
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A4A4A).withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _factController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: 'Her favorite color is...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF), // gray-400
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                filled: true,
                                fillColor: _isInputFocused 
                                    ? Colors.white 
                                    : Colors.white.withOpacity(0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFFBCFE8).withOpacity(0.5), // pink-200/50
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF9A8D4), // pink-300
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFFBCFE8).withOpacity(0.5), // pink-200/50
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                suffixIcon: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    color: _isInputFocused 
                                        ? const Color(0xFFEC4899) // pink-500
                                        : const Color(0xFF9CA3AF), // gray-400
                                    size: 24,
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF374151), // gray-700
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              onSubmitted: (_) => _submitFact(),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          AnimatedScale(
                            scale: _isInputFocused ? 1.02 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEC4899), Color(0xFFF97316)], // pink-500 to orange-500
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEC4899).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _submitFact,
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Remember this',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Feature Preview
                      Column(
                        children: [
                          const Text(
                            'AI-POWERED SUGGESTIONS FOR',
                            style: TextStyle(
                              color: Color(0xFF6B7280), // gray-500
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFFBCFE8).withOpacity(0.3), // pink-200/30
                                    ),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.card_giftcard,
                                        color: Color(0xFFEC4899), // pink-500
                                        size: 24,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Perfect Gifts',
                                        style: TextStyle(
                                          color: Color(0xFF374151), // gray-700
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFFED7AA).withOpacity(0.3), // orange-200/30
                                    ),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: Color(0xFFF97316), // orange-500
                                        size: 24,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Date Ideas',
                                        style: TextStyle(
                                          color: Color(0xFF374151), // gray-700
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Footer
                      Padding(
                        padding: const EdgeInsets.only(top: 32, bottom: 24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF472B6), // pink-400
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFB923C), // orange-400
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Success Animation Overlay
            if (_showSuccess)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                left: 24,
                right: 24,
                child: AnimatedBuilder(
                  animation: _successAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _successAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)], // green gradient
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Moment saved successfully!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

          ],
        ),
      ),
    );
  }

}
