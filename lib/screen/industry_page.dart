import 'dart:io';

import 'package:flutter/material.dart';

import 'app_drawer.dart';
import 'resume_builder_page.dart';
import 'job_seeker.dart';
import 'hiring_poster_builder.dart';
import 'received_resumes.dart';

import '../model/industry_partner_model.dart';
import '../model/hiring_poster_model.dart';
import '../service/database_service.dart';

class IndustryPage extends StatefulWidget {
  final String userRole;
  final String username;

  const IndustryPage({
    super.key,
    required this.userRole,
    required this.username,
  });

  @override
  State<IndustryPage> createState() => _IndustryPageState();
}

class _IndustryPageState extends State<IndustryPage> {
  IndustryPartner? _partnerProfile;
  int? _userId;
  bool _isLoading = true;

  bool get _isIndustryPartner {
    final role = widget.userRole.trim().toLowerCase();

    return role == 'industry' ||
        role == 'industry partner' ||
        role == 'industry_partner';
  }

  @override
  void initState() {
    super.initState();

    if (_isIndustryPartner) {
      _loadPartnerData();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadPartnerData() async {
    try {
      final id = await DatabaseService().getUserId(widget.username);

      if (id != null) {
        final partner =
        await DatabaseService().getIndustryPartnerByUserId(id);

        if (mounted) {
          setState(() {
            _userId = id;
            _partnerProfile = partner;
          });
        }
      }
    } catch (e) {
      debugPrint(
        'Error loading industry partner profile: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // INDUSTRY PARTNER
    // ============================================================

    if (_isIndustryPartner) {
      if (_isLoading) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Partner Portal'),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
          drawer: AppDrawer(
            userRole: widget.userRole,
            username: widget.username,
          ),
        );
      }

      final titleName =
      _partnerProfile?.companyName.isNotEmpty == true
          ? _partnerProfile!.companyName
          : widget.username;

      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('$titleName (Partner)'),
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  icon: Icon(Icons.campaign),
                  text: 'Hiring Posters',
                ),
                Tab(
                  icon: Icon(Icons.folder_shared),
                  text: 'Received Resumes',
                ),
              ],
            ),
          ),

          body: TabBarView(
            children: [
              PartnerPostersTab(
                userId: _userId,
                partner: _partnerProfile,
              ),

              // ReceivedResumesTab is now in received_resumes.dart
              const ReceivedResumesTab(),
            ],
          ),

          drawer: AppDrawer(
            userRole: widget.userRole,
            username: widget.username,
          ),
        ),
      );
    }

    // ============================================================
    // NORMAL USER / STUDENT
    // ============================================================

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Industry'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(
                text: 'Resume Builder',
              ),
              Tab(
                text: 'Job Seeker',
              ),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            ResumeHomeTab(),
            JobSeekerTab(),
          ],
        ),

        drawer: AppDrawer(
          userRole: widget.userRole,
          username: widget.username,
        ),
      ),
    );
  }
}

// ============================================================================
// PARTNER TAB 1: HIRING POSTERS MANAGEMENT
// ============================================================================

class PartnerPostersTab extends StatefulWidget {
  final int? userId;
  final IndustryPartner? partner;

  const PartnerPostersTab({
    super.key,
    required this.userId,
    required this.partner,
  });

  @override
  State<PartnerPostersTab> createState() =>
      _PartnerPostersTabState();
}

class _PartnerPostersTabState
    extends State<PartnerPostersTab> {
  List<HiringPoster> _posters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosters();
  }

  Future<void> _loadPosters() async {
    if (widget.userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final list = await DatabaseService()
        .getHiringPostersByUserId(widget.userId!);

    if (mounted) {
      setState(() {
        _posters = list;
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // OPEN POSTER FORM
  // ============================================================

  void _openPosterFormModal({
    HiringPoster? posterToEdit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => PosterFormSheet(
        userId: widget.userId,
        partner: widget.partner,
        posterToEdit: posterToEdit,
        onSuccess: _loadPosters,
      ),
    );
  }

  // ============================================================
  // VIEW POSTER DETAILS
  // ============================================================

  void _viewPosterDetails(HiringPoster poster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.campaign,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(poster.title),
            ),
          ],
        ),

        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),

              _detailRow(
                Icons.business,
                'Company',
                poster.companyName,
              ),

              _detailRow(
                Icons.email,
                'Email',
                poster.email,
              ),

              _detailRow(
                Icons.phone,
                'Contact',
                poster.contactNumber,
              ),

              _detailRow(
                Icons.location_on,
                'Address',
                poster.address,
              ),

              _detailRow(
                Icons.calendar_today,
                'Posted Date',
                poster.datePosted,
              ),

              const SizedBox(height: 12),

              const Text(
                'Job Description & Requirements:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Text(
                  poster.description,
                ),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);

              _openPosterFormModal(
                posterToEdit: poster,
              );
            },
            icon: const Icon(
              Icons.edit,
              size: 18,
            ),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.blueAccent,
          ),

          const SizedBox(width: 8),

          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
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

  // ============================================================
  // DELETE POSTER
  // ============================================================

  Future<void> _deletePoster(
      int posterId,
      ) async {
    await DatabaseService()
        .deleteHiringPoster(posterId);

    _loadPosters();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poster deleted.'),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: _posters.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),

          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [
              if (widget.partner
                  ?.photoPath.isNotEmpty ==
                  true)
                CircleAvatar(
                  radius: 36,
                  backgroundImage: FileImage(
                    File(
                      widget.partner!.photoPath,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.business,
                  size: 64,
                  color: Colors.blue,
                ),

              const SizedBox(height: 12),

              Text(
                widget.partner?.companyName ??
                    'Industry Partner',

                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                widget.partner?.location ?? '',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'No hiring posters created yet.',
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () =>
                    _openPosterFormModal(),

                icon: const Icon(
                  Icons.add,
                ),

                label: const Text(
                  'Create Hiring Poster',
                ),
              ),
            ],
          ),
        ),
      )

          : ListView.builder(
        padding: const EdgeInsets.all(16),

        itemCount: _posters.length,

        itemBuilder: (context, index) {
          final poster = _posters[index];

          return Card(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),

            child: ListTile(
              onTap: () =>
                  _viewPosterDetails(poster),

              leading: const CircleAvatar(
                backgroundColor:
                Colors.blueAccent,

                child: Icon(
                  Icons.campaign,
                  color: Colors.white,
                ),
              ),

              title: Text(
                poster.title,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Text(
                '${poster.companyName} • '
                    '${poster.contactNumber}\n'
                    '${poster.description}',

                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
              ),

              isThreeLine: true,

              trailing: Row(
                mainAxisSize:
                MainAxisSize.min,

                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.blue,
                    ),

                    onPressed: () =>
                        _openPosterFormModal(
                          posterToEdit: poster,
                        ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),

                    onPressed: () {
                      if (poster.id != null) {
                        _deletePoster(
                          poster.id!,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),

      floatingActionButton:
      _posters.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () =>
            _openPosterFormModal(),

        icon: const Icon(
          Icons.add,
        ),

        label: const Text(
          'New Poster',
        ),
      )
          : null,
    );
  }
}