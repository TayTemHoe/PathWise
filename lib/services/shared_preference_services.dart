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

  String? _cachedUserId;

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

  // Helper to generate user-specific keys
  String _getUserKey(String key, String userId) => '${key}_$userId';

  /// Save complete progress with matched programs
  Future<void> saveProgressWithPrograms({
    required String userId,
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
          sp.setString(_getUserKey(_keyEducationLevel, userId), educationLevel.name)
        else
          sp.remove(_getUserKey(_keyEducationLevel, userId)),

        if (otherEducationText != null && otherEducationText.isNotEmpty)
          sp.setString(_getUserKey(_keyOtherEducation, userId), otherEducationText)
        else
          sp.remove(_getUserKey(_keyOtherEducation, userId)),

        sp.setString(
          _getUserKey(_keyAcademicRecords, userId),
          jsonEncode(academicRecords.map((r) => r.toJson()).toList()),
        ),

        sp.setString(
          _getUserKey(_keyEnglishTests, userId),
          jsonEncode(englishTests.map((t) => t.toJson()).toList()),
        ),

        if (personality != null)
          sp.setString(_getUserKey(_keyPersonality, userId), jsonEncode(personality.toJson()))
        else
          sp.remove(_getUserKey(_keyPersonality, userId)),

        sp.setString(_getUserKey(_keyInterests, userId), jsonEncode(interests)),

        sp.setString(_getUserKey(_keyPreferences, userId), jsonEncode(preferences.toJson())),

        if (matchResponse != null)
          sp.setString(_getUserKey(_keyMatchResponse, userId), jsonEncode(matchResponse.toJson()))
        else
          sp.remove(_getUserKey(_keyMatchResponse, userId)),

        if (matchedProgramIds != null && matchedProgramIds.isNotEmpty)
          sp.setString(_getUserKey(_keyMatchedPrograms, userId), jsonEncode(matchedProgramIds))
        else
          sp.remove(_getUserKey(_keyMatchedPrograms, userId)),

        sp.setInt(_getUserKey(_keyMatchTimestamp, userId), DateTime.now().millisecondsSinceEpoch),
        sp.setInt(_getUserKey(_keyLastSaved, userId), DateTime.now().millisecondsSinceEpoch),
      ];

      await Future.wait(futures);

      _isCacheValid = false;
      _cache.clear();

      stopwatch.stop();
      debugPrint('✅ Progress saved in ${stopwatch.elapsedMilliseconds}ms for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving progress: $e');
      rethrow;
    }
  }

  /// Load complete progress including matched programs
  Future<AIMatchProgressData?> loadProgressWithPrograms({
    required String userId,
    bool forceRefresh = false,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Always reload from disk if forceRefresh is true
      if (forceRefresh) {
        debugPrint('🔄 Force refresh: Clearing cache and reloading from disk for user: $userId');
        _isCacheValid = false;
        _cache.clear();
        _cachedUserId = null;
      }

      // CRITICAL FIX: Validate that the cache belongs to the requested userId
      if (_isCacheValid &&
          _cache.isNotEmpty &&
          !forceRefresh &&
          _cachedUserId == userId) {
        debugPrint('⚡ Loaded from cache in ${stopwatch.elapsedMilliseconds}ms');
        return _buildProgressDataFromCache();
      }

      final sp = await prefs;

      // Check if any data exists for this user on disk
      if (!sp.containsKey(_getUserKey(_keyEducationLevel, userId)) &&
          !sp.containsKey(_getUserKey(_keyAcademicRecords, userId))) {
        debugPrint('ℹ️ No saved progress found for user: $userId');

        // If we switched users and the new user has no data, clear the old cache
        if (_cachedUserId != userId) {
          _cache.clear();
          _isCacheValid = false;
          _cachedUserId = null;
        }
        return null;
      }

      // Load all data using user-specific keys
      final educationLevelStr = sp.getString(_getUserKey(_keyEducationLevel, userId));
      final otherEducation = sp.getString(_getUserKey(_keyOtherEducation, userId));
      final academicJson = sp.getString(_getUserKey(_keyAcademicRecords, userId));
      final englishJson = sp.getString(_getUserKey(_keyEnglishTests, userId));
      final personalityJson = sp.getString(_getUserKey(_keyPersonality, userId));
      final interestsJson = sp.getString(_getUserKey(_keyInterests, userId));
      final prefsJson = sp.getString(_getUserKey(_keyPreferences, userId));
      final matchResponseJson = sp.getString(_getUserKey(_keyMatchResponse, userId));
      final matchedProgramsJson = sp.getString(_getUserKey(_keyMatchedPrograms, userId));
      final matchTimestamp = sp.getInt(_getUserKey(_keyMatchTimestamp, userId));

      debugPrint('📋 Loaded matched programs JSON for user $userId: $matchedProgramsJson');

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

      // Mark cache as valid for this specific user
      _cachedUserId = userId;
      _isCacheValid = true;

      stopwatch.stop();
      debugPrint('✅ Progress loaded in ${stopwatch.elapsedMilliseconds}ms for user: $userId');

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

  Future<bool> hasSavedProgress(String userId) async {
    final sp = await prefs;
    return sp.containsKey(_getUserKey(_keyEducationLevel, userId)) ||
        sp.containsKey(_getUserKey(_keyAcademicRecords, userId));
  }

  Future<DateTime?> getLastSavedTime(String userId) async {
    final sp = await prefs;
    final timestamp = sp.getInt(_getUserKey(_keyLastSaved, userId));
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> clearProgress(String userId) async {
    try {
      final sp = await prefs;

      await Future.wait([
        sp.remove(_getUserKey(_keyEducationLevel, userId)),
        sp.remove(_getUserKey(_keyOtherEducation, userId)),
        sp.remove(_getUserKey(_keyAcademicRecords, userId)),
        sp.remove(_getUserKey(_keyEnglishTests, userId)),
        sp.remove(_getUserKey(_keyPersonality, userId)),
        sp.remove(_getUserKey(_keyInterests, userId)),
        sp.remove(_getUserKey(_keyPreferences, userId)),
        sp.remove(_getUserKey(_keyMatchResponse, userId)),
        sp.remove(_getUserKey(_keyMatchedPrograms, userId)),
        sp.remove(_getUserKey(_keyMatchTimestamp, userId)),
        sp.remove(_getUserKey(_keyLastSaved, userId)),
      ]);

      _cache.clear();
      _isCacheValid = false;

      debugPrint('✅ Saved progress cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing progress: $e');
    }
  }

  void invalidateCache() {
    _isCacheValid = false;
    _cache.clear();
  }
}