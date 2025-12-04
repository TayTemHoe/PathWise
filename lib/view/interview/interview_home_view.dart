// lib/view/interview/interview_home_view.dart
import 'package:flutter/material.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/interview_view_model.dart';
import 'package:path_wise/viewModel/career_view_model.dart';

import '../../utils/app_color.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color info = Color(0xFF74B9FF);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFD63031);
  static Color shadow = Colors.black.withOpacity(0.08);
}

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
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Interview Simulator',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: _DesignColors.textSecondary),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<InterviewViewModel>(
          builder: (context, interviewVM, child) {
            if (interviewVM.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
                ),
              );
            }

            final stats = interviewVM.getStatistics();

            return RefreshIndicator(
              onRefresh: _loadData,
              color: _DesignColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Section
                    _buildStatisticsCards(stats),

                    const SizedBox(height: 24),

                    // Action Cards
                    _buildActionCards(context),

                    const SizedBox(height: 24),

                    // Recent Performance
                    _buildRecentPerformance(interviewVM),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(Map<String, dynamic> stats) {
    final hasData = stats['hasData'] ?? false;
    final avgScore = hasData ? stats['averageScore'] ?? 0 : 0;
    final totalSessions = stats['totalSessions'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events_outlined,
            iconColor: _DesignColors.warning,
            value: '$avgScore%',
            label: 'Average Score',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline,
            iconColor: _DesignColors.success,
            value: '$totalSessions',
            label: 'Total Sessions',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: _DesignColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.play_arrow_rounded,
          iconColor: _DesignColors.primary,
          title: 'Start New Interview',
          subtitle: 'Practice with customizable interview settings',
          onTap: () => _startNewInterview(context),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          icon: Icons.history_rounded,
          iconColor: _DesignColors.info,
          title: 'View History',
          subtitle: 'Track your progress and review past sessions',
          onTap: () => _viewHistory(context),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _DesignColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
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
                          color: _DesignColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _DesignColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _DesignColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPerformance(InterviewViewModel interviewVM) {
    final recentSessions = interviewVM.recentSessions;

    if (recentSessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _DesignColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No interview sessions yet',
              style: TextStyle(
                fontSize: 16,
                color: _DesignColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start your first interview to see performance metrics',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _DesignColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Recent Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _DesignColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _DesignColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPerformanceHeader(),
                const Divider(height: 24),
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
    );
  }

  Widget _buildPerformanceHeader() {
    return const Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            'Session',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Job Title',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: 50, child: Center(child: Text(
          'Score',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textSecondary,
          ),
        ))),
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

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '#$sessionNumber',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _DesignColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.jobTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _DesignColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(session.difficultyLevel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    session.difficultyLevel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyColor(session.difficultyLevel),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                // Mini progress bar
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: score / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return _DesignColors.success;
    if (score >= 60) return _DesignColors.warning;
    return _DesignColors.error;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return _DesignColors.success;
      case 'intermediate':
        return _DesignColors.warning;
      case 'advanced':
        return _DesignColors.error;
      default:
        return _DesignColors.info;
    }
  }

  void _startNewInterview(BuildContext context) async {
    // Check if user has career suggestions
    final careerVM = Provider.of<CareerViewModel>(context, listen: false);

    // In a real scenario, check logic here. For UI demo:
    bool hasSuggestions = careerVM.hasLatestSuggestion;

    if (!hasSuggestions) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Career Analysis Required'),
          content: const Text(
            'Complete your career analysis to generate personalized interview questions.',
            style: TextStyle(color: _DesignColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: _DesignColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to career logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _DesignColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Go to Career', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

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
            Icon(Icons.help_outline, color: _DesignColors.primary),
            SizedBox(width: 12),
            Text('Interview Simulator', style: TextStyle(color: _DesignColors.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpStep('1', 'Complete career analysis first.'),
              _buildHelpStep('2', 'Start a new interview session.'),
              _buildHelpStep('3', 'Answer AI-generated questions.'),
              _buildHelpStep('4', 'Receive detailed feedback.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: _DesignColors.primary, fontWeight: FontWeight.bold)),
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
              color: _DesignColors.primary,
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
              style: const TextStyle(fontSize: 14, color: _DesignColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}