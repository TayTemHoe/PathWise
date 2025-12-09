// lib/viewModel/careerroadmap_view_model.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_wise/model/careerroadmap_model.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:path_wise/services/gemini_service2.dart';
import 'package:path_wise/services/roadmap_service.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';

/// viewModel for Career Roadmap, Skill Gap Analysis, and Learning Resources
/// Manages the state and business logic for Module B.2 and B.3
///
/// This viewModel follows the MVVM architecture pattern and integrates with:
/// - ProfileViewModel: For user profile data
/// - AiService: For AI-powered roadmap generation
/// - RoadmapService: For Firestore CRUD operations
class CareerRoadmapViewModel extends ChangeNotifier {
  CareerRoadmapViewModel({
    AiService? aiService,
    RoadmapService? roadmapService,
    FirebaseAuth? auth,
  })  : _aiService = aiService ?? AiService(),
        _roadmapService = roadmapService ?? RoadmapService(),
        _auth = auth ?? FirebaseAuth.instance;

  final AiService _aiService;
  final RoadmapService _roadmapService;
  final FirebaseAuth _auth;

  // ==================== STATE VARIABLES ====================

  // Loading states
  bool _isLoadingRoadmap = false;
  bool _isLoadingSkillGap = false;
  bool _isLoadingResources = false;
  bool _isGenerating = false;

  // Data states
  CareerRoadmap? _currentRoadmap;
  String? _currentRoadmapId;
  SkillGap? _currentSkillGap;
  String? _currentSkillGapId;
  LearningResource? _currentLearningResources;
  String? _currentLearningResourceId;

  // UI states
  String? _errorMessage;
  String? _successMessage;
  int? _selectedStageIndex;
  bool _showSkillGapAnalysis = false;
  Map<String, bool> _expandedStages = {};

  // Metadata
  bool _isFromCache = false;
  DateTime? _lastGeneratedAt;
  String? _currentJobTitle;
  bool _profileOutdated = false;

  // ==================== GETTERS ====================

  // Loading states
  bool get isLoadingRoadmap => _isLoadingRoadmap;
  bool get isLoadingSkillGap => _isLoadingSkillGap;
  bool get isLoadingResources => _isLoadingResources;
  bool get isGenerating => _isGenerating;
  bool get isLoading => _isLoadingRoadmap || _isLoadingSkillGap || _isLoadingResources || _isGenerating;

  // Data states
  CareerRoadmap? get currentRoadmap => _currentRoadmap;
  String? get currentRoadmapId => _currentRoadmapId;
  SkillGap? get currentSkillGap => _currentSkillGap;
  String? get currentSkillGapId => _currentSkillGapId;
  LearningResource? get currentLearningResources => _currentLearningResources;
  String? get currentLearningResourceId => _currentLearningResourceId;

  // UI states
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int? get selectedStageIndex => _selectedStageIndex;
  bool get showSkillGapAnalysis => _showSkillGapAnalysis;
  bool get isFromCache => _isFromCache;
  DateTime? get lastGeneratedAt => _lastGeneratedAt;
  String? get currentJobTitle => _currentJobTitle;
  bool get profileOutdated => _profileOutdated;

  // Helper getters
  String? get uid =>  FirebaseAuth.instance.currentUser?.uid;
  bool isStageExpanded(int index) => _expandedStages[index.toString()] ?? false;
  bool get hasRoadmap => _currentRoadmap != null;
  bool get hasSkillGap => _currentSkillGap != null;
  bool get hasLearningResources => _currentLearningResources != null;
  bool get hasError => _errorMessage != null;

  // Roadmap stages
  List<RoadmapStage> get roadmapStages => _currentRoadmap?.roadmap ?? [];
  int get stageCount => roadmapStages.length;
  RoadmapStage? get selectedStage =>
      _selectedStageIndex != null && _selectedStageIndex! < stageCount
          ? roadmapStages[_selectedStageIndex!]
          : null;

  // Skill gap statistics
  int get totalSkillGaps => _currentSkillGap?.skillgaps.length ?? 0;

  int get criticalSkillGaps => _currentSkillGap?.skillgaps
      .where((gap) => gap.priorityLevel == 'Critical')
      .length ?? 0;

  int get highSkillGaps => _currentSkillGap?.skillgaps
      .where((gap) => gap.priorityLevel == 'High')
      .length ?? 0;

  int get mediumSkillGaps => _currentSkillGap?.skillgaps
      .where((gap) => gap.priorityLevel == 'Medium')
      .length ?? 0;

  // Learning resources statistics
  int get totalLearningResources => _currentLearningResources?.resources.length ?? 0;
  int get freeLearningResources => _currentLearningResources?.resources
      .where((resource) => resource.cost == 0)
      .length ?? 0;

  /// Calculate career readiness percentage
  /// Based on skill gap analysis (UC015 - A3)
  double get careerReadinessPercentage {
    if (_currentSkillGap == null || _currentSkillGap!.skillgaps.isEmpty) {
      return 100.0; // No gaps = 100% ready
    }

    final totalGaps = _currentSkillGap!.skillgaps.length;
    double totalGapScore = 0.0;

    for (var gap in _currentSkillGap!.skillgaps) {
      final gapSize = gap.requiredProficiencyLevel - gap.userProficiencyLevel;
      final maxGap = gap.requiredProficiencyLevel;

      if (maxGap > 0) {
        final gapPercentage = (gapSize / maxGap) * 100;
        totalGapScore += gapPercentage;
      }
    }

    final averageGap = totalGapScore / totalGaps;
    final readiness = 100 - averageGap;
    return readiness.clamp(0.0, 100.0);
  }

  /// Get prioritized skill gaps (Critical > High > Medium)
  List<SkillGapEntry> get prioritizedSkillGaps {
    if (_currentSkillGap == null) return [];

    final gaps = List<SkillGapEntry>.from(_currentSkillGap!.skillgaps);

    gaps.sort((a, b) {
      const priorityOrder = {'Critical': 0, 'High': 1, 'Medium': 2};
      final aPriority = priorityOrder[a.priorityLevel] ?? 3;
      final bPriority = priorityOrder[b.priorityLevel] ?? 3;
      return aPriority.compareTo(bPriority);
    });

    return gaps;
  }

  // ==================== CORE METHODS ====================

  /// Generate and load career roadmap for a specific job title
  /// UC015 Basic Flow: Step 1-10
  /// This is the main entry point called from career_view.dart
  Future<bool> generateCareerRoadmap({
    required String jobTitle,
    required ProfileViewModel profileViewModel,
  }) async {
    try {
      _isGenerating = true;
      _isLoadingRoadmap = true;
      _isLoadingSkillGap = true;
      _errorMessage = null;
      _successMessage = null;
      _currentJobTitle = jobTitle;
      notifyListeners();

      final userProfile = profileViewModel.profile;

      // Validation
      if (userProfile == null) {
        throw Exception("User profile is missing. Please complete your profile first.");
      }

      debugPrint('🚀 Generating career roadmap for: $jobTitle');
      debugPrint('👤 User: $uid');

      // Check if profile is outdated (A7: Outdated Profile Information)
      _profileOutdated = _isProfileOutdated(userProfile);
      if (_profileOutdated) {
        debugPrint('⚠️ Profile is outdated (>6 months)');
        _successMessage = 'M3: Profile Update Recommended';
        // Continue with generation but with disclaimer
      }

      // Check profile completion for accuracy
      final completion = userProfile.completionPercent ?? 0.0;
      if (completion < 30) {
        _errorMessage = 'Profile completion is too low ($completion%). Please complete at least 30% of your profile for accurate roadmap generation.';
        _isGenerating = false;
        _isLoadingRoadmap = false;
        _isLoadingSkillGap = false;
        notifyListeners();
        return false;
      }

      // Generate/fetch roadmap and skill gaps via AI Service
      // This method handles caching automatically
      debugPrint('✅ Received career roadmap from AI');

      final result = await _aiService.saveCareerRoadmapToFirestore(
        uid: profileViewModel.uid,
        jobTitle: jobTitle,
        userModel: userProfile,
      );

      _currentRoadmapId = result['roadmapId'];
      _currentSkillGapId = result['skillGapId'];
      _isFromCache = result['isNew'] == 'false';
      _lastGeneratedAt = DateTime.now();

      debugPrint('✅ Roadmap ID: $_currentRoadmapId');
      debugPrint('✅ Skill Gap ID: $_currentSkillGapId');
      debugPrint('📦 From Cache: $_isFromCache');

      // Load the generated data from Firestore
      await _loadRoadmapData();

      // Check if skills are already sufficient (A5: Skills Already Sufficient)
      if (_currentSkillGap != null && _currentSkillGap!.skillgaps.isEmpty) {
        _successMessage = 'M4: Skills Assessment Positive - You already have ${careerReadinessPercentage.toStringAsFixed(0)}% of the required skills!';
        debugPrint('🎊 User already meets requirements!');
      }

      _isGenerating = false;
      _isLoadingRoadmap = false;
      _isLoadingSkillGap = false;

      _successMessage = _successMessage ?? 'Career roadmap generated successfully!';
      notifyListeners();

      debugPrint('🎉 Career roadmap generation completed successfully');
      return true;
    } catch (e) {
      _isGenerating = false;
      _isLoadingRoadmap = false;
      _isLoadingSkillGap = false;
      _errorMessage = 'Failed to generate career roadmap: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ Error generating career roadmap: $e');
      return false;
    }
  }

  /// Load roadmap data from Firestore by roadmap ID
  Future<bool> loadRoadmapById(String roadmapId) async {
    try {
      _isLoadingRoadmap = true;
      _isLoadingSkillGap = true;
      _errorMessage = null;
      notifyListeners();

      _currentRoadmapId = roadmapId;

      await _loadRoadmapData();

      _isLoadingRoadmap = false;
      _isLoadingSkillGap = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoadingRoadmap = false;
      _isLoadingSkillGap = false;
      _errorMessage = 'Failed to load roadmap: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ Error loading roadmap: $e');
      return false;
    }
  }

  /// Load complete roadmap data (roadmap + skill gap)
  /// Private helper method
  Future<void> _loadRoadmapData() async {
    if (_currentRoadmapId == null) {
      throw Exception('Roadmap ID is null');
    }

    // Load roadmap
    _currentRoadmap = await _roadmapService.getCareerRoadmap(uid!, _currentRoadmapId!);

    if (_currentRoadmap == null) {
      throw Exception('Roadmap not found');
    }

    _currentJobTitle = _currentRoadmap!.jobTitle;

    // Load skill gap
    if (_currentSkillGapId != null) {
      _currentSkillGap = await _roadmapService.getSkillGap(uid!, _currentSkillGapId!);
    } else {
      // Try to find skill gap by roadmap ID
      _currentSkillGap = await _roadmapService.getSkillGapByRoadmapId(uid!, _currentRoadmapId!);

      // If found, update the skill gap ID
      if (_currentSkillGap != null) {
        final skillGapSnapshot = await _roadmapService.getAllSkillGaps(uid!);
        for (var sgData in skillGapSnapshot) {
          if (sgData['careerRoadmapId'] == _currentRoadmapId) {
            _currentSkillGapId = sgData['id'];
            break;
          }
        }
      }
    }

    // Try to load existing learning resources
    if (_currentSkillGapId != null) {
      try {
        _currentLearningResources = await _roadmapService.getLatestLearningResources(
            uid!,
            _currentSkillGapId!
        );

        if (_currentLearningResources != null) {
          debugPrint('📚 Loaded existing learning resources');
        }
      } catch (e) {
        debugPrint('ℹ️ No existing learning resources: $e');
        _currentLearningResources = null;
      }
    }
  }

  /// Generate learning resources for skill gaps
  /// UC015 Basic Flow: Step 11-12
  /// UC015 Alternate Flow: A4: Find Learning Resources
  Future<bool> generateLearningResources() async {
    if (_currentSkillGap == null || _currentSkillGapId == null) {
      _errorMessage = 'No skill gaps found. Please generate roadmap first.';
      notifyListeners();
      return false;
    }

    if (_currentSkillGap!.skillgaps.isEmpty) {
      _successMessage = 'M4: Skills Assessment Positive - No learning resources needed!';
      notifyListeners();
      return false;
    }

    try {
      _isLoadingResources = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      debugPrint('🔍 Finding learning resources for ${_currentSkillGap!.skillgaps.length} skill gaps');

      // Generate learning resources via AI Service
      _currentLearningResourceId = await _aiService.saveLearningResourcesToFirestore(
        uid: uid!,
        skillGapId: _currentSkillGapId!,
        skillGaps: _currentSkillGap!.skillgaps,
      );

      // Load the generated resources
      _currentLearningResources = await _roadmapService.getLearningResource(
        uid!,
        _currentLearningResourceId!,
      );

      _isLoadingResources = false;

      // Check if no resources found (A6: No Learning Resources Available)
      if (_currentLearningResources == null || _currentLearningResources!.resources.isEmpty) {
        _errorMessage = 'M1: Learning Resources Unavailable - No learning resources found for these skills.';
        debugPrint('⚠️ No learning resources found');
        notifyListeners();
        return false;
      } else {
        _successMessage = 'Found ${_currentLearningResources!.resources.length} learning resources!';
        debugPrint('✅ Found ${_currentLearningResources!.resources.length} learning resources');
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoadingResources = false;
      _errorMessage = 'Failed to generate learning resources: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ Error generating learning resources: $e');
      return false;
    }
  }

  /// Load existing learning resources from Firestore
  Future<void> loadLearningResources() async {
    if (_currentSkillGapId == null) {
      debugPrint('⚠️ Cannot load learning resources: Skill Gap ID is null');
      return;
    }

    try {
      _isLoadingResources = true;
      notifyListeners();

      _currentLearningResources = await _roadmapService.getLatestLearningResources(
        uid!,
        _currentSkillGapId!,
      );

      _isLoadingResources = false;
      notifyListeners();

      if (_currentLearningResources == null) {
        debugPrint('ℹ️ No existing learning resources found');
      } else {
        debugPrint('📚 Loaded ${_currentLearningResources!.resources.length} learning resources');
      }
    } catch (e) {
      _isLoadingResources = false;
      _errorMessage = 'Failed to load learning resources: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ Error loading learning resources: $e');
    }
  }

  // ==================== UI INTERACTION METHODS ====================

  /// Toggle stage expansion
  /// UC015 Alternate Flow: A2: Explore Roadmap Stage Details
  void toggleStageExpansion(int index) {
    if (index < 0 || index >= stageCount) return;

    _expandedStages[index.toString()] = !(_expandedStages[index.toString()] ?? false);
    _selectedStageIndex = _expandedStages[index.toString()]! ? index : null;
    notifyListeners();

    debugPrint('📖 Stage $index (${roadmapStages[index].jobTitle}) expanded: ${_expandedStages[index.toString()]}');
  }

  /// Select a specific stage
  void selectStage(int index) {
    if (index < 0 || index >= stageCount) return;

    _selectedStageIndex = index;
    _expandedStages[index.toString()] = true;
    notifyListeners();

    debugPrint('✅ Selected stage: ${roadmapStages[index].jobTitle}');
  }

  /// Clear stage selection
  void clearStageSelection() {
    _selectedStageIndex = null;
    _expandedStages.clear();
    notifyListeners();
    debugPrint('🔄 Cleared stage selection');
  }

  /// Toggle skill gap analysis visibility
  /// UC015 Basic Flow: Step 9
  void toggleSkillGapAnalysis() {
    _showSkillGapAnalysis = !_showSkillGapAnalysis;
    notifyListeners();
    debugPrint('📊 Skill gap analysis ${_showSkillGapAnalysis ? "shown" : "hidden"}');
  }

  /// Show skill gap analysis section
  void showSkillGapAnalysisSection() {
    _showSkillGapAnalysis = true;
    notifyListeners();
  }

  /// Hide skill gap analysis section
  void hideSkillGapAnalysisSection() {
    _showSkillGapAnalysis = false;
    notifyListeners();
  }

  // ==================== ROADMAP MANAGEMENT METHODS ====================

  /// Get all roadmaps for current user
  Future<List<Map<String, dynamic>>> getAllRoadmaps() async {
    try {
      return await _roadmapService.getAllCareerRoadmaps(uid!);
    } catch (e) {
      debugPrint('❌ Error fetching all roadmaps: $e');
      return [];
    }
  }

  /// Get roadmap summary for current user
  Future<List<Map<String, dynamic>>> getRoadmapSummary() async {
    try {
      return await _roadmapService.getRoadmapSummary(uid!);
    } catch (e) {
      debugPrint('❌ Error fetching roadmap summary: $e');
      return [];
    }
  }

  /// Delete current roadmap and all associated data
  Future<bool> deleteCurrentRoadmap() async {
    if (_currentRoadmapId == null) {
      _errorMessage = 'No roadmap to delete';
      notifyListeners();
      return false;
    }

    try {
      await _roadmapService.deleteCompleteRoadmap(uid!, _currentRoadmapId!);

      // Clear current state
      clearRoadmapData();

      _successMessage = 'Roadmap deleted successfully';
      notifyListeners();

      debugPrint('🗑️ Roadmap deleted successfully');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete roadmap: ${e.toString()}';
      notifyListeners();
      debugPrint('❌ Error deleting roadmap: $e');
      return false;
    }
  }

  /// Bookmark/Save current roadmap
  /// UC015 Basic Flow: Step 13-14
  Future<bool> bookmarkRoadmap() async {
    if (_currentRoadmapId == null) {
      _errorMessage = 'No roadmap to bookmark';
      notifyListeners();
      return false;
    }

    // For now, we'll just show a success message
    // In the future, this could update a user preference in Firestore
    _successMessage = 'M5: Roadmap Saved - Career roadmap bookmarked successfully!';
    notifyListeners();

    debugPrint('🔖 Roadmap bookmarked: $_currentRoadmapId');
    return true;
  }

  // ==================== HELPER METHODS ====================

  /// Check if user profile is outdated (>6 months)
  /// UC015 Alternate Flow: A7: Outdated Profile Information
  bool _isProfileOutdated(UserModel profile) {
    final lastUpdated = profile.lastUpdated?.toDate();

    if (lastUpdated == null) {
      return false; // No update date = consider as fresh
    }

    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    final monthsDifference = difference.inDays / 30;

    return monthsDifference > 6;
  }

  /// Get skill gaps by priority level
  List<SkillGapEntry> getSkillGapsByPriority(String priority) {
    if (_currentSkillGap == null) return [];
    return _currentSkillGap!.skillgaps
        .where((gap) => gap.priorityLevel == priority)
        .toList();
  }

  /// Get learning resources filtered by cost
  List<LearningResourceEntry> getFreeLearningResources() {
    if (_currentLearningResources == null) return [];
    return _currentLearningResources!.resources
        .where((resource) => resource.cost == 0)
        .toList();
  }

  List<LearningResourceEntry> getPaidLearningResources() {
    if (_currentLearningResources == null) return [];
    return _currentLearningResources!.resources
        .where((resource) => resource.cost > 0)
        .toList();
  }

  /// Get estimated total timeline to reach target position
  String getEstimatedTotalTimeline() {
    if (_currentRoadmap == null || _currentRoadmap!.roadmap.isEmpty) {
      return 'Unknown';
    }

    final stages = _currentRoadmap!.roadmap;
    if (stages.length == 1) {
      return 'Current Level';
    }

    // This is a simplified calculation
    // In a real implementation, you might want to parse and sum the timeframes
    return stages.last.estimatedTimeframe;
  }

  /// Get complete roadmap statistics
  Map<String, dynamic> getRoadmapStatistics() {
    return {
      'hasRoadmap': hasRoadmap,
      'jobTitle': _currentJobTitle ?? 'N/A',
      'stageCount': stageCount,
      'currentStage': selectedStage?.jobTitle ?? 'N/A',
      'totalSkillGaps': totalSkillGaps,
      'criticalGaps': criticalSkillGaps,
      'highGaps': highSkillGaps,
      'mediumGaps': mediumSkillGaps,
      'readinessPercentage': careerReadinessPercentage.toStringAsFixed(1),
      'hasLearningResources': hasLearningResources,
      'totalResources': totalLearningResources,
      'freeResources': freeLearningResources,
      'estimatedTimeline': getEstimatedTotalTimeline(),
      'isFromCache': _isFromCache,
      'generatedAt': _lastGeneratedAt?.toString() ?? 'N/A',
    };
  }

  /// Clear all roadmap data
  void clearRoadmapData() {
    _currentRoadmap = null;
    _currentRoadmapId = null;
    _currentSkillGap = null;
    _currentSkillGapId = null;
    _currentLearningResources = null;
    _currentLearningResourceId = null;
    _selectedStageIndex = null;
    _expandedStages.clear();
    _showSkillGapAnalysis = false;
    _errorMessage = null;
    _successMessage = null;
    _isFromCache = false;
    _lastGeneratedAt = null;
    _currentJobTitle = null;
    _profileOutdated = false;
    notifyListeners();

    debugPrint('🧹 Cleared all roadmap data');
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear success message
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// Clear all messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Refresh current roadmap data
  Future<bool> refreshRoadmap() async {
    if (_currentRoadmapId == null) {
      _errorMessage = 'No roadmap to refresh';
      notifyListeners();
      return false;
    }

    debugPrint('🔄 Refreshing roadmap data...');
    return await loadRoadmapById(_currentRoadmapId!);
  }

  // ==================== STREAM METHODS ====================

  /// Stream roadmap updates in real-time
  Stream<CareerRoadmap?> streamRoadmap(String roadmapId) {
    return _roadmapService.streamCareerRoadmap(uid!, roadmapId);
  }

  /// Stream skill gap updates in real-time
  Stream<SkillGap?> streamSkillGap(String skillGapId) {
    return _roadmapService.streamSkillGap(uid!, skillGapId);
  }

  /// Stream learning resources updates in real-time
  Stream<LearningResource?> streamLearningResources(String skillGapId) {
    return _roadmapService.streamLatestLearningResources(uid!, skillGapId);
  }

  /// Start listening to current roadmap in real-time
  void startListeningToCurrentRoadmap() {
    if (_currentRoadmapId == null) return;

    streamRoadmap(_currentRoadmapId!).listen(
          (roadmap) {
        _currentRoadmap = roadmap;
        notifyListeners();
        debugPrint('📡 Real-time update: Roadmap changed');
      },
      onError: (error) {
        debugPrint('❌ Stream error: $error');
        _errorMessage = 'Real-time update error: $error';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    debugPrint('🧹 CareerRoadmapViewModel disposed');
    super.dispose();
  }
}