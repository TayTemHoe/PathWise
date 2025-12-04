// lib/viewModel/big_five_test_view_model.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter/foundation.dart';
import '../model/big_five_model.dart';
import '../repository/big_five_repository.dart';

class BigFiveTestViewModel extends ChangeNotifier {
  final BigFiveRepository _repository = BigFiveRepository.instance;

  // State
  List<BigFiveQuestion> _questions = [];
  final Map<String, BigFiveAnswer> _answers = {}; // questionId -> answer
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  BigFiveResult? _result;

  // Auto-save timer
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  String? _lastLoadedUserId;

  // Getters
  List<BigFiveQuestion> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get totalQuestions => _questions.length;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  BigFiveResult? get result => _result;

  // Helper to get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  bool get hasAnsweredCurrent =>
      _currentQuestionIndex < _questions.length &&
          _answers.containsKey(_questions[_currentQuestionIndex].id);

  int? get currentAnswer => _currentQuestionIndex < _questions.length
      ? _answers[_questions[_currentQuestionIndex].id]?.score
      : null;

  int get answeredCount => _answers.length;

  double get progress => _questions.isEmpty
      ? 0.0
      : _answers.length / _questions.length;

  bool get canSubmit => _answers.length == _questions.length;

  BigFiveQuestion? get currentQuestion =>
      _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;

  /// Initialize the test
  Future<void> initialize() async {
    if (_userId == null) {
      _errorMessage = 'User not logged in';
      notifyListeners();
      return;
    }

    if (_lastLoadedUserId != null && _lastLoadedUserId != _userId) {
      debugPrint('🔄 User changed - clearing test data');
      _clearTestData();
      _lastLoadedUserId = _userId; // ✅ SET IMMEDIATELY
      notifyListeners(); // ✅ FORCE UI UPDATE
      return; // ✅ EXIT EARLY, LET USER RE-INITIALIZE
    }
    _lastLoadedUserId = _userId;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🚀 Initializing Big Five test for user: $_userId...');

      // Load saved progress with userId
      final savedProgress = await _repository.loadProgress(_userId!);

      if (savedProgress != null) {
        debugPrint('📂 Found saved progress: ${savedProgress.answers.length} answers');

        // Restore answers
        for (var answer in savedProgress.answers) {
          _answers[answer.questionId] = answer;
        }
        _currentQuestionIndex = savedProgress.currentQuestionIndex;
      }

      // Fetch questions (shared data, no userId needed)
      _questions = await _repository.getQuestions();
      debugPrint('✅ Loaded ${_questions.length} questions');

      // Check if test was already completed with userId
      final savedResult = await _repository.loadResult(_userId!);
      if (savedResult != null) {
        debugPrint('📊 Found saved result');
        _result = savedResult;
      }

    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      _errorMessage = 'Failed to load test: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Answer current question
  void answerQuestion(int score) {
    if (_currentQuestionIndex >= _questions.length) return;

    final question = _questions[_currentQuestionIndex];
    _answers[question.id] = BigFiveAnswer(
      questionId: question.id,
      domain: question.domain,
      facet: question.facet,
      score: score,
    );
    _hasUnsavedChanges = true;

    debugPrint('✅ Question ${_currentQuestionIndex + 1}/$totalQuestions answered: $score');

    // Schedule auto-save
    _scheduleAutoSave();

    notifyListeners();
  }

  /// Go to next question
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  /// Go to previous question
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  /// Jump to specific question
  void goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  /// Schedule auto-save (debounced)
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _autoSave();
    });
  }

  /// Auto-save progress
  Future<void> _autoSave() async {
    if (!_hasUnsavedChanges || _userId == null) return;

    try {
      final progress = BigFiveTestProgress(
        answers: _answers.values.toList(),
        currentQuestionIndex: _currentQuestionIndex,
        lastUpdated: DateTime.now(),
      );

      await _repository.saveProgress(_userId!, progress);
      _hasUnsavedChanges = false;
      debugPrint('💾 Auto-saved progress: ${_answers.length} answers');
    } catch (e) {
      debugPrint('⚠️ Auto-save failed: $e');
      // Don't show error to user - auto-save failure is non-critical
    }
  }

  /// Submit test
  Future<void> submitTest() async {
    if (!canSubmit) {
      _errorMessage = 'Please answer all questions';
      notifyListeners();
      return;
    }

    if (_userId == null) {
      _errorMessage = 'User session invalid. Please login again.';
      notifyListeners();
      return;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📤 Submitting Big Five test...');

      final answersList = _answers.values.toList();

      // Submit with userId
      _result = await _repository.submitTest(
        userId: _userId!,
        answers: answersList,
      );

      debugPrint('✅ Test submitted successfully');

    } catch (e) {
      debugPrint('❌ Submission error: $e');
      _errorMessage = 'Failed to submit test: ${e.toString()}';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Restart test
  Future<void> restartTest() async {
    if (_userId == null) return;

    try {
      // Restart with userId
      await _repository.restartTest(_userId!);

      _answers.clear();
      _currentQuestionIndex = 0;
      _result = null;
      _errorMessage = null;
      _hasUnsavedChanges = false;

      debugPrint('🔄 Test restarted');

      // Only notify if not disposed
      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Restart error: $e');
      _errorMessage = 'Failed to restart test: ${e.toString()}';
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  // Track disposal state
  bool _isDisposed = false;

  /// Check if a specific question is answered
  bool isQuestionAnswered(int index) {
    if (index >= _questions.length) return false;
    return _answers.containsKey(_questions[index].id);
  }

  /// Get answer for a specific question
  int? getAnswerForQuestion(int index) {
    if (index >= _questions.length) return null;
    return _answers[_questions[index].id]?.score;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoSaveTimer?.cancel();
    // Perform final auto-save
    if (_hasUnsavedChanges) {
      _autoSave();
    }
    super.dispose();
  }

  void _clearTestData() {
    _questions = [];
    _answers.clear();
    _currentQuestionIndex = 0;
    _result = null;
    _errorMessage = null;
    _hasUnsavedChanges = false;
    // Add any other state variables specific to each test
  }

  void reset() {
    _clearTestData();
    _lastLoadedUserId = null;
    notifyListeners();
    debugPrint('🧹 Big Five ViewModel reset');
  }
}