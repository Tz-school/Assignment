import 'package:flutter/material.dart';
import 'app_drawer.dart';

class IndustryPage extends StatelessWidget {
  final String userRole;
  final String username;

  const IndustryPage({
    super.key,
    required this.userRole,
    required this.username,
  });

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
          // 3. The drawer now has access to the variables
          drawer: AppDrawer(userRole: userRole, username: username)
      ),
    );
  }
}