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
      // Changed length to 2 for students
      length: isAdmin ? 4 : 2,
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
              ],
            ),
          ),
          // UPDATED FLOATING ACTION BUTTON
          floatingActionButton: isAdmin
              ? Builder(
            builder: (context) {
              // Get the nearest TabController from the DefaultTabController
              final TabController tabController = DefaultTabController.of(context);

              // Use AnimatedBuilder to listen to tab changes
              return AnimatedBuilder(
                animation: tabController,
                builder: (context, child) {
                  // Check if the current tab is index 0 ("All Events & Workshops")
                  return tabController.index == 0
                      ? FloatingActionButton.extended(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateWorkshopScreen(),
                        ),
                      );

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
                      : const SizedBox.shrink(); // Hide the FAB on other tabs
                },
              );
            },
          )
              : null,
          body: TabBarView(
            children: isAdmin
                ? [
              AdminWorkshopListView(
                key: ValueKey(_refreshKey),
                dbService: DatabaseService(),
              ),
              AdminPendingRequestsView(dbService: DatabaseService()),
              AdminAssignAdvisorView(dbService: DatabaseService()),
              AllBookingsView(dbService: DatabaseService()),
            ]
                : [
              // Use a nested widget for the sub-tabs
              StudentWorkshopsParentTab(
                username: widget.username,
                refreshKey: _refreshKey,
              ),
              StudentBookingTab(
                bookingType: 'Mock Interview',
                username: widget.username,
              ),
            ],
          ),
          drawer: AppDrawer(userRole: widget.userRole, username: widget.username)
      ),
    );
  }
}

class StudentWorkshopsParentTab extends StatelessWidget {
  final String username;
  final int refreshKey;

  const StudentWorkshopsParentTab({
    super.key,
    required this.username,
    required this.refreshKey,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Colors.indigo,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                labelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelColor: Colors.grey.shade700,
                tabs: const [
                  Tab(text: 'All Events'),
                  Tab(text: 'My Bookings'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                StudentWorkshopListView(
                  key: ValueKey(refreshKey),
                  username: username,
                ),
                StudentBookingStatusView(
                  dbService: DatabaseService(),
                  username: username,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}