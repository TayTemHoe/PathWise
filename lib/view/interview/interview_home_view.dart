// lib/view/interview/interview_home_view.dart
import 'package:flutter/material.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/interview_view_model.dart';
import 'package:path_wise/viewModel/career_view_model.dart';

class InterviewHomePage extends StatefulWidget {
  const InterviewHomePage({Key? key}) : super(key: key);

  @override
  State<InterviewHomePage> createState() => _InterviewHomePageState();
}

class _InterviewHomePageState extends State<InterviewHomePage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
    final user = profileVM.uid;
    if (user != null) {
      final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);
      await Future.wait([
        interviewVM.loadSessionHistory(user),
        interviewVM.loadRecentSessions(user, limit: 5),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Consumer<InterviewViewModel>(
                    builder: (context, interviewVM, child) {
                      if (interviewVM.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final stats = interviewVM.getStatistics();

                      return RefreshIndicator(
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: 20), // Add top padding
                              // Statistics Cards
                              _buildStatisticsCards(stats),

                              // Action Cards
                              _buildActionCards(context),

                              // Recent Performance
                              _buildRecentPerformance(interviewVM),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Balance the space
          const Expanded(
            child: Text(
              'Interview Simulator',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(Map<String, dynamic> stats) {
    final hasData = stats['hasData'] ?? false;
    final avgScore = hasData ? stats['averageScore'] ?? 0 : 0;
    final totalSessions = stats['totalSessions'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.emoji_events,
              iconColor: Colors.orange,
              value: '$avgScore%',
              label: 'Average\nScore',
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.adjust,
              iconColor: Colors.green,
              value: '$totalSessions',
              label: 'Total\nSessions',
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionCard(
            icon: Icons.play_circle_outline,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Start New Interview',
            subtitle: 'Practice with customizable\ninterview settings',
            onTap: () => _startNewInterview(context),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.history,
            iconColor: const Color(0xFF3B82F6),
            title: 'View History',
            subtitle: 'Track your progress and review\npast sessions',
            onTap: () => _viewHistory(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPerformance(InterviewViewModel interviewVM) {
    final recentSessions = interviewVM.recentSessions;

    if (recentSessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No interview sessions yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your first interview to see your performance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your last ${recentSessions.length} interview sessions',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPerformanceHeader(),
                  const SizedBox(height: 16),
                  ...recentSessions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final session = entry.value;
                    return _buildPerformanceRow(
                      sessionNumber: recentSessions.length - index,
                      session: session,
                      isLast: index == recentSessions.length - 1,
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceHeader() {
    return Row(
      children: [
        const SizedBox(width: 60),
        Expanded(
          child: Text(
            'Job Title',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 60),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildPerformanceRow({
    required int sessionNumber,
    required session,
    required bool isLast,
  }) {
    final score = session.totalScore ?? 0;
    final scoreColor = _getScoreColor(score);

    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                'Session\n$sessionNumber',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(session.difficultyLevel),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.jobTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: score / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: scoreColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '$score%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _startNewInterview(BuildContext context) async {
    final user = 'U0001';
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    // Check if user has career suggestions (A1)
    final careerVM = Provider.of<CareerViewModel>(context, listen: false);
    if (!careerVM.hasLatestSuggestion) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Career Analysis Required'),
          content: const Text(
            'Please complete your career analysis first to get personalised interview questions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to career prediction
                // Navigator.pushNamed(context, '/career-prediction');
              },
              child: const Text('Go to Career Analysis'),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to interview setup
    Navigator.pushNamed(context, '/interview-setup');
  }

  void _viewHistory(BuildContext context) {
    Navigator.pushNamed(context, '/interview-history');
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF8B5CF6)),
            SizedBox(width: 12),
            Text('How to use Interview Simulator', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpStep('1', 'Complete your career analysis to get personalized questions'),
              _buildHelpStep('2', 'Click "Start New Interview" to configure settings'),
              _buildHelpStep('3', 'Practice with AI-powered interview questions'),
              _buildHelpStep('4', 'Review your performance and feedback'),
              _buildHelpStep('5', 'Track your progress over multiple sessions'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}