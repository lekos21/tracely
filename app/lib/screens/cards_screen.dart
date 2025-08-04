import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

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
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Load AI-generated recommendations on startup
    _loadRecommendations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cards',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: _refreshCards,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Cards',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Generating personalized recommendations...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRecommendations,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _currentIndex >= _cards.length
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'All cards reviewed!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pull to refresh for new suggestions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Drag cards left or right to review',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background cards (next cards) - only show if different from current
                          for (int i = _currentIndex + 1; i < _currentIndex + 3 && i < _cards.length; i++)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: (i - _currentIndex) * 8.0, // Slight vertical offset
                              child: Center(
                                child: Transform.scale(
                                  scale: 1.0 - (i - _currentIndex) * 0.05, // More noticeable scaling
                                  child: Opacity(
                                    opacity: 1.0 - (i - _currentIndex) * 0.3, // Fade background cards
                                    child: DraggableCard(
                                      card: _cards[i],
                                      isInteractive: false,
                                      isBackground: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Current card (draggable) - always on top
                          if (_currentIndex < _cards.length)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              child: Center(
                                child: GestureDetector(
                                  onPanStart: (details) {
                                    setState(() {
                                      _isDragging = true;
                                    });
                                  },
                                  onPanUpdate: (details) {
                                    setState(() {
                                      _dragOffset += details.delta;
                                    });
                                  },
                                  onPanEnd: (details) {
                                    _handlePanEnd();
                                  },
                                  child: Transform.translate(
                                    offset: _dragOffset,
                                    child: Transform.rotate(
                                      angle: _dragOffset.dx * 0.001, // Slight rotation during drag
                                      child: DraggableCard(
                                        card: _cards[_currentIndex],
                                        isInteractive: true,
                                        dragOffset: _dragOffset,
                                        isBackground: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: 'reject',
                        onPressed: () => _rejectCard(),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                      FloatingActionButton(
                        heroTag: 'accept',
                        onPressed: () => _acceptCard(),
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.favorite, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_currentIndex + 1} / ${_cards.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade400,
                        ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  void _handlePanEnd() {
    const threshold = 100.0;
    
    if (_dragOffset.dx.abs() > threshold) {
      // Card was dragged far enough
      if (_dragOffset.dx > 0) {
        _acceptCard();
      } else {
        _rejectCard();
      }
    } else {
      // Snap back to center
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
    }
  }

  void _acceptCard() {
    print('Card accepted: ${_cards[_currentIndex].title}');
    _nextCard();
  }

  void _rejectCard() {
    print('Card rejected: ${_cards[_currentIndex].title}');
    _nextCard();
  }

  void _nextCard() {
    setState(() {
      _currentIndex++;
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }

  void _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final firebaseService = FirebaseService();
      final result = await firebaseService.generateRecommendations(
        count: 5,
      );
      
      if (result['success']) {
        final List<dynamic> suggestions = result['suggestions'] ?? [];
        
        if (suggestions.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Add some facts about your partner to get personalized recommendations!';
          });
          return;
        }
        
        setState(() {
          _cards = suggestions
              .map((suggestion) => InsightCard.fromRecommendation(suggestion))
              .toList();
          _currentIndex = 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? result['error'] ?? 'Failed to load recommendations';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error. Please check your internet connection.';
      });
      print('Error loading recommendations: $e');
    }
  }
  
  void _refreshCards() async {
    _loadRecommendations();
  }
}

class DraggableCard extends StatelessWidget {
  final InsightCard card;
  final bool isInteractive;
  final Offset dragOffset;
  final bool isBackground;

  const DraggableCard({
    super.key,
    required this.card,
    this.isInteractive = true,
    this.dragOffset = Offset.zero,
    this.isBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate opacity based on drag distance for visual feedback
    double opacity = 1.0;
    Color? overlayColor;
    
    if (isInteractive && dragOffset.dx.abs() > 50) {
      opacity = 0.8;
      if (dragOffset.dx > 0) {
        overlayColor = Colors.green.withOpacity(0.3);
      } else {
        overlayColor = Colors.red.withOpacity(0.3);
      }
    }

    return Container(
      width: 300,
      constraints: const BoxConstraints(
        minHeight: 300,
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        color: isBackground ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isBackground ? 0.05 : 0.1),
            blurRadius: isBackground ? 5 : 10,
            offset: Offset(0, isBackground ? 2 : 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getCardColor(card.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: Text(
                      card.icon,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getCardColor(card.type),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Content
                Text(
                  card.content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Tag badges
                if (card.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: card.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTagColor(tag).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getTagColor(tag).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTagColor(tag),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          // Overlay for drag feedback
          if (overlayColor != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: overlayColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    dragOffset.dx > 0 ? Icons.favorite : Icons.close,
                    size: 60,
                    color: dragOffset.dx > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCardColor(String type) {
    switch (type) {
      case 'gift':
        return Colors.purple;
      case 'date':
        return Colors.pink;
      case 'insight':
        return Colors.blue;
      case 'activity':
        return Colors.orange;
      case 'food':
        return Colors.green;
      case 'people':
        return Colors.indigo;
      case 'warning':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'gifts':
        return Colors.purple;
      case 'dates':
        return Colors.pink;
      case 'activities':
        return Colors.orange;
      case 'food':
        return Colors.green;
      case 'people':
        return Colors.indigo;
      case 'dislikes':
        return Colors.red;
      case 'history':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

class InsightCard {
  final String type;
  final String title;
  final String content;
  final String icon;
  final List<String> tags;

  InsightCard({
    required this.type,
    required this.title,
    required this.content,
    required this.icon,
    this.tags = const [],
  });

  factory InsightCard.fromRecommendation(Map<String, dynamic> suggestion) {
    final tags = List<String>.from(suggestion['tags'] ?? []);
    return InsightCard(
      type: _getTypeFromTags(tags),
      title: _getTitleFromTags(tags),
      content: suggestion['sentence'] ?? '',
      icon: _getIconFromTags(tags),
      tags: tags,
    );
  }

  static String _getTypeFromTags(List<String> tags) {
    if (tags.contains('gifts')) return 'gift';
    if (tags.contains('dates')) return 'date';
    if (tags.contains('activities')) return 'activity';
    if (tags.contains('food')) return 'food';
    if (tags.contains('people')) return 'people';
    if (tags.contains('dislikes')) return 'warning';
    return 'insight';
  }

  static String _getTitleFromTags(List<String> tags) {
    if (tags.contains('gifts')) return 'Gift Idea';
    if (tags.contains('dates')) return 'Date Suggestion';
    if (tags.contains('activities')) return 'Activity Idea';
    if (tags.contains('food')) return 'Food Suggestion';
    if (tags.contains('people')) return 'People Insight';
    if (tags.contains('dislikes')) return 'Important Note';
    if (tags.contains('history')) return 'Background Info';
    return 'Relationship Tip';
  }

  static String _getIconFromTags(List<String> tags) {
    if (tags.contains('gifts')) return '🎁';
    if (tags.contains('dates')) return '💕';
    if (tags.contains('activities')) return '🎯';
    if (tags.contains('food')) return '🍽️';
    if (tags.contains('people')) return '👥';
    if (tags.contains('dislikes')) return '⚠️';
    if (tags.contains('history')) return '📚';
    return '💡';
  }
}


