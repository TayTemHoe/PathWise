// lib/view/interview/interview_results_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/interview_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InterviewResultsPage extends StatelessWidget {
  const InterviewResultsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Interview Results'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Consumer<InterviewViewModel>(
        builder: (context, interviewVM, child) {
          final session = interviewVM.currentSession;
          if (session == null) {
            return const Center(child: Text('No session data'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildScoreOverview(session),
                _buildFeedbackSection(session),
                _buildRecommendationsSection(session),
                _buildQuestionsReview(session),
                _buildActionButtons(context, session),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreOverview(session) {
    final totalScore = session.totalScore ?? 0;
    final contentScore = session.contentScore ?? 0;
    final commScore = session.communicationScore ?? 0;
    final timeScore = session.responseTimeScore ?? 0;
    final confScore = session.confidenceScore ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Score',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildScoreMetric(
                  'Content',
                  contentScore,
                  40,
                  Icons.article,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreMetric(
                  'Communication',
                  commScore,
                  30,
                  Icons.chat_bubble_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildScoreMetric(
                  'Time',
                  timeScore,
                  20,
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreMetric(
                  'Confidence',
                  confScore,
                  10,
                  Icons.psychology,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreMetric(String label, int score, int max, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            '$score/$max',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(session) {
    if (session.feedback == null || session.feedback.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.feedback, color: Color(0xFF8B5CF6)),
                SizedBox(width: 12),
                Text(
                  'Overall Feedback',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              session.feedback,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(session) {
    if (session.recommendations == null || session.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B)),
                SizedBox(width: 12),
                Text(
                  'Recommended Next Steps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...session.recommendations.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsReview(session) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.quiz, color: Color(0xFF3B82F6)),
                SizedBox(width: 12),
                Text(
                  'Question by Question Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...session.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return _buildQuestionExpansion(index + 1, question);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionExpansion(int number, question) {
    final score = question.aiScore ?? 0;
    final isSkipped = question.userAnswer == null || question.userAnswer.isEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey[50],
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getQuestionScoreColor(score),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getQuestionScoreColor(score),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSkipped ? 'Skipped' : '$score/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(question.questionType),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.questionType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Answer:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      isSkipped ? 'Question was skipped.' : question.userAnswer,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isSkipped ? Colors.grey[500] : Colors.black87,
                        fontStyle: isSkipped ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                  if (!isSkipped && question.aiFeedback != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.tips_and_updates,
                            color: Color(0xFF8B5CF6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AI Feedback:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  question.aiFeedback,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, session) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _retakeInterview(context, session),
              icon: const Icon(Icons.replay),
              label: const Text('Retake Interview'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
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
    );
  }

  Color _getQuestionScoreColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Technical Skills':
        return const Color(0xFF3B82F6);
      case 'Behavioral':
        return const Color(0xFF10B981);
      case 'Situational':
        return const Color(0xFFF59E0B);
      case 'Company Fit':
        return const Color(0xFF8B5CF6);
      case 'Leadership':
        return const Color(0xFFEF4444);
      case 'Problem Solving':
        return const Color(0xFF06B6D4);
      case 'Communication':
        return const Color(0xFFEC4899);
      case 'Adaptability':
        return const Color(0xFF6366F1);
      default:
        return Colors.grey;
    }
  }

  void _retakeInterview(BuildContext context, session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retake Interview?'),
        content: const Text(
          'You will answer the same questions again. Your current results will be saved in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retake'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Preparing retake session...')),
          ],
        ),
      ),
    );

    try {
      final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);
      final success = await interviewVM.retakeSession(
        userId: user.uid,
        originalSession: session,
      );

      Navigator.pop(context); // Close loading

      if (success) {
        Navigator.pushReplacementNamed(context, '/interview-session');
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}