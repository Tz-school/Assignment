import 'package:flutter/material.dart';
import '../service/database_service.dart';

/// Category -> list of features, used to populate the two dependent
/// dropdowns. The first dropdown picks a tab of the app; the second is
/// filtered down to just that tab's features.
const Map<String, List<String>> kFeedbackFeaturesByCategory = {
  'Data Analysis': [
    'Wage by State & Sector',
    'GDP by State',
    'State Feasibility Matcher',
    'Saved Comparisons',
  ],
  'Booking': [
    'Events & Workshops',
    'Mock Interview & Advisory',
  ],
  'Industry': [
    'Resume Builder',
    'Job Seeker',
  ],
  'Career Planner': [
    'Suitability Quiz',
    'Course Simulator',
    'Career Roadmap',
    'Goal Tracker',
    'What-If Simulator',
    'Career Score',
    'Data Manager',
    'Skills Builder',
    'Interview Practice',
  ],
};

class FeedbackScreen extends StatefulWidget {
  final String username;
  const FeedbackScreen({super.key, required this.username});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  int _rating = 0; // 0 means "not selected yet"
  String? _selectedCategory;
  String? _selectedFeature;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tab.')),
      );
      return;
    }
    if (_selectedFeature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a feature.')),
      );
      return;
    }
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write some feedback before submitting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await DatabaseService().insertFeedback(
      widget.username,
      _rating,
      _feedbackController.text.trim(),
      category: _selectedCategory!,
      feature: _selectedFeature!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your feedback!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          iconSize: 36,
          onPressed: () => setState(() => _rating = starValue),
          icon: Icon(
            starValue <= _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final features = _selectedCategory != null
        ? kFeedbackFeaturesByCategory[_selectedCategory!]!
        : <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const Text(
              'How would you rate your experience?',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStarRating(),
            const SizedBox(height: 24),

            const Text(
              'Which part of the app is this about?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 1. Tab selection
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Tab',
                border: OutlineInputBorder(),
              ),
              items: kFeedbackFeaturesByCategory.keys
                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                  _selectedFeature = null; // Reset - old feature may not belong to the new tab
                });
              },
            ),
            const SizedBox(height: 16),

            // 2. Feature selection - only enabled once a tab is picked
            DropdownButtonFormField<String>(
              value: _selectedFeature,
              decoration: InputDecoration(
                labelText: 'Feature',
                border: const OutlineInputBorder(),
                hintText: _selectedCategory == null ? 'Select a tab first' : null,
              ),
              items: features
                  .map((feature) => DropdownMenuItem(value: feature, child: Text(feature)))
                  .toList(),
              onChanged: _selectedCategory == null
                  ? null
                  : (val) => setState(() => _selectedFeature = val),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your feedback',
                hintText: 'Tell us what you think...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSubmitting ? null : _submitFeedback,
              child: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}