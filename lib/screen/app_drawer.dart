import 'dart:io';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'profile_screen.dart'; // Import the profile & feedback screens
import '../service/database_service.dart';

class AppDrawer extends StatefulWidget {
  final String userRole;
  final String username;

  const AppDrawer({super.key, required this.userRole, required this.username});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _displayName;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseService().getUserProfile(widget.username);
    if (mounted) {
      setState(() {
        final name = profile?['name'] as String?;
        _displayName = (name != null && name.trim().isNotEmpty) ? name : widget.username;
        _photoPath = profile?['photoPath'] as String?;
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: hasPhoto ? FileImage(File(_photoPath!)) : null,
                child: hasPhoto
                    ? null
                    : const Icon(Icons.person, size: 40, color: Colors.indigo),
              ),
              accountName: Text(
                _displayName ?? widget.username,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(widget.userRole.toUpperCase()),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.indigo),
              title: const Text('Edit Profile'),
              onTap: () async {
                Navigator.pop(context); // Close the drawer
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(username: widget.username),
                  ),
                );
                // Refresh the name/photo in case they were changed.
                _loadProfile();
              },
            ),
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
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _confirmLogout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}