class InsightCard {
  final String type;
  final String title;
  final String content;
  final String icon;
  final List<String> tags;
  final int effort;

  InsightCard({
    required this.type,
    required this.title,
    required this.content,
    required this.icon,
    this.tags = const [],
    this.effort = 1,
  });

  factory InsightCard.fromRecommendation(Map<String, dynamic> suggestion) {
    // Normalize tags to List<String>
    List<String> tags = const [];
    final dynamic rawTags = suggestion['tags'];
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    } else if (rawTags is String && rawTags.trim().isNotEmpty) {
      // Support comma-separated string as a fallback
      tags = rawTags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    // Normalize content field across possible keys
    final String content = (suggestion['sentence'] ??
            suggestion['text'] ??
            suggestion['content'] ??
            suggestion['suggestion'] ??
            '')
        .toString();

    // Extract effort score (default to 1 if not provided)
    final int effort = (suggestion['effort'] is int) 
        ? suggestion['effort'] as int
        : 1;

    return InsightCard(
      type: _getTypeFromTags(tags),
      title: _getTitleFromTags(tags),
      content: content,
      icon: _getIconFromTags(tags),
      tags: tags,
      effort: effort,
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
    if (tags.contains('dates')) return '🌸';
    if (tags.contains('activities')) return '🎯';
    if (tags.contains('food')) return '🍽️';
    if (tags.contains('people')) return '👥';
    if (tags.contains('dislikes')) return '⚠️';
    if (tags.contains('history')) return '📚';
    return '💡';
  }
}
