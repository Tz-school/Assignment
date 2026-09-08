import 'package:flutter/material.dart';
import '../service/database_service.dart';
import '../model/event_model.dart';
import '../model/event_registration_model.dart';
import '../model/booking_model.dart';

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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    _speakerController.dispose();
    _venueController.dispose();
    _limitController.dispose();
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
  State<AdminPendingRequestsView> createState() =>
      _AdminPendingRequestsViewState();
}

class _AdminPendingRequestsViewState extends State<AdminPendingRequestsView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventRegistrationModel>>(
      future: widget.dbService.getAllRegistrations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingList = snapshot.data!
            .where((r) => r.status == 'pending')
            .toList();

        if (pendingList.isEmpty) {
          return const Center(child: Text('No pending requests to review.'));
        }

        return ListView.builder(
          itemCount: pendingList.length,
          itemBuilder: (context, index) {
            final r = pendingList[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('${r.eventTitle} - ${r.username}'),
                subtitle: Text('Requested Date: ${r.date} at ${r.time}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        await widget.dbService.updateRegistrationStatus(
                            r.registrationId, r.eventId, 'accepted'
                        );

                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Registration for ${r.username} accepted!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          setState(() {});
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        await widget.dbService.updateRegistrationStatus(
                            r.registrationId, r.eventId, 'rejected'
                        );

                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Registration for ${r.username} rejected.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() {});
                        }
                      },
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

class AdminAssignAdvisorView extends StatefulWidget {
  final DatabaseService dbService;
  const AdminAssignAdvisorView({super.key, required this.dbService});

  @override
  State<AdminAssignAdvisorView> createState() => _AdminAssignAdvisorViewState();
}

class _AdminAssignAdvisorViewState extends State<AdminAssignAdvisorView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookingModel>>(
      future: widget.dbService.getBookings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final approvedList = snapshot.data!
            .where((b) => b.status == 'Approved')
            .toList();

        if (approvedList.isEmpty)
          return const Center(
            child: Text('No approved bookings ready for assignment.'),
          );

        return ListView.builder(
          itemCount: approvedList.length,
          itemBuilder: (context, index) {
            final b = approvedList[index];
            return Card(
              child: ListTile(
                title: Text('${b.studentName} (${b.bookingType})'),
                subtitle: Text('Assigned: ${b.assignedAdvisor ?? "None"}'),
                trailing: ElevatedButton(
                  child: const Text('Assign Advisor'),
                  onPressed: () async {
                    b.assignedAdvisor = 'Dr. Smith (HR Manager)';
                    await widget.dbService.editBooking(b);
                    setState(() {});
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