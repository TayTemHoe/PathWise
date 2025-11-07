// lib/viewmodel/career_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:path_wise/model/career_suggestion.dart';
import 'package:path_wise/service/gemini_service.dart';
import 'package:path_wise/service/career_service.dart';
import 'package:path_wise/ViewModel/profile_view_model.dart';

/// ViewModel for managing career suggestions
/// Follows MVVM architecture pattern with ChangeNotifier for state management
class CareerViewModel extends ChangeNotifier {
  // Services
  final AiService _aiService = AiService();
  final CareerService _careerService = CareerService();

  // State variables
  CareerSuggestion? _latestSuggestion;
  List<CareerSuggestion> _suggestionsHistory = [];
  String? _errorMessage;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _lastGeneratedId;

  // Getters for UI to access state
  CareerSuggestion? get latestSuggestion => _latestSuggestion;
  List<CareerSuggestion> get suggestionsHistory => _suggestionsHistory;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get lastGeneratedId => _lastGeneratedId;
  bool get hasLatestSuggestion => _latestSuggestion != null;
  bool get hasHistory => _suggestionsHistory.isNotEmpty;
  bool get hasError => _errorMessage != null;

  /// Get total count of suggestions
  int get totalSuggestionsCount => _suggestionsHistory.length;

  /// Get top N career matches from latest suggestion
  List<CareerMatch> getTopMatches({int limit = 3}) {
    if (_latestSuggestion == null) return [];
    return _latestSuggestion!.matches.take(limit).toList();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set generating state
  void _setGenerating(bool value) {
    _isGenerating = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    _isGenerating = false;
    notifyListeners();
  }

  /// Generate new career suggestions from AI
  /// This is the main action that generates suggestions based on user profile
  Future<bool> generateCareerSuggestions({
    required String userId,
    required ProfileViewModel profileViewModel,
  }) async {
    try {
      _setGenerating(true);
      _errorMessage = null;

      // Validate profile
      if (profileViewModel.profile == null) {
        throw Exception('User profile is not loaded');
      }

      final profile = profileViewModel.profile!;

      // Check profile completion
      if ((profile.completionPercent ?? 0) < 30) {
        _setError('Profile completion is too low (${profile.completionPercent}%). Please complete at least 30% of your profile.');
        return false;
      }

      debugPrint('🤖 Requesting career suggestions from Gemini AI...');

      final predictions = await _aiService.getCareerSuggestions(profileViewModel);

      debugPrint('✅ Received predictions from AI');

      // Step 2: Save to Firestore (automatically marks previous as stale)
      final suggestionId = await _aiService.saveCareerSuggestionToFirestore(
        userId,
        predictions,
        profile,
      );

      _lastGeneratedId = suggestionId;
      debugPrint('💾 Saved career suggestion: $suggestionId');

      // Step 3: Refresh latest suggestion and history
      await fetchLatestSuggestion(userId);
      await fetchSuggestionsHistory(userId);

      _setGenerating(false);
      return true;
    } catch (e) {
      debugPrint('❌ Error generating career suggestions: $e');
      _setError('Failed to generate career suggestions: ${e.toString()}');
      return false;
    }
  }

  /// Fetch the latest career suggestion for a user
  Future<void> fetchLatestSuggestion(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final suggestion = await _careerService.getLatestCareerSuggestion(userId);
      _latestSuggestion = suggestion;

      _setLoading(false);

      if (suggestion == null) {
        debugPrint('⚠️ No latest career suggestion found');
      } else {
        debugPrint('📌 Fetched latest suggestion: ${suggestion.id}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching latest suggestion: $e');
      _setError('Failed to fetch latest suggestion: ${e.toString()}');
    }
  }

  /// Fetch all career suggestions history
  Future<void> fetchSuggestionsHistory(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final history = await _careerService.getCareerSuggestionsHistory(userId);
      _suggestionsHistory = history;

      _setLoading(false);
      debugPrint('📚 Fetched ${history.length} career suggestions');
    } catch (e) {
      debugPrint('❌ Error fetching suggestions history: $e');
      _setError('Failed to fetch suggestions history: ${e.toString()}');
    }
  }

  /// Fetch a specific career suggestion by ID
  Future<CareerSuggestion?> fetchSuggestionById(
      String userId,
      String suggestionId,
      ) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final suggestion = await _careerService.getCareerSuggestionById(
        userId,
        suggestionId,
      );

      _setLoading(false);

      if (suggestion == null) {
        debugPrint('⚠️ Suggestion $suggestionId not found');
      } else {
        debugPrint('📄 Fetched suggestion: ${suggestion.id}');
      }

      return suggestion;
    } catch (e) {
      debugPrint('❌ Error fetching suggestion by ID: $e');
      _setError('Failed to fetch suggestion: ${e.toString()}');
      return null;
    }
  }

  /// Delete a specific career suggestion
  Future<bool> deleteSuggestion(String userId, String suggestionId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _careerService.deleteCareerSuggestion(userId, suggestionId);

      // Refresh data
      await fetchLatestSuggestion(userId);
      await fetchSuggestionsHistory(userId);

      _setLoading(false);
      debugPrint('🗑️ Deleted suggestion: $suggestionId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting suggestion: $e');
      _setError('Failed to delete suggestion: ${e.toString()}');
      return false;
    }
  }

  /// Delete all career suggestions
  Future<bool> deleteAllSuggestions(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _careerService.deleteAllCareerSuggestions(userId);

      // Clear local state
      _latestSuggestion = null;
      _suggestionsHistory = [];

      _setLoading(false);
      debugPrint('🗑️ Deleted all suggestions for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting all suggestions: $e');
      _setError('Failed to delete all suggestions: ${e.toString()}');
      return false;
    }
  }

  /// Mark a suggestion as stale manually
  Future<bool> markSuggestionAsStale(String userId, String suggestionId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _aiService.markAsStale(userId, suggestionId);

      // Refresh data
      await fetchLatestSuggestion(userId);
      await fetchSuggestionsHistory(userId);

      _setLoading(false);
      debugPrint('✅ Marked suggestion $suggestionId as stale');
      return true;
    } catch (e) {
      debugPrint('❌ Error marking suggestion as stale: $e');
      _setError('Failed to mark suggestion as stale: ${e.toString()}');
      return false;
    }
  }

  /// Initialize: Load latest suggestion and history
  Future<void> initialize(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await Future.wait([
        fetchLatestSuggestion(userId),
        fetchSuggestionsHistory(userId),
      ]);

      _setLoading(false);
      debugPrint('✅ CareerViewModel initialized for user $userId');
    } catch (e) {
      debugPrint('❌ Error initializing CareerViewModel: $e');
      _setError('Failed to initialize: ${e.toString()}');
    }
  }

  /// Refresh all data
  Future<void> refresh(String userId) async {
    await initialize(userId);
  }

  /// Listen to real-time updates for latest suggestion
  void startListeningToLatest(String userId) {
    _careerService.streamLatestCareerSuggestion(userId).listen(
          (suggestion) {
        _latestSuggestion = suggestion;
        notifyListeners();
        debugPrint('🔄 Real-time update: Latest suggestion changed');
      },
      onError: (error) {
        debugPrint('❌ Stream error: $error');
        _setError('Real-time update error: $error');
      },
    );
  }

  /// Listen to real-time updates for history
  void startListeningToHistory(String userId) {
    _careerService.streamCareerSuggestionsHistory(userId).listen(
          (history) {
        _suggestionsHistory = history;
        notifyListeners();
        debugPrint('🔄 Real-time update: History changed (${history.length} items)');
      },
      onError: (error) {
        debugPrint('❌ Stream error: $error');
        _setError('Real-time update error: $error');
      },
    );
  }

  /// Get suggestion statistics
  Map<String, dynamic> getStatistics() {
    if (_latestSuggestion == null) {
      return {
        'hasData': false,
        'message': 'No career suggestions available',
      };
    }

    final matches = _latestSuggestion!.matches;
    final avgFitScore = matches.isEmpty
        ? 0
        : matches.map((m) => m.fitScore).reduce((a, b) => a + b) / matches.length;

    return {
      'hasData': true,
      'latestId': _latestSuggestion!.id,
      'createdAt': _latestSuggestion!.createdAt,
      'totalMatches': matches.length,
      'averageFitScore': avgFitScore.round(),
      'profileCompletion': _latestSuggestion!.profileCompletionPercent,
      'topCareer': matches.isNotEmpty ? matches.first.jobTitle : 'N/A',
      'totalHistory': _suggestionsHistory.length,
    };
  }

  /// Search suggestions by job title
  List<CareerMatch> searchCareersByTitle(String query) {
    if (_latestSuggestion == null || query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return _latestSuggestion!.matches.where((match) {
      return match.jobTitle.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Filter matches by minimum fit score
  List<CareerMatch> filterByFitScore(int minScore) {
    if (_latestSuggestion == null) return [];

    return _latestSuggestion!.matches.where((match) {
      return match.fitScore >= minScore;
    }).toList();
  }

  /// Get matches sorted by salary
  List<CareerMatch> getMatchesSortedBySalary({bool descending = true}) {
    if (_latestSuggestion == null) return [];

    final matches = List<CareerMatch>.from(_latestSuggestion!.matches);
    matches.sort((a, b) {
      final aMax = a.avgSalaryMYR['max'] ?? 0;
      final bMax = b.avgSalaryMYR['max'] ?? 0;
      return descending ? bMax.compareTo(aMax) : aMax.compareTo(bMax);
    });

    return matches;
  }

  /// Compare two suggestions
  Map<String, dynamic>? compareSuggestions(String id1, String id2) {
    final suggestion1 = _suggestionsHistory.firstWhere(
          (s) => s.id == id1,
      orElse: () => throw Exception('Suggestion $id1 not found'),
    );

    final suggestion2 = _suggestionsHistory.firstWhere(
          (s) => s.id == id2,
      orElse: () => throw Exception('Suggestion $id2 not found'),
    );

    return {
      'suggestion1': {
        'id': suggestion1.id,
        'date': suggestion1.createdAt,
        'matchCount': suggestion1.matches.length,
        'profileCompletion': suggestion1.profileCompletionPercent,
      },
      'suggestion2': {
        'id': suggestion2.id,
        'date': suggestion2.createdAt,
        'matchCount': suggestion2.matches.length,
        'profileCompletion': suggestion2.profileCompletionPercent,
      },
      'improvement': {
        'matchesChange': suggestion2.matches.length - suggestion1.matches.length,
        'profileChange': suggestion2.profileCompletionPercent - suggestion1.profileCompletionPercent,
      },
    };
  }

  @override
  void dispose() {
    // Clean up resources
    debugPrint('🧹 CareerViewModel disposed');
    super.dispose();
  }
}