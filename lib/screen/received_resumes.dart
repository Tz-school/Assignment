import 'dart:io';
import 'package:flutter/material.dart';
import '../model/resume_model.dart';
import '../service/database_service.dart';
import 'chat_screen.dart';

class ReceivedResumesTab extends StatefulWidget {


  final String currentUsername;

  const ReceivedResumesTab({
    super.key,
    required this.currentUsername,
  });

  @override
  State<ReceivedResumesTab> createState() =>
      _ReceivedResumesTabState();
}

class _ReceivedResumesTabState
    extends State<ReceivedResumesTab> {
  final DatabaseService _databaseService =
  DatabaseService();

  List<Map<String, dynamic>> _applications = [];

  bool _isLoading = true;

  int? _selectedPosterId;

  @override
  void initState() {
    super.initState();
    _loadAllApplications();
  }

  Future<void> _loadAllApplications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final applications =
      await _databaseService.getAllApplications();

      if (!mounted) return;

      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Error loading applications: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load applications: $e',
          ),
        ),
      );
    }
  }

  Future<void> _filterByPoster(
      int? posterId,
      ) async {
    setState(() {
      _selectedPosterId = posterId;
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>>
      applications;

      if (posterId == null) {
        applications =
        await _databaseService
            .getAllApplications();
      } else {
        applications =
        await _databaseService
            .getApplicationsByHiringPoster(
          posterId,
        );
      }

      if (!mounted) return;

      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Error filtering applications: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to filter applications: $e',
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>>
  _getUniquePosters() {
    final Map<int, Map<String, dynamic>>
    posters = {};

    for (final application in _applications) {
      final posterId =
      application['hiringPosterId'];

      if (posterId != null) {
        posters[posterId as int] =
            application;
      }
    }

    return posters.values.toList();
  }

  ResumeData _convertToResume(
      Map<String, dynamic> data,
      ) {
    return ResumeData(
      id: data['id'] as int?,
      profileImage: File(
        data['profileImage']
            ?.toString() ??
            '',
      ),
      certificateImage:
      data['certificateImage'] != null
          ? File(
        data['certificateImage']
            .toString(),
      )
          : null,
      fullName:
      data['fullName']?.toString() ??
          '',
      age:
      data['age']?.toString() ??
          '',
      gender:
      data['gender']?.toString() ??
          '',
      email:
      data['email']?.toString() ??
          '',
      phone:
      data['phone']?.toString() ??
          '',
      address:
      data['address']?.toString() ??
          '',
      summary:
      data['summary']?.toString() ??
          '',
      experience:
      data['experience']?.toString() ??
          '',
      education:
      data['education']?.toString() ??
          '',
    );
  }

  void _viewResume(
      Map<String, dynamic> application,
      ) {
    final resume =
    _convertToResume(application);

    final String studentUsername =
        application['studentUsername']
            ?.toString() ??
            '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            IndustryResumeViewPage(
              resume: resume,
              industryUsername:
              widget.currentUsername,
              studentUsername:
              studentUsername,
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

    final posters =
    _getUniquePosters();

    return RefreshIndicator(
      onRefresh: _loadAllApplications,
      child: ListView(
        padding:
        const EdgeInsets.all(16),
        children: [

          Card(
            child: Padding(
              padding:
              const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Applications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  DropdownButtonFormField<
                      int?>(
                    value:
                    _selectedPosterId,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Hiring Poster',
                      border:
                      OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.work_outline,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<
                          int?>(
                        value: null,
                        child: Text(
                          'All Hiring Posters',
                        ),
                      ),

                      ...posters.map(
                            (poster) {
                          return DropdownMenuItem<
                              int?>(
                            value: poster[
                            'hiringPosterId'] as int,
                            child: Text(
                              '${poster['hiringPosterTitle']} - '
                                  '${poster['companyName']}',
                              overflow:
                              TextOverflow
                                  .ellipsis,
                            ),
                          );
                        },
                      ),
                    ],
                    onChanged:
                    _filterByPoster,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),


          Text(
            'Received Applications: '
                '${_applications.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),


          if (_applications.isEmpty)
            const Card(
              child: Padding(
                padding:
                EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(
                      Icons
                          .description_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      'No applications found.',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                        Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),


          ..._applications.map(
                (application) {
              final imagePath =
                  application[
                  'profileImage']
                      ?.toString() ??
                      '';

              final hasImage =
                  imagePath.isNotEmpty &&
                      File(imagePath)
                          .existsSync();

              return Card(
                margin:
                const EdgeInsets.only(
                  bottom: 12,
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.all(
                    12,
                  ),

                  leading: hasImage
                      ? CircleAvatar(
                    radius: 28,
                    backgroundImage:
                    FileImage(
                      File(imagePath),
                    ),
                  )
                      : const CircleAvatar(
                    radius: 28,
                    child: Icon(
                      Icons.person,
                    ),
                  ),

                  title: Text(
                    application[
                    'fullName']
                        ?.toString() ??
                        'Unknown Applicant',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  subtitle:
                  Padding(
                    padding:
                    const EdgeInsets
                        .only(
                      top: 6,
                    ),
                    child: Text(
                      '${application['gender'] ?? ''} • '
                          'Age ${application['age'] ?? ''}\n'
                          'Job: ${application['hiringPosterTitle'] ?? ''}\n'
                          'Company: ${application['companyName'] ?? ''}\n'
                          'Email: ${application['email'] ?? ''}',
                    ),
                  ),

                  isThreeLine: true,

                  trailing:
                  ElevatedButton(
                    onPressed: () =>
                        _viewResume(
                          application,
                        ),
                    child:
                    const Text(
                      'View Resume',
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


class IndustryResumeViewPage
    extends StatelessWidget {
  final ResumeData resume;


  final String industryUsername;
  final String studentUsername;

  const IndustryResumeViewPage({
    super.key,
    required this.resume,
    required this.industryUsername,
    required this.studentUsername,
  });


  void _contactUser(
      BuildContext context,
      ) {
    if (studentUsername.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Student username is missing.',
          ),
        ),
      );

      return;
    }

    if (industryUsername.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Industry username is missing.',
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ConversationPage(
              currentUsername:
              industryUsername,
              otherUsername:
              studentUsername,
            ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final hasProfileImage =
        resume.profileImage.path
            .isNotEmpty &&
            resume.profileImage
                .existsSync();

    final hasCertificate =
        resume.certificateImage !=
            null &&
            resume.certificateImage!
                .path
                .isNotEmpty &&
            resume.certificateImage!
                .existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Applicant Resume',
        ),
      ),

      body:
      SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  20,
                ),
                child: Column(
                  children: [
                    Center(
                      child:
                      hasProfileImage
                          ? CircleAvatar(
                        radius: 55,
                        backgroundImage:
                        FileImage(
                          resume
                              .profileImage,
                        ),
                      )
                          : const CircleAvatar(
                        radius: 55,
                        child:
                        Icon(
                          Icons.person,
                          size: 55,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Text(
                      resume.fullName,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        fontSize: 24,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      '${resume.gender} • Age ${resume.age}',
                      style:
                      const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            _buildSection(
              title:
              'Contact Information',
              icon: Icons
                  .contact_mail_outlined,
              children: [
                _buildInfoRow(
                  Icons.email_outlined,
                  'Email',
                  resume.email,
                ),
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Phone',
                  resume.phone,
                ),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Address',
                  resume.address,
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),


            _buildSection(
              title:
              'Profile Summary',
              icon: Icons
                  .person_outline,
              children: [
                Text(
                  resume.summary.isEmpty
                      ? 'No profile summary provided.'
                      : resume.summary,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            _buildSection(
              title:
              'Work Experience',
              icon: Icons
                  .work_outline,
              children: [
                Text(
                  resume.experience
                      .isEmpty
                      ? 'No work experience provided.'
                      : resume.experience,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),
            _buildSection(
              title: 'Education',
              icon: Icons
                  .school_outlined,
              children: [
                Text(
                  resume.education.isEmpty
                      ? 'No education information provided.'
                      : resume.education,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),


            if (hasCertificate)
              _buildSection(
                title: 'Certificate',
                icon: Icons
                    .verified_outlined,
                children: [
                  ClipRRect(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                    child:
                    Image.file(
                      resume
                          .certificateImage!,
                      width:
                      double.infinity,
                      fit: BoxFit
                          .contain,
                    ),
                  ),
                ],
              ),

            const SizedBox(
              height: 24,
            ),

            SizedBox(
              width:
              double.infinity,
              height: 52,
              child:
              ElevatedButton.icon(
                onPressed: () =>
                    _contactUser(
                      context,
                    ),
                icon: const Icon(
                  Icons.chat_outlined,
                ),
                label: const Text(
                  'Contact User',
                  style:
                  TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget>
    children,
  }) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: Colors.grey[700],
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  label,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  value.isEmpty
                      ? 'Not provided'
                      : value,
                  style:
                  const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}