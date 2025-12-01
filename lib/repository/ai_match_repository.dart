// lib/repository/ai_match_repository.dart - OPTIMIZED VERSION
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../model/ai_match_model.dart';
import '../model/program.dart';
import '../model/program_filter.dart';
import '../services/gemini_service.dart';
import '../services/local_data_source.dart';

class AIMatchRepository {
  static final AIMatchRepository instance = AIMatchRepository._init();
  AIMatchRepository._init();

  final GeminiService _geminiService = GeminiService.instance;
  final LocalDataSource _localDataSource = LocalDataSource.instance;

  // Cache for available options
  List<String>? _cachedSubjectAreas;
  List<String>? _cachedStudyModes;
  List<String>? _cachedStudyLevels;
  List<String>? _cachedCountries;
  (double, double)? _cachedTuitionRange;
  Set<String>? _cachedMalaysianBranchIds;

  /// Generate AI match recommendations with validation
  Future<AIMatchResponse> generateMatches(AIMatchRequest request) async {
    try {
      debugPrint('🎯 Starting AI match generation...');

      // Get available study areas from cache or database
      final availableAreas = await getAvailableSubjectAreas();
      debugPrint('📚 Available study areas: ${availableAreas.length}');

      if (availableAreas.isEmpty) {
        throw Exception('No study areas available in database');
      }

      // Generate matches using Gemini
      final response = await _geminiService.generateEducationMatch(request);

      if (response.recommendedSubjectAreas.isEmpty) {
        throw Exception('No recommendations generated');
      }

      debugPrint('✅ AI generated ${response.recommendedSubjectAreas.length} recommendations');

      // Validate that recommended areas exist in database
      final validRecommendations = response.recommendedSubjectAreas.where((rec) {
        final isValid = availableAreas.any(
                (area) => area.toLowerCase().trim() == rec.subjectArea.toLowerCase().trim()
        );

        if (!isValid) {
          debugPrint('⚠️ Recommendation "${rec.subjectArea}" not found in database');
        }

        return isValid;
      }).toList();

      if (validRecommendations.isEmpty) {
        debugPrint('❌ No valid recommendations found in database');
        throw Exception('No matching subject areas found in database');
      }

      if (validRecommendations.length < response.recommendedSubjectAreas.length) {
        debugPrint('⚠️ ${response.recommendedSubjectAreas.length - validRecommendations.length} recommendations filtered out');
      }

      debugPrint('✅ Returning ${validRecommendations.length} valid recommendations');
      return AIMatchResponse(recommendedSubjectAreas: validRecommendations);

    } catch (e, stackTrace) {
      debugPrint('❌ Error generating AI matches: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get programs for recommended subject areas with optimized filtering
  Future<List<ProgramModel>> getProgramsForRecommendations({
    required List<RecommendedSubjectArea> recommendations,
    required UserPreferences preferences,
    int? limit,
  }) async {
    try {
      debugPrint('🔍 Fetching programs for ${recommendations.length} recommendations...');

      // Extract subject areas
      final subjectAreas = recommendations.map((r) => r.subjectArea).toList();

      // ✅ Get branch IDs based on user's country preferences
      Set<String>? countryBranchIds;
      if (preferences.locations.isNotEmpty) {
        countryBranchIds = await _getBranchIdsByCountries(preferences.locations);
        debugPrint('🌍 Filtering ${countryBranchIds.length} branches from ${preferences.locations.join(", ")}');
      }

      // ✅ FIXED: Use topN instead of min/maxSubjectRanking
      final filter = ProgramFilterModel(
        subjectArea: subjectAreas,
        studyLevels: preferences.studyLevel,
        studyModes: preferences.mode,
        minTuitionFeeMYR: preferences.tuitionMin,
        maxTuitionFeeMYR: preferences.tuitionMax,
        topN: preferences.maxRanking,
        malaysianBranchIds: countryBranchIds,
        countries: preferences.locations,
        rankingSortOrder: 'asc', // Always sort best first
      );

      // Fetch programs for each subject area
      final Map<String, ProgramModel> uniquePrograms = {};
      int totalFetched = 0;

      for (final subjectArea in subjectAreas) {
        debugPrint('  📖 Fetching programs for: $subjectArea');

        final programs = await _localDataSource.getPrograms(
          limit: 100,
          offset: 0,
          filter: filter,
        );

        debugPrint('Found ${programs.length} programs');
        totalFetched += programs.length;

        for (final program in programs) {
          if (!uniquePrograms.containsKey(program.programId)) {
            uniquePrograms[program.programId] = program;
          }
        }

        if (uniquePrograms.length >= 500) {
          debugPrint('  ℹ️ Reached safety limit (500), stopping fetch');
          break;
        }
      }

      debugPrint('📊 Total programs fetched: $totalFetched');
      debugPrint('📊 Unique programs: ${uniquePrograms.length}');

      // Sort by ranking
      final result = uniquePrograms.values.toList();
      result.sort((a, b) {
        if (a.minSubjectRanking == null && b.minSubjectRanking == null) return 0;
        if (a.minSubjectRanking == null) return 1;
        if (b.minSubjectRanking == null) return -1;
        return a.minSubjectRanking!.compareTo(b.minSubjectRanking!);
      });

      final limitedResult = (limit != null && limit > 0)
          ? result.take(limit).toList()
          : result;

      debugPrint('✅ Returning ${limitedResult.length} programs (sorted by ranking)');

      return limitedResult;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching programs: $e');
      debugPrint('🔍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Set<String>> _getBranchIdsByCountries(List<String> countries) async {
    try {
      return await _localDataSource.getBranchIdsByCountries(countries);
    } catch (e) {
      debugPrint('❌ Error getting branch IDs: $e');
      return {};
    }
  }

  /// Get Malaysian branch IDs with caching
  Future<Set<String>> getMalaysianBranchIds() async {
    if (_cachedMalaysianBranchIds != null) {
      return _cachedMalaysianBranchIds!;
    }

    _cachedMalaysianBranchIds = await _localDataSource.getMalaysianBranchIds();
    return _cachedMalaysianBranchIds!;
  }

  /// Get available subject areas with caching
  Future<List<String>> getAvailableSubjectAreas() async {
    if (_cachedSubjectAreas != null) {
      return _cachedSubjectAreas!;
    }

    _cachedSubjectAreas = await _localDataSource.getAvailableSubjectAreas();
    return _cachedSubjectAreas!;
  }

  /// Get available study modes with caching
  Future<List<String>> getAvailableStudyModes() async {
    if (_cachedStudyModes != null) {
      return _cachedStudyModes!;
    }

    _cachedStudyModes = await _localDataSource.getAvailableStudyModes();
    return _cachedStudyModes!;
  }

  /// Get available study levels with caching
  Future<List<String>> getAvailableStudyLevels() async {
    if (_cachedStudyLevels != null) {
      return _cachedStudyLevels!;
    }

    _cachedStudyLevels = await _localDataSource.getAvailableStudyLevels();
    return _cachedStudyLevels!;
  }

  /// Get available countries with caching
  Future<List<String>> getAvailableCountries() async {
    if (_cachedCountries != null) {
      return _cachedCountries!;
    }

    _cachedCountries = await _localDataSource.getAvailableCountries();
    return _cachedCountries!;
  }

  /// Get tuition fee range with caching
  Future<(double, double)> getProgramTuitionFeeRange() async {
    if (_cachedTuitionRange != null) {
      return _cachedTuitionRange!;
    }

    _cachedTuitionRange = await _localDataSource.getProgramTuitionFeeRange();
    return _cachedTuitionRange!;
  }

  /// Clear all caches
  void clearCache() {
    _cachedSubjectAreas = null;
    _cachedStudyModes = null;
    _cachedStudyLevels = null;
    _cachedCountries = null;
    _cachedTuitionRange = null;
    _cachedMalaysianBranchIds = null;
    debugPrint('🗑️ Repository cache cleared');
  }

  /// Test Gemini API connection
  Future<bool> testGeminiConnection() async {
    return await _geminiService.testConnection();
  }

  /// Save match request to local storage
  Future<void> saveMatchRequest(AIMatchRequest request) async {
    // TODO: Implement local storage saving if needed
    debugPrint('💾 Match request saved (implement local storage if needed)');
  }

  /// Load saved match request
  Future<AIMatchRequest?> loadSavedMatchRequest() async {
    // TODO: Implement local storage loading if needed
    debugPrint('📂 Loading saved match request (implement local storage if needed)');
    return null;
  }
}