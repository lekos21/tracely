import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class FactsScreen extends StatefulWidget {
  const FactsScreen({super.key});

  @override
  State<FactsScreen> createState() => _FactsScreenState();
}

class _FactsScreenState extends State<FactsScreen> {
  List<Map<String, dynamic>> _facts = [];
  List<Map<String, dynamic>> _filteredFacts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedTagFilter;
  
  final List<String> _availableTags = [
    'people', 'dislikes', 'gifts', 'activities', 'dates', 'food', 'history'
  ];

  @override
  void initState() {
    super.initState();
    _loadFacts();
  }

  Future<void> _loadFacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firebaseService = FirebaseService();
      final result = await firebaseService.getUserFacts();

      if (result['success']) {
        final facts = List<Map<String, dynamic>>.from(result['facts'] ?? []);
        setState(() {
          _facts = facts;
          _filteredFacts = facts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] ?? 'Failed to load facts';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error. Please check your internet connection.';
      });
      print('Error loading facts: $e');
    }
  }

  void _filterByTag(String? tag) {
    setState(() {
      _selectedTagFilter = tag;
      if (tag == null) {
        _filteredFacts = _facts;
      } else {
        _filteredFacts = _facts.where((fact) {
          final factTags = List<String>.from(fact['tags'] ?? []);
          return factTags.contains(tag);
        }).toList();
      }
    });
  }

  Future<void> _deleteFact(String factId) async {
    try {
      final firebaseService = FirebaseService();
      final result = await firebaseService.deleteFact(factId);

      if (result['success']) {
        setState(() {
          _facts.removeWhere((fact) => fact['id'] == factId);
          _filterByTag(_selectedTagFilter); // Reapply current filter
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fact deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting fact: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error while deleting fact'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error deleting fact: $e');
    }
  }

  Future<void> _editFact(Map<String, dynamic> fact) async {
    final TextEditingController controller = TextEditingController(
      text: fact['fact'] ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Fact'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter fact...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != fact['fact']) {
      try {
        final firebaseService = FirebaseService();
        final updateResult = await firebaseService.updateFact(
          fact['id'],
          result,
        );

        if (updateResult['success']) {
          setState(() {
            final index = _facts.indexWhere((f) => f['id'] == fact['id']);
            if (index != -1) {
              _facts[index]['fact'] = result;
              _filterByTag(_selectedTagFilter); // Reapply current filter
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fact updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating fact: ${updateResult['error']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection error while updating fact'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('Error updating fact: $e');
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Facts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            onPressed: _loadFacts,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Facts',
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tag filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 0.5),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All', style: TextStyle(fontSize: 13)),
                    selected: _selectedTagFilter == null,
                    onSelected: (_) => _filterByTag(null),
                    selectedColor: Colors.blue.withOpacity(0.15),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide.none,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const SizedBox(width: 8),
                  ..._availableTags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tag, style: const TextStyle(fontSize: 13)),
                      selected: _selectedTagFilter == tag,
                      onSelected: (_) => _filterByTag(tag),
                      selectedColor: _getTagColor(tag).withOpacity(0.15),
                      backgroundColor: Colors.grey[100],
                      checkmarkColor: _getTagColor(tag),
                      side: BorderSide.none,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  )),
                ],
              ),
            ),
          ),
          // Facts list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading facts...',
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
                              onPressed: _loadFacts,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : _filteredFacts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedTagFilter == null
                                      ? 'No facts yet!'
                                      : 'No facts with tag "$_selectedTagFilter"',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Add some facts through the chat to see them here.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFacts,
                            color: Colors.blue,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              itemCount: _filteredFacts.length,
                              itemBuilder: (context, index) {
                                final fact = _filteredFacts[index];
                                return FactCard(
                                  fact: fact,
                                  getTagColor: _getTagColor,
                                  onEdit: () => _editFact(fact),
                                  onDelete: () => _deleteFact(fact['id']),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class FactCard extends StatelessWidget {
  final Map<String, dynamic> fact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color Function(String) getTagColor;

  const FactCard({
    super.key,
    required this.fact,
    required this.onEdit,
    required this.onDelete,
    required this.getTagColor,
  });

  @override
  Widget build(BuildContext context) {
    final factText = fact['fact'] ?? '';
    final tags = List<String>.from(fact['tags'] ?? []);
    final sentiment = fact['sentiment'] ?? 'neutral';
    final date = fact['date'] != null 
        ? DateTime.tryParse(fact['date'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with sentiment, date and actions
            Row(
              children: [
                // Sentiment indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getSentimentColor(sentiment).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sentiment,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getSentimentColor(sentiment),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Date
                if (date != null)
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const Spacer(),
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, size: 18, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fact text
            Text(
              factText,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),
            // Tags
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: getTagColor(tag).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      color: getTagColor(tag),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
      default:
        return Colors.grey;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fact'),
        content: const Text('Are you sure you want to delete this fact? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
