// lib/view/interview/interview_session_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_wise/viewmodel/interview_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class InterviewSessionPage extends StatefulWidget {
  const InterviewSessionPage({Key? key}) : super(key: key);

  @override
  State<InterviewSessionPage> createState() => _InterviewSessionPageState();
}

class _InterviewSessionPageState extends State<InterviewSessionPage> {
  final TextEditingController _answerController = TextEditingController();
  Timer? _timer;
  int _questionStartTime = 0;

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
      setState(() {});

      final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);

      // Check for timeout
      if (interviewVM.hasTimedOut()) {
        _handleTimeout();
      }

      // Show warning at 5 minutes
      if (interviewVM.shouldShowTimeWarning() &&
          interviewVM.getRemainingTimeMinutes() == 5 &&
          _questionStartTime == 0) {
        _showTimeWarning();
        _questionStartTime = 1;
      }
    });
  }

  void _showTimeWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ 5 minutes remaining in your interview session'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _handleTimeout() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Timeout'),
        content: const Text(
          'Your interview session has exceeded the time limit. All responses captured so far will be saved and evaluated.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishInterview();
            },
            child: const Text('Continue to Results'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Interview?'),
            content: const Text('Your progress will be lost if you exit now.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF8B5CF6),
        body: SafeArea(
          child: Consumer<InterviewViewModel>(
            builder: (context, interviewVM, child) {
              if (interviewVM.currentQuestion == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  _buildHeader(interviewVM),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async {
                  final shouldPop = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Exit Interview?'),
                      content: const Text('Your progress will be lost.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Exit'),
                        ),
                      ],
                    ),
                  );
                  if (shouldPop == true) {
                    Navigator.pop(context);
                  }
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      '${session.difficultyLevel} level',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$remainingTime:00',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$progress of $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress / total,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(InterviewViewModel interviewVM) {
    final question = interviewVM.currentQuestion!;
    final questionTime = interviewVM.getCurrentQuestionElapsedSeconds();

    return Card(
      elevation: 0,
      color: const Color(0xFF8B5CF6).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(question.questionType),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    question.questionType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(question.questionType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(questionTime),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Question ${interviewVM.currentQuestionIndex + 1} of ${interviewVM.totalQuestions}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Suggested limit: 4 minutes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _answerController,
          maxLines: 10,
          maxLength: maxWords * 6, // Approximate char limit
          decoration: InputDecoration(
            hintText: 'Click here to start answering...',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Minimum recommended: $minRecommended words',
              style: TextStyle(
                fontSize: 12,
                color: wordCount >= minRecommended ? Colors.green : Colors.grey[600],
              ),
            ),
            Text(
              '$wordCount words',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: wordCount >= minRecommended ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        if (wordCount > maxWords)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '⚠️ ${wordCount - maxWords} more words recommended',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(InterviewViewModel interviewVM) {
    final hasAnswer = _answerController.text.trim().isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: hasAnswer
                ? () => _submitAnswer(interviewVM)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              interviewVM.isLastQuestion
                  ? 'Submit Answer & Finish'
                  : 'Submit Answer & Continue',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _repeatQuestion(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Repeat Question'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: const Color(0xFF8B5CF6),
                  side: const BorderSide(color: Color(0xFF8B5CF6)),
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
                label: const Text('Skip Question'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _submitAnswer(InterviewViewModel interviewVM) async {
    final answer = _answerController.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an answer before continuing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await interviewVM.submitAnswer(answer);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your answer has been saved. Moving to the next question.'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    _answerController.clear();

    if (interviewVM.isLastQuestion) {
      // All questions answered - go to evaluation
      _finishInterview();
    } else {
      setState(() {
        _questionStartTime = 0;
      });
    }
  }

  void _skipQuestion(InterviewViewModel interviewVM) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Question?'),
        content: const Text('Question skipped. This will be noted in your final evaluation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await interviewVM.skipQuestion();
      _answerController.clear();

      if (interviewVM.isLastQuestion) {
        _finishInterview();
      } else {
        setState(() {
          _questionStartTime = 0;
        });
      }
    }
  }

  void _repeatQuestion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repeat Question?'),
        content: const Text('This will clear your current answer and restart the timer for this question.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);
              interviewVM.repeatQuestion();
              _answerController.clear();
              setState(() {
                _questionStartTime = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Question timer restarted'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Repeat'),
          ),
        ],
      ),
    );
  }

  void _finishInterview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);

    // Check completion percentage (A5)
    final completionRate = interviewVM.answeredQuestionsCount / interviewVM.totalQuestions;
    if (completionRate < 0.5) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Session'),
          content: const Text(
            'Complete more questions for comprehensive feedback and accurate scoring. Continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _proceedToEvaluation(user.uid);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      return;
    }

    _proceedToEvaluation(user.uid);
  }

  void _proceedToEvaluation(String userId) async {
    // Show evaluation loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Analyzing your responses...\nThis may take 5-8 seconds.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      final interviewVM = Provider.of<InterviewViewModel>(context, listen: false);
      final success = await interviewVM.evaluateInterview(userId);

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Navigate to results
        Navigator.pushReplacementNamed(context, '/interview-results');
      } else {
        throw Exception('Evaluation failed');
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