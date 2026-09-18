import 'dart:io';
import 'package:flutter/material.dart';
import '../model/hiring_poster_model.dart';
import '../model/resume_model.dart';
import '../service/database_service.dart';


class JobSeekerTab extends StatefulWidget {
  final String username;

  const JobSeekerTab({
    super.key,
    required this.username,
  });

  @override
  State<JobSeekerTab> createState() => _JobSeekerTabState();
}

class _JobSeekerTabState extends State<JobSeekerTab> {
  final DatabaseService _databaseService = DatabaseService();

  List<HiringPoster> _allPosters = [];
  List<HiringPoster> _filteredPosters = [];

  String _selectedState = 'Display All';

  bool _isLoading = true;

  final List<String> _states = [
    'Display All',
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Putrajaya',
    'Labuan',
  ];

  @override
  void initState() {
    super.initState();
    _loadHiringPosters();
  }

  Future<void> _loadHiringPosters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final posters =
      await _databaseService.getAllHiringPosters();

      if (!mounted) return;

      setState(() {
        _allPosters = posters;
        _filteredPosters = posters;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load hiring posters: $e',
          ),
        ),
      );
    }
  }

  void _filterByState(String state) {
    setState(() {
      _selectedState = state;

      if (state == 'Display All') {
        _filteredPosters = List.from(_allPosters);
      } else {
        _filteredPosters = _allPosters.where((poster) {
          return poster.state.toLowerCase().trim() ==
              state.toLowerCase().trim();
        }).toList();
      }
    });
  }

  String _formatDate(String date) {
    if (date.isEmpty) {
      return '';
    }

    try {
      final dateTime = DateTime.parse(date);

      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year}';
    } catch (_) {
      return date;
    }
  }

  Widget _buildFilter() {
    return Card(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.filter_list,
              color: Colors.indigo,
            ),
            const SizedBox(width: 12),
            const Text(
              'State:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: _states.map((state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _filterByState(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(HiringPoster poster) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HiringPosterDetailPage(
                poster: poster,
                username: widget.username,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildPosterImage(poster),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      poster.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      poster.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            poster.state.isEmpty
                                ? poster.address
                                : poster.state,
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (poster.datePosted.isNotEmpty)
                      Text(
                        'Posted: ${_formatDate(poster.datePosted)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosterImage(HiringPoster poster) {
    if (poster.imagePath.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.business,
          size: 40,
          color: Colors.indigo,
        ),
      );
    }

    final file = File(poster.imagePath);

    if (!file.existsSync()) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.business,
          size: 40,
          color: Colors.indigo,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        file,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Hiring Posters Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedState == 'Display All'
                  ? 'There are currently no job vacancies.'
                  : 'There are no job vacancies in $_selectedState.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Seeker'),
        actions: [
          IconButton(
            onPressed: _loadHiringPosters,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilter(),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: Row(
              children: [
                Text(
                  '${_filteredPosters.length} job(s) found',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : _filteredPosters.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadHiringPosters,
              child: ListView.builder(
                padding:
                const EdgeInsets.only(
                  bottom: 20,
                ),
                itemCount:
                _filteredPosters.length,
                itemBuilder:
                    (context, index) {
                  return _buildJobCard(
                    _filteredPosters[index],
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


class HiringPosterDetailPage extends StatelessWidget {
  final HiringPoster poster;
  final String username;

  const HiringPosterDetailPage({
    super.key,
    required this.poster,
    required this.username,
  });

  String _formatDate(String date) {
    if (date.isEmpty) {
      return '';
    }

    try {
      final dateTime = DateTime.parse(date);

      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year}';
    } catch (_) {
      return date;
    }
  }

  Widget _detailRow(
      IconData icon,
      String title,
      String value,
      ) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.indigo,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            if (poster.imagePath.isNotEmpty &&
                File(poster.imagePath).existsSync())
              ClipRRect(
                borderRadius:
                BorderRadius.circular(12),
                child: Image.file(
                  File(poster.imagePath),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business,
                  size: 80,
                  color: Colors.indigo,
                ),
              ),

            const SizedBox(height: 20),

            Text(
              poster.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              poster.companyName,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.indigo,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 16),

            _detailRow(
              Icons.location_on,
              'Location',
              poster.address,
            ),

            _detailRow(
              Icons.map,
              'State',
              poster.state,
            ),

            _detailRow(
              Icons.email,
              'Email',
              poster.email,
            ),

            _detailRow(
              Icons.phone,
              'Contact Number',
              poster.contactNumber,
            ),

            if (poster.datePosted.isNotEmpty)
              _detailRow(
                Icons.calendar_today,
                'Date Posted',
                _formatDate(
                  poster.datePosted,
                ),
              ),

            const SizedBox(height: 10),

            const Text(
              'Job Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Text(
                poster.description.isEmpty
                    ? 'No job description provided.'
                    : poster.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SelectResumePage(
                            poster: poster,

                            currentUsername: username,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text(
                  'Apply Now',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}



class SelectResumePage extends StatefulWidget {
  final HiringPoster poster;

  final String currentUsername;

  const SelectResumePage({
    super.key,
    required this.poster,
    required this.currentUsername,
  });

  @override
  State<SelectResumePage> createState() =>
      _SelectResumePageState();
}

class _SelectResumePageState
    extends State<SelectResumePage> {
  final DatabaseService _databaseService =
  DatabaseService();

  List<ResumeData> _resumes = [];

  ResumeData? _selectedResume;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resumes =
      await _databaseService.getAllResumes();

      if (!mounted) return;

      setState(() {
        _resumes = resumes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load resumes: $e',
          ),
        ),
      );
    }
  }



  Future<void> _reviewResume() async {
    if (_selectedResume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a resume first.',
          ),
        ),
      );
      return;
    }

    final confirmed =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResumeReviewPage(
              resume: _selectedResume!,
              poster: widget.poster,
            ),
      ),
    );


    if (confirmed == true) {
      if (_selectedResume?.id == null ||
          widget.poster.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to submit application. Missing ID.',
            ),
          ),
        );
        return;
      }

      try {
        await _databaseService.submitApplication(
          resumeId: _selectedResume!.id!,
          hiringPosterId: widget.poster.id!,


          studentUsername:
          widget.currentUsername,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Application submitted successfully!',
            ),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit application: $e',
            ),
          ),
        );
      }
    }
  }

  Widget _resumeCard(ResumeData resume) {
    final isSelected =
        _selectedResume?.id == resume.id;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: RadioListTile<int>(
        value: resume.id ?? 0,
        groupValue:
        _selectedResume?.id ?? -1,
        onChanged: (value) {
          setState(() {
            _selectedResume = resume;
          });
        },
        title: Text(
          resume.fullName.isEmpty
              ? 'Unnamed Resume'
              : resume.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            if (resume.email.isNotEmpty)
              Text(resume.email),

            if (resume.phone.isNotEmpty)
              Text(resume.phone),

            if (resume.address.isNotEmpty)
              Text(
                resume.address,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
              ),
          ],
        ),
        selected: isSelected,
        activeColor: Colors.indigo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Resume',
        ),
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _resumes.isEmpty
          ? Center(
        child: Padding(
          padding:
          const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 70,
                color:
                Colors.grey.shade400,
              ),

              const SizedBox(
                height: 16,
              ),

              const Text(
                'No Resume Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Please create a resume before applying for a job.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      )
          : Column(
        children: [

          Container(
            width: double.infinity,
            margin:
            const EdgeInsets.all(16),
            padding:
            const EdgeInsets.all(16),
            decoration:
            BoxDecoration(
              color:
              Colors.indigo.shade50,
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                const Text(
                  'Applying for',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  widget.poster.title,
                  style:
                  const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  widget.poster
                      .companyName,
                  style:
                  const TextStyle(
                    color:
                    Colors.indigo,
                  ),
                ),
              ],
            ),
          ),


          const Padding(
            padding:
            EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Align(
              alignment:
              Alignment.centerLeft,
              child: Text(
                'Choose your resume',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Expanded(
            child:
            ListView.builder(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 16,
              ),
              itemCount:
              _resumes.length,
              itemBuilder:
                  (context, index) {
                return _resumeCard(
                  _resumes[index],
                );
              },
            ),
          ),


          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.all(
                16,
              ),
              child: SizedBox(
                width:
                double.infinity,
                height: 52,
                child:
                ElevatedButton.icon(
                  onPressed:
                  _reviewResume,
                  icon: const Icon(
                    Icons.visibility,
                  ),
                  label: const Text(
                    'Review Resume Before Submitting',
                    style:
                    TextStyle(
                      fontSize: 16,
                    ),
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



class ResumeReviewPage extends StatelessWidget {
  final ResumeData resume;
  final HiringPoster poster;

  const ResumeReviewPage({
    super.key,
    required this.resume,
    required this.poster,
  });

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _resumeField(
      String label,
      String value,
      ) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
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
        title: const Text(
          'Review Your Resume',
        ),
      ),

      body: Column(
        children: [

          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius:
              BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.shade200,
              ),
            ),
            child: const Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Please double-check your resume before submitting your application.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child:
            SingleChildScrollView(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                20,
              ),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding:
                  const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [

                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.description,
                              size: 55,
                              color:
                              Colors.indigo,
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            Text(
                              resume.fullName
                                  .isEmpty
                                  ? 'Resume'
                                  : resume
                                  .fullName,
                              textAlign:
                              TextAlign
                                  .center,
                              style:
                              const TextStyle(
                                fontSize: 26,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            const Text(
                              'Resume submitted for job application',
                              style: TextStyle(
                                color:
                                Colors.grey,
                              ),
                              textAlign:
                              TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const Divider(
                        height: 35,
                      ),


                      _sectionTitle(
                        'Personal Information',
                      ),

                      _resumeField(
                        'Full Name',
                        resume.fullName,
                      ),

                      _resumeField(
                        'Age',
                        resume.age,
                      ),

                      _resumeField(
                        'Gender',
                        resume.gender,
                      ),

                      _sectionTitle(
                        'Contact Information',
                      ),

                      _resumeField(
                        'Email',
                        resume.email,
                      ),

                      _resumeField(
                        'Phone',
                        resume.phone,
                      ),

                      _resumeField(
                        'Address',
                        resume.address,
                      ),


                      _sectionTitle(
                        'Professional Summary',
                      ),

                      _resumeField(
                        'Summary',
                        resume.summary,
                      ),

                      _sectionTitle(
                        'Work Experience',
                      ),

                      _resumeField(
                        'Experience',
                        resume.experience,
                      ),

                      _sectionTitle(
                        'Education',
                      ),

                      _resumeField(
                        'Education',
                        resume.education,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      const Divider(),

                      const SizedBox(
                        height: 10,
                      ),


                      _sectionTitle(
                        'Application',
                      ),

                      _resumeField(
                        'Position',
                        poster.title,
                      ),

                      _resumeField(
                        'Company',
                        poster.companyName,
                      ),

                      _resumeField(
                        'Location',
                        poster.address,
                      ),

                      _resumeField(
                        'State',
                        poster.state,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.all(
                          14,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.green.shade50,
                          borderRadius:
                          BorderRadius
                              .circular(
                            10,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color:
                              Colors.green,
                            ),

                            SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                'Check all information carefully. Once you confirm, your resume will be submitted with this application.',
                                style:
                                TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      style:
                      OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Back',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    flex: 2,
                    child:
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          true,
                        );
                      },
                      icon: const Icon(
                        Icons.send,
                      ),
                      label: const Text(
                        'Confirm & Submit',
                      ),
                      style:
                      ElevatedButton.styleFrom(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}