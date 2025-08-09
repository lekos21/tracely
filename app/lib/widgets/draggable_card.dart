import 'package:flutter/material.dart';
import 'insight_card.dart';

class DraggableCard extends StatelessWidget {
  final InsightCard card;
  final bool isInteractive;
  final Offset dragOffset;
  final bool isBackground;
  final double parallax;

  const DraggableCard({
    super.key,
    required this.card,
    this.isInteractive = true,
    this.dragOffset = Offset.zero,
    this.isBackground = false,
    this.parallax = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate overlay color based on drag distance for visual feedback
    Color? overlayColor;
    
    // Parallax intensity (clamped)
    final double p = parallax.clamp(-1.0, 1.0).toDouble();
    
    if (isInteractive && dragOffset.dx.abs() > 50) {
      if (dragOffset.dx > 0) {
        overlayColor = Colors.green.withAlpha(77);
      } else {
        overlayColor = Colors.red.withAlpha(77);
      }
    }

    return GestureDetector(
      onLongPress: () {
        // Vibration removed - kept only on Facts page
      },
      onTap: () {
        // Vibration removed - kept only on Facts page
      },
      child: Container(
      width: 300,
      constraints: const BoxConstraints(
        minHeight: 280,
        maxHeight: 380,
      ),
      decoration: BoxDecoration(
        color: isBackground ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A4A4A).withAlpha(isBackground ? 13 : 26),
            blurRadius: isBackground ? 5 : 10,
            offset: Offset(0, isBackground ? 2 : 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Transform.translate(
                  offset: Offset(0, -12 * p),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Center(
                      child: Text(
                        card.icon,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                Transform.translate(
                  offset: Offset(0, -8 * p),
                  child: Text(
                    card.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                // Content
                Transform.translate(
                  offset: Offset(0, -4 * p),
                  child: Text(
                    card.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Tag badges
                if (card.tags.isNotEmpty && card.tags.length <= 3) ...[
                  const SizedBox(height: 10),
                  Transform.translate(
                    offset: Offset(0, -2 * p),
                    child: Wrap(
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
                            fontSize: 11,
                            color: _getTagColor(tag),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Effort score indicator (top right)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getEffortColor(card.effort).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getEffortColor(card.effort).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getEffortIcon(card.effort),
                    size: 14,
                    color: _getEffortColor(card.effort),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${card.effort}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getEffortColor(card.effort),
                    ),
                  ),
                ],
              ),
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
    ),
    );
  }

  // Helper methods for effort score styling
  Color _getEffortColor(int effort) {
    switch (effort) {
      case 1:
        return const Color(0xFF10B981); // green-500 - easy
      case 2:
        return const Color(0xFFF59E0B); // amber-500 - moderate
      case 3:
        return const Color(0xFFEF4444); // red-500 - high effort
      default:
        return const Color(0xFF6B7280); // gray-500 - fallback
    }
  }

  IconData _getEffortIcon(int effort) {
    return Icons.bolt; // Single bolt icon for all effort levels
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'people':
        return Colors.blue;
      case 'dislikes':
        return Colors.red;
      case 'gifts':
        return Colors.purple;
      case 'activities':
        return Colors.orange;
      case 'dates':
        return Colors.pink;
      case 'food':
        return Colors.green;
      case 'history':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
