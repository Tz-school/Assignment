import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../service/database_service.dart';
import '../service/supabase_service.dart';
import 'feedback_submission.dart';
import 'feedback_view.dart';
import 'chat_screen.dart';

class AppDrawer extends StatefulWidget {
  final String userRole;
  final String username;

  const AppDrawer({
    super.key,
    required this.userRole,
    required this.username,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final DatabaseService _databaseService =
  DatabaseService();

  final SupabaseService _supabaseService =
  SupabaseService();

  String? _displayName;
  String? _photoPath;

  int _unreadChatCount = 0;

  Timer? _chatTimer;

  @override
  void initState() {
    super.initState();

    _loadProfile();

    if (widget.userRole != 'admin') {
      _loadUnreadChatCount();

      _chatTimer = Timer.periodic(
        const Duration(seconds: 5),
            (_) {
          _loadUnreadChatCount();
        },
      );
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile =
      await _databaseService.getUserProfile(
        widget.username,
      );

      debugPrint(
        'Loaded profile for ${widget.username}: $profile',
      );

      if (!mounted) return;

      setState(() {
        final name =
        profile?['name']?.toString();

        _displayName =
        name != null &&
            name.trim().isNotEmpty
            ? name
            : widget.username;

        _photoPath =
            profile?['photoPath']
                ?.toString();

        debugPrint(
          'Profile photo path: $_photoPath',
        );
      });
    } catch (e) {
      debugPrint(
        'Error loading profile: $e',
      );

      if (!mounted) return;

      setState(() {
        _displayName = widget.username;
        _photoPath = null;
      });
    }
  }



  bool get _hasProfilePhoto {
    if (_photoPath == null ||
        _photoPath!.trim().isEmpty) {
      return false;
    }

    return File(_photoPath!).existsSync();
  }



  Widget _buildProfilePicture() {
    if (_hasProfilePhoto) {
      return CircleAvatar(
        radius: 38,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.file(
            File(_photoPath!),
            width: 76,
            height: 76,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) {
              return const Icon(
                Icons.person,
                size: 40,
                color: Colors.indigo,
              );
            },
          ),
        ),
      );
    }

    return const CircleAvatar(
      radius: 38,
      backgroundColor: Colors.white,
      child: Icon(
        Icons.person,
        size: 40,
        color: Colors.indigo,
      ),
    );
  }


  Future<void> _loadUnreadChatCount() async {
    try {
      final count =
      await _supabaseService
          .getUnreadChatCount(
        username: widget.username,
      );

      if (!mounted) return;

      setState(() {
        _unreadChatCount = count;
      });
    } catch (e) {
      debugPrint(
        'Error loading unread chat count: $e',
      );
    }
  }



  void _confirmLogout(
      BuildContext context,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
          const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child:
              const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const LoginScreen(),
                  ),
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [


            UserAccountsDrawerHeader(
              decoration:
              const BoxDecoration(
                color: Colors.indigo,
              ),

              currentAccountPicture:
              _buildProfilePicture(),

              accountName: Text(
                _displayName ??
                    widget.username,
                style: const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              accountEmail: Text(
                widget.userRole
                    .toUpperCase(),
              ),
            ),


            ListTile(
              leading: const Icon(
                Icons.edit,
                color: Colors.indigo,
              ),
              title:
              const Text(
                'Edit Profile',
              ),
              onTap: () async {
                Navigator.pop(context);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfileScreen(
                          username:
                          widget.username,
                        ),
                  ),
                );


                await _loadProfile();
              },
            ),


            if (widget.userRole != 'admin')
              ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.indigo,
                ),
                title: Row(
                  children: [
                    const Expanded(
                      child: Text('Chat'),
                    ),

                    if (_unreadChatCount > 0)
                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                        BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                          BorderRadius
                              .circular(
                            20,
                          ),
                        ),
                        child: Text(
                          _unreadChatCount > 99
                              ? '99+'
                              : '$_unreadChatCount',
                          style:
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () async {
                  Navigator.pop(context);

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(
                            username:
                            widget.username,
                          ),
                    ),
                  );

                  _loadUnreadChatCount();
                },
              ),



            ListTile(
              leading: const Icon(
                Icons.feedback_outlined,
                color: Colors.indigo,
              ),
              title: Text(
                widget.userRole == 'admin'
                    ? 'View Feedback'
                    : 'Submit Feedback',
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    widget.userRole ==
                        'admin'
                        ? const FeedbackViewScreen()
                        : FeedbackScreen(
                      username:
                      widget.username,
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            const Divider(
              height: 1,
            ),



            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onTap: () =>
                  _confirmLogout(context),
            ),

            const SizedBox(
              height: 8,
            ),
          ],
        ),
      ),
    );
  }
}