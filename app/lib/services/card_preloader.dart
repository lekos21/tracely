import '../services/firebase_service.dart';
import '../widgets/insight_card.dart';

class CardPreloader {
  static final CardPreloader _instance = CardPreloader._internal();
  factory CardPreloader() => _instance;
  CardPreloader._internal();

  List<InsightCard>? _preloadedCards;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters for the cards screen to use
  List<InsightCard>? get preloadedCards => _preloadedCards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPreloadedCards => _preloadedCards != null && _preloadedCards!.isNotEmpty;

  // Start preloading cards in the background
  Future<void> preloadCards() async {
    // Don't preload if already loading or already have cards
    if (_isLoading || hasPreloadedCards) return;

    _isLoading = true;
    _errorMessage = null;

    try {
      final firebaseService = FirebaseService();
      final result = await firebaseService.generateRecommendations(
        count: 8,
      );

      if (result['success']) {
        final List<dynamic> suggestions = result['suggestions'] ?? [];
        
        if (suggestions.isNotEmpty) {
          _preloadedCards = suggestions
              .map((suggestion) => InsightCard.fromRecommendation(suggestion))
              .toList();
          print('Cards preloaded successfully: ${_preloadedCards!.length} cards');
        } else {
          _errorMessage = 'Add some facts about your partner to get personalized recommendations!';
        }
      } else {
        _errorMessage = result['message'] ?? result['error'] ?? 'Failed to load recommendations';
      }
    } catch (e) {
      _errorMessage = 'Connection error. Please check your internet connection.';
      print('Error preloading cards: $e');
    } finally {
      _isLoading = false;
    }
  }

  // Clear preloaded cards (useful for refresh)
  void clearPreloadedCards() {
    _preloadedCards = null;
    _errorMessage = null;
    _isLoading = false;
  }

  // Force reload cards
  Future<void> reloadCards() async {
    clearPreloadedCards();
    await preloadCards();
  }
}
