import 'dart:io';
import 'package:flutter/material.dart';
import '../service/database_service.dart';
import 'feedback_submission.dart'; // reuse kFeedbackFeaturesByCategory

class FeedbackViewScreen extends StatefulWidget {
  const FeedbackViewScreen({super.key});

  @override
  State<FeedbackViewScreen> createState() => _FeedbackViewScreenState();
}

class _FeedbackViewScreenState extends State<FeedbackViewScreen> {
  List<Map<String, dynamic>> _allFeedback = [];
  bool _isLoading = true;

  String _filterCategory = 'All';
  String _filterFeature = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Loads every feedback row, then looks up each submitter's stored profile
  // (name + photoPath) so the list can show their real name and photo
  // instead of just the raw username.
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final feedbackRows = await DatabaseService().getAllFeedback();
    final enriched = await Future.wait(feedbackRows.map((row) async {
      final username = row['username'] as String? ?? 'Unknown';
      final profile = await DatabaseService().getUserProfile(username);
      final name = profile?['name'] as String?;
      return {
        ...row,
        'username': username,
        'displayName': (name != null && name.trim().isNotEmpty) ? name : username,
        'photoPath': profile?['photoPath'] as String?,
      };
    }));

    if (mounted) {
      setState(() {
        _allFeedback = enriched;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _displayedFeedback {
    return _allFeedback.where((entry) {
      final category = entry['category'] as String?;
      final feature = entry['feature'] as String?;
      if (_filterCategory != 'All' && category != _filterCategory) return false;
      if (_filterFeature != 'All' && feature != _filterFeature) return false;
      return true;
    }).toList();
  }

  bool get _isFiltering => _filterCategory != 'All' || _filterFeature != 'All';

  Future<void> _deleteFeedback(int id) async {
    await DatabaseService().deleteFeedback(id);
    if (mounted) {
      setState(() {
        _allFeedback.removeWhere((e) => e['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback deleted.')),
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteFeedback(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    // Work on temp copies so Cancel-by-swipe-down doesn't half-apply a filter.
    String tempCategory = _filterCategory;
    String tempFeature = _filterFeature;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final features = tempCategory == 'All'
                ? const <String>[]
                : kFeedbackFeaturesByCategory[tempCategory] ?? const <String>[];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Filter Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tempCategory,
                    decoration: const InputDecoration(labelText: 'Tab', border: OutlineInputBorder()),
                    items: ['All', ...kFeedbackFeaturesByCategory.keys]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setSheetState(() {
                        tempCategory = val!;
                        tempFeature = 'All'; // Reset - old feature may not belong to the new tab
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tempFeature,
                    decoration: const InputDecoration(labelText: 'Feature', border: OutlineInputBorder()),
                    items: ['All', ...features]
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: tempCategory == 'All'
                        ? null
                        : (val) => setSheetState(() => tempFeature = val!),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              tempCategory = 'All';
                              tempFeature = 'All';
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _filterCategory = tempCategory;
                              _filterFeature = tempFeature;
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Feedback'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: _isFiltering ? Colors.amber : null),
            tooltip: 'Filter',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isFiltering)
            Container(
              width: double.infinity,
              color: Colors.indigo.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtering: ${_filterCategory == 'All' ? 'All tabs' : _filterCategory}'
                          '${_filterFeature == 'All' ? '' : ' • $_filterFeature'}',
                      style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _filterCategory = 'All';
                      _filterFeature = 'All';
                    }),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadData,
              child: _displayedFeedback.isEmpty
                  ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      _isFiltering
                          ? 'No feedback matches this filter.'
                          : 'No feedback submitted yet.',
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _displayedFeedback.length,
                itemBuilder: (context, index) {
                  final entry = _displayedFeedback[index];
                  return _FeedbackCard(
                    key: ValueKey(entry['id']),
                    entry: entry,
                    onDelete: () => _confirmDelete(entry['id'] as int),
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

// Converts the stored ISO-8601 timestamp (e.g. "2026-09-16T17:43:42.167286")
// into a readable "16 Sep 2026, 5:43 PM" style string.
String _formatDateTime(String iso) {
  try {
    final dt = DateTime.parse(iso);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour12:$minute $period';
  } catch (_) {
    return iso; // Fall back to the raw string if it can't be parsed
  }
}

// A feedback card that slides left on tap to reveal a delete button behind
// it. Tapping the card again (or the delete button) closes/handles it.
class _FeedbackCard extends StatefulWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onDelete;

  const _FeedbackCard({super.key, required this.entry, required this.onDelete});

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  bool _isRevealed = false;
  static const double _revealWidth = 84;

  Color _ratingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final displayName = entry['displayName'] as String? ?? 'Unknown';
    final photoPath = entry['photoPath'] as String?;
    final rating = entry['rating'] as int? ?? 0;
    final comment = entry['comment'] as String? ?? '';
    final createdAt = entry['createdAt'] as String? ?? '';
    final category = entry['category'] as String?;
    final feature = entry['feature'] as String?;

    final hasPhoto = photoPath != null && File(photoPath).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Stack(
        children: [
          // Delete button revealed behind the card once slid open.
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: _revealWidth,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  tooltip: 'Delete',
                  onPressed: widget.onDelete,
                ),
              ),
            ),
          ),
          // Foreground card - slides left on tap to reveal the button above.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_isRevealed ? -_revealWidth : 0, 0, 0),
            child: GestureDetector(
              onTap: () => setState(() => _isRevealed = !_isRevealed),
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.indigo.shade100,
                            backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
                            child: hasPhoto
                                ? null
                                : Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                size: 16,
                                color: _ratingColor(rating),
                              );
                            }),
                          ),
                        ],
                      ),
                      if (category != null || feature != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            [category, feature].where((s) => s != null && s.isNotEmpty).join(' • '),
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (createdAt.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatDateTime(createdAt),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        comment.isEmpty ? 'No comment provided.' : comment,
                        style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}