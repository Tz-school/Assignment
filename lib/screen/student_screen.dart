import 'package:flutter/material.dart';
import '../service/database_service.dart';
import '../model/event_model.dart';
import '../model/event_registration_model.dart';
import '../model/booking_model.dart';

class StudentWorkshopListView extends StatefulWidget {
  final String username;
  const StudentWorkshopListView({super.key, required this.username});

  @override
  State<StudentWorkshopListView> createState() => _StudentWorkshopListViewState();
}

class _StudentWorkshopListViewState extends State<StudentWorkshopListView> {

  void _showEventDetails(BuildContext context, EventModel event) {
    final int available = event.capacity - event.booked;
    final bool isFull = available <= 0;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    event.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.indigo),
                  title: const Text('Speaker / Advisor'),
                  subtitle: Text(event.speaker),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.indigo),
                  title: const Text('Venue'),
                  subtitle: Text(event.venue),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                  title: const Text('Date & Time'),
                  subtitle: Text('${event.date} at ${event.time}'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: isFull ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isFull ? Colors.red.shade200 : Colors.green.shade200
                      )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Available Slots:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFull ? Colors.red.shade700 : Colors.green.shade700
                          )
                      ),
                      Text(
                          isFull ? 'FULL' : '$available / ${event.capacity}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isFull ? Colors.red.shade700 : Colors.green.shade700
                          )
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isFull ? Colors.grey : Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                        )
                    ),
                    onPressed: isFull
                        ? null
                        : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final userId = await DatabaseService().getUserId(widget.username);

                      if (userId != null && event.id != null) {
                        final alreadyRegistered = await DatabaseService()
                            .hasUserRegistered(userId, event.id!);

                        if (alreadyRegistered) {
                          if (mounted) {
                            Navigator.pop(context);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('You have already registered for this event.'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                          return;
                        }

                        await DatabaseService().registerForEvent(userId, event.id!);

                        if (mounted) {
                          Navigator.pop(context);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Registration submitted! Waiting for Admin approval.'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          setState(() {});
                        }
                      }
                    },
                    child: Text(
                        isFull ? 'Event is Full' : 'Reserve My Slot',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                )
              ],
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventModel>>(
      future: DatabaseService().getEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No upcoming workshops right now.'));
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showEventDetails(context, event),
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
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${event.date} • ${event.time}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                          Icons.chevron_right,
                          color: isFull ? Colors.red.shade300 : Colors.grey.shade400
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

class StudentBookingTab extends StatelessWidget {
  final String bookingType;
  final String username;

  const StudentBookingTab({
    super.key,
    required this.bookingType,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            bookingType == 'Career Workshop'
                ? Icons.work
                : Icons.record_voice_over,
            size: 64,
            color: Colors.indigo,
          ),
          const SizedBox(height: 16),
          Text(
            'Book a $bookingType',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final newBooking = BookingModel(
                studentName: username,
                bookingType: bookingType,
                date: '2026-09-10',
                status: 'Pending',
              );
              await DatabaseService().insertBooking(newBooking);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Requested booking for $bookingType!')),
              );
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}

class StudentHistoryTab extends StatefulWidget {
  final String username;
  const StudentHistoryTab({super.key, required this.username});

  @override
  State<StudentHistoryTab> createState() => _StudentHistoryTabState();
}

class _StudentHistoryTabState extends State<StudentHistoryTab> {
  Future<List<EventRegistrationModel>> _fetchMyRegistrations() async {
    final userId = await DatabaseService().getUserId(widget.username);
    if (userId == null) return [];
    return await DatabaseService().getUserRegistrations(userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventRegistrationModel>>(
      future: _fetchMyRegistrations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final myBookings = snapshot.data!;

        if (myBookings.isEmpty) {
          return const Center(child: Text('No booking requests found.'));
        }

        return ListView.builder(
          itemCount: myBookings.length,
          itemBuilder: (context, index) {
            final booking = myBookings[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(booking.eventTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Date: ${booking.date} • ${booking.time}'),
                trailing: Chip(
                  label: Text(booking.status.toUpperCase()),
                  backgroundColor: booking.status == 'accepted'
                      ? Colors.green.shade100
                      : booking.status == 'rejected'
                      ? Colors.red.shade100
                      : Colors.orange.shade100,
                ),
              ),
            );
          },
        );
      },
    );
  }
}