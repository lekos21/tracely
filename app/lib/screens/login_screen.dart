import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/firebase_service.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _floatingAnimationController;
  late List<AnimationController> _heartAnimationControllers;

  @override
  void initState() {
    super.initState();
    
    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    // Initialize heart animations
    _heartAnimationControllers = List.generate(6, (index) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 3000 + (math.Random().nextInt(2000))),
        vsync: this,
      );
      Future.delayed(Duration(milliseconds: index * 800), () {
        if (mounted) controller.repeat();
      });
      return controller;
    });
  }

  @override
  void dispose() {
    _floatingAnimationController.dispose();
    for (var controller in _heartAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = await FirebaseService().signInWithGoogle();
      
      if (user == null) {
        _showError('Accesso con Google annullato o popup bloccato.\nProva a disabilitare il popup blocker e riprova.');
      } else {
        // Success - AuthWrapper will handle navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Benvenuto, ${user.displayName ?? user.email}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Errore durante l\'accesso';
      
      if (e.toString().contains('popup_closed')) {
        errorMessage = 'Popup chiuso prematuramente.\nAssicurati di completare l\'accesso nella finestra popup.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Errore di connessione. Verifica la tua connessione internet.';
      } else {
        errorMessage = 'Errore: ${e.toString()}';
      }
      
      _showError(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
            // Floating decorative circles
            Positioned(
              top: 80,
              right: -40,
              child: AnimatedBuilder(
                animation: _floatingAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      math.sin(_floatingAnimationController.value * 2 * math.pi) * 20,
                      math.cos(_floatingAnimationController.value * 2 * math.pi) * 15,
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF472B6).withValues(alpha: 0.1), // pink-400
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 150,
              left: -20,
              child: AnimatedBuilder(
                animation: _floatingAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      math.cos(_floatingAnimationController.value * 2 * math.pi) * 15,
                      math.sin(_floatingAnimationController.value * 2 * math.pi) * 10,
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFB923C).withValues(alpha: 0.1), // orange-400
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Floating hearts animation
            ...List.generate(6, (index) {
              return AnimatedBuilder(
                animation: _heartAnimationControllers[index],
                builder: (context, child) {
                  final progress = _heartAnimationControllers[index].value;
                  final screenHeight = MediaQuery.of(context).size.height;
                  final screenWidth = MediaQuery.of(context).size.width;
                  
                  return Positioned(
                    left: (screenWidth * 0.1) + (index * screenWidth * 0.15),
                    top: screenHeight - (progress * screenHeight * 1.2),
                    child: Opacity(
                      opacity: (1 - progress).clamp(0.0, 0.3),
                      child: Icon(
                        Icons.favorite,
                        color: index.isEven 
                            ? const Color(0xFFF472B6) // pink-400
                            : const Color(0xFFFB923C), // orange-400
                        size: 12 + (index * 2),
                      ),
                    ),
                  );
                },
              );
            }),
            
            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo and title section
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF472B6).withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // App icon with gradient
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF472B6), // pink-400
                                        Color(0xFFFB923C), // orange-400
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF472B6).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // App title
                                const Text(
                                  'TraceLy',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937), // gray-800
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Relationship Intelligence',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // Welcome message
                                Text(
                                  'Accedi con il tuo account Google\nper iniziare',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Google Sign-In button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4285F4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/images/google_logo.svg',
                                          width: 24,
                                          height: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Continua con Google',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Footer
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
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
                          const SizedBox(height: 16),
                          Text(
                            'Accedendo accetti i nostri Termini di Servizio\ne la Privacy Policy',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
