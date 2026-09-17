import 'dart:io';

import 'package:flutter/material.dart';
import '../service/database_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allUsers = [];

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final users = await _databaseService.getStudentUsers();

      if (!mounted) return;

      setState(() {
        _allUsers
          ..clear()
          ..addAll(
            users.map(
                  (user) => Map<String, dynamic>.from(user),
            ),
          );

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return List<Map<String, dynamic>>.from(_allUsers);
    }

    return _allUsers.where((user) {
      final name = user['name']?.toString().toLowerCase() ?? '';
      final username = user['username']?.toString().toLowerCase() ?? '';

      return name.contains(query) || username.contains(query);
    }).toList();
  }

  bool _hasProfilePhoto(Map<String, dynamic> user) {
    final photoPath = user['photoPath']?.toString().trim() ?? '';

    if (photoPath.isEmpty) {
      return false;
    }

    return File(photoPath).existsSync();
  }

  String _getDisplayName(Map<String, dynamic> user) {
    final name = user['name']?.toString().trim() ?? '';
    final username = user['username']?.toString().trim() ?? '';

    return name.isNotEmpty ? name : username;
  }

  String _getUsername(Map<String, dynamic> user) {
    return user['username']?.toString().trim() ?? '';
  }

  Future<void> _toggleBanStatus(Map<String, dynamic> user) async {
    final username = _getUsername(user);

    final currentlyBanned =
        user['Banned']?.toString().trim().toLowerCase() == 'yes';

    final newBannedStatus = !currentlyBanned;

    try {
      final affectedRows = await _databaseService.updateUserBanStatus(
        username: username,
        banned: newBannedStatus,
      );

      if (affectedRows == 0) {
        throw Exception('No student user was updated');
      }

      if (!mounted) return;

      setState(() {
        final index = _allUsers.indexWhere(
              (item) => item['username']?.toString() == username,
        );

        if (index != -1) {
          _allUsers[index] = {
            ..._allUsers[index],
            'Banned': newBannedStatus ? 'Yes' : 'No',
          };
        }
      });

      final action = newBannedStatus ? 'banned' : 'unbanned';
      final displayName = _getDisplayName(user);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$displayName was successfully $action.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to update user status: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Widget _buildUserAvatar(Map<String, dynamic> user, bool isBanned) {
    final photoPath = user['photoPath']?.toString().trim() ?? '';
    final displayName = _getDisplayName(user);
    final hasPhoto = _hasProfilePhoto(user);

    return CircleAvatar(
      radius: 28,
      backgroundColor:
      isBanned ? Colors.red.shade100 : Colors.indigo.shade100,
      backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
      child: hasPhoto
          ? null
          : Text(
        displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : 'U',
        style: TextStyle(
          color: isBanned ? Colors.red : Colors.indigo,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedUsers = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or username',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : displayedUsers.isEmpty
                ? const Center(
              child: Text('No student users found'),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: displayedUsers.length,
              itemBuilder: (context, index) {
                final user = displayedUsers[index];

                final isBanned = user['Banned']
                    ?.toString()
                    .trim()
                    .toLowerCase() ==
                    'yes';

                final displayName = _getDisplayName(user);
                final username = _getUsername(user);

                return Card(
                  color: isBanned
                      ? Colors.red.shade50
                      : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: _buildUserAvatar(user, isBanned),
                    title: Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@$username',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isBanned ? 'Banned' : 'Active',
                            style: TextStyle(
                              color: isBanned
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => _toggleBanStatus(user),
                      child: Text(
                        isBanned ? 'Unban' : 'Ban',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}