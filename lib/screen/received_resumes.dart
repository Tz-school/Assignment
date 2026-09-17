import 'dart:io';
import 'package:flutter/material.dart';
import '../model/resume_model.dart';
import '../service/database_service.dart';
import 'job_seeker.dart';

class ReceivedResumesTab extends StatefulWidget {
  const ReceivedResumesTab({super.key});

  @override
  State<ReceivedResumesTab> createState() => _ReceivedResumesTabState();
}

class _ReceivedResumesTabState extends State<ReceivedResumesTab> {
  List<ResumeData> _resumes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    try {
      final list = await DatabaseService().getAllResumes();

      if (mounted) {
        setState(() {
          _resumes = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading received resumes: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _viewResume(ResumeData resume) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumeResultPage(
          data: resume,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_resumes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No job applicant resumes received yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadResumes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _resumes.length,
        itemBuilder: (context, index) {
          final resume = _resumes[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),

              leading: _buildProfileImage(resume),

              title: Text(
                resume.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${resume.gender} • Age ${resume.age}\n'
                      'Email: ${resume.email}',
                ),
              ),

              isThreeLine: true,

              trailing: ElevatedButton(
                onPressed: () => _viewResume(resume),
                child: const Text('View Resume'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImage(ResumeData resume) {
    if (resume.profileImage.path.isNotEmpty &&
        File(resume.profileImage.path).existsSync()) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: FileImage(
          resume.profileImage,
        ),
      );
    }

    return const CircleAvatar(
      radius: 28,
      child: Icon(Icons.person),
    );
  }
}

class ResumeResultPage extends StatelessWidget {
  final ResumeData data;

  const ResumeResultPage({
    super.key,
    required this.data,
  });

  Widget _resumeSection(
      String title,
      String content,
      IconData icon,
      ) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicant Resume'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  if (data.profileImage.path.isNotEmpty &&
                      File(data.profileImage.path).existsSync())
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: FileImage(
                        data.profileImage,
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: 55,
                      child: Icon(
                        Icons.person,
                        size: 55,
                      ),
                    ),

                  const SizedBox(height: 12),

                  Text(
                    data.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _infoRow(
                      'Age',
                      data.age.toString(),
                    ),

                    _infoRow(
                      'Gender',
                      data.gender,
                    ),

                    _infoRow(
                      'Email',
                      data.email,
                    ),

                    _infoRow(
                      'Phone',
                      data.phone,
                    ),

                    _infoRow(
                      'Address',
                      data.address,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            _resumeSection(
              'Professional Summary',
              data.summary,
              Icons.person_outline,
            ),

            _resumeSection(
              'Work Experience',
              data.experience,
              Icons.work_outline,
            ),


            _resumeSection(
              'Education',
              data.education,
              Icons.school_outlined,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}