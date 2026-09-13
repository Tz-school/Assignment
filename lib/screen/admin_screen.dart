import 'package:flutter/material.dart';
import '../service/database_service.dart';
import '../model/event_model.dart';
import '../model/event_registration_model.dart';
import '../model/booking_model.dart';
import '../model/mock_interview_model.dart';
import '../model/timetable_model.dart';

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
            FutureBuilder<List<String>>(
              future: widget.dbService.getAcceptedParticipants(widget.event.id!),
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
                    final username = participants[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          username,
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
    List<EventRegistrationModel> list = _allRegistrations
        .where((r) => r.status.toLowerCase() == 'pending')
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

  // Updated to use registrationId & eventId matching DatabaseService
  void _updateStatus(int registrationId, int eventId, String newStatus) async {
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
    for (String key in _selectedKeys) {
      final parts = key.split('_');
      final regId = int.parse(parts[0]);
      final eventId = int.parse(parts[1]);
      await widget.dbService.updateRegistrationStatus(regId, eventId, newStatus);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedKeys.length} requests $newStatus successfully.'),
          backgroundColor: newStatus == 'accepted' ? Colors.green : Colors.red,
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

class AdminAssignAdvisorView extends StatefulWidget {
  final DatabaseService dbService;
  const AdminAssignAdvisorView({super.key, required this.dbService});

  @override
  State<AdminAssignAdvisorView> createState() => _AdminAssignAdvisorViewState();
}

class _AdminAssignAdvisorViewState extends State<AdminAssignAdvisorView> {

  void _showAssignDialog(BuildContext context, MockInterviewModel request) async {
    final counselors = await widget.dbService.getCareerCounselors();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String? selectedCounselor;
            String? selectedTime;
            int selectedDuration = 30;
            final venueController = TextEditingController();

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
                        decoration: const InputDecoration(labelText: 'Select Counselor', border: OutlineInputBorder()),
                        items: counselors.map((c) => DropdownMenuItem(
                          value: c['username'] as String,
                          child: Text(c['username'] as String),
                        )).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedCounselor = val;
                            selectedTime = null; // Reset time when advisor changes
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Timetable Graph (Only shows if an advisor is selected)
                      if (selectedCounselor != null) ...[
                        const Text('Advisor Timetable (Tap an available slot):', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: FutureBuilder<List<TimetableSlot>>(
                            future: widget.dbService.getAdvisorTimetable(selectedCounselor!, request.date),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                              final slots = snapshot.data!;
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: slots.length,
                                itemBuilder: (context, index) {
                                  final slot = slots[index];
                                  final isSelected = selectedTime == slot.timeLabel;

                                  return GestureDetector(
                                    onTap: slot.isBooked ? null : () {
                                      setDialogState(() => selectedTime = slot.timeLabel);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: slot.isBooked
                                            ? Colors.red.shade100
                                            : (isSelected ? Colors.indigo : Colors.green.shade100),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: slot.isBooked ? Colors.red : (isSelected ? Colors.indigo : Colors.green),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          slot.timeLabel,
                                          style: TextStyle(
                                            color: slot.isBooked
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

                        // 3. Venue & Duration Assignments
                        TextField(
                          controller: venueController,
                          decoration: const InputDecoration(
                            labelText: 'Assigned Venue / Link',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedDuration,
                          decoration: const InputDecoration(labelText: 'Duration', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 30, child: Text('30 Minutes')),
                            DropdownMenuItem(value: 60, child: Text('1 Hour')),
                            DropdownMenuItem(value: 90, child: Text('1.5 Hours')),
                          ],
                          onChanged: (val) => setDialogState(() => selectedDuration = val!),
                        ),
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
                  onPressed: (selectedCounselor == null || selectedTime == null || venueController.text.isEmpty)
                      ? null
                      : () async {
                    if (request.id != null) {
                      await widget.dbService.assignAdvisorWithDetails(
                        request.id!,
                        selectedCounselor!,
                        selectedTime!,
                        venueController.text.trim(),
                        selectedDuration,
                      );

                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Advisor assigned and scheduled successfully!'), backgroundColor: Colors.green),
                        );
                        setState(() {}); // Refresh parent list
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MockInterviewModel>>(
      future: widget.dbService.getAllMockInterviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No session requests found.'));
        }

        // Only show requests that haven't been assigned/accepted yet
        final pendingRequests = snapshot.data!
            .where((r) => r.status.toLowerCase() == 'pending')
            .toList();

        if (pendingRequests.isEmpty) {
          return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text('All requests have been assigned!',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              )
          );
        }

        return ListView.builder(
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
        );
      },
    );
  }
}

class AllBookingsView extends StatefulWidget {
  final DatabaseService dbService;
  const AllBookingsView({super.key, required this.dbService});

  @override
  State<AllBookingsView> createState() => _AllBookingsViewState();
}

class _AllBookingsViewState extends State<AllBookingsView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookingModel>>(
      future: widget.dbService.getBookings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final b = snapshot.data![index];
            return Card(
              child: ListTile(
                title: Text('${b.bookingType} - ${b.studentName}'),
                subtitle: Text('Status: ${b.status} | Date: ${b.date}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () async {
                    if (b.id != null) {
                      await widget.dbService.deleteBooking(b.id!);
                      setState(() {});
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}