import 'package:flutter/material.dart';
import 'insight_card.dart';

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
    // Calculate overlay color based on drag distance for visual feedback
    Color? overlayColor;
    
    if (isInteractive && dragOffset.dx.abs() > 50) {
      if (dragOffset.dx > 0) {
        overlayColor = Colors.green.withValues(alpha: 0.3);
      } else {
        overlayColor = Colors.red.withValues(alpha: 0.3);
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
            color: const Color(0xFF4A4A4A).withValues(alpha: isBackground ? 0.05 : 0.1),
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
                    color: _getCardColor(card.type).withValues(alpha: 0.1),
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
                    color: Color(0xFF2A2A2A),
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
                        color: _getTagColor(tag).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getTagColor(tag).withValues(alpha: 0.3),
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
