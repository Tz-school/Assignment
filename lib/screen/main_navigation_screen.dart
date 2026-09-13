import 'package:flutter/material.dart';
import 'career_planner_page.dart';
import 'data_analysis_page.dart';
import 'booking_page.dart';
import 'industry_page.dart';

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
    final List<Widget> pages = [
      DataAnalysisPage(userRole: widget.userRole, username: widget.username),
      BookingPage(userRole: widget.userRole, username: widget.username),
      IndustryPage(userRole: widget.userRole, username: widget.username),
      CareerPlannerPage(userRole: widget.userRole, username: widget.username),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Industry',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'Planner'
          ),
        ],
      ),
    );
  }
}