// lib/viewmodel/interview_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_wise/model/interview_model.dart';
import 'package:path_wise/services/gemini_service.dart';
import 'package:path_wise/services/interview_service.dart';

/// viewModel for managing interview simulator sessions
class InterviewViewModel extends ChangeNotifier {
  final AiService _aiService = AiService();
  final InterviewService _interviewService = InterviewService();

  // Current session state
  InterviewSession? _currentSession;
  List<InterviewSession> _sessionHistory = [];
  List<InterviewSession> _recentSessions = [];

  int _currentQuestionIndex = 0;
  Map<String, String> _userAnswers = {}; // questionId -> answer
  Map<String, int> _responseTimesSeconds = {}; // questionId -> seconds
  DateTime? _sessionStartTime;
  DateTime? _currentQuestionStartTime;

  // Loading states
  bool _isGeneratingQuestions = false;
  bool _isEvaluating = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  InterviewSession? get currentSession => _currentSession;
  List<InterviewSession> get sessionHistory => _sessionHistory;
  List<InterviewSession> get recentSessions => _recentSessions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get totalQuestions => _currentSession?.questions.length ?? 0;
  InterviewQuestion? get currentQuestion {
    if (_currentSession == null || _currentQuestionIndex >= totalQuestions) {
      return null;
    }
    return _currentSession!.questions[_currentQuestionIndex];
  }

  bool get isGeneratingQuestions => _isGeneratingQuestions;
  bool get isEvaluating => _isEvaluating;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  bool get hasCurrentSession => _currentSession != null;
  bool get isLastQuestion => _currentQuestionIndex == totalQuestions - 1;
  bool get hasHistory => _sessionHistory.isNotEmpty;

  int get answeredQuestionsCount => _userAnswers.length;
  int get skippedQuestionsCount {
    if (_currentSession == null) return 0;
    return _currentQuestionIndex - _userAnswers.length;
  }

  /// Get elapsed time for current session in minutes
  int getElapsedTimeMinutes() {
    if (_sessionStartTime == null) return 0;
    return DateTime.now().difference(_sessionStartTime!).inMinutes;
  }

  /// Get elapsed time for current question in seconds
  int getCurrentQuestionElapsedSeconds() {
    if (_currentQuestionStartTime == null) return 0;
    return DateTime.now().difference(_currentQuestionStartTime!).inSeconds;
  }

  /// Get remaining time in minutes
  int getRemainingTimeMinutes() {
    if (_currentSession == null || _sessionStartTime == null) return 0;
    final elapsed = getElapsedTimeMinutes();
    return (_currentSession!.sessionDuration - elapsed).clamp(0, _currentSession!.sessionDuration);
  }

  /// Check if time warning should be shown (5 minutes remaining)
  bool shouldShowTimeWarning() {
    return getRemainingTimeMinutes() <= 5 && getRemainingTimeMinutes() > 0;
  }

  /// Check if session has timed out
  bool hasTimedOut() {
    return getRemainingTimeMinutes() <= 0;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isGeneratingQuestions = false;
    _isEvaluating = false;
    _isLoading = false;
    notifyListeners();
  }

  void _setGeneratingQuestions(bool value) {
    _isGeneratingQuestions = value;
    notifyListeners();
  }

  void _setEvaluating(bool value) {
    _isEvaluating = value;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Generate and start new interview session
  Future<bool> startNewInterviewSession({
    required String userId,
    required String jobTitle,
    required String difficultyLevel,
    required int sessionDuration,
    required int numQuestions,
    required List<String> questionCategories,
  }) async {
    try {
      _setGeneratingQuestions(true);
      _errorMessage = null;

      debugPrint('🎤 Starting interview: $jobTitle ($difficultyLevel)');

      // Generate questions from AI
      final questionsResponse = await _aiService.generateInterviewQuestions(
        jobTitle: jobTitle,
        difficultyLevel: difficultyLevel,
        numQuestions: numQuestions,
        questionCategories: questionCategories,
        sessionDuration: sessionDuration,
      );

      // Generate session ID
      final sessionId = await _aiService.generateNextInterviewSessionId(userId);

      // Parse questions
      final questions = (questionsResponse['questions'] as List<dynamic>)
          .map((q) => InterviewQuestion.fromGemini(Map<String, dynamic>.from(q)))
          .toList();

      // Create session
      _currentSession = InterviewSession(
        id: sessionId,
        jobTitle: jobTitle,
        difficultyLevel: difficultyLevel,
        sessionDuration: sessionDuration,
        numQuestions: numQuestions,
        questionCategories: questionCategories,
        questions: questions,
        startTime: Timestamp.now(),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        isRetake: false,
      );

      // Save initial session to Firestore
      await _aiService.saveInterviewSessionToFirestore(
        uid: userId,
        sessionData: _currentSession!.toMap(),
      );

      // Initialize session tracking
      _currentQuestionIndex = 0;
      _userAnswers = {};
      _responseTimesSeconds = {};
      _sessionStartTime = DateTime.now();
      _currentQuestionStartTime = DateTime.now();

      _setGeneratingQuestions(false);
      debugPrint('✅ Interview session started: $sessionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting interview: $e');
      _setError('Failed to start interview: ${e.toString()}');
      return false;
    }
  }

  /// Submit answer for current question and move to next
  Future<void> submitAnswer(String answer) async {
    if (_currentSession == null || currentQuestion == null) return;

    try {
      final questionId = currentQuestion!.questionId;

      // Record answer and response time
      _userAnswers[questionId] = answer;
      _responseTimesSeconds[questionId] = getCurrentQuestionElapsedSeconds();

      // Update question with answer
      final updatedQuestions = List<InterviewQuestion>.from(_currentSession!.questions);
      updatedQuestions[_currentQuestionIndex] = currentQuestion!.copyWith(
        userAnswer: answer,
      );

      _currentSession = _currentSession!.copyWith(questions: updatedQuestions);

      debugPrint('✅ Answer submitted for $questionId');

      // Move to next question if not last
      if (!isLastQuestion) {
        _currentQuestionIndex++;
        _currentQuestionStartTime = DateTime.now();
        notifyListeners();
      } else {
        // Last question - session complete
        debugPrint('🎯 All questions answered');
      }
    } catch (e) {
      debugPrint('❌ Error submitting answer: $e');
      _setError('Failed to submit answer: ${e.toString()}');
    }
  }

  /// Skip current question
  Future<void> skipQuestion() async {
    if (_currentSession == null || currentQuestion == null) return;

    try {
      final questionId = currentQuestion!.questionId;

      // Record as skipped (empty answer)
      _userAnswers[questionId] = '';
      _responseTimesSeconds[questionId] = getCurrentQuestionElapsedSeconds();

      debugPrint('⏭️ Question skipped: $questionId');

      // Move to next question
      if (!isLastQuestion) {
        _currentQuestionIndex++;
        _currentQuestionStartTime = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error skipping question: $e');
      _setError('Failed to skip question: ${e.toString()}');
    }
  }

  /// Repeat/clear answer for current question
  void repeatQuestion() {
    if (currentQuestion != null) {
      final questionId = currentQuestion!.questionId;
      _userAnswers.remove(questionId);
      _currentQuestionStartTime = DateTime.now();
      notifyListeners();
      debugPrint('🔄 Question repeated: $questionId');
    }
  }

  /// Get user's answer for current question
  String getUserAnswer(String questionId) {
    return _userAnswers[questionId] ?? '';
  }

  /// Evaluate interview and save results
  Future<bool> evaluateInterview(String userId) async {
    if (_currentSession == null) {
      _setError('No active interview session');
      return false;
    }

    try {
      _setEvaluating(true);
      _errorMessage = null;

      debugPrint('📊 Evaluating interview...');

      // Calculate total duration
      final totalDuration = getElapsedTimeMinutes();

      // Prepare questions and answers for evaluation
      final questionsAndAnswers = _currentSession!.questions.map((q) {
        return {
          'questionId': q.questionId,
          'questionType': q.questionType,
          'questionText': q.questionText,
          'userAnswer': _userAnswers[q.questionId] ?? '',
          'responseTimeSeconds': _responseTimesSeconds[q.questionId] ?? 0,
        };
      }).toList();

      // Get evaluation from AI
      final evaluation = await _aiService.evaluateInterviewResponses(
        jobTitle: _currentSession!.jobTitle,
        difficultyLevel: _currentSession!.difficultyLevel,
        questionsAndAnswers: questionsAndAnswers,
        totalDuration: totalDuration,
        sessionDuration: _currentSession!.sessionDuration,
      );

      // Update questions with individual scores and feedback
      final questionEvaluations = evaluation['questionEvaluations'] as List<dynamic>;
      final updatedQuestions = _currentSession!.questions.map((q) {
        final eval = questionEvaluations.firstWhere(
              (e) => e['questionId'] == q.questionId,
          orElse: () => <String, dynamic>{},
        );

        return q.copyWith(
          userAnswer: _userAnswers[q.questionId],
          aiScore: eval['aiScore'] as int?,
          aiFeedback: eval['aiFeedback']?.toString(),
        );
      }).toList();

      // Update session with evaluation results
      _currentSession = _currentSession!.copyWith(
        questions: updatedQuestions,
        endTime: Timestamp.now(),
        totalScore: evaluation['totalScore'] as int?,
        contentScore: evaluation['contentScore'] as int?,
        communicationScore: evaluation['communicationScore'] as int?,
        responseTimeScore: evaluation['responseTimeScore'] as int?,
        confidenceScore: evaluation['confidenceScore'] as int?,
        feedback: evaluation['feedback']?.toString(),
        recommendations: (evaluation['recommendations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        updatedAt: Timestamp.now(),
      );

      // Save evaluation to Firestore
      await _interviewService.updateInterviewSessionWithEvaluation(
        uid: userId,
        sessionId: _currentSession!.id,
        evaluationData: {
          'endTime': _currentSession!.endTime,
          'totalScore': _currentSession!.totalScore,
          'contentScore': _currentSession!.contentScore,
          'communicationScore': _currentSession!.communicationScore,
          'responseTimeScore': _currentSession!.responseTimeScore,
          'confidenceScore': _currentSession!.confidenceScore,
          'feedback': _currentSession!.feedback,
          'recommendations': _currentSession!.recommendations,
          'questions': _currentSession!.questions.map((q) => q.toMap()).toList(),
        },
      );

      _setEvaluating(false);
      debugPrint('✅ Interview evaluated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error evaluating interview: $e');
      _setError('Failed to evaluate interview: ${e.toString()}');
      return false;
    }
  }

  /// Load interview session history
  Future<void> loadSessionHistory(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final sessions = await _interviewService.getAllInterviewSessions(userId);
      _sessionHistory = sessions
          .map((data) => InterviewSession.fromMap(data, id: data['id']))
          .toList();

      _setLoading(false);
      debugPrint('📚 Loaded ${_sessionHistory.length} interview sessions');
    } catch (e) {
      debugPrint('❌ Error loading session history: $e');
      _setError('Failed to load session history: ${e.toString()}');
    }
  }

  /// Load recent interview sessions
  Future<void> loadRecentSessions(String userId, {int limit = 5}) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final sessions = await _interviewService.getRecentInterviewSessions(userId, limit: limit);
      _recentSessions = sessions
          .map((data) => InterviewSession.fromMap(data, id: data['id']))
          .toList();

      _setLoading(false);
      debugPrint('📌 Loaded ${_recentSessions.length} recent sessions');
    } catch (e) {
      debugPrint('❌ Error loading recent sessions: $e');
      _setError('Failed to load recent sessions: ${e.toString()}');
    }
  }

  /// Load specific session by ID
  Future<void> loadSession(String userId, String sessionId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final sessionData = await _interviewService.getInterviewSession(userId, sessionId);
      if (sessionData != null) {
        _currentSession = InterviewSession.fromMap(sessionData, id: sessionId);
        debugPrint('📖 Loaded session: $sessionId');
      } else {
        throw Exception('Session not found');
      }

      _setLoading(false);
    } catch (e) {
      debugPrint('❌ Error loading session: $e');
      _setError('Failed to load session: ${e.toString()}');
    }
  }

  /// Create retake session from existing session
  Future<bool> retakeSession({
    required String userId,
    required InterviewSession originalSession,
  }) async {
    try {
      _setGeneratingQuestions(true);
      _errorMessage = null;

      debugPrint('🔄 Creating retake session...');

      // Generate new session ID
      final sessionId = await _aiService.generateNextInterviewSessionId(userId);

      // Create new session with same questions but reset answers
      final resetQuestions = originalSession.questions.map((q) {
        return InterviewQuestion(
          questionId: q.questionId,
          questionType: q.questionType,
          questionText: q.questionText,
          userAnswer: null,
          aiScore: null,
          aiFeedback: null,
        );
      }).toList();

      _currentSession = InterviewSession(
        id: sessionId,
        jobTitle: originalSession.jobTitle,
        difficultyLevel: originalSession.difficultyLevel,
        sessionDuration: originalSession.sessionDuration,
        numQuestions: originalSession.numQuestions,
        questionCategories: originalSession.questionCategories,
        questions: resetQuestions,
        startTime: Timestamp.now(),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        isRetake: true,
      );

      // Save to Firestore
      await _aiService.saveInterviewSessionToFirestore(
        uid: userId,
        sessionData: _currentSession!.toMap(),
      );

      // Reset tracking
      _currentQuestionIndex = 0;
      _userAnswers = {};
      _responseTimesSeconds = {};
      _sessionStartTime = DateTime.now();
      _currentQuestionStartTime = DateTime.now();

      _setGeneratingQuestions(false);
      debugPrint('✅ Retake session created: $sessionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating retake: $e');
      _setError('Failed to create retake session: ${e.toString()}');
      return false;
    }
  }

  /// Delete session
  Future<bool> deleteSession(String userId, String sessionId) async {
    try {
      _setLoading(true);
      await _interviewService.deleteInterviewSession(userId, sessionId);

      // Refresh history
      await loadSessionHistory(userId);

      _setLoading(false);
      debugPrint('🗑️ Deleted session: $sessionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting session: $e');
      _setError('Failed to delete session: ${e.toString()}');
      return false;
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    if (_sessionHistory.isEmpty) {
      return {
        'hasData': false,
        'totalSessions': 0,
      };
    }

    final completedSessions = _sessionHistory.where((s) => s.totalScore != null).toList();

    if (completedSessions.isEmpty) {
      return {
        'hasData': false,
        'totalSessions': _sessionHistory.length,
      };
    }

    final avgScore = completedSessions
        .map((s) => s.totalScore ?? 0)
        .reduce((a, b) => a + b) / completedSessions.length;

    final highestScore = completedSessions
        .map((s) => s.totalScore ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return {
      'hasData': true,
      'totalSessions': _sessionHistory.length,
      'completedSessions': completedSessions.length,
      'averageScore': avgScore.round(),
      'highestScore': highestScore,
      'lastSessionDate': completedSessions.first.createdAt?.toDate(),
    };
  }

  /// Reset current session
  void resetCurrentSession() {
    _currentSession = null;
    _currentQuestionIndex = 0;
    _userAnswers = {};
    _responseTimesSeconds = {};
    _sessionStartTime = null;
    _currentQuestionStartTime = null;
    notifyListeners();
    debugPrint('🔄 Current session reset');
  }

  @override
  void dispose() {
    debugPrint('🧹 InterviewViewModel disposed');
    super.dispose();
  }
}