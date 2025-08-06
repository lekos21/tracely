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
        // Fix type casting issue for mobile
        final factsRaw = result['facts'] ?? [];
        final facts = (factsRaw as List).map((fact) => 
          Map<String, dynamic>.from(fact as Map)
        ).toList();
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
        _errorMessage = 'Error: $e'; // Show actual error instead of generic message
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
    // Store the fact for potential restoration
    final factToDelete = _facts.firstWhere((fact) => fact['id'] == factId);
    final originalIndex = _facts.indexWhere((fact) => fact['id'] == factId);
    
    // Optimistic update - immediately remove from UI
    setState(() {
      _facts.removeWhere((fact) => fact['id'] == factId);
      _filterByTag(_selectedTagFilter); // Reapply current filter
    });

    // Show immediate success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fact deleted'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }

    // Sync with backend in background
    try {
      final firebaseService = FirebaseService();
      final result = await firebaseService.deleteFact(factId);

      if (!result['success']) {
        // Revert optimistic update on failure
        setState(() {
          _facts.insert(originalIndex, factToDelete);
          _filterByTag(_selectedTagFilter);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete fact: ${result['error']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _facts.insert(originalIndex, factToDelete);
        _filterByTag(_selectedTagFilter);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error - deletion reverted'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Edit Fact'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your fact...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(context).pop(text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != fact['fact']) {
      // Optimistic update
      final originalFact = Map<String, dynamic>.from(fact);
      final factIndex = _facts.indexWhere((f) => f['id'] == fact['id']);
      
      setState(() {
        _facts[factIndex]['fact'] = result;
        _filterByTag(_selectedTagFilter);
      });

      // Show immediate success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fact updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Sync with backend
      try {
        final firebaseService = FirebaseService();
        final updateResult = await firebaseService.updateFact(fact['id'], result);

        if (!updateResult['success']) {
          // Revert on failure
          setState(() {
            _facts[factIndex] = originalFact;
            _filterByTag(_selectedTagFilter);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update fact: ${updateResult['error']}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        // Revert on error
        setState(() {
          _facts[factIndex] = originalFact;
          _filterByTag(_selectedTagFilter);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection error - update reverted'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        print('Error updating fact: $e');
      }
    }
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
        child: SafeArea(
          child: Column(
            children: [
              // Tag filter chips
              Container(
                margin: const EdgeInsets.only(left: 20, right: 20, top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A4A4A).withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
              const SizedBox(height: 16),
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
                                    const Text(
                                      'No facts yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
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
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
        ),
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

    // Month abbreviations in Italian
    const monthAbbreviations = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic'
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left side: full-height sentiment indicator
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _getSentimentColor(sentiment),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
            ),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tags and date row (above the fact)
                    Row(
                      children: [
                        // Tags
                        if (tags.isNotEmpty) ...
                          tags.take(3).map((tag) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: getTagColor(tag).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                color: getTagColor(tag),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )).toList(),
                        if (tags.length > 3)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+${tags.length - 3}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        // Date in Italian format (9-lug)
                        if (date != null)
                          Text(
                            '${date.day}-${monthAbbreviations[date.month - 1]}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF999999),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Fact text
                    Text(
                      factText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF2A2A2A),
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right side: actions
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 4),
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Color(0xFFBBBBBB),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
            ),
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
