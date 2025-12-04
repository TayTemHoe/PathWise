// lib/view/interview/interview_session_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewModel/interview_view_model.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';
import 'dart:async';

import '../../utils/app_color.dart';

// Defining KYYAP Design Colors locally
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

class InterviewSessionPage extends StatefulWidget {
  const InterviewSessionPage({Key? key}) : super(key: key);

  @override
  State<InterviewSessionPage> createState() => _InterviewSessionPageState();
}

class _InterviewSessionPageState extends State<InterviewSessionPage> {
  final TextEditingController _answerController = TextEditingController();
  Timer? _timer;
  bool _hasShownTimeWarning = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {});

      final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);

      // Check for timeout
      if (interviewVM.hasTimedOut()) {
        _handleTimeout();
        return;
      }

      // Show warning at 5 minutes remaining
      if (interviewVM.shouldShowTimeWarning() && !_hasShownTimeWarning) {
        _showTimeWarning();
        _hasShownTimeWarning = true;
      }
    });
  }

  void _showTimeWarning() {
    if (!mounted) return;

    final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);
    final remaining = interviewVM.getRemainingTimeMinutes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ $remaining minutes remaining in your interview session'),
        backgroundColor: _DesignColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleTimeout() {
    _timer?.cancel();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Session Timeout'),
        content: const Text(
          'Your interview session has exceeded the time limit. All responses captured so far will be saved and evaluated.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishInterview(isTimeout: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continue to Evaluation', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showExitDialog();
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: _DesignColors.background,
        body: SafeArea(
          child: Consumer<InterviewViewModel>(
            builder: (context, interviewVM, child) {
              if (interviewVM.currentQuestion == null || interviewVM.currentSession == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary),
                  ),
                );
              }

              return Column(
                children: [
                  _buildHeader(interviewVM),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuestionCard(interviewVM),
                          const SizedBox(height: 24),
                          _buildAnswerSection(interviewVM),
                          const SizedBox(height: 24),
                          _buildActionButtons(interviewVM),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(InterviewViewModel interviewVM) {
    final session = interviewVM.currentSession!;
    final progress = interviewVM.currentQuestionIndex + 1;
    final total = interviewVM.totalQuestions;
    final remainingTime = interviewVM.getRemainingTimeMinutes();
    final isLowTime = remainingTime <= 5;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: _DesignColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                    Icons.arrow_back_ios, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final shouldExit = await _showExitDialog();
                  if (shouldExit == true && mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session.jobTitle} Interview',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${session.difficultyLevel} Level',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isLowTime
                      ? _DesignColors.warning
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: isLowTime ? Colors.black87 : Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$remainingTime:00',
                      style: TextStyle(
                        color: isLowTime ? Colors.black87 : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '$progress of $total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress / total,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(InterviewViewModel interviewVM) {
    final question = interviewVM.currentQuestion!;
    final questionTime = interviewVM.getCurrentQuestionElapsedSeconds();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getCategoryColor(question.questionType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
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
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: _DesignColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(questionTime),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _DesignColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Question ${interviewVM.currentQuestionIndex + 1}',
            style: const TextStyle(
              fontSize: 12,
              color: _DesignColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 18,
              height: 1.4,
              color: _DesignColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _DesignColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: _DesignColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Be concise and structure your answer clearly.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _DesignColors.textSecondary,
                      fontStyle: FontStyle.italic,
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

  Widget _buildAnswerSection(InterviewViewModel interviewVM) {
    final currentAnswer = _answerController.text;
    final wordCount = currentAnswer.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    const maxWords = 500;
    const minRecommended = 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Answer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _DesignColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _DesignColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _answerController,
            maxLines: 8,
            maxLength: maxWords * 6,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 15, height: 1.5, color: _DesignColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Type your answer here...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              counterText: "",
              contentPadding: const EdgeInsets.all(20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _DesignColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wordCount < minRecommended
                    ? 'Recommended: $minRecommended+ words'
                    : 'Good length',
                style: TextStyle(
                  fontSize: 12,
                  color: wordCount < minRecommended ? _DesignColors.textSecondary : _DesignColors.success,
                ),
              ),
              Text(
                '$wordCount words',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: wordCount > maxWords
                      ? _DesignColors.error
                      : (wordCount >= minRecommended ? _DesignColors.success : _DesignColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(InterviewViewModel interviewVM) {
    final hasAnswer = _answerController.text.trim().isNotEmpty;
    final isLastQuestion = interviewVM.isLastQuestion;

    return Column(
      children: [
        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: hasAnswer ? () => _submitAnswer(interviewVM) : null,
            icon: Icon(
              isLastQuestion ? Icons.check_circle_outline : Icons.arrow_forward,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              isLastQuestion ? 'Submit & Finish' : 'Submit Answer',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Secondary Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _repeatQuestion(interviewVM),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Repeat'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: _DesignColors.textSecondary,
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _skipQuestion(interviewVM),
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Skip'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: _DesignColors.warning,
                  side: const BorderSide(color: _DesignColors.warning),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Logic Methods ---

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Technical Skills': return _DesignColors.primary;
      case 'Behavioral': return _DesignColors.success;
      case 'Situational': return _DesignColors.warning;
      case 'Company Fit': return _DesignColors.info;
      default: return _DesignColors.textSecondary;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Interview?'),
        content: const Text(
          'Your progress will be lost if you exit now. Are you sure?',
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
              backgroundColor: _DesignColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitAnswer(InterviewViewModel interviewVM) async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    final isLastQuestion = interviewVM.isLastQuestion;
    await interviewVM.submitAnswer(answer);
    _answerController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLastQuestion ? 'Answer saved! Preparing results...' : 'Answer saved.',
          ),
          backgroundColor: _DesignColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (isLastQuestion) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _finishInterview();
    }
  }

  void _skipQuestion(InterviewViewModel interviewVM) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Skip Question?'),
        content: const Text(
          'This will be marked as skipped (Score: 0).',
          style: TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _DesignColors.warning),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final isLastQuestion = interviewVM.isLastQuestion;
      await interviewVM.skipQuestion();
      _answerController.clear();

      if (isLastQuestion) {
        if (mounted) _finishInterview();
      }
    }
  }

  void _repeatQuestion(InterviewViewModel interviewVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Repeat Question?'),
        content: const Text(
          'This will restart the timer for this question and clear your current answer.',
          style: TextStyle(color: _DesignColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              interviewVM.repeatQuestion();
              _answerController.clear();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _DesignColors.primary),
            child: const Text('Repeat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _finishInterview({bool isTimeout = false}) async {
    final profileVM = context.read<ProfileViewModel>();
    final userId = profileVM.uid;
    final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);

    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_DesignColors.primary)),
              SizedBox(height: 20),
              Text(
                'Evaluating Session...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'AI is analyzing your responses',
                style: TextStyle(color: _DesignColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await interviewVM.evaluateInterview(userId);
      if (mounted) Navigator.pop(context); // Close loading

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/interview-results');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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