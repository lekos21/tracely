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
