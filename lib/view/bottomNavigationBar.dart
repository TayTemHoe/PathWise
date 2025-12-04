// lib/view/bottomNavigationBar.dart
import 'package:flutter/material.dart';
import 'package:path_wise/view/profile/profile_overview_view.dart';
import 'package:path_wise/view/career/career_view.dart';
import 'package:path_wise/view/career/job_view.dart'; // Added JobView import
import 'package:path_wise/view/roadmap/careerroadmap_list_view.dart';
import 'package:path_wise/view/resume/resume_home_view.dart';
import 'package:path_wise/view/interview/interview_home_view.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color background = Color(0xFFFFFFFF);
}

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({Key? key}) : super(key: key);

  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  // List of screens including the new JobView
  final List<Widget> _screens = [
    const CareerDiscoveryView(),
    const JobView(),
    const RoadmapListView(),
    const ResumeListPage(),
    const InterviewHomePage(),
    const ProfileOverviewScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed, // Required for >3 items
          selectedItemColor: _DesignColors.primary,
          unselectedItemColor: _DesignColors.textSecondary,
          selectedFontSize: 0, // Hiding default labels as we use custom icon builder
          unselectedFontSize: 0,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.explore_outlined, Icons.explore, 0),
              label: 'Career',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.work_outline, Icons.work, 1),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.map_outlined, Icons.map, 2),
              label: 'Roadmap',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.description_outlined, Icons.description, 3),
              label: 'Resume',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.chat_bubble_outline, Icons.chat_bubble, 4),
              label: 'Interview',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.person_outline, Icons.person, 5),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Custom Icon Builder with Animation and Label
  Widget _buildIcon(IconData unselectedIcon, IconData selectedIcon, int index) {
    final isSelected = _currentIndex == index;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isSelected ? 0 : 2),
            child: Icon(
              isSelected ? selectedIcon : unselectedIcon,
              size: 24,
              color: isSelected ? _DesignColors.primary : _DesignColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getLabel(index),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? _DesignColors.primary : _DesignColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          // Active Indicator Dot/Line
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            width: isSelected ? 4 : 0,
            decoration: BoxDecoration(
              color: _DesignColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel(int index) {
    switch (index) {
      case 0: return 'Career';
      case 1: return 'Jobs';
      case 2: return 'Roadmap';
      case 3: return 'Resume';
      case 4: return 'Interview';
      case 5: return 'Profile';
      default: return '';
    }
  }
}