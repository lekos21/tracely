import '../services/firebase_service.dart';
import '../widgets/insight_card.dart';

class CardPreloader {
  static final CardPreloader _instance = CardPreloader._internal();
  factory CardPreloader() => _instance;
  CardPreloader._internal();

  List<InsightCard> _allCards = [];
  bool _isLoadingBatch = false;
  String? _errorMessage;
  int _currentBatch = 0;
  static const int _batchSize = 8;
  bool _hasMoreCards = true;

  // Getters for the cards screen to use
  List<InsightCard> get allCards => List.unmodifiable(_allCards);
  bool get isLoadingBatch => _isLoadingBatch;
  String? get errorMessage => _errorMessage;
  bool get hasCards => _allCards.isNotEmpty;
  bool get hasMoreCards => _hasMoreCards;
  int get totalCards => _allCards.length;

  // Start preloading initial batch of cards
  Future<void> preloadCards() async {
    // Don't preload if already loading or already have cards
    if (_isLoadingBatch || hasCards) return;

    await _loadNextBatch();
  }

  // Load the next batch of cards in background
  Future<void> loadNextBatch() async {
    if (_isLoadingBatch || !_hasMoreCards) return;
    await _loadNextBatch();
  }

  // Internal method to load a batch of cards
  Future<void> _loadNextBatch() async {
    _isLoadingBatch = true;
    _errorMessage = null;

    try {
      final firebaseService = FirebaseService();
      final result = await firebaseService.generateRecommendations(
        count: _batchSize,
      );

      if (result['success']) {
        final List<dynamic> suggestions = result['suggestions'] ?? [];
        
        if (suggestions.isNotEmpty) {
          final newCards = suggestions
              .map((suggestion) => InsightCard.fromRecommendation(suggestion))
              .toList();
          
          _allCards.addAll(newCards);
          _currentBatch++;
          
          // If we got fewer cards than requested, we might have reached the end
          if (suggestions.length < _batchSize) {
            _hasMoreCards = false;
          }
          
          print('Batch ${_currentBatch} loaded: ${newCards.length} cards (Total: ${_allCards.length})');
        } else {
          if (_allCards.isEmpty) {
            _errorMessage = 'Add some facts about your partner to get personalized recommendations!';
          }
          _hasMoreCards = false;
        }
      } else {
        if (_allCards.isEmpty) {
          _errorMessage = result['message'] ?? result['error'] ?? 'Failed to load recommendations';
        }
        _hasMoreCards = false;
      }
    } catch (e) {
      if (_allCards.isEmpty) {
        _errorMessage = 'Connection error. Please check your internet connection.';
      }
      print('Error loading batch: $e');
    } finally {
      _isLoadingBatch = false;
    }
  }

  // Clear all cards (useful for refresh)
  void clearAllCards() {
    _allCards.clear();
    _errorMessage = null;
    _isLoadingBatch = false;
    _currentBatch = 0;
    _hasMoreCards = true;
  }

  // Force reload cards from beginning
  Future<void> reloadCards() async {
    clearAllCards();
    await preloadCards();
  }

  // Check if we should preload next batch based on current position
  bool shouldPreloadNext(int currentIndex) {
    // Start preloading when user reaches the 2nd card of the latest loaded batch
    // Example: with batch size 8, trigger at indices 1, 9, 17, ... as you enter each new batch
    if (!_hasMoreCards || _isLoadingBatch || _allCards.isEmpty) return false;
    // Only trigger for the most recently loaded batch to avoid duplicate triggers when multiple batches exist
    final latestBatchStart = (_currentBatch - 1) * _batchSize; // 0, 8, 16, ...
    final isSecondOfLatestBatch = currentIndex == latestBatchStart + 1;
    // Ensure we've fully loaded exactly _currentBatch batches (no partial overfetch beyond expected batch size)
    final isAlignedWithBatches = _allCards.length >= _currentBatch * _batchSize || !_hasMoreCards;
    return isSecondOfLatestBatch && isAlignedWithBatches;
  }
}
