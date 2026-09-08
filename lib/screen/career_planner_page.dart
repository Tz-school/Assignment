import 'package:flutter/material.dart';
import 'app_drawer.dart';

class CareerPlannerPage extends StatelessWidget {
  final String userRole;
  final String username;

  const CareerPlannerPage({super.key, required this.userRole, required this.username});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Smart Career Planner'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Suitability Quiz'),
              Tab(text: 'Course Simulator'),
              Tab(text: 'Career Roadmap'),
              Tab(text: 'Goal Tracker'),
              Tab(text: 'What-If Simulator'),
              Tab(text: 'Career Score'),
            ],
          ),
        ),
        drawer: AppDrawer(userRole: userRole, username: username),
        body: const TabBarView(
          children: [
            Center(child: Text('Career Suitability Quiz Content')),
            Center(child: Text('Course Comparison Simulator Content')),
            Center(child: Text('Personal Career Roadmap Content')),
            Center(child: Text('Career Goal Tracker Content')),
            Center(child: Text('What-If Career Simulator Content')),
            Center(child: Text('Personalized Career Score Content')),
          ],
        ),
      ),
    );
  }
}