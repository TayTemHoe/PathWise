import 'package:flutter/material.dart';
import 'package:path_wise/view/profile_overview_view.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({Key? key}) : super(key: key);

  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    const CareerScreen(),
    const RoadmapScreen(),
    const ResumeScreen(),
    const InterviewScreen(),
    const ProfileOverviewScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index; // Update the selected tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set up a body with the selected screen
      body: _screens[_currentIndex],

      // Bottom Navigation Bar with 5 tabs
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Current selected tab
        onTap: _onTabTapped, // Handle tab selection
        selectedItemColor: Colors.blue, // Color for selected item label
        unselectedItemColor: Colors.grey, // Color for unselected item labels
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.work, 0), // Career
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.map, 1), // Roadmap
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.article, 2), // Resume
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.comment, 3), // Interview
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.person, 4), // Profile
            label: '',
          ),
        ],
      ),
    );
  }

  // Build custom icon with a blue circle under the selected tab and label below
  Widget _buildIcon(IconData icon, int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: _currentIndex == index ? Colors.blue : Colors.grey),
            Text(
              _getLabel(index),
              style: TextStyle(
                fontSize: 12,
                color: _currentIndex == index ? Colors.blue : Colors.grey, // Label color
              ),
            ),
          ],
        ),
        if (_currentIndex == index)
          Positioned(
            bottom: -8,
            left: 15,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
            ),
          ),
      ],
    );
  }

  // Get the label based on the selected index
  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'Career';
      case 1:
        return 'Roadmap';
      case 2:
        return 'Resume';
      case 3:
        return 'Interview';
      case 4:
        return 'Profile';
      default:
        return '';
    }
  }
}

// Sample screens for each tab
class CareerScreen extends StatelessWidget {
  const CareerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Career Screen'),
    );
  }
}

class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Roadmap Screen'),
    );
  }
}

class ResumeScreen extends StatelessWidget {
  const ResumeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Resume Screen'),
    );
  }
}

class InterviewScreen extends StatelessWidget {
  const InterviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Interview Screen'),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Screen'),
    );
  }
}
