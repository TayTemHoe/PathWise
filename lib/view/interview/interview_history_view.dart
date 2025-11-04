// lib/view/interview/interview_history_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewmodel/interview_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);
      await interviewVM.loadSessionHistory(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Interview History'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
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
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = _getSortedSessions(interviewVM.sessionHistory);

          if (sessions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: Column(
              children: [
                _buildHeader(sessions.length),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      return _buildSessionCard(sessions[index]);
                    },
                  ),
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
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                '$count Interview Sessions Completed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No interview history yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your first interview to see your history here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewSessionDetails(session),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.jobTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(session.difficultyLevel),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                session.difficultyLevel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (session.isRetake) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Retake',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(score),
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getScoreColor(score),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300], height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoItem(
                    Icons.calendar_today,
                    date != null ? DateFormat('MMM dd, yyyy').format(date) : 'N/A',
                  ),
                  const SizedBox(width: 24),
                  _buildInfoItem(
                    Icons.access_time,
                    duration,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoItem(
                    Icons.quiz,
                    '$completedQuestions/${session.numQuestions} completed',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _viewSessionDetails(session),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Load the session into current session
    final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);
    await interviewVM.loadSession(user.uid, session.id);

    // Navigate to results page
    Navigator.pushNamed(context, '/interview-results');
  }
}