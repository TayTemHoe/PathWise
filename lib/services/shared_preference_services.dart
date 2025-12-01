import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/ai_match_model.dart';

class SharedPreferenceService {
  static final SharedPreferenceService instance = SharedPreferenceService._init();
  SharedPreferenceService._init();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _cache = {};
  bool _isCacheValid = false;

  // UPDATED Keys (removed _keyCurrentPage)
  static const String _keyEducationLevel = 'ai_match_education_level';
  static const String _keyOtherEducation = 'ai_match_other_education';
  static const String _keyAcademicRecords = 'ai_match_academic_records';
  static const String _keyEnglishTests = 'ai_match_english_tests';
  static const String _keyPersonality = 'ai_match_personality';
  static const String _keyInterests = 'ai_match_interests';
  static const String _keyPreferences = 'ai_match_preferences';
  static const String _keyMatchResponse = 'ai_match_response';
  static const String _keyMatchedPrograms = 'ai_match_matched_programs';
  static const String _keyMatchTimestamp = 'ai_match_timestamp';
  static const String _keyLastSaved = 'ai_match_last_saved';

  Future<void> initialize() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('✅ AI Match Storage initialized');
    }
  }

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save complete progress with matched programs
  Future<void> saveProgressWithPrograms({
    EducationLevel? educationLevel,
    String? otherEducationText,
    required List<AcademicRecord> academicRecords,
    required List<EnglishTest> englishTests,
    PersonalityProfile? personality,
    required List<String> interests,
    required UserPreferences preferences,
    AIMatchResponse? matchResponse,
    List<String>? matchedProgramIds,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final sp = await prefs;

      final futures = <Future>[
        if (educationLevel != null)
          sp.setString(_keyEducationLevel, educationLevel.name)
        else
          sp.remove(_keyEducationLevel),

        if (otherEducationText != null && otherEducationText.isNotEmpty)
          sp.setString(_keyOtherEducation, otherEducationText)
        else
          sp.remove(_keyOtherEducation),

        sp.setString(
          _keyAcademicRecords,
          jsonEncode(academicRecords.map((r) => r.toJson()).toList()),
        ),

        sp.setString(
          _keyEnglishTests,
          jsonEncode(englishTests.map((t) => t.toJson()).toList()),
        ),

        if (personality != null)
          sp.setString(_keyPersonality, jsonEncode(personality.toJson()))
        else
          sp.remove(_keyPersonality),

        sp.setString(_keyInterests, jsonEncode(interests)),

        sp.setString(_keyPreferences, jsonEncode(preferences.toJson())),

        if (matchResponse != null)
          sp.setString(_keyMatchResponse, jsonEncode(matchResponse.toJson()))
        else
          sp.remove(_keyMatchResponse),

        if (matchedProgramIds != null && matchedProgramIds.isNotEmpty)
          sp.setString(_keyMatchedPrograms, jsonEncode(matchedProgramIds))
        else
          sp.remove(_keyMatchedPrograms),

        sp.setInt(_keyMatchTimestamp, DateTime.now().millisecondsSinceEpoch),
        sp.setInt(_keyLastSaved, DateTime.now().millisecondsSinceEpoch),
      ];

      await Future.wait(futures);

      _isCacheValid = false;
      _cache.clear();

      stopwatch.stop();
      debugPrint('✅ Progress saved in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ Error saving progress: $e');
      rethrow;
    }
  }

  /// Load complete progress including matched programs
  Future<AIMatchProgressData?> loadProgressWithPrograms({bool forceRefresh = false}) async {
    try {
      final stopwatch = Stopwatch()..start();

      // ✅ FIX: Always reload from disk if forceRefresh is true
      if (forceRefresh) {
        debugPrint('🔄 Force refresh: Clearing cache and reloading from disk');
        _isCacheValid = false;
        _cache.clear();
      }

      if (_isCacheValid && _cache.isNotEmpty && !forceRefresh) {
        debugPrint('⚡ Loaded from cache in ${stopwatch.elapsedMilliseconds}ms');
        return _buildProgressDataFromCache();
      }

      final sp = await prefs;

      // Check if any data exists
      if (!sp.containsKey(_keyEducationLevel) &&
          !sp.containsKey(_keyAcademicRecords)) {
        debugPrint('ℹ️ No saved progress found');
        return null;
      }

      // Load all data
      final educationLevelStr = sp.getString(_keyEducationLevel);
      final otherEducation = sp.getString(_keyOtherEducation);
      final academicJson = sp.getString(_keyAcademicRecords);
      final englishJson = sp.getString(_keyEnglishTests);
      final personalityJson = sp.getString(_keyPersonality);
      final interestsJson = sp.getString(_keyInterests);
      final prefsJson = sp.getString(_keyPreferences);
      final matchResponseJson = sp.getString(_keyMatchResponse);
      final matchedProgramsJson = sp.getString(_keyMatchedPrograms);
      final matchTimestamp = sp.getInt(_keyMatchTimestamp);

      debugPrint('📋 Loaded matched programs JSON: $matchedProgramsJson');

      // Parse data
      EducationLevel? educationLevel;
      if (educationLevelStr != null) {
        educationLevel = EducationLevel.values.firstWhere(
              (e) => e.name == educationLevelStr,
          orElse: () => EducationLevel.other,
        );
      }

      final academicRecords = academicJson != null
          ? (jsonDecode(academicJson) as List)
          .map((j) => AcademicRecord.fromJson(j))
          .toList()
          : <AcademicRecord>[];

      final englishTests = englishJson != null
          ? (jsonDecode(englishJson) as List)
          .map((j) => EnglishTest.fromJson(j))
          .toList()
          : <EnglishTest>[];

      final personality = personalityJson != null
          ? PersonalityProfile.fromJson(jsonDecode(personalityJson))
          : null;

      final interests = interestsJson != null
          ? (jsonDecode(interestsJson) as List<dynamic>).cast<String>()
          : <String>[];

      final preferences = prefsJson != null
          ? UserPreferences.fromJson(jsonDecode(prefsJson))
          : UserPreferences();

      final matchResponse = matchResponseJson != null
          ? AIMatchResponse.fromJson(jsonDecode(matchResponseJson))
          : null;

      final matchedProgramIds = matchedProgramsJson != null
          ? (jsonDecode(matchedProgramsJson) as List<dynamic>).cast<String>()
          : <String>[];

      debugPrint('✅ Parsed ${matchedProgramIds.length} matched program IDs');

      // Cache the data
      _cache.clear();
      _cache['educationLevel'] = educationLevel;
      _cache['otherEducation'] = otherEducation;
      _cache['academicRecords'] = academicRecords;
      _cache['englishTests'] = englishTests;
      _cache['personality'] = personality;
      _cache['interests'] = interests;
      _cache['preferences'] = preferences;
      _cache['matchResponse'] = matchResponse;
      _cache['matchedProgramIds'] = matchedProgramIds;
      _cache['matchTimestamp'] = matchTimestamp;
      _isCacheValid = true;

      stopwatch.stop();
      debugPrint('✅ Progress loaded in ${stopwatch.elapsedMilliseconds}ms');

      return AIMatchProgressData(
        educationLevel: educationLevel,
        otherEducationText: otherEducation,
        academicRecords: academicRecords,
        englishTests: englishTests,
        personality: personality,
        interests: interests,
        preferences: preferences,
        matchResponse: matchResponse,
        matchedProgramIds: matchedProgramIds.isNotEmpty ? matchedProgramIds : null,
        matchTimestamp: matchTimestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(matchTimestamp)
            : null,
      );
    } catch (e) {
      debugPrint('❌ Error loading progress: $e');
      return null;
    }
  }

  AIMatchProgressData? _buildProgressDataFromCache() {
    if (_cache.isEmpty) return null;

    return AIMatchProgressData(
      educationLevel: _cache['educationLevel'] as EducationLevel?,
      otherEducationText: _cache['otherEducation'] as String?,
      academicRecords: _cache['academicRecords'] as List<AcademicRecord>,
      englishTests: _cache['englishTests'] as List<EnglishTest>,
      personality: _cache['personality'] as PersonalityProfile?,
      interests: _cache['interests'] as List<String>,
      preferences: _cache['preferences'] as UserPreferences,
      matchResponse: _cache['matchResponse'] as AIMatchResponse?,
      matchedProgramIds: _cache['matchedProgramIds'] as List<String>?,
      matchTimestamp: _cache['matchTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(_cache['matchTimestamp'] as int)
          : null,
    );
  }

  Future<bool> hasSavedProgress() async {
    final sp = await prefs;
    return sp.containsKey(_keyEducationLevel) ||
        sp.containsKey(_keyAcademicRecords);
  }

  Future<DateTime?> getLastSavedTime() async {
    final sp = await prefs;
    final timestamp = sp.getInt(_keyLastSaved);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> clearProgress() async {
    try {
      final sp = await prefs;

      await Future.wait([
        sp.remove(_keyEducationLevel),
        sp.remove(_keyOtherEducation),
        sp.remove(_keyAcademicRecords),
        sp.remove(_keyEnglishTests),
        sp.remove(_keyPersonality),
        sp.remove(_keyInterests),
        sp.remove(_keyPreferences),
        sp.remove(_keyMatchResponse),
        sp.remove(_keyMatchedPrograms),
        sp.remove(_keyMatchTimestamp),
        sp.remove(_keyLastSaved),
      ]);

      _cache.clear();
      _isCacheValid = false;

      debugPrint('✅ Saved progress cleared');
    } catch (e) {
      debugPrint('❌ Error clearing progress: $e');
    }
  }

  void invalidateCache() {
    _isCacheValid = false;
    _cache.clear();
  }
}
