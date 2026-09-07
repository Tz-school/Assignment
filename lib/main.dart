import 'package:flutter/material.dart';
import 'booking_model.dart';
import 'database_service.dart';
import 'event_registration_model.dart';

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
// 3. HOME PAGE (with Drawer: Profile / Edit / Feedback / Logout)
// ==========================================
class HomePage extends StatelessWidget {
  final String userRole;
  final String username;


  const HomePage({super.key, required this.userRole, required this.username});


  void _confirmLogout(BuildContext context) {
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
                Navigator.pop(context); // Close the drawer
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
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $username'),
        // Setting a `drawer` automatically shows the hamburger/menu
        // icon in the AppBar, replacing the old standalone logout button.
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // --- Profile Header: picture + username ---
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.indigo),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.indigo,
                  ),
                ),
                accountName: Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                accountEmail: Text(userRole.toUpperCase()),
              ),


              // --- Edit Profile ---
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.indigo),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        username: username,
                      ),
                    ),
                  );
                },
              ),


              // --- Submit Feedback ---
              ListTile(
                leading: const Icon(Icons.feedback_outlined, color: Colors.indigo),
                title: const Text('Submit Feedback'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  );
                },
              ),


              const Spacer(),
              const Divider(height: 1),


              // --- Logout ---
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _confirmLogout(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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
// 3a. EDIT PROFILE SCREEN (placeholder)
// ==========================================
class EditProfileScreen extends StatefulWidget {
  final String username;
  const EditProfileScreen({super.key, required this.username});


  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}


class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController =
  TextEditingController(text: widget.username);


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo upload coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Change Photo'),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                // TODO: Persist profile changes via DatabaseService.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated!')),
                );
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}


// ==========================================
// 3b. SUBMIT FEEDBACK SCREEN (placeholder)
// ==========================================
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});


  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}


class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  double _rating = 3;


  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How would you rate your experience?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.round().toString(),
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your feedback',
                hintText: 'Tell us what you think...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                // TODO: Persist feedback via DatabaseService.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thanks for your feedback!')),
                );
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
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
    return FutureBuilder<List<EventRegistrationModel>>(
      future: widget.dbService.getAllRegistrations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter only the 'pending' requests
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
// 7. ADMIN: CREATE EVENT SCREEN (FULL PAGE)
// ==========================================
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
                    onPressed: isFull
                        ? null
                        : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final userId = await DatabaseService().getUserId(widget.username);

                      if (userId != null && event.id != null) {
                        // 1. Check for existing registration
                        final alreadyRegistered = await DatabaseService()
                            .hasUserRegistered(userId, event.id!);

                        if (alreadyRegistered) {
                          if (mounted) {
                            Navigator.pop(context); // Close bottom sheet
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('You have already registered for this event.'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                          return; // Stop execution
                        }

                        // 2. Submit if no duplicate found
                        await DatabaseService().registerForEvent(userId, event.id!);

                        if (mounted) {
                          Navigator.pop(context); // Close bottom sheet
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Registration submitted! Waiting for Admin approval.'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          setState(() {}); // Refresh list view
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

// --- ADMIN TAB 0: View All Events & Workshops ---
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

// ==========================================
// ADMIN: EVENT DETAILS & PARTICIPANTS SCREEN
// ==========================================
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
                Navigator.pop(dialogContext); // Close dialog
                if (widget.event.id != null) {
                  await widget.dbService.deleteEvent(widget.event.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event deleted successfully!')),
                    );
                    Navigator.pop(context, true); // Pop back with true to reload list
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
            // --- EVENT SUMMARY CARD ---
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
              'Registered Participants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // --- PARTICIPANTS LIST ---
            FutureBuilder<List<BookingModel>>(
              future: widget.dbService.getBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Filter bookings matching this workshop
                final participants = (snapshot.data ?? []).where((booking) {
                  return booking.bookingType == 'Workshop: ${event.title}' ||
                      booking.bookingType == event.title;
                }).toList();

                if (participants.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No students have reserved a slot for this event yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final p = participants[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            p.studentName.isNotEmpty
                                ? p.studentName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          p.studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Booked on: ${p.date}'),
                        trailing: Chip(
                          label: Text(p.status),
                          backgroundColor: Colors.green.shade100,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // --- DELETE EVENT BUTTON ---
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