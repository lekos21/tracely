import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

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
  late AnimationController _successAnimationController;
  late Animation<double> _successAnimation;

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
  }

  @override
  void dispose() {
    _factController.dispose();
    _focusNode.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  Future<void> _submitFact() async {
    if (_factController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _showSuccess = false;
    });

    try {
      final result = await FirebaseService().saveFact(_factController.text.trim());
      
      if (result['success'] == true) {
        _factController.clear();
        _focusNode.unfocus();
        
        setState(() {
          _showSuccess = true;
        });
        
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
      } else {
        _showError(result['message'] ?? 'Failed to save fact');
      }
    } catch (e) {
      _showError('Error saving fact: $e');
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TraceLy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Header Section
            const Icon(
              Icons.favorite,
              size: 80,
              color: Color(0xFF6B73FF),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to TraceLy',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your Relationship Intelligence Assistant',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Quick Fact Input Section
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Quick Fact',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share something about your partner or relationship',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Input Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: _focusNode.hasFocus 
                            ? const Color(0xFF6B73FF)
                            : Colors.grey.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _factController,
                          focusNode: _focusNode,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'e.g., She loves chocolate ice cream on rainy days...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                          ),
                          onChanged: (value) {
                            setState(() {}); // Rebuild to update button state
                          },
                          onSubmitted: (_) => _submitFact(),
                        ),
                        
                        // Submit Button
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton(
                            onPressed: _factController.text.trim().isEmpty || _isLoading
                                ? null
                                : _submitFact,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B73FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Fact',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Success Animation
            if (_showSuccess)
              AnimatedBuilder(
                animation: _successAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _successAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Fact saved successfully!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 48),
            
            // Features Preview
            const Text(
              '🚀 More Features:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '💬 AI Chat Assistant\n🎴 Swipeable Insight Cards\n📝 Relationship Onboarding',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
