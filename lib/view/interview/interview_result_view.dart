// lib/view/interview/interview_result_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/interview_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Defining KYYAP Design Colors locally
class _DesignColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
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

class InterviewResultsPage extends StatelessWidget {
  const InterviewResultsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DesignColors.background,
      appBar: AppBar(
        title: const Text(
          'Interview Results',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        backgroundColor: _DesignColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _DesignColors.textPrimary),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: _DesignColors.primary),
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
                const SizedBox(height: 40),
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
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _DesignColors.primary,
            _DesignColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
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
              const Text(
                '/100',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
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
                  Icons.article_outlined,
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
                  Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreMetric(
                  'Confidence',
                  confScore,
                  10,
                  Icons.psychology_outlined,
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 8),
          Text(
            '$score/$max',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(session) {
    if (session.feedback == null || session.feedback.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _DesignColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.feedback_outlined, color: _DesignColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Overall Feedback',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              session.feedback,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: _DesignColors.textPrimary,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _DesignColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lightbulb_outline, color: _DesignColors.warning, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.textPrimary,
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
                      margin: const EdgeInsets.only(top: 2),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _DesignColors.warning.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: _DesignColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: _DesignColors.textSecondary,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _DesignColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.quiz_outlined, color: _DesignColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Detailed Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.textPrimary,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _DesignColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Container(
                width: 28,
                height: 28,
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
                      fontSize: 12,
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
                    color: _DesignColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isSkipped ? 'Skipped' : '$score/10',
                style: TextStyle(
                  color: _getQuestionScoreColor(score),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(question.questionType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          question.questionType,
                          style: TextStyle(
                            color: _getCategoryColor(question.questionType),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Answer',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: _DesignColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Text(
                      isSkipped ? 'Question was skipped.' : question.userAnswer,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isSkipped ? _DesignColors.textSecondary : _DesignColors.textPrimary,
                        fontStyle: isSkipped ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                  if (!isSkipped && question.aiFeedback != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _DesignColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _DesignColors.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: _DesignColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AI Feedback',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _DesignColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  question.aiFeedback,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: _DesignColors.textPrimary,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _retakeInterview(context, session),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Retake Interview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DesignColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _DesignColors.textSecondary,
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
    if (score >= 8) return _DesignColors.success;
    if (score >= 6) return _DesignColors.warning;
    return _DesignColors.error;
  }

  Color _getCategoryColor(String category) {
    // Return distinct colors for categories, sticking to design palette where possible
    switch (category) {
      case 'Technical Skills':
        return _DesignColors.primary;
      case 'Behavioral':
        return _DesignColors.success;
      case 'Situational':
        return _DesignColors.warning;
      case 'Company Fit':
        return _DesignColors.info;
      default:
        return _DesignColors.textSecondary;
    }
  }

  void _retakeInterview(BuildContext context, session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retake Interview?'),
        content: const Text(
          'You will answer the same questions again. Your current results are saved in history.',
          style: TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _DesignColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Retake', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show loading
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
          ),
        ),
      );
    }

    try {
      final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);
      final success = await interviewVM.retakeSession(
        userId: user.uid,
        originalSession: session,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        if (success) {
          Navigator.pushReplacementNamed(context, '/interview-session');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: _DesignColors.error,
          ),
        );
      }
    }
  }
}