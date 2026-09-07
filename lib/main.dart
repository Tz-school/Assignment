import 'package:flutter/material.dart';
import 'booking_model.dart';
import 'database_service.dart';


void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career & Industry Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Set LoginScreen as the starting page
      home: const LoginScreen(),
    );
  }
}


// ==========================================
// 1. LOGIN SCREEN (AUTHENTICATION)
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegistering = false; // Toggles between Login and Register views

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character.';
    }
    return null;
  }

  void _submitForm() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_isRegistering) {
      // --- REGISTRATION LOGIC ---
      final confirmPassword = _confirmPasswordController.text.trim();

      // 1. Validate Password Strength
      final passwordError = _validatePassword(password);
      if (passwordError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(passwordError)));
        return; // Stop the registration process
      }


      // 2. Check if passwords match
      if (password != confirmPassword) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }


      // 3. Register the user
      try {
        await DatabaseService().registerUser(username, password, 'student');


        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Logging in...'),
          ),
        );


        _navigateToMain(username: username, role: 'student');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already exists!')),
        );
      }
    } else {
      // --- LOGIN LOGIC WITH HARDCODED ADMIN ---


      // 1. HARDCODED ADMIN CHECK
      if (username == 'admin' && password == 'admin123') {
        _navigateToMain(username: 'System Admin', role: 'admin');
        return;
      }


      // 2. CHECK DATABASE FOR OTHER USERS (Registered Students)
      final user = await DatabaseService().loginUser(username, password);
      if (user != null) {
        _navigateToMain(username: user['username'], role: user['role']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      }
    }
  }


  void _navigateToMain({required String username, required String role}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MainNavigationScreen(userRole: role, username: username),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school, size: 64, color: Colors.indigo),
                  const SizedBox(height: 16),
                  Text(
                    _isRegistering
                        ? 'Create Student Account'
                        : 'Career & Industry Portal',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),


                  // Username Field
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),


                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),


                  // Confirm Password Field (Only shown during registration)
                  if (_isRegistering) ...[
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],


                  // Submit Button
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isRegistering ? 'Register' : 'Login',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),


                  // Mode Toggle Button (Login <-> Register)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                      });
                    },
                    child: Text(
                      _isRegistering
                          ? 'Already have an account? Login here'
                          : "Don't have an account? Register here",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ==========================================
// 2. MAIN NAVIGATION (Role-Aware)
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  final String userRole;
  final String username;


  const MainNavigationScreen({
    super.key,
    required this.userRole,
    required this.username,
  });


  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}


class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;


  @override
  Widget build(BuildContext context) {
    // Dynamic pages based on passing user details
    final List<Widget> pages = [
      HomePage(userRole: widget.userRole, username: widget.username),
      const DataAnalysisPage(),
      BookingPage(userRole: widget.userRole, username: widget.username),
      const IndustryPage(),
    ];


    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Data Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Industry',
          ),
        ],
      ),
    );
  }
}


// ==========================================
// 3. HOME PAGE (with Logout option)
// ==========================================
class HomePage extends StatelessWidget {
  final String userRole;
  final String username;


  const HomePage({super.key, required this.userRole, required this.username});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $username'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Logged in as: ${userRole.toUpperCase()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Home Content'),
          ],
        ),
      ),
    );
  }
}


// ==========================================
// 4. DATA ANALYSIS PAGE
// ==========================================
class DataAnalysisPage extends StatelessWidget {
  const DataAnalysisPage({super.key});


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Analysis'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Average Income Analysis'),
              Tab(text: 'District GDP Analysis'),
              Tab(text: 'Purchasing Power Analysis'),
              Tab(text: 'Course to Career ROI Calculator'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Average Income Analysis Content')),
            Center(child: Text('District GDP Analysis Content')),
            Center(child: Text('Purchasing Power Analysis Content')),
            Center(child: Text('Course to Career ROI Calculator Content')),
          ],
        ),
      ),
    );
  }
}


// ==========================================
// 5. MODULE 2: BOOKING AND RESERVATION (ROLE-BASED)
// ==========================================
class BookingPage extends StatelessWidget {
  final String userRole;
  final String username;


  const BookingPage({
    super.key,
    required this.userRole,
    required this.username,
  });


  @override
  Widget build(BuildContext context) {
    final bool isAdmin = userRole == 'admin';


    return DefaultTabController(
      length: 3,
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
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const CreateWorkshopDialog(),
            );
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
            AdminPendingRequestsView(dbService: DatabaseService()),
            AdminAssignAdvisorView(dbService: DatabaseService()),
            AllBookingsView(dbService: DatabaseService()),
          ]
              : [
            StudentWorkshopListView(username: username),


            StudentBookingTab(
              bookingType: 'Mock Interview',
              username: username,
            ),
            StudentHistoryTab(username: username),
          ],
        ),
      ),
    );
  }
}


// --- STUDENT TAB: Make a Booking ---
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


// --- STUDENT TAB: My Booking Status ---
class StudentHistoryTab extends StatefulWidget {
  final String username;
  const StudentHistoryTab({super.key, required this.username});


  @override
  State<StudentHistoryTab> createState() => _StudentHistoryTabState();
}


class _StudentHistoryTabState extends State<StudentHistoryTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookingModel>>(
      future: DatabaseService().getBookings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());


        // Filter bookings belonging to this student
        final myBookings = snapshot.data!
            .where((b) => b.studentName == widget.username)
            .toList();


        if (myBookings.isEmpty)
          return const Center(child: Text('No booking requests found.'));


        return ListView.builder(
          itemCount: myBookings.length,
          itemBuilder: (context, index) {
            final booking = myBookings[index];
            return Card(
              child: ListTile(
                title: Text(booking.bookingType),
                subtitle: Text(
                  'Date: ${booking.date}\nAdvisor: ${booking.assignedAdvisor ?? "Not assigned yet"}',
                ),
                trailing: Chip(
                  label: Text(booking.status),
                  backgroundColor: booking.status == 'Approved'
                      ? Colors.green.shade100
                      : booking.status == 'Rejected'
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


// --- ADMIN TAB 1: Accept or Reject ---
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
    return FutureBuilder<List<BookingModel>>(
      future: widget.dbService.getBookings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final pendingList = snapshot.data!
            .where((b) => b.status == 'Pending')
            .toList();


        if (pendingList.isEmpty)
          return const Center(child: Text('No pending requests to review.'));


        return ListView.builder(
          itemCount: pendingList.length,
          itemBuilder: (context, index) {
            final b = pendingList[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('${b.bookingType} - ${b.studentName}'),
                subtitle: Text('Requested Date: ${b.date}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        b.status = 'Approved';
                        await widget.dbService.editBooking(b);
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        b.status = 'Rejected';
                        await widget.dbService.editBooking(b);
                        setState(() {});
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


// --- ADMIN TAB 2: Arrange Interviewers & Advisors ---
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


// --- ADMIN TAB 3: All Bookings & Cancel Action ---
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


// ==========================================
// 6. INDUSTRY PAGE
// ==========================================
class IndustryPage extends StatelessWidget {
  const IndustryPage({super.key});


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Industry'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Resume Builder'),
              Tab(text: 'Job Seeker'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Resume Builder Content')),
            Center(child: Text('Job Seeker Content')),
          ],
        ),
      ),
    );
  }
}


// ==========================================
// 7. ADMIN: CREATE EVENT DIALOG
// ==========================================
class CreateWorkshopDialog extends StatefulWidget {
  const CreateWorkshopDialog({super.key});


  @override
  State<CreateWorkshopDialog> createState() => _CreateWorkshopDialogState();
}


class _CreateWorkshopDialogState extends State<CreateWorkshopDialog> {
  final _titleController = TextEditingController();
  final _speakerController = TextEditingController();
  final _venueController = TextEditingController();
  final _limitController = TextEditingController();


  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;


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

    final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

    final newEvent = EventModel(
      title: _titleController.text.trim(),
      speaker: _speakerController.text.trim(),
      venue: _venueController.text.trim(),
      date: dateStr,
      time: _selectedTime!.format(context),
      capacity: int.parse(_limitController.text.trim()),
    );

    await DatabaseService().insertEvent(newEvent);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Workshop'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title *',
                hintText: 'e.g. Resume Masterclass',
              ),
            ),
            TextField(
              controller: _speakerController,
              decoration: const InputDecoration(
                labelText: 'Speaker / Advisor',
                hintText: 'e.g. Dr. Smith',
              ),
            ),
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Venue / Link',
                hintText: 'e.g. Room 302 or Zoom',
              ),
            ),
            TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Booking Limit (Pax) *',
                hintText: 'e.g. 30',
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
            const SizedBox(height: 8),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveEvent,
          child: const Text('Create Event'),
        ),
      ],
    );
  }
}

// ==========================================
// 8. STUDENT: WORKSHOP LIST & DETAILS
// ==========================================
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
                    onPressed: isFull ? null : () async {
                      // 1. Create the booking record
                      final newBooking = BookingModel(
                        studentName: widget.username,
                        bookingType: 'Workshop: ${event.title}',
                        date: event.date,
                        status: 'Approved',
                      );
                      await DatabaseService().insertBooking(newBooking);

                      // 2. Increment the booked count for the event
                      if (event.id != null) {
                        await DatabaseService().incrementEventBooking(event.id!, event.booked);
                      }

                      if (context.mounted) {
                        Navigator.pop(context); // Close bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Slot reserved successfully!')),
                        );
                        setState(() {}); // Refresh the list view to show updated capacity
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