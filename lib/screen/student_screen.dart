import 'dart:math';
import '../main.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as handler;
import '../service/database_service.dart';
import '../model/event_model.dart';
import '../model/event_registration_model.dart';
import '../model/mock_interview_model.dart';

class CampusLocation {
  final String name;
  final double? latitude;
  final double? longitude;

  const CampusLocation(this.name, {this.latitude, this.longitude});

  bool get hasCoordinates => latitude != null && longitude != null;
}

const List<CampusLocation> kCampusLocations = [
  CampusLocation('Main Library', latitude: 3.2173321637368133, longitude: 101.72759358871654),
  CampusLocation('Student Cafeteria', latitude: 3.214019495382605, longitude: 101.72680233705995),
  CampusLocation('Career Center Office', latitude: 3.2152768109484704, longitude: 101.7265622793334),
  CampusLocation('Auditorium', latitude: 3.2164591414335, longitude: 101.72951136816741),
  CampusLocation('Block N', latitude: 3.2172842372411377, longitude: 101.73042805834564),
  CampusLocation('Online (Video Call)'),
];

/// Haversine distance between two lat/lng points, in metres.
double _distanceInMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _deg2rad(double deg) => deg * (pi / 180);

// --- Shared date/time + status helpers (used across all views below) ------

/// Parses a time label that may be 24-hour ("14:00"), 12-hour with AM/PM
/// ("2:00 PM"), or already zero-padded ("09:00"). Returns null if it can't
/// be understood.
TimeOfDay? _parseFlexibleTimeLabel(String label) {
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

/// Combines a "yyyy-MM-dd" date string with an optional time label (plus an
/// optional duration) into a single DateTime for comparisons against "now".
/// If no time is given, or it can't be parsed, returns the very end of that
/// date (23:59:59) so a same-day item with no specific time is only
/// considered "over" once the whole day has passed.
DateTime? _combineDateAndTime(String date, String? timeLabel, {int durationMinutes = 0}) {
  final base = DateTime.tryParse(date);
  if (base == null) return null;

  if (timeLabel == null || timeLabel.trim().isEmpty) {
    return DateTime(base.year, base.month, base.day, 23, 59, 59);
  }

  final parsedTime = _parseFlexibleTimeLabel(timeLabel);
  if (parsedTime == null) {
    return DateTime(base.year, base.month, base.day, 23, 59, 59);
  }

  final start = DateTime(base.year, base.month, base.day, parsedTime.hour, parsedTime.minute);
  return start.add(Duration(minutes: durationMinutes));
}

/// Formats an assigned start time ("HH:MM") and duration (minutes) into a
/// display range like "10:00 - 11:00". Falls back to the raw assignedTime
/// string if it can't be parsed, and returns null if no time is assigned.
String? _formatTimeRange(String? assignedTime, int? durationMinutes) {
  if (assignedTime == null || assignedTime.isEmpty) return null;

  final parts = assignedTime.split(':');
  final startHour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final startMinute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
  if (startHour == null) return assignedTime; // Unrecognized format - show as-is.

  final duration = durationMinutes ?? 60; // Fall back to a 1-hour block if unknown.
  final startTotalMinutes = startHour * 60 + (startMinute ?? 0);
  final endTotalMinutes = startTotalMinutes + duration;

  String fmt(int totalMinutes) {
    final h = (totalMinutes ~/ 60) % 24;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  return '${fmt(startTotalMinutes)} - ${fmt(endTotalMinutes)}';
}

class _StatusDisplay {
  final String label;
  final Color color;
  const _StatusDisplay(this.label, this.color);
}

/// Maps a raw status + the item's end date/time into what's actually shown:
/// - Accepted, but the date/time has passed -> "ENDED"
/// - Anything else (e.g. still pending), but the date/time has passed -> "EXPIRED"
/// - Cancelled / Rejected always show as themselves, regardless of date
/// - Otherwise, the raw status is shown as-is (e.g. "PENDING", "ACCEPTED")
_StatusDisplay _resolveStatusDisplay(String rawStatus, DateTime? endDateTime) {
  final status = rawStatus.toLowerCase();
  final hasEnded = endDateTime != null && endDateTime.isBefore(DateTime.now());

  if (status == 'cancelled') {
    return const _StatusDisplay('CANCELLED', Colors.grey);
  }
  if (status == 'rejected') {
    return const _StatusDisplay('REJECTED', Colors.red);
  }
  if (status == 'accepted') {
    return hasEnded
        ? const _StatusDisplay('ENDED', Colors.grey)
        : const _StatusDisplay('ACCEPTED', Colors.green);
  }
  return hasEnded
      ? const _StatusDisplay('EXPIRED', Colors.grey)
      : _StatusDisplay(rawStatus.toUpperCase(), Colors.orange);
}

/// Whether a booking/reservation can still be cancelled by the student -
/// only while its displayed status is still (raw) pending or accepted.
bool _isCancellable(String rawStatus, DateTime? endDateTime) {
  final display = _resolveStatusDisplay(rawStatus, endDateTime).label;
  return display == 'ACCEPTED' || display == rawStatus.toUpperCase();
}

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

        final now = DateTime.now();

        // Filter out events whose date+time has already started/passed, not
        // just events before today - a workshop earlier today should also
        // disappear once its start time is behind us.
        final events = snapshot.data!.where((event) {
          final eventDateTime = _combineDateAndTime(event.date, event.time) ??
              DateTime.tryParse(event.date) ??
              now;
          return eventDateTime.isAfter(now);
        }).toList();

        // Check again after filtering
        if (events.isEmpty) {
          return const Center(child: Text('No upcoming workshops right now.'));
        }

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

class StudentBookingTab extends StatefulWidget {
  final String bookingType;
  final String username;

  const StudentBookingTab({
    super.key,
    required this.bookingType,
    required this.username,
  });

  @override
  State<StudentBookingTab> createState() => _StudentBookingTabState();
}

class _StudentBookingTabState extends State<StudentBookingTab> {
  int _refreshKey = 0;

  void _showNewRequestDialog(BuildContext context) {
    String selectedType = 'Mock Interview';
    DateTime? selectedDate;

    // Preferred location is now chosen from a dropdown of known campus
    // locations, optionally auto-selected via "Select nearest location".
    String? selectedLocation;
    bool isDetectingLocation = false;
    String? formError; // Inline validation message - always visible, never hidden behind the sheet
    final notesController = TextEditingController();

    const String kNearestLocationOption = '📍 Select nearest location';

    // Uses the `location` + `permission_handler` packages (see Practical 13)
    // to read the device's current GPS position, then picks whichever
    // CampusLocation is closest by straight-line distance.
    Future<void> selectNearestLocation(
        void Function(void Function()) setModalState,
        BuildContext sheetContext,
        ) async {
      setModalState(() {
        isDetectingLocation = true;
        formError = null;
      });
      try {
        final locationService = loc.Location();

        bool gpsEnabled = await locationService.serviceEnabled();
        if (!gpsEnabled) {
          gpsEnabled = await locationService.requestService();
          if (!gpsEnabled) {
            setModalState(() => formError = 'Please enable GPS/location services.');
            return;
          }
        }

        handler.PermissionStatus permissionStatus =
        await handler.Permission.locationWhenInUse.status;
        if (!permissionStatus.isGranted) {
          permissionStatus =
          await handler.Permission.locationWhenInUse.request();
          if (!permissionStatus.isGranted) {
            setModalState(() => formError =
            'Location permission is required to detect the nearest location.');
            return;
          }
        }

        final currentLocation = await locationService.getLocation();
        final userLat = currentLocation.latitude;
        final userLng = currentLocation.longitude;

        if (userLat == null || userLng == null) return;

        CampusLocation? nearest;
        double? nearestDistance;
        for (final campusLocation in kCampusLocations) {
          if (!campusLocation.hasCoordinates) continue; // e.g. 'Online'
          final distance = _distanceInMeters(
            userLat,
            userLng,
            campusLocation.latitude!,
            campusLocation.longitude!,
          );
          if (nearestDistance == null || distance < nearestDistance) {
            nearestDistance = distance;
            nearest = campusLocation;
          }
        }

        if (nearest != null) {
          setModalState(() {
            selectedLocation = nearest!.name;
            formError =
            'Selected "${nearest!.name}" (${(nearestDistance! / 1000).toStringAsFixed(1)} km away)';
          });
        }
      } catch (e) {
        setModalState(() => formError = 'Could not detect location: $e');
      } finally {
        setModalState(() => isDetectingLocation = false);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Request Session',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Session Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Mock Interview', 'Career Advisory']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker (Full Width Now)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(selectedDate == null
                        ? 'Pick Date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                  ),
                  const SizedBox(height: 16),

                  // Preferred Location Field - a dropdown of preset campus
                  // locations, plus a "Select nearest location" entry that
                  // triggers GPS detection instead of setting a value directly.
                  DropdownButtonFormField<String>(
                    value: selectedLocation,
                    decoration: InputDecoration(
                      labelText: 'Preferred Location *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: isDetectingLocation
                          ? const Padding(
                        padding: EdgeInsets.all(14.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : null,
                    ),
                    hint: const Text('Choose a location'),
                    items: [
                      const DropdownMenuItem(
                        value: kNearestLocationOption,
                        child: Text(
                          kNearestLocationOption,
                          style: TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...kCampusLocations.map((campusLocation) => DropdownMenuItem(
                        value: campusLocation.name,
                        child: Text(campusLocation.name),
                      )),
                    ],
                    onChanged: isDetectingLocation
                        ? null
                        : (val) {
                      if (val == kNearestLocationOption) {
                        // Don't select the sentinel itself - detect instead.
                        selectNearestLocation(setModalState, context);
                      } else {
                        setModalState(() {
                          selectedLocation = val;
                          formError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Specific focus (Optional)',
                      hintText: 'e.g. Focus on technical questions...',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  // Inline feedback - always visible, sits right in the sheet's
                  // own layout instead of a SnackBar that can get hidden behind it.
                  if (formError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      formError!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (selectedDate == null || selectedLocation == null) {
                        setModalState(() =>
                        formError = 'Please select a date and a preferred location');
                        return;
                      }

                      final dateStr = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

                      // Updated Model Call
                      final newRequest = MockInterviewModel(
                        username: widget.username,
                        requestType: selectedType,
                        date: dateStr,
                        preferredLocation: selectedLocation,
                        notes: notesController.text.trim(),
                      );

                      await DatabaseService().insertMockInterviewRequest(newRequest);

                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        rootScaffoldMessengerKey.currentState!.showSnackBar(
                            const SnackBar(content: Text('Request submitted successfully'), backgroundColor: Colors.green));
                        setState(() {
                          _refreshKey++;
                        });
                      }
                    },
                    child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // We use a Scaffold inside the tab to easily anchor the FloatingActionButton to the bottom right
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewRequestDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<MockInterviewModel>>(
        key: ValueKey(_refreshKey), // Put back your refresh key
        future: DatabaseService().getStudentMockInterviews(widget.username),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_ind_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No requests found.\nTap "New Request" to book a session.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 80), // Padding bottom for FAB
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return _MockInterviewCard(
                key: ValueKey(req.id),
                request: req,
                onCancelled: () => setState(() => _refreshKey++),
              );
            },
          );
        },
      ),
    );
  }
}

// A mock-interview/advisory request card that slides left on tap to reveal a
// "Cancel" button behind it, mirroring the feedback-list reveal pattern.
// Only cancellable (still pending/accepted, not yet ended) requests get the
// slide affordance; anything ended/expired/rejected/cancelled renders as a
// plain static card.
class _MockInterviewCard extends StatefulWidget {
  final MockInterviewModel request;
  final VoidCallback onCancelled;

  const _MockInterviewCard({
    super.key,
    required this.request,
    required this.onCancelled,
  });

  @override
  State<_MockInterviewCard> createState() => _MockInterviewCardState();
}

class _MockInterviewCardState extends State<_MockInterviewCard> {
  bool _isRevealed = false;
  static const double _revealWidth = 100;

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text('Are you sure you want to cancel this reservation? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (widget.request.id != null) {
                await DatabaseService().cancelMockInterview(widget.request.id!);
                widget.onCancelled();
              }
            },
            child: const Text('Cancel Reservation', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final endDateTime = _combineDateAndTime(req.date, req.assignedTime, durationMinutes: req.durationMinutes ?? 0);
    final statusDisplay = _resolveStatusDisplay(req.status, endDateTime);
    final canCancel = _isCancellable(req.status, endDateTime);

    final card = Card(
      margin: EdgeInsets.zero,
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
                  req.requestType,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusDisplay.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusDisplay.color.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusDisplay.label,
                    style: TextStyle(color: statusDisplay.color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Location: ${req.preferredLocation ?? "N/A"}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(req.date),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_formatTimeRange(req.assignedTime, req.durationMinutes) ?? 'Time TBD'),
              ],
            ),
            if (req.advisor != null && req.advisor!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Advisor: ${req.advisor}'),
                ],
              ),
            ],
            if (req.venue != null && req.venue!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.meeting_room, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Assigned Venue: ${req.venue}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
                    ),
                  ),
                ],
              ),
            ],
            if (req.notes != null && req.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Notes: ${req.notes}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            ],
            if (canCancel) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '← Tap to cancel',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!canCancel) {
      // Not cancellable (ended/expired/rejected/cancelled already) - plain
      // static card, no slide/cancel affordance.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: card,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          // Cancel button revealed behind the card once slid open.
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: _revealWidth,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.event_busy, color: Colors.white),
                      tooltip: 'Cancel Reservation',
                      onPressed: () => _confirmCancel(context),
                    ),
                    const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          // Foreground card - slides left on tap to reveal the button above.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_isRevealed ? -_revealWidth : 0, 0, 0),
            child: GestureDetector(
              onTap: () => setState(() => _isRevealed = !_isRevealed),
              child: card,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentBookingStatusView extends StatefulWidget {
  final DatabaseService dbService;
  final String username;

  const StudentBookingStatusView({
    super.key,
    required this.dbService,
    required this.username,
  });

  @override
  State<StudentBookingStatusView> createState() => _StudentBookingStatusViewState();
}

class _StudentBookingStatusViewState extends State<StudentBookingStatusView> {
  bool _isHistoryTab = false;
  String _sortOrder = 'Newest';
  String _filterTimeline = 'All';
  String _filterStatus = 'All';

  void _confirmCancelBooking(BuildContext sheetContext, EventRegistrationModel r) {
    showDialog(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close confirm dialog
              await widget.dbService.updateRegistrationStatus(r.registrationId, r.eventId, 'cancelled');
              if (mounted) {
                Navigator.pop(sheetContext); // Close the details bottom sheet
                setState(() {}); // Refresh the list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking cancelled.')),
                );
              }
            },
            child: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRegisteredEventDetails(BuildContext context, EventModel event, EventRegistrationModel r) {
    final eventDateTime = _combineDateAndTime(event.date, event.time);
    final statusDisplay = _resolveStatusDisplay(r.status, eventDateTime);
    final canCancel = _isCancellable(r.status, eventDateTime);

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
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
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: statusDisplay.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusDisplay.color.withOpacity(0.4)),
                  ),
                  child: Text(
                    'Status: ${statusDisplay.label}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusDisplay.color),
                  ),
                ),
                if (canCancel) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          )
                      ),
                      onPressed: () => _confirmCancelBooking(sheetContext, r),
                      icon: const Icon(Icons.event_busy),
                      label: const Text(
                          'Cancel Booking',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sort By Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 12,
                    children: ['Newest', 'Oldest'].map((sort) {
                      return ChoiceChip(
                        label: Text(sort),
                        selected: _sortOrder == sort,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => _sortOrder = sort);
                            setState(() => _sortOrder = sort);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Filter by Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 12,
                    children: ['All', 'Future', 'Past'].map((timeline) {
                      return ChoiceChip(
                        label: Text(timeline),
                        selected: _filterTimeline == timeline,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => _filterTimeline = timeline);
                            setState(() => _filterTimeline = timeline);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Filter by Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 12,
                    children: ['All', 'Accepted', 'Pending', 'Rejected', 'Cancelled'].map((status) {
                      return ChoiceChip(
                        label: Text(status),
                        selected: _filterStatus == status,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => _filterStatus = status);
                            setState(() => _filterStatus = status);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply & Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isHistoryTab = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isHistoryTab ? Colors.indigo : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: !_isHistoryTab
                            ? [const BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Booking Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isHistoryTab ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isHistoryTab = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isHistoryTab ? Colors.indigo : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isHistoryTab
                            ? [const BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Booking History',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isHistoryTab ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isHistoryTab ? 'All Records' : 'Current Bookings',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                onPressed: _showFilterModal,
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('Sort & Filter'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: FutureBuilder<List<EventRegistrationModel>>(
            future: widget.dbService.getAllRegistrations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No booking records found.'));
              }

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              List<EventRegistrationModel> myRegistrations = snapshot.data!
                  .where((r) => r.username == widget.username)
                  .toList();

              if (!_isHistoryTab) {
                myRegistrations = myRegistrations.where((r) {
                  final eventDate = DateTime.tryParse(r.date) ?? today;
                  return eventDate.isAfter(today.subtract(const Duration(days: 1)));
                }).toList();
              }

              if (_filterTimeline == 'Future') {
                myRegistrations = myRegistrations.where((r) {
                  final eventDate = DateTime.tryParse(r.date) ?? today;
                  return eventDate.isAfter(today.subtract(const Duration(days: 1)));
                }).toList();
              } else if (_filterTimeline == 'Past') {
                myRegistrations = myRegistrations.where((r) {
                  final eventDate = DateTime.tryParse(r.date) ?? today;
                  return eventDate.isBefore(today);
                }).toList();
              }

              if (_filterStatus != 'All') {
                myRegistrations = myRegistrations.where((r) {
                  return r.status.toLowerCase() == _filterStatus.toLowerCase();
                }).toList();
              }

              myRegistrations.sort((a, b) {
                final dateA = DateTime.tryParse(a.date) ?? today;
                final dateB = DateTime.tryParse(b.date) ?? today;
                if (_sortOrder == 'Newest') {
                  return dateB.compareTo(dateA);
                } else {
                  return dateA.compareTo(dateB);
                }
              });

              if (myRegistrations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No records match your current filters.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: myRegistrations.length,
                itemBuilder: (context, index) {
                  final r = myRegistrations[index];
                  final eventDateTime = _combineDateAndTime(r.date, r.time);
                  final statusDisplay = _resolveStatusDisplay(r.status, eventDateTime);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        // Fetch the full event details from the database
                        final event = await widget.dbService.getEventById(r.eventId);

                        if (mounted) {
                          if (event != null) {
                            _showRegisteredEventDetails(context, event, r);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Event details are no longer available (deleted by admin).'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    r.eventTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusDisplay.color.withOpacity(0.1),
                                    border: Border.all(color: statusDisplay.color.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusDisplay.label,
                                    style: TextStyle(
                                      color: statusDisplay.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('${r.date} at ${r.time}', style: TextStyle(color: Colors.grey.shade700)),
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
          ),
        ),
      ],
    );
  }
}