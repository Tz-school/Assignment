import 'package:flutter/material.dart';

class JobSeekerTab extends StatefulWidget {
  const JobSeekerTab({super.key});

  @override
  State<JobSeekerTab> createState() => _JobSeekerTabState();
}

class _JobSeekerTabState extends State<JobSeekerTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Job Seeker Content',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}