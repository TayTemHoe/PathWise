// lib/viewModel/ai_match_view_model.dart - MODIFIED VERSION
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../model/ai_match_model.dart';
import '../model/program.dart';
import '../model/program_filter.dart';
import '../repository/ai_match_repository.dart';
import '../services/shared_preference_services.dart';

class AIMatchViewModel extends ChangeNotifier {
  final AIMatchRepository _repository = AIMatchRepository.instance;
  final SharedPreferenceService _storage = SharedPreferenceService.instance;

  // Progress tracking (REMOVED _currentPage)
  int _currentPage = 0;
  double _progress = 0.0;

  // Form data
  EducationLevel? _educationLevel;
  String? _otherEducationLevelText;
  final List<AcademicRecord> _academicRecords = [];
  final List<EnglishTest> _englishTests = [];
  PersonalityProfile? _personalityProfile;
  final List<String> _interests = [];
  UserPreferences _preferences = UserPreferences();

  // AI match results
  AIMatchResponse? _matchResponse;
  List<ProgramModel>? _matchedPrograms;
  List<String>? _matchedProgramIds;
  DateTime? _matchTimestamp;
  bool _isGeneratingMatches = false;
  String? _errorMessage;

  // Available options (cached)
  List<String> _availableSubjectAreas = [];
  List<String> _availableStudyModes = [];
  List<String> _availableStudyLevels = [];
  List<String> _availableCountries = [];
  (double, double) _tuitionRange = (0, 500000);

  // Getters
  int get currentPage => _currentPage;
  double get progress => _progress;
  EducationLevel? get educationLevel => _educationLevel;
  String? get otherEducationLevelText => _otherEducationLevelText;
  List<AcademicRecord> get academicRecords => _academicRecords;
  List<EnglishTest> get englishTests => _englishTests;
  PersonalityProfile? get personalityProfile => _personalityProfile;
  List<String> get interests => _interests;
  UserPreferences get preferences => _preferences;
  AIMatchResponse? get matchResponse => _matchResponse;
  List<ProgramModel>? get matchedPrograms => _matchedPrograms;
  List<String>? get matchedProgramIds => _matchedProgramIds;
  DateTime? get matchTimestamp => _matchTimestamp;
  bool get hasAIMatches => _matchResponse != null && _matchedProgramIds != null;
  bool get isGeneratingMatches => _isGeneratingMatches;
  String? get errorMessage => _errorMessage;
  List<String> get availableSubjectAreas => _availableSubjectAreas;
  List<String> get availableStudyModes => _availableStudyModes;
  List<String> get availableStudyLevels => _availableStudyLevels;
  List<String> get availableCountries => _availableCountries;
  (double, double) get tuitionRange => _tuitionRange;

  bool get canProceed {
    switch (_currentPage) {
      case 0: // Education + Academic
        if (_educationLevel == null) return false;
        if (_educationLevel == EducationLevel.other) {
          if (_otherEducationLevelText == null ||
              _otherEducationLevelText!.trim().isEmpty) {
            return false;
          }
        }
        return _academicRecords.isNotEmpty;
      case 1: // English Tests
        return _englishTests.isNotEmpty;
      case 2: // Interests
        return _interests.isNotEmpty;
      case 3: // Personality (Optional)
        return true;
      case 4: // Preferences (Has defaults)
        return true;
      case 5: // Review
        return true;
      default:
        return false;
    }
  }

  // Initialize
  Future<void> initialize() async {
    try {
      debugPrint('🚀 Initializing AI Match viewModel...');
      await _loadAvailableOptions();
      await loadProgress();
      debugPrint('✅ AI Match viewModel initialized');
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
    }
  }

  Future<void> _loadAvailableOptions() async {
    _availableSubjectAreas = await _repository.getAvailableSubjectAreas();
    _availableStudyModes = await _repository.getAvailableStudyModes();
    _availableStudyLevels = await _repository.getAvailableStudyLevels();
    _availableCountries = await _repository.getAvailableCountries();
    _tuitionRange = await _repository.getProgramTuitionFeeRange();
    notifyListeners();
  }

  // UPDATED: Save progress
  Future<void> saveProgress() async {
    try {
      await _storage.saveProgressWithPrograms(
        educationLevel: _educationLevel,
        otherEducationText: _otherEducationLevelText,
        academicRecords: _academicRecords,
        englishTests: _englishTests,
        personality: _personalityProfile,
        interests: _interests,
        preferences: _preferences,
        matchResponse: _matchResponse,
        matchedProgramIds: _matchedProgramIds,
      );
      debugPrint('✅ Progress saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving progress: $e');
      rethrow;
    }
  }

  // UPDATED: Load progress
  Future<void> loadProgress({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        debugPrint('🔄 Force refreshing AI match data from storage');
      }

      final progressData = await _storage.loadProgressWithPrograms(
        forceRefresh: forceRefresh,
      );

      if (progressData == null) {
        debugPrint('ℹ️ No saved progress to load');
        return;
      }

      // Apply loaded data
      _educationLevel = progressData.educationLevel;
      _otherEducationLevelText = progressData.otherEducationText;

      _academicRecords.clear();
      _academicRecords.addAll(progressData.academicRecords);

      _englishTests.clear();
      _englishTests.addAll(progressData.englishTests);

      _personalityProfile = progressData.personality;

      _interests.clear();
      _interests.addAll(progressData.interests);

      _preferences = progressData.preferences;
      _matchResponse = progressData.matchResponse;
      _matchedProgramIds = progressData.matchedProgramIds;
      _matchTimestamp = progressData.matchTimestamp;

      _updateProgress();
      debugPrint('✅ Progress loaded successfully');

      if (_matchedProgramIds != null) {
        debugPrint('📊 Loaded ${_matchedProgramIds!.length} matched programs');
        debugPrint('📋 Program IDs: $_matchedProgramIds');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading progress: $e');
    }
  }

  Future<void> clearSavedProgress() async {
    await _storage.clearProgress();
  }

  Future<bool> hasSavedProgress() async {
    return await _storage.hasSavedProgress();
  }

  void _autoSaveProgress() {
    Future.delayed(const Duration(milliseconds: 500), () {
      saveProgress();
    });
  }

  // Navigation
  void nextPage() {
    if (_currentPage < 6) {
      _currentPage++;
      _updateProgress();
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _updateProgress();
      notifyListeners();
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page <= 6) {
      _currentPage = page;
      _updateProgress();
      notifyListeners();
    }
  }

  void _updateProgress() {
    switch (_currentPage) {
      case 0: _progress = 0.15; break;
      case 1: _progress = 0.35; break;
      case 2: _progress = 0.55; break;
      case 3: _progress = 0.70; break;
      case 4: _progress = 0.85; break;
      case 5: _progress = 0.95; break;
      case 6: _progress = 1.0; break;
    }
  }

  // Data modification methods with auto-save
  void setEducationLevel(EducationLevel level) {
    if (!canChangeEducationLevel()) return;
    _educationLevel = level;
    notifyListeners();
    _autoSaveProgress();
  }

  void setOtherEducationLevelText(String text) {
    _otherEducationLevelText = text;
    notifyListeners();
    _autoSaveProgress();
  }

  void addAcademicRecord(AcademicRecord record) {
    _academicRecords.add(record);
    notifyListeners();
    _autoSaveProgress();
  }

  void updateAcademicRecord(int index, AcademicRecord record) {
    if (index >= 0 && index < _academicRecords.length) {
      _academicRecords[index] = record;
      notifyListeners();
      _autoSaveProgress();
    }
  }

  void removeAcademicRecord(int index) {
    if (index >= 0 && index < _academicRecords.length) {
      _academicRecords.removeAt(index);
      notifyListeners();
      _autoSaveProgress();
    }
  }

  void addEnglishTest(EnglishTest test) {
    _englishTests.add(test);
    notifyListeners();
    _autoSaveProgress();
  }

  void removeEnglishTest(int index) {
    if (index >= 0 && index < _englishTests.length) {
      _englishTests.removeAt(index);
      notifyListeners();
      _autoSaveProgress();
    }
  }

  void toggleInterest(String interest) {
    if (_interests.contains(interest)) {
      _interests.remove(interest);
    } else if (_interests.length < 6) {
      _interests.add(interest);
    }
    notifyListeners();
    _autoSaveProgress();
  }

  void setInterests(List<String> interests) {
    _interests.clear();
    _interests.addAll(interests);
    notifyListeners();
    _autoSaveProgress();
  }

  void setPersonalityProfile(PersonalityProfile profile) {
    _personalityProfile = profile;
    notifyListeners();
    _autoSaveProgress();
  }

  void updatePreferences(UserPreferences preferences) {
    _preferences = preferences;
    notifyListeners();
    _autoSaveProgress();
  }

  bool canChangeEducationLevel() {
    return _academicRecords.isEmpty;
  }

  void clearAllAcademicRecords() {
    _academicRecords.clear();
    notifyListeners();
    _autoSaveProgress();
  }

  void updateEnglishTest(int index, EnglishTest newTest) {
    if (index >= 0 && index < englishTests.length) {
      englishTests[index] = newTest;
      notifyListeners();
    }
  }

  // UPDATED: Generate AI Matches
  Future<void> generateMatches() async {
    _isGeneratingMatches = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPage = 6;
      debugPrint('🎯 Starting AI match generation...');

      final request = AIMatchRequest(
        academicRecords: _academicRecords,
        englishTests: _englishTests,
        personality: _personalityProfile,
        interests: _interests,
        preferences: _preferences,
      );

      await _repository.saveMatchRequest(request);

      // Generate matches
      _matchResponse = await _repository.generateMatches(request);
      debugPrint('✅ AI matches generated: ${_matchResponse!.recommendedSubjectAreas.length}');

      // Fetch programs
      _matchedPrograms = await _repository.getProgramsForRecommendations(
        recommendations: _matchResponse!.recommendedSubjectAreas,
        preferences: _preferences,
        limit: null,
      );

      debugPrint('✅ Programs fetched: ${_matchedPrograms!.length}');

      // Save program IDs
      _matchedProgramIds = _matchedPrograms!.map((p) => p.programId).toList();
      _matchTimestamp = DateTime.now();

      // Auto-save after successful generation
      await saveProgress();

      _progress = 1.0;
    } catch (e) {
      debugPrint('❌ Match generation error: $e');
      _errorMessage = 'Failed to generate matches: ${e.toString()}';
    } finally {
      _isGeneratingMatches = false;
      notifyListeners();
    }
  }

  Future<ProgramFilterModel?> getAIRecommendationFilter() async {
    if (_matchResponse == null) return null;

    // Get Malaysian branch IDs if needed
    Set<String>? malaysianBranchIds;
    if (_preferences.locations.any((loc) => loc.toLowerCase().contains('malaysia'))) {
      malaysianBranchIds = await _repository.getMalaysianBranchIds();
    }

    // Extract subject areas
    final subjectAreas = _matchResponse!.recommendedSubjectAreas
        .map((rec) => rec.subjectArea)
        .toList();

    // ✅ FIXED: Use topN instead of min/maxSubjectRanking
    return ProgramFilterModel(
      subjectArea: subjectAreas,
      studyLevels: _preferences.studyLevel,
      studyModes: _preferences.mode,
      minTuitionFeeMYR: null,
      maxTuitionFeeMYR: _preferences.tuitionMax,
      topN: _preferences.maxRanking, // ✅ Use maxRanking as Top N
      malaysianBranchIds: malaysianBranchIds,
      countries: _preferences.locations,
      rankingSortOrder: 'asc',
    );
  }

  String getLoadingStatus() {
    if (_isGeneratingMatches) {
      return 'Analyzing your profile with AI...';
    }
    return 'Loading...';
  }

  void reset() {
    _currentPage = 0;
    _progress = 0.0;
    _educationLevel = null;
    _otherEducationLevelText = null;
    _academicRecords.clear();
    _englishTests.clear();
    _personalityProfile = null;
    _interests.clear();
    _preferences = UserPreferences();
    _matchResponse = null;
    _matchedPrograms = null;
    _matchedProgramIds = null;
    _matchTimestamp = null;
    _errorMessage = null;
    clearSavedProgress();
    notifyListeners();
  }

  Future<List<String>> getSubjectAreas() async {
    try {
      _availableSubjectAreas = await _repository.getAvailableSubjectAreas();
      return _availableSubjectAreas;
    } catch (e) {
      debugPrint('⚠️ Error fetching subject areas: $e');
      return [];
    }
  }
}