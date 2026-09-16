import 'package:flutter/material.dart';
import '../service/database_service.dart';

class FeedbackViewScreen extends StatefulWidget {
  const FeedbackViewScreen({super.key});

  @override
  State<FeedbackViewScreen> createState() => _FeedbackViewScreenState();
}

class _FeedbackViewScreenState extends State<FeedbackViewScreen> {
  late Future<List<Map<String, dynamic>>> _feedbackFuture;

  @override
  void initState() {
    super.initState();
    _feedbackFuture = DatabaseService().getAllFeedback();
  }

  Future<void> _refresh() async {
    setState(() {
      _feedbackFuture = DatabaseService().getAllFeedback();
    });
  }

  Color _ratingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Feedback')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _feedbackFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No feedback submitted yet.')),
                ],
              );
            }

            final feedbackList = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final entry = feedbackList[index];
                final username = entry['username'] as String? ?? 'Unknown';
                final rating = entry['rating'] as int? ?? 0;
                final comment = entry['comment'] as String? ?? '';
                final createdAt = entry['createdAt'] as String? ?? '';
                final category = entry['category'] as String?;
                final feature = entry['feature'] as String?;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  size: 18,
                                  color: _ratingColor(rating),
                                );
                              }),
                            ),
                          ],
                        ),
                        if (category != null || feature != null) ...[
                          const SizedBox(height: 6),
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
                            createdAt,
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}