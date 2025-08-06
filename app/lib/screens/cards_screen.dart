import 'package:flutter/material.dart';
import '../services/card_preloader.dart';
import '../widgets/insight_card.dart';
import '../widgets/draggable_card.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> with TickerProviderStateMixin {
  List<InsightCard> _cards = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _loadingAnimationController;
  late AnimationController _textAnimationController;
  int _currentPhraseIndex = 0;
  final CardPreloader _cardPreloader = CardPreloader();
  
  final List<String> _loadingPhrases = [
    "Crafting personalized suggestions...",
    "Finding the perfect ideas for you...",
    "Discovering unique experiences...",
    "Almost ready!"
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize animation controllers
    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Start phrase cycling
    _startPhraseAnimation();
    _loadRecommendations();
    
    // Listen for page changes to trigger background loading
    _pageController.addListener(_onPageChanged);
  }
  
  void _startPhraseAnimation() {
    _textAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _isLoading) {
          _textAnimationController.reverse().then((_) {
            if (mounted && _isLoading) {
              setState(() {
                _currentPhraseIndex = (_currentPhraseIndex + 1) % _loadingPhrases.length;
              });
              _startPhraseAnimation();
            }
          });
        }
      });
    });
  }

  void _onPageChanged() {
    if (!_pageController.hasClients) return;
    
    final newIndex = _pageController.page?.round() ?? 0;
    if (newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
      
      // Check if we should preload next batch
      if (_cardPreloader.shouldPreloadNext(_currentIndex)) {
        _loadNextBatchInBackground();
      }
    }
  }
  
  void _loadNextBatchInBackground() async {
    await _cardPreloader.loadNextBatch();
    
    // Update UI with new cards if any were loaded
    if (mounted && _cardPreloader.allCards.length > _cards.length) {
      setState(() {
        _cards = _cardPreloader.allCards;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _loadingAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
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
              top: 100,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF472B6).withValues(alpha: 0.1), // pink-400
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFB923C).withValues(alpha: 0.1), // orange-400
                ),
              ),
            ),
            
            // Main content
            SafeArea(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated loading circles
                          AnimatedBuilder(
                            animation: _loadingAnimationController,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer rotating circle
                                  Transform.rotate(
                                    angle: _loadingAnimationController.value * 2 * 3.14159,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFF472B6).withOpacity(0.3),
                                          width: 3,
                                        ),
                                      ),
                                      child: const Align(
                                        alignment: Alignment.topCenter,
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.favorite,
                                            color: Color(0xFFF472B6),
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Inner pulsing circle
                                  Transform.scale(
                                    scale: 0.7 + (0.3 * (1 + (_loadingAnimationController.value * 2 - 1).abs()) / 2),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFF472B6).withOpacity(0.6),
                                            const Color(0xFFFB923C).withOpacity(0.6),
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          // Animated text
                          AnimatedBuilder(
                            animation: _textAnimationController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textAnimationController.value,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - _textAnimationController.value)),
                                  child: Text(
                                    _loadingPhrases[_currentPhraseIndex],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B7280),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Progress dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: index <= _currentPhraseIndex ? 8 : 6,
                                height: index <= _currentPhraseIndex ? 8 : 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index <= _currentPhraseIndex
                                      ? const Color(0xFFF472B6)
                                      : const Color(0xFFF472B6).withOpacity(0.3),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadRecommendations,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF472B6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : _cards.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.favorite_border,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No cards available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pull down to refresh',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                           : Column(
                              children: [
                                // Vertical PageView
                                Expanded(
                                  child: PageView.builder(
                                    controller: _pageController,
                                    scrollDirection: Axis.vertical,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentIndex = index;
                                      });
                                    },
                                    itemCount: _cards.length,
                                    itemBuilder: (context, index) {
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16,
                                          ),
                                          child: DraggableCard(
                                            card: _cards[index],
                                            isInteractive: false,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                
                                // Navigation hint
                                if (_cards.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      children: [
                                        if (_currentIndex < _cards.length - 1)
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.grey[400],
                                            size: 24,
                                          ),
                                        Text(
                                          _currentIndex < _cards.length - 1
                                              ? 'Swipe up for next card'
                                              : 'End of cards',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        if (_currentIndex > 0)
                                          Icon(
                                            Icons.keyboard_arrow_up,
                                            color: Colors.grey[400],
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadRecommendations() async {
    // Check if we have cards already loaded
    if (_cardPreloader.hasCards) {
      // Use existing cards for instant loading
      setState(() {
        _cards = _cardPreloader.allCards;
        _isLoading = false;
        _errorMessage = null;
      });
      
      debugPrint('Using existing cards: ${_cards.length} cards');
      return;
    }
    
    // If preloader is still loading, show loading state but don't start new request
    if (_cardPreloader.isLoadingBatch) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Wait for preloader to finish and try again
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadRecommendations();
      });
      return;
    }
    
    // If preloader has an error, show it
    if (_cardPreloader.errorMessage != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = _cardPreloader.errorMessage;
      });
      return;
    }
    
    // If no cards and not loading, trigger initial load
    if (!_cardPreloader.hasCards && !_cardPreloader.isLoadingBatch) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      await _cardPreloader.preloadCards();
      
      // Check result after loading
      if (_cardPreloader.hasCards) {
        setState(() {
          _cards = _cardPreloader.allCards;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = _cardPreloader.errorMessage ?? 'Failed to load cards';
        });
      }
    }
  }
}
