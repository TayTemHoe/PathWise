// lib/view/interview/interview_history_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'package:path_wise/viewModel/interview_view_model.dart';
import 'package:intl/intl.dart';

// Defining Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFD63031);
  static const Color info = Color(0xFF74B9FF);
  static Color shadow = Colors.black.withOpacity(0.08);
}

class InterviewHistoryPage extends StatefulWidget {
  const InterviewHistoryPage({Key? key}) : super(key: key);

  @override
  State<InterviewHistoryPage> createState() => _InterviewHistoryPageState();
}

class _InterviewHistoryPageState extends State<InterviewHistoryPage> {
  String _sortBy = 'date'; // 'date', 'score', 'job'

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = Provider.of<ProfileViewModel>(context, listen: false);
    if (user.uid != null) {
      final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);
      await interviewVM.loadSessionHistory(user.uid);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _DesignColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Interview History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: _DesignColors.textPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'score',
                child: Text('Sort by Score'),
              ),
              const PopupMenuItem(
                value: 'job',
                child: Text('Sort by Job Title'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<InterviewViewModel>(
        builder: (context, interviewVM, child) {
          if (interviewVM.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
              ),
            );
          }

          final sessions = _getSortedSessions(interviewVM.sessionHistory);

          if (sessions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadHistory,
            color: _DesignColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(sessions.length),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    return _buildSessionCard(sessions[index]);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _DesignColors.primary,
            _DesignColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_edu, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Sessions Completed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _DesignColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_toggle_off, size: 60, color: _DesignColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'No interview history',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Complete your first interview session to see your progress history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _DesignColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DesignColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(session) {
    final score = session.totalScore ?? 0;
    final date = session.createdAt?.toDate();
    final duration = _calculateDuration(session);
    final completedQuestions = session.questions.where((q) =>
    q.userAnswer != null && q.userAnswer.isNotEmpty
    ).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          onTap: () => _viewSessionDetails(session),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title, Badges, Score
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.jobTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _DesignColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildStatusChip(
                                session.difficultyLevel,
                                _getDifficultyColor(session.difficultyLevel),
                              ),
                              if (session.isRetake)
                                _buildStatusChip('Retake', _DesignColors.info),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildScoreIndicator(score),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.grey.withOpacity(0.1), height: 1),
                const SizedBox(height: 16),

                // Info Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today_outlined,
                        date != null ? DateFormat('MMM dd, yyyy').format(date) : 'N/A',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.schedule,
                        duration,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoItem(
                  Icons.checklist_rtl_rounded,
                  '$completedQuestions/${session.numQuestions} completed',
                ),

                const SizedBox(height: 16),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _viewSessionDetails(session),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DesignColors.primary,
                      side: const BorderSide(color: _DesignColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(int score) {
    final color = _getScoreColor(score);
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 2),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Score',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _DesignColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: _DesignColors.textSecondary,
          ),
        ),
      ],
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

  String _calculateDuration(session) {
    if (session.startTime == null || session.endTime == null) {
      return '${session.sessionDuration} min';
    }

    final start = session.startTime.toDate();
    final end = session.endTime.toDate();
    final duration = end.difference(start);

    final minutes = duration.inMinutes;
    return '$minutes min';
  }

  List<dynamic> _getSortedSessions(List<dynamic> sessions) {
    final sorted = List.from(sessions);

    switch (_sortBy) {
      case 'score':
        sorted.sort((a, b) => (b.totalScore ?? 0).compareTo(a.totalScore ?? 0));
        break;
      case 'job':
        sorted.sort((a, b) => a.jobTitle.compareTo(b.jobTitle));
        break;
      case 'date':
      default:
        sorted.sort((a, b) {
          final aDate = a.createdAt?.toDate() ?? DateTime(2000);
          final bDate = b.createdAt?.toDate() ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
    }

    return sorted;
  }

  void _viewSessionDetails(session) async {
    final user = Provider.of<ProfileViewModel>(context, listen: false);
    if (user.uid == null) return;

    final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
        ),
      ),
    );

    await interviewVM.loadSession(user.uid, session.id);

    if (mounted) {
      Navigator.pop(context); // Close loading
      Navigator.pushNamed(context, '/interview-results');
    }
  }
}