import 'package:flutter/material.dart';
import 'app_drawer.dart';

class DataAnalysisPage extends StatelessWidget {
  final String userRole;
  final String username;

  const DataAnalysisPage({
    super.key,
    required this.userRole,
    required this.username,
  });

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
        // 3. Remove "widget." because this is a StatelessWidget
        drawer: AppDrawer(userRole: userRole, username: username),
      ),
    );
  }
}