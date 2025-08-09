import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
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
      // If clicking the same tag, deselect it and show all
      if (_selectedTagFilter == tag) {
        _selectedTagFilter = null;
        _filteredFacts = _facts;
      } else {
        _selectedTagFilter = tag;
        if (tag == null) {
          _filteredFacts = _facts;
        } else {
          _filteredFacts = _facts.where((fact) {
            final factTags = List<String>.from(fact['tags'] ?? []);
            return factTags.contains(tag);
          }).toList();
        }
      }
    });
  }
  
  // Show input overlay (modal bottom sheet) to add a new fact
  void _showAddFactSheet() {
    final rootContext = context;
    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) {
        final TextEditingController controller = TextEditingController();
        final FocusNode focusNode = FocusNode();
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              final text = controller.text.trim();
              if (text.isEmpty || isSaving) return;
              setModalState(() => isSaving = true);
              try {
                final result = await FirebaseService().saveFact(text);
                setModalState(() => isSaving = false);
                if (result['success'] == true) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(
                      content: Text('Fact saved'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  // Refresh list
                  _loadFacts();
                } else {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Failed to save fact'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                setModalState(() => isSaving = false);
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(
                    content: Text('Network error. Your fact may not have been saved.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4A4A4A).withAlpha(38),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9CA3AF).withAlpha(102),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Her favorite color is...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF), // gray-400
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Color(0xFFFBCFE8).withAlpha(128), // pink-200/50
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Color(0xFFF9A8D4), // pink-300
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Color(0xFFFBCFE8).withAlpha(128), // pink-200/50
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            suffixIcon: const Icon(
                              Icons.chat_bubble_outline,
                              color: Color(0xFF9CA3AF), // gray-400
                              size: 24,
                            ),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF374151), // gray-700
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          onSubmitted: (_) => submit(),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFFF97316)], // pink-500 to orange-500
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withAlpha(77),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isSaving ? null : submit,
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                child: Center(
                                  child: isSaving
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Remember this',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
    
    // Get current tags from the fact
    final List<String> currentTags = List<String>.from(fact['tags'] ?? []);
    final Set<String> selectedTags = Set<String>.from(currentTags);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Edit Fact',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Color(0xFF2A2A2A),
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text field
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Enter your fact...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFEC4899),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  minLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                
                // Tags section
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select tags that describe this fact:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Tag chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    final tagColor = _getTagColor(tag);
                    
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          if (isSelected) {
                            selectedTags.remove(tag);
                          } else {
                            selectedTags.add(tag);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? tagColor.withOpacity(0.2)
                            : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                              ? tagColor
                              : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: tagColor,
                              ),
                            if (isSelected) const SizedBox(width: 4),
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected 
                                  ? FontWeight.w600 
                                  : FontWeight.w500,
                                color: isSelected 
                                  ? tagColor 
                                  : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFB923C), // orange-400
                    Color(0xFFF97316), // orange-500
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    Navigator.of(context).pop({
                      'text': text,
                      'tags': selectedTags.toList(),
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        ),
      ),
    );

    if (result != null && (result['text'] != fact['fact'] || !_listEquals(result['tags'], currentTags))) {
      // Optimistic update
      final originalFact = Map<String, dynamic>.from(fact);
      final factIndex = _facts.indexWhere((f) => f['id'] == fact['id']);
      
      setState(() {
        _facts[factIndex]['fact'] = result['text'];
        _facts[factIndex]['tags'] = result['tags'];
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
        final updateResult = await firebaseService.updateFact(
          fact['id'], 
          result['text'],
          tags: result['tags'],
        );

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
            SnackBar(
              content: Text('Error updating fact: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        print('Error updating fact: $e');
      }
    }
  }

  // Helper function to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF472B6), // pink-400
              Color(0xFFEC4899), // pink-500
              Color(0xFFFB923C), // orange-400
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'addFactFab',
          onPressed: _showAddFactSheet,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
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
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A4A4A).withAlpha(15),
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
                        selectedColor: Colors.blue.withAlpha(38),
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
                          selectedColor: _getTagColor(tag).withAlpha(38),
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
                                    return Dismissible(
                                      key: Key(fact['id']),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (direction) async {
                                        // Vibrate on swipe gesture
                                        if (await Vibration.hasVibrator()) {
                                          Vibration.vibrate(duration: 50);
                                        }
                                        return await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            title: const Text(
                                              'Delete Fact',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18,
                                              ),
                                            ),
                                            content: const Text(
                                              'Are you sure you want to delete this fact? This action cannot be undone.',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(color: Colors.grey),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ) ?? false;
                                      },
                                      onDismissed: (direction) {
                                        _deleteFact(fact['id']);
                                      },
                                      background: Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        child: const Icon(
                                          Icons.delete_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onLongPress: () async {
                                          // Vibrate on long press
                                          if (await Vibration.hasVibrator()) {
                                            Vibration.vibrate(duration: 100);
                                          }
                                          _editFact(fact);
                                        },
                                        child: FactCard(
                                          fact: fact,
                                          getTagColor: _getTagColor,
                                          onEdit: () => _editFact(fact),
                                          onDelete: () => _deleteFact(fact['id']),
                                        ),
                                      ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withAlpha(20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Main content
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tags row (without date)
                        if (tags.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              ...tags.take(3).map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: getTagColor(tag).withAlpha(26),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(26),
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
                            ],
                          ),
                        SizedBox(height: tags.isNotEmpty ? 4 : 0),
                        // Fact text
                        Padding(
                          padding: const EdgeInsets.only(right: 40), // Make space for date
                          child: Text(
                            factText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2A2A2A),
                              height: 1.2,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Date positioned in top right corner
                  if (date != null)
                    Positioned(
                      top: 8,
                      right: 12,
                      child: Text(
                        '${date.day}-${monthAbbreviations[date.month - 1]}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w500,
                        ),
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
}
