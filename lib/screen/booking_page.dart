import 'package:flutter/material.dart';
import 'admin_screen.dart';
import 'student_screen.dart';
import '../service/database_service.dart';
import 'app_drawer.dart';

class BookingPage extends StatefulWidget {
  final String userRole;
  final String username;

  const BookingPage({
    super.key,
    required this.userRole,
    required this.username,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int _refreshKey = 0; // Incremented to trigger immediate list refresh

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.userRole == 'admin';

    return DefaultTabController(
      length: isAdmin ? 4 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isAdmin
                ? 'Admin Booking Management'
                : 'Student Booking & Reservation',
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: isAdmin
                ? const [
              Tab(text: 'All Events & Workshops'),
              Tab(text: 'Pending Requests (Accept/Reject)'),
              Tab(text: 'Assign Interviewer / Advisor'),
              Tab(text: 'All Bookings & Cancellations'),
            ]
                : const [
              Tab(text: 'Workshops & Fairs'),
              Tab(text: 'Mock Interviews & Advisory'),
              Tab(text: 'My Booking Status'),
            ],
          ),
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
          onPressed: () async {
            // Navigate to full screen page instead of dialog
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateWorkshopScreen(),
              ),
            );

            // If an event was created, trigger immediate state refresh
            if (result == true) {
              setState(() {
                _refreshKey++;
              });
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('New Event'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        )
            : null,
        body: TabBarView(
          children: isAdmin
              ? [
            AdminWorkshopListView(
              key: ValueKey(_refreshKey), // Forces refresh when returning
              dbService: DatabaseService(),
            ),
            AdminPendingRequestsView(dbService: DatabaseService()),
            AdminAssignAdvisorView(dbService: DatabaseService()),
            AllBookingsView(dbService: DatabaseService()),
          ]
              : [
            StudentWorkshopListView(
              key: ValueKey(_refreshKey),
              username: widget.username,
            ),
            StudentBookingTab(
              bookingType: 'Mock Interview',
              username: widget.username,
            ),
            StudentHistoryTab(username: widget.username),
          ],
        ),
        drawer: AppDrawer(userRole: widget.userRole, username: widget.username)
      ),
    );
  }
}