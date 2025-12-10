import 'package:flutter/material.dart';
import '../model/user_profile.dart';
import '../utils/app_color.dart';

enum DashboardMode { education, career }

class DashboardItem {
  final String title;
  final String description; // [NEW] Add description field
  final IconData icon;
  final Color color;
  final String route;
  final bool isPrimary;

  DashboardItem({
    required this.title,
    required this.description, // [NEW]
    required this.icon,
    required this.color,
    required this.route,
    this.isPrimary = false,
  });
}

class DashboardViewModel extends ChangeNotifier {
  DashboardMode _currentMode = DashboardMode.education;
  UserModel? _currentUser;

  DashboardMode get currentMode => _currentMode;
  UserModel? get currentUser => _currentUser;

  // Initialize based on user role
  void init(UserModel user) {
    _currentUser = user;
    // Always reset to user's role, don't keep previous state
    if (user.userRole == 'career') {
      _currentMode = DashboardMode.career;
    } else {
      _currentMode = DashboardMode.education;
    }
    notifyListeners();
  }

  void toggleMode() {
    _currentMode = _currentMode == DashboardMode.education
        ? DashboardMode.career
        : DashboardMode.education;
    notifyListeners();
  }

  String get dashboardTitle => _currentMode == DashboardMode.education
      ? 'Education Hub'
      : 'Career Center';

  // --- Education Features ---
  List<DashboardItem> get educationFeatures => [
    DashboardItem(
      title: 'Universities',
      description: 'Explore top-tier institutions worldwide.',
      icon: Icons.account_balance_rounded,
      color: AppColors.primary,
      route: '/university_list',
      isPrimary: true,
    ),
    DashboardItem(
      title: 'Programs',
      description: 'Find the perfect degree or course for you.',
      icon: Icons.school_rounded,
      color: Colors.orange,
      route: '/program_list',
      isPrimary: true,
    ),
    DashboardItem(
      title: 'AI Match',
      description: 'Get personalized recommendations based on your profile.',
      icon: Icons.auto_awesome_rounded,
      color: Colors.purple,
      route: '/ai_match',
      isPrimary: true,
    ),
    DashboardItem(
      title: 'Compare',
      description: 'Side-by-side comparison of your top choices.',
      icon: Icons.compare_arrows_rounded,
      color: Colors.blue,
      route: '/compare',
    ),
  ];

  // --- Career Features ---
  List<DashboardItem> get careerFeatures => [
    DashboardItem(
      title: 'Job Listing',
      description: 'Browse current openings relevant to your skills.',
      icon: Icons.work_rounded,
      color: Colors.indigo,
      route: '/job_list',
      isPrimary: true,
    ),
    DashboardItem(
      title: 'AI Job Match',
      description: 'Let AI find roles that fit your personality perfectly.',
      icon: Icons.psychology_rounded,
      color: Colors.teal,
      route: '/ai_job_match',
      isPrimary: true,
    ),
    DashboardItem(
      title: 'Resume Builder',
      description: 'Create professional resumes that stand out.',
      icon: Icons.description_rounded,
      color: Colors.pink,
      route: '/resume',
    ),
    DashboardItem(
      title: 'Mock Interview',
      description: 'Practice with AI to ace your real interviews.',
      icon: Icons.record_voice_over_rounded,
      color: Colors.deepOrange,
      route: '/interview',
    ),
    DashboardItem(
      title: 'Roadmap',
      description: 'Visualize and plan your career trajectory.',
      icon: Icons.map_rounded,
      color: Colors.green,
      route: '/roadmap',
    ),
  ];

  // --- Shared Features ---
  List<DashboardItem> get sharedFeatures => [
    DashboardItem(
      title: 'MBTI Test',
      description: 'Discover your personality type and preferences.',
      icon: Icons.person_search_rounded,
      color: const Color(0xFF6C63FF),
      route: '/mbti',
    ),
    DashboardItem(
      title: 'RIASEC Test',
      description: 'Find careers matching your interests.',
      icon: Icons.engineering_rounded,
      color: const Color(0xFFFF6584),
      route: '/riasec',
    ),
    DashboardItem(
      title: 'Big Five',
      description: 'Understand your core personality traits.',
      icon: Icons.pie_chart_rounded,
      color: const Color(0xFFFFB74D),
      route: '/big_five',
    ),
    DashboardItem(
      title: 'Profile',
      description: 'Manage your personal information and settings.',
      icon: Icons.person_rounded,
      color: Colors.grey,
      route: '/profile',
    ),
  ];

  void reset() {
    _currentUser = null;
    _currentMode = DashboardMode.education; // Reset to default
    notifyListeners();
    debugPrint('🧹 Dashboard ViewModel reset');
  }
}