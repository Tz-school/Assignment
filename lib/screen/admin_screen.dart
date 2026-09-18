import 'package:flutter/material.dart';
import '../service/database_service.dart';
import '../model/event_model.dart';
import '../model/event_registration_model.dart';
import '../model/booking_model.dart';
import '../model/mock_interview_model.dart';
import '../model/timetable_model.dart';
import 'dart:io';

class CreateWorkshopScreen extends StatefulWidget {
  const CreateWorkshopScreen({super.key});

  @override
  State<CreateWorkshopScreen> createState() => _CreateWorkshopScreenState();
}

class _CreateWorkshopScreenState extends State<CreateWorkshopScreen> {
  final _titleController = TextEditingController();
  final _speakerController = TextEditingController();
  final _venueController = TextEditingController();
  final _limitController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    _speakerController.dispose();
    _venueController.dispose();
    _limitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _saveEvent() async {
    if (_titleController.text.isEmpty ||
        _limitController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Title, Limit, Date, and Time'),
        ),
      );
      return;
    }

    final dateStr =
        "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

    final newEvent = EventModel(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      speaker: _speakerController.text.trim(),
      venue: _venueController.text.trim(),
      date: dateStr,
      time: _selectedTime!.format(context),
      capacity: int.parse(_limitController.text.trim()),
    );

    await DatabaseService().insertEvent(newEvent);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workshop created successfully!')),
      );
      // Return 'true' so the calling page knows to reload the event list
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Workshop'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title *',
                hintText: 'e.g. Resume Masterclass',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Event Description',
                hintText: 'Provide details about the event...',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _speakerController,
              decoration: const InputDecoration(
                labelText: 'Speaker / Advisor',
                hintText: 'e.g. Dr. Smith',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Venue / Link',
                hintText: 'e.g. Room 302 or Zoom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Booking Limit (Pax) *',
                hintText: 'e.g. 30',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _selectedTime == null
                          ? 'Select Time'
                          : _selectedTime!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _saveEvent,
              child: const Text(
                'Create Event',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminWorkshopListView extends StatefulWidget {
  final DatabaseService dbService;
  const AdminWorkshopListView({super.key, required this.dbService});

  @override
  State<AdminWorkshopListView> createState() => _AdminWorkshopListViewState();
}

class _AdminWorkshopListViewState extends State<AdminWorkshopListView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventModel>>(
      future: widget.dbService.getEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No events created yet. Click "New Event" to start.'),
          );
        }

        final events = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final bool isFull = event.booked >= event.capacity;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  // Navigate to Detail Page & reload list if deleted
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminEventDetailScreen(
                        event: event,
                        dbService: widget.dbService,
                      ),
                    ),
                  );

                  if (result == true) {
                    setState(() {}); // Refresh list if event was deleted
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event, color: Colors.indigo, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('📅 ${event.date} • ⏰ ${event.time}'),
                            const SizedBox(height: 2),
                            Text(
                              '📍 ${event.venue} | 🎤 ${event.speaker}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Booked', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            '${event.booked}/${event.capacity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isFull ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminEventDetailScreen extends StatefulWidget {
  final EventModel event;
  final DatabaseService dbService;

  const AdminEventDetailScreen({
    super.key,
    required this.event,
    required this.dbService,
  });

  @override
  State<AdminEventDetailScreen> createState() => _AdminEventDetailScreenState();
}

class _AdminEventDetailScreenState extends State<AdminEventDetailScreen> {
  late final Future<List<Map<String, dynamic>>> _participantsFuture;

  @override
  void initState() {
    super.initState();
    _participantsFuture = _loadParticipantsWithProfiles();
  }

  // Fetches accepted usernames, then looks up each one's stored profile
  // (name + photoPath) so the list can show the real name and photo
  // instead of just the raw username.
  Future<List<Map<String, dynamic>>> _loadParticipantsWithProfiles() async {
    final usernames = await widget.dbService.getAcceptedParticipants(widget.event.id!);

    final profiles = await Future.wait(usernames.map((username) async {
      final profile = await widget.dbService.getUserProfile(username);
      return {
        'username': username,
        'name': profile?['name'] as String?,
        'photoPath': profile?['photoPath'] as String?,
      };
    }));

    return profiles;
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: Text(
            'Are you sure you want to delete "${widget.event.title}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (widget.event.id != null) {
                  await widget.dbService.deleteEvent(widget.event.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event deleted successfully!')),
                    );
                    Navigator.pop(context, true);
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final int available = event.capacity - event.booked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.indigo),
                      title: const Text('Speaker / Advisor'),
                      subtitle: Text(event.speaker.isEmpty ? 'N/A' : event.speaker),
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.indigo),
                      title: const Text('Venue'),
                      subtitle: Text(event.venue.isEmpty ? 'N/A' : event.venue),
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                      title: const Text('Date & Time'),
                      subtitle: Text('${event.date} at ${event.time}'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    ListTile(
                      leading: const Icon(Icons.groups, color: Colors.indigo),
                      title: const Text('Slots / Capacity'),
                      subtitle: Text(
                        '${event.booked} booked out of ${event.capacity} ($available slots remaining)',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 24),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description, color: Colors.indigo),
                      title: const Text(
                        'Event Description',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              event.description.isEmpty ? 'N/A' : event.description,
                              style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Accepted Participants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _participantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No participants have been accepted yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final participants = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final participant = participants[index];
                    final username = participant['username'] as String;
                    final name = participant['name'] as String?;
                    final photoPath = participant['photoPath'] as String?;

                    // Prefer the stored full name; fall back to username if
                    // the participant never set one.
                    final displayName = (name != null && name.trim().isNotEmpty)
                        ? name
                        : username;

                    // Only treat it as a real photo if the file actually
                    // exists on disk (it may have been cleared or the app
                    // reinstalled since the path was saved).
                    final hasPhoto = photoPath != null && File(photoPath).existsSync();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
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
                        title: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Chip(
                          label: const Text('ACCEPTED'),
                          backgroundColor: Colors.green.shade100,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_forever),
                label: const Text(
                  'Delete Event',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPendingRequestsView extends StatefulWidget {
  final DatabaseService dbService;

  const AdminPendingRequestsView({super.key, required this.dbService});

  @override
  State<AdminPendingRequestsView> createState() => _AdminPendingRequestsViewState();
}

class _AdminPendingRequestsViewState extends State<AdminPendingRequestsView> {
  String _searchQuery = '';
  String _sortOrder = 'Newest';

  List<EventRegistrationModel> _allRegistrations = [];
  bool _isLoading = true;
  Set<String> _selectedKeys = {};

  bool _isBatchMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await widget.dbService.getAllRegistrations();
    if (mounted) {
      setState(() {
        _allRegistrations = data;
        _isLoading = false;
      });
    }
  }

  List<EventRegistrationModel> get _displayedRequests {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<EventRegistrationModel> list = _allRegistrations
        .where((r) => r.status.toLowerCase() == 'pending')
        .where((r) {
      // Hide requests for events that have already happened — there's
      // nothing actionable an admin can do with them. If the date can't
      // be parsed, err on the side of still showing it.
      final eventDate = DateTime.tryParse(r.date);
      if (eventDate == null) return true;
      return !eventDate.isBefore(today);
    })
        .toList();

    if (_searchQuery.isNotEmpty) {
      list = list.where((r) {
        final usernameMatch = (r.username ?? '').toLowerCase().contains(_searchQuery);
        final titleMatch = (r.eventTitle ?? '').toLowerCase().contains(_searchQuery);
        return usernameMatch || titleMatch;
      }).toList();
    }

    list.sort((a, b) {
      if (_sortOrder == 'Newest') {
        return b.registrationId.compareTo(a.registrationId);
      } else {
        return a.registrationId.compareTo(b.registrationId);
      }
    });

    return list;
  }

  /// True if the event has no remaining capacity (or no longer exists).
  Future<bool> _isEventFull(int eventId) async {
    final event = await widget.dbService.getEventById(eventId);
    if (event == null) return true; // Deleted event — treat as unavailable.
    return event.booked >= event.capacity;
  }

  // Updated to use registrationId & eventId matching DatabaseService
  void _updateStatus(int registrationId, int eventId, String newStatus) async {
    // Only accepting requires a capacity check — rejecting is always allowed,
    // which is exactly the escape hatch we want to leave open for a full event.
    if (newStatus.toLowerCase() == 'accepted' && await _isEventFull(eventId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This event is fully booked — you can only reject this request.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return; // Halt: do not update status.
    }

    setState(() => _isLoading = true);
    await widget.dbService.updateRegistrationStatus(registrationId, eventId, newStatus);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request $newStatus successfully.'),
          backgroundColor: newStatus == 'accepted' ? Colors.green : Colors.red,
        ),
      );
      _selectedKeys.remove("${registrationId}_${eventId}");
      await _loadData();
    }
  }

  // Updated batch status logic for registrationId & eventId
  void _batchUpdateStatus(String newStatus) async {
    if (_selectedKeys.isEmpty) return;

    setState(() => _isLoading = true);

    int successCount = 0;
    int blockedCount = 0;

    for (String key in _selectedKeys) {
      final parts = key.split('_');
      final regId = int.parse(parts[0]);
      final eventId = int.parse(parts[1]);

      // Skip (leave pending) any "accept" whose event is already full. Re-checked
      // per item since accepting earlier items in this same batch can fill a
      // shared event's capacity partway through the loop.
      if (newStatus.toLowerCase() == 'accepted' && await _isEventFull(eventId)) {
        blockedCount++;
        continue;
      }

      await widget.dbService.updateRegistrationStatus(regId, eventId, newStatus);
      successCount++;
    }

    if (mounted) {
      final message = blockedCount > 0
          ? '$successCount request(s) $newStatus. $blockedCount skipped — event fully booked (still pending, can be rejected).'
          : '$successCount request(s) $newStatus successfully.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: blockedCount > 0
              ? Colors.orange
              : (newStatus == 'accepted' ? Colors.green : Colors.red),
        ),
      );
      _selectedKeys.clear();
      _isBatchMode = false; // Exit batch mode after completion
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedList = _displayedRequests;
    final allSelected = displayedList.isNotEmpty && _selectedKeys.length == displayedList.length;

    return Column(
      children: [
        // 1. Search, Filter, and Toggle Batch Mode Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isBatchMode = !_isBatchMode;
                    _selectedKeys.clear(); // Clear selections when toggling
                  });
                },
                icon: Icon(_isBatchMode ? Icons.cancel : Icons.checklist),
                color: _isBatchMode ? Colors.red : Colors.indigo,
                tooltip: _isBatchMode ? 'Cancel Batch Selection' : 'Enable Batch Selection',
              ),
              const SizedBox(width: 8),

              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search student or event...',
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortOrder,
                    icon: const Icon(Icons.sort, color: Colors.indigo, size: 20),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13),
                    items: ['Newest', 'Oldest'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _sortOrder = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Batch Select & Action Bar (ONLY SHOWS IF BATCH MODE IS ON)
        if (_isBatchMode) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  activeColor: Colors.indigo,
                  onChanged: displayedList.isEmpty ? null : (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedKeys = displayedList.map((r) => "${r.registrationId}_${r.eventId}").toSet();
                      } else {
                        _selectedKeys.clear();
                      }
                    });
                  },
                ),
                const Text('Select All', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_selectedKeys.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () => _batchUpdateStatus('rejected'),
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    label: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _batchUpdateStatus('accepted'),
                    icon: const Icon(Icons.check, size: 20),
                    label: Text('Accept (${_selectedKeys.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        // 3. List of Pending Requests
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : displayedList.isEmpty
              ? Center(
            child: Text(
              'No pending requests match your search.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: displayedList.length,
            itemBuilder: (context, index) {
              final req = displayedList[index];
              // Changed key from userId to registrationId
              final String itemKey = "${req.registrationId}_${req.eventId}";
              final bool isSelected = _selectedKeys.contains(itemKey);

              return Card(
                elevation: isSelected ? 4 : 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: isSelected ? Colors.indigo.shade300 : Colors.transparent,
                        width: 2
                    )
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _isBatchMode
                      ? () {
                    setState(() {
                      if (isSelected) {
                        _selectedKeys.remove(itemKey);
                      } else {
                        _selectedKeys.add(itemKey);
                      }
                    });
                  }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isBatchMode)
                          Checkbox(
                            value: isSelected,
                            activeColor: Colors.indigo,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedKeys.add(itemKey);
                                } else {
                                  _selectedKeys.remove(itemKey);
                                }
                              });
                            },
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.eventTitle ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.indigo),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Student: ${req.username}',
                                      style: TextStyle(color: Colors.grey.shade800),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.indigo),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${req.date} at ${req.time}',
                                      style: TextStyle(color: Colors.grey.shade800),
                                    ),
                                  ],
                                ),

                                if (!_isBatchMode) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          // Replaced userId! with req.registrationId
                                          onPressed: () => _updateStatus(req.registrationId, req.eventId, 'rejected'),
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.red.shade200),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          // Replaced userId! with req.registrationId
                                          onPressed: () => _updateStatus(req.registrationId, req.eventId, 'accepted'),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Accept'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A counselor's real occupied window on a given date, in
/// minutes-since-midnight — e.g. a 1.5-hour 10:00 booking is (600, 690).
class _BookedRange {
  final int start;
  final int end;
  const _BookedRange(this.start, this.end);
}

class AdminAssignAdvisorView extends StatefulWidget {
  final DatabaseService dbService;
  const AdminAssignAdvisorView({super.key, required this.dbService});

  @override
  State<AdminAssignAdvisorView> createState() => _AdminAssignAdvisorViewState();
}

class _AdminAssignAdvisorViewState extends State<AdminAssignAdvisorView> {
  late Future<List<MockInterviewModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.dbService.getAllMockInterviews();
  }

  /// Re-fetches the mock interview list. Needed because this screen can stay
  /// mounted (e.g. kept alive in a bottom-nav tab) without rebuilding on its
  /// own — so a student cancelling their request elsewhere wouldn't
  /// otherwise be reflected here until something explicitly asks for fresh
  /// data. Called after assigning a request, and available via pull-to-refresh.
  Future<void> _refresh() async {
    setState(() {
      _future = widget.dbService.getAllMockInterviews();
    });
  }

  // --- Time helpers -------------------------------------------------------

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Best-effort parser that turns a slot's display label (e.g. "9:00 AM" or
  /// "14:00") back into a [TimeOfDay] so it can be compared numerically.
  /// Returns null if the label can't be understood, in which case that slot
  /// is simply skipped by the availability check rather than crashing it.
  TimeOfDay? _parseTimeLabel(String label) {
    try {
      final cleaned = label.trim().toUpperCase();
      final isPM = cleaned.contains('PM');
      final isAM = cleaned.contains('AM');
      final numeric = cleaned.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = numeric.split(':');
      if (parts.isEmpty || parts.first.isEmpty) return null;
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 && parts[1].isNotEmpty ? int.parse(parts[1]) : 0;
      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      return TimeOfDay(hour: hour % 24, minute: minute % 60);
    } catch (_) {
      return null;
    }
  }

  /// Formats a time as the exact "HH:00" label that getAdvisorTimetable
  /// generates and matches against (see database_service.dart). The stored
  /// `assignedTime` MUST use this format, or future availability checks for
  /// this counselor will silently fail to recognize the slot as booked.
  String _formatHourLabel(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:00';

  /// A booking's real occupied window, in minutes-since-midnight — computed
  /// from its own assignedTime + durationMinutes, not the coarse one-hour
  /// grid getAdvisorTimetable exposes (which can't represent a booking
  /// spanning more than one hour, e.g. a 1.5-hour 10:00 session also
  /// occupying the 11:00 hour).
  static const int _defaultBookingDurationMin = 60;

  /// Fetches every 'Accepted' mock interview for [counselorName] on [date]
  /// and returns each one's real [start, end) range in minutes-since-midnight.
  Future<List<_BookedRange>> _fetchBookedRanges(
      String counselorName,
      String date,
      ) async {
    final all = await widget.dbService.getAllMockInterviews();
    final ranges = <_BookedRange>[];

    for (final r in all) {
      if (r.advisor != counselorName) continue;
      if (r.date != date) continue;
      if (r.status.toLowerCase() != 'accepted') continue;
      if (r.assignedTime == null || r.assignedTime!.isEmpty) continue;

      final start = _parseTimeLabel(r.assignedTime!);
      if (start == null) continue;

      final startMin = _toMinutes(start);
      final duration = r.durationMinutes ?? _defaultBookingDurationMin;
      ranges.add(_BookedRange(startMin, startMin + duration));
    }

    return ranges;
  }

  /// Returns true if the requested [start, end) range overlaps ANY of the
  /// counselor's real booked ranges (each already in minutes-since-midnight).
  bool _rangeConflictsWithRanges({
    required List<_BookedRange> ranges,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    final startMin = _toMinutes(start);
    final endMin = _toMinutes(end);

    for (final r in ranges) {
      final overlaps = startMin < r.end && endMin > r.start;
      if (overlaps) return true;
    }
    return false;
  }

  void _showAssignDialog(BuildContext context, MockInterviewModel request) async {
    final counselors = await widget.dbService.getCareerCounselors();
    if (!context.mounted) return;

    // Captured BEFORE entering showDialog. The StatefulBuilder below declares
    // its own `context` parameter that shadows this one for the rest of the
    // dialog's closures. Using the shadowed (dialog) context AFTER
    // Navigator.pop(dialogContext) has torn it down is what causes
    // "'_dependents.isEmpty': is not true" — so the post-close SnackBar must
    // use this captured `screenContext` instead.
    final screenContext = context;

    // Declared here (outside the StatefulBuilder's builder) so the values
    // persist across setDialogState-triggered rebuilds instead of resetting
    // to null every time the dialog redraws.
    String? selectedCounselor;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;
    int selectedDuration = 30;
    String? availabilityError;
    final venueController = TextEditingController();
    // Created once per counselor selection (see onChanged below), NOT inline
    // inside build(). Calling an async DB method directly as a FutureBuilder's
    // `future:` re-creates a brand new Future on every rebuild, which can
    // still be in flight when Navigator.pop() tears the dialog down — that
    // race is what was causing the "'_dependents.isEmpty': is not true" crash.
    //
    // Holds each of the counselor's real booked [start, end) ranges (in
    // minutes-since-midnight) for the chosen date — NOT the coarse one-slot-
    // per-hour grid getAdvisorTimetable exposes, which can't represent a
    // booking spanning more than one hour.
    Future<List<_BookedRange>>? bookedRangesFuture;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {

            void applyDurationToEndTime() {
              if (selectedStartTime == null) return;
              final endMinutes = _toMinutes(selectedStartTime!) + selectedDuration;
              selectedEndTime = TimeOfDay(hour: (endMinutes ~/ 60) % 24, minute: endMinutes % 60);
            }

            Future<void> pickStartTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: selectedStartTime ?? const TimeOfDay(hour: 9, minute: 0),
              );
              if (picked != null) {
                setDialogState(() {
                  // The timetable only tracks whole-hour slots ("09:00", "10:00", ...),
                  // so snap the picked start time down to the hour to stay compatible
                  // with how availability is stored and checked.
                  selectedStartTime = TimeOfDay(hour: picked.hour, minute: 0);
                  availabilityError = null;
                  applyDurationToEndTime();
                });
              }
            }

            Future<void> pickEndTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: selectedEndTime ?? const TimeOfDay(hour: 9, minute: 30),
              );
              if (picked != null) {
                setDialogState(() {
                  selectedEndTime = picked;
                  availabilityError = null;
                });
              }
            }

            return AlertDialog(
              title: const Text('Assign Counselor & Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student Preferred Location: ${request.preferredLocation ?? "Not provided"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 16),

                      // 1. Advisor Selection
                      DropdownButtonFormField<String>(
                        value: selectedCounselor,
                        decoration: const InputDecoration(labelText: 'Select Counselor', border: OutlineInputBorder()),
                        items: counselors.map((c) => DropdownMenuItem(
                          value: c['username'] as String,
                          child: Text(c['username'] as String),
                        )).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedCounselor = val;
                            // Reset schedule fields since availability depends on the counselor.
                            selectedStartTime = null;
                            selectedEndTime = null;
                            availabilityError = null;
                            // Fetch this counselor's real booked ranges exactly once per selection.
                            bookedRangesFuture = val == null
                                ? null
                                : _fetchBookedRanges(val, request.date);
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Timetable Graph (Only shows if an advisor is selected)
                      if (selectedCounselor != null) ...[
                        const Text('Advisor Timetable (tap an available slot to set the start time):',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: FutureBuilder<List<_BookedRange>>(
                            future: bookedRangesFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                              final bookedRanges = snapshot.data!;
                              // Fixed 9am-5pm hourly grid — matches the range
                              // getAdvisorTimetable used to generate, but each
                              // hour's booked/available status is now computed
                              // from the counselor's REAL booking durations.
                              final hours = List<int>.generate(9, (i) => i + 9); // 9..17

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: hours.length,
                                itemBuilder: (context, index) {
                                  final hour = hours[index];
                                  final slotStart = TimeOfDay(hour: hour, minute: 0);
                                  final slotEnd = TimeOfDay(hour: hour + 1, minute: 0);
                                  final isBooked = _rangeConflictsWithRanges(
                                    ranges: bookedRanges,
                                    start: slotStart,
                                    end: slotEnd,
                                  );
                                  final timeLabel = _formatHourLabel(slotStart);
                                  final isSelected = selectedStartTime != null &&
                                      _toMinutes(slotStart) == _toMinutes(selectedStartTime!);

                                  return GestureDetector(
                                    onTap: isBooked ? null : () {
                                      setDialogState(() {
                                        availabilityError = null;
                                        selectedStartTime = slotStart;
                                        applyDurationToEndTime();
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isBooked
                                            ? Colors.red.shade100
                                            : (isSelected ? Colors.indigo : Colors.green.shade100),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isBooked ? Colors.red : (isSelected ? Colors.indigo : Colors.green),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          timeLabel,
                                          style: TextStyle(
                                            color: isBooked
                                                ? Colors.red.shade900
                                                : (isSelected ? Colors.white : Colors.green.shade900),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Explicit start / end time entry
                        const Text('Time Slot:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: pickStartTime,
                                icon: const Icon(Icons.access_time),
                                label: Text(selectedStartTime == null ? 'Start Time' : selectedStartTime!.format(context)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: pickEndTime,
                                icon: const Icon(Icons.access_time_filled),
                                label: Text(selectedEndTime == null ? 'End Time' : selectedEndTime!.format(context)),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Start time is recorded to the nearest hour to match the availability grid.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. Venue & Duration Assignments
                        TextField(
                          controller: venueController,
                          decoration: const InputDecoration(
                            labelText: 'Assigned Venue / Link',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          onChanged: (_) => setDialogState(() => availabilityError = null),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedDuration,
                          decoration: const InputDecoration(
                            labelText: 'Duration (used to suggest an end time)',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 30, child: Text('30 Minutes')),
                            DropdownMenuItem(value: 60, child: Text('1 Hour')),
                            DropdownMenuItem(value: 90, child: Text('1.5 Hours')),
                          ],
                          onChanged: (val) => setDialogState(() {
                            selectedDuration = val!;
                            applyDurationToEndTime();
                          }),
                        ),

                        if (availabilityError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    availabilityError!,
                                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (selectedCounselor == null ||
                      selectedStartTime == null ||
                      selectedEndTime == null ||
                      venueController.text.trim().isEmpty)
                      ? null
                      : () async {
                    // Dismiss the keyboard/focus first. If a text field's floating
                    // label animation (AnimatedDefaultTextStyle) is still running when
                    // Navigator.pop() below tears the dialog down, the framework can
                    // throw "Tried to build dirty widget in the wrong build scope."
                    FocusManager.instance.primaryFocus?.unfocus();

                    // Guard 1: end time must be strictly after start time. Halt otherwise.
                    if (_toMinutes(selectedEndTime!) <= _toMinutes(selectedStartTime!)) {
                      setDialogState(() {
                        availabilityError = 'End time must be after the start time.';
                      });
                      return;
                    }

                    // Guard 2: re-check the counselor's real bookings right before
                    // committing (they may have changed since the dialog opened). Uses
                    // each existing booking's actual start+duration — not the coarse
                    // one-hour grid — so a 1.5-hour booking starting at 10:00 correctly
                    // blocks 11:00 too, not just the literal 10:00 slot.
                    final freshRanges = await _fetchBookedRanges(
                      selectedCounselor!,
                      request.date,
                    );

                    final hasConflict = _rangeConflictsWithRanges(
                      ranges: freshRanges,
                      start: selectedStartTime!,
                      end: selectedEndTime!,
                    );

                    if (hasConflict) {
                      setDialogState(() {
                        availabilityError =
                        'This counselor is no longer available for the selected time slot. '
                            'Please pick a different time.';
                      });
                      return; // Halt: do not proceed to save the assignment.
                    }

                    if (request.id != null) {
                      // Duration reflects whatever start/end the admin actually
                      // settled on (which may differ from the Duration dropdown
                      // if they manually adjusted the end time).
                      final effectiveDuration =
                          _toMinutes(selectedEndTime!) - _toMinutes(selectedStartTime!);

                      await widget.dbService.assignAdvisorWithDetails(
                        request.id!,
                        selectedCounselor!,
                        // Must match the "HH:00" format getAdvisorTimetable generates,
                        // otherwise this booking won't be recognized on future checks.
                        _formatHourLabel(selectedStartTime!),
                        venueController.text.trim(),
                        effectiveDuration,
                      );

                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(screenContext).showSnackBar(
                          const SnackBar(
                            content: Text('Advisor assigned and scheduled successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _refresh(); // Refresh parent list with fresh data
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: const Text('Confirm Assignment'),
                ),
              ],
            );
          },
        );
      },
    );

    venueController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MockInterviewModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(child: Text('No session requests found.')),
              ],
            ),
          );
        }

        // Only show requests that haven't been assigned/accepted/cancelled/rejected —
        // i.e. anything still awaiting admin action.
        final pendingRequests = snapshot.data!
            .where((r) => r.status.toLowerCase() == 'pending')
            .toList();

        if (pendingRequests.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                const SizedBox(height: 16),
                const Center(
                  child: Text('All requests have been assigned!',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final req = pendingRequests[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
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
                            '${req.requestType}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                border: Border.all(color: Colors.orange.shade200),
                                borderRadius: BorderRadius.circular(8)
                            ),
                            child: Text(
                              req.status.toUpperCase(),
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text('Student: ${req.username}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text('Pref. Location: ${req.preferredLocation ?? "Not provided"}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text('${req.date} ${req.assignedTime != null ? "at ${req.assignedTime}" : "(Time TBD)"}'),
                        ],
                      ),
                      if (req.notes != null && req.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                              'Notes: ${req.notes}',
                              style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic)
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _showAssignDialog(context, req),
                          icon: const Icon(Icons.assignment_ind),
                          label: const Text('Assign Counselor & Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Wraps the assigned-interview list this tab displays.
class _AllBookingsData {
  final List<MockInterviewModel> assignedInterviews;
  _AllBookingsData(this.assignedInterviews);
}

class AllBookingsView extends StatefulWidget {
  final DatabaseService dbService;
  const AllBookingsView({super.key, required this.dbService});

  @override
  State<AllBookingsView> createState() => _AllBookingsViewState();
}

class _AllBookingsViewState extends State<AllBookingsView> {
  late Future<_AllBookingsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<_AllBookingsData> _loadAll() async {
    final allInterviews = await widget.dbService.getAllMockInterviews();
    final assigned = allInterviews
        .where((r) => r.status.toLowerCase() == 'accepted')
        .toList();
    return _AllBookingsData(assigned);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadAll();
    });
  }

  /// True once the interview's end time (start + duration) is in the past.
  /// Used to hide the Cancel Assignment action for sessions that have
  /// already happened — there's nothing left to cancel.
  bool _hasEnded(MockInterviewModel req) {
    final date = DateTime.tryParse(req.date);
    if (date == null) return false; // Unparsable date — don't hide, err safe.

    int startHour = 0;
    int startMinute = 0;
    if (req.assignedTime != null && req.assignedTime!.isNotEmpty) {
      final parts = req.assignedTime!.split(':');
      startHour = int.tryParse(parts[0]) ?? 0;
      startMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    }
    final durationMinutes = req.durationMinutes ?? 60;

    final start = DateTime(date.year, date.month, date.day, startHour, startMinute);
    final end = start.add(Duration(minutes: durationMinutes));

    return end.isBefore(DateTime.now());
  }

  /// Formats the assigned start time ("HH:MM", e.g. "09:00") and duration
  /// (minutes) into a display range like "10:00 - 11:00". Mirrors the same
  /// helper in student_screen.dart so the two screens agree on formatting.
  String? _formatAssignedTimeRange(String? assignedTime, int? durationMinutes) {
    if (assignedTime == null || assignedTime.isEmpty) return null;

    final parts = assignedTime.split(':');
    final startHour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final startMinute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    if (startHour == null) return assignedTime;

    final duration = durationMinutes ?? 60;
    final startTotalMinutes = startHour * 60 + (startMinute ?? 0);
    final endTotalMinutes = startTotalMinutes + duration;

    String fmt(int totalMinutes) {
      final h = (totalMinutes ~/ 60) % 24;
      final m = totalMinutes % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    return '${fmt(startTotalMinutes)} - ${fmt(endTotalMinutes)}';
  }

  Future<void> _cancelAssignment(MockInterviewModel req) async {
    if (_hasEnded(req)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This session has already passed and can no longer be cancelled.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Assignment'),
        content: Text(
          'Cancel the mock interview assignment for "${req.username}"'
              '${(req.advisor != null && req.advisor!.isNotEmpty) ? " with ${req.advisor}" : ""}?\n\n'
              'This cannot be undone — the student will need to submit a new '
              'request or be reassigned separately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Assignment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Assignment',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || req.id == null) return;

    // Reuses the same cancellation path a student uses on their own booking —
    // this marks the interview 'Cancelled', which also frees up that
    // counselor's slot for future availability checks.
    await widget.dbService.cancelMockInterview(req.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment cancelled.'),
          backgroundColor: Colors.orange,
        ),
      );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AllBookingsData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignedInterviews = snapshot.data!.assignedInterviews;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                'Assigned Mock Interview Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (assignedInterviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No assigned mock interviews.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              else
                ...assignedInterviews.map((req) {
                  final timeRange = _formatAssignedTimeRange(req.assignedTime, req.durationMinutes);
                  final ended = _hasEnded(req);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  req.username,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ACCEPTED',
                                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('Advisor: ${req.advisor ?? "N/A"}', style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(req.date, style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(timeRange ?? 'Time TBD', style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                          if (req.venue != null && req.venue!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.meeting_room, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('Venue: ${req.venue}', style: TextStyle(color: Colors.grey.shade700)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (ended)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'This session has already passed.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _cancelAssignment(req),
                                icon: const Icon(Icons.event_busy, color: Colors.red),
                                label: const Text('Cancel Assignment', style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red.shade200),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}