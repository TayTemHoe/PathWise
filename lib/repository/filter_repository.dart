// lib/repository/filter_repository_v2.dart
import 'package:flutter/foundation.dart';
import '../services/local_data_source.dart';
import '../utils/currency_utils.dart';

class FilterRepository {
  final LocalDataSource _localDataSource = LocalDataSource.instance;

  // ==================== IN-MEMORY CACHE ====================
  // Cache filter metadata (lightweight)
  List<String>? _cachedCountries;
  Map<String, List<String>> _cachedCities = {};
  List<String>? _cachedSubjectAreas;
  List<String>? _cachedStudyModes;
  List<String>? _cachedStudyLevels;
  List<String>? _cachedIntakeMonths;
  List<Map<String, String>>? _cachedUniversities;
  (int, int)? _cachedStudentRange;
  (int, int)? _cachedRankingRange;
  (int, int)? _cachedSubjectRankingRange;
  (double, double)? _cachedDurationRange;
  (double, double)? _cachedTuitionRange;
  (double, double)? _cachedProgramTuitionRange;
  List<String>? _cachedInstitutionTypes;

  DateTime? _lastCacheTime;
  static const Duration _cacheValidity = Duration(hours: 12);

  bool get _isCacheValid {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheValidity;
  }

  // ==================== UNIVERSITY FILTERS ====================

  /// Get available countries
  Future<List<String>> getAvailableCountries() async {
    if (_isCacheValid && _cachedCountries != null) {
      debugPrint('📦 Cache HIT: Countries');
      return _cachedCountries!;
    }

    try {
      debugPrint('📥 Loading countries from SQLite...');

      _cachedCountries = await _localDataSource.getAvailableCountries();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Loaded ${_cachedCountries!.length} countries');
      return _cachedCountries!;
    } catch (e) {
      debugPrint('❌ Error loading countries: $e');
      return [];
    }
  }

  /// Get cities for country
  Future<List<String>> getCitiesForCountry(String country) async {
    if (_isCacheValid && _cachedCities.containsKey(country)) {
      debugPrint('📦 Cache HIT: Cities for $country');
      return _cachedCities[country]!;
    }

    try {
      debugPrint('📥 Loading cities for $country from SQLite...');

      final cities = await _localDataSource.getCitiesForCountry(country);
      _cachedCities[country] = cities;
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Loaded ${cities.length} cities');
      return cities;
    } catch (e) {
      debugPrint('❌ Error loading cities: $e');
      return [];
    }
  }

  /// Get student range
  Future<(int, int)> getStudentRange() async {
    if (_isCacheValid && _cachedStudentRange != null) {
      debugPrint('📦 Cache HIT: Student range');
      return _cachedStudentRange!;
    }

    try {
      debugPrint('📥 Loading student range from SQLite...');

      _cachedStudentRange = await _localDataSource.getStudentRange();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Student range: ${_cachedStudentRange!.$1} - ${_cachedStudentRange!.$2}');
      return _cachedStudentRange!;
    } catch (e) {
      debugPrint('❌ Error loading student range: $e');
      return (0, 100000);
    }
  }

  /// Get ranking range
  Future<(int, int)> getRankingRange() async {
    if (_isCacheValid && _cachedRankingRange != null) {
      debugPrint('📦 Cache HIT: Ranking range');
      return _cachedRankingRange!;
    }

    try {
      debugPrint('📥 Loading ranking range from SQLite...');

      _cachedRankingRange = await _localDataSource.getRankingRange();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Ranking range: #${_cachedRankingRange!.$1} - #${_cachedRankingRange!.$2}');
      return _cachedRankingRange!;
    } catch (e) {
      debugPrint('❌ Error loading ranking range: $e');
      return (1, 2000);
    }
  }

  /// Get tuition fee range (for universities)
  Future<(double, double)> getTuitionFeeRange() async {
    if (_isCacheValid && _cachedTuitionRange != null) {
      debugPrint('📦 Cache HIT: Tuition range');
      return _cachedTuitionRange!;
    }

    try {
      debugPrint('📥 Loading tuition range...');

      // Ensure currency rates are loaded
      await CurrencyUtils.fetchExchangeRates();

      _cachedTuitionRange = await _localDataSource.getTuitionFeeRange();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Tuition range: ${CurrencyUtils.formatMYR(_cachedTuitionRange!.$1)} - ${CurrencyUtils.formatMYR(_cachedTuitionRange!.$2)}');
      return _cachedTuitionRange!;
    } catch (e) {
      debugPrint('❌ Error loading tuition range: $e');
      return (0.0, 500000.0);
    }
  }

  /// Get institution types (static list)
  Future<List<String>> getInstitutionTypes() async {
    if (_cachedInstitutionTypes != null) {
      return _cachedInstitutionTypes!;
    }

    _cachedInstitutionTypes = [
      'Public',
      'Private',
      'Research',
      'Technical',
      'Community',
      'Liberal Arts',
    ];

    return _cachedInstitutionTypes!;
  }

  // ==================== PROGRAM FILTERS ====================

  /// Get available subject areas
  Future<List<String>> getAvailableSubjectAreas() async {
    if (_isCacheValid && _cachedSubjectAreas != null) {
      debugPrint('📦 Cache HIT: Subject areas');
      return _cachedSubjectAreas!;
    }

    try {
      debugPrint('📥 Loading subject areas from SQLite...');

      _cachedSubjectAreas = await _localDataSource.getAvailableSubjectAreas();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Loaded ${_cachedSubjectAreas!.length} subject areas');
      return _cachedSubjectAreas!;
    } catch (e) {
      debugPrint('❌ Error loading subject areas: $e');
      return [];
    }
  }

  /// Get available study modes
  Future<List<String>> getAvailableStudyModes() async {
    if (_isCacheValid && _cachedStudyModes != null) {
      debugPrint('📦 Cache HIT: Study modes');
      return _cachedStudyModes!;
    }

    try {
      debugPrint('📥 Loading study modes from SQLite...');

      _cachedStudyModes = await _localDataSource.getAvailableStudyModes();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Loaded ${_cachedStudyModes!.length} study modes');
      return _cachedStudyModes!;
    } catch (e) {
      debugPrint('❌ Error loading study modes: $e');
      return [];
    }
  }

  /// Get available study levels
  Future<List<String>> getAvailableStudyLevels() async {
    if (_isCacheValid && _cachedStudyLevels != null) {
      debugPrint('📦 Cache HIT: Study levels');
      return _cachedStudyLevels!;
    }

    try {
      debugPrint('📥 Loading study levels from SQLite...');

      _cachedStudyLevels = await _localDataSource.getAvailableStudyLevels();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Loaded ${_cachedStudyLevels!.length} study levels');
      return _cachedStudyLevels!;
    } catch (e) {
      debugPrint('❌ Error loading study levels: $e');
      return [];
    }
  }

  /// Get available intake months
  Future<List<String>> getAvailableIntakeMonths() async {
    if (_isCacheValid && _cachedIntakeMonths != null) {
      debugPrint('📦 Cache HIT: Intake months');
      return _cachedIntakeMonths!;
    }

    try {
      debugPrint('📥 Loading intake months from SQLite...');

      _cachedIntakeMonths = await _localDataSource.getAvailableIntakeMonths();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Loaded ${_cachedIntakeMonths!.length} intake months');
      return _cachedIntakeMonths!;
    } catch (e) {
      debugPrint('❌ Error loading intake months: $e');
      return [];
    }
  }

  /// Get available universities
  Future<List<Map<String, String>>> getAvailableUniversities() async {
    if (_isCacheValid && _cachedUniversities != null) {
      debugPrint('📦 Cache HIT: Universities');
      return _cachedUniversities!;
    }

    try {
      debugPrint('📥 Loading universities from SQLite...');

      _cachedUniversities = await _localDataSource.getAvailableUniversities();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Loaded ${_cachedUniversities!.length} universities');
      return _cachedUniversities!;
    } catch (e) {
      debugPrint('❌ Error loading universities: $e');
      return [];
    }
  }

  /// Get subject ranking range
  Future<(int, int)> getSubjectRankingRange() async {
    if (_isCacheValid && _cachedSubjectRankingRange != null) {
      debugPrint('📦 Cache HIT: Subject ranking range');
      return _cachedSubjectRankingRange!;
    }

    try {
      debugPrint('📥 Loading subject ranking range from SQLite...');

      _cachedSubjectRankingRange = await _localDataSource.getSubjectRankingRange();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Subject ranking range: #${_cachedSubjectRankingRange!.$1} - #${_cachedSubjectRankingRange!.$2}');
      return _cachedSubjectRankingRange!;
    } catch (e) {
      debugPrint('❌ Error loading subject ranking range: $e');
      return (1, 500);
    }
  }

  /// Get duration range
  Future<(double, double)> getDurationRange() async {
    if (_isCacheValid && _cachedDurationRange != null) {
      debugPrint('📦 Cache HIT: Duration range');
      return _cachedDurationRange!;
    }

    try {
      debugPrint('📥 Loading duration range from SQLite...');

      _cachedDurationRange = await _localDataSource.getDurationRange();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Duration range: ${_cachedDurationRange!.$1} - ${_cachedDurationRange!.$2} years');
      return _cachedDurationRange!;
    } catch (e) {
      debugPrint('❌ Error loading duration range: $e');
      return (1.0, 6.0);
    }
  }

  /// Get program tuition fee range
  Future<(double, double)> getProgramTuitionFeeRange() async {
    if (_isCacheValid && _cachedProgramTuitionRange != null) {
      debugPrint('📦 Cache HIT: Program tuition range');
      return _cachedProgramTuitionRange!;
    }

    try {
      debugPrint('📥 Loading program tuition range...');

      // Ensure currency rates are loaded
      await CurrencyUtils.fetchExchangeRates();

      _cachedProgramTuitionRange = await _localDataSource.getProgramTuitionFeeRange();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Program tuition range: ${CurrencyUtils.formatMYR(_cachedProgramTuitionRange!.$1)} - ${CurrencyUtils.formatMYR(_cachedProgramTuitionRange!.$2)}');
      return _cachedProgramTuitionRange!;
    } catch (e) {
      debugPrint('❌ Error loading program tuition range: $e');
      return (0.0, 500000.0);
    }
  }

  // ==================== BULK OPERATIONS ====================

  /// Load all university filter metadata at once
  Future<Map<String, dynamic>> loadUniversityFilterMetadata() async {
    try {
      debugPrint('📥 Loading all university filter metadata...');

      final results = await Future.wait([
        getAvailableCountries(),
        getInstitutionTypes(),
        getStudentRange(),
        getTuitionFeeRange(),
        getRankingRange(),
      ]);

      final metadata = {
        'countries': results[0] as List<String>,
        'institutionTypes': results[1] as List<String>,
        'studentRange': results[2] as (int, int),
        'tuitionRange': results[3] as (double, double),
        'rankingRange': results[4] as (int, int),
      };

      debugPrint('✅ University filter metadata loaded');
      return metadata;
    } catch (e) {
      debugPrint('❌ Error loading university filter metadata: $e');
      return {};
    }
  }

  /// Load all program filter metadata at once
  Future<Map<String, dynamic>> loadProgramFilterMetadata() async {
    try {
      debugPrint('📥 Loading all program filter metadata...');

      final results = await Future.wait([
        getAvailableSubjectAreas(),
        getAvailableStudyModes(),
        getAvailableStudyLevels(),
        getAvailableIntakeMonths(),
        getAvailableUniversities(),
        getSubjectRankingRange(),
        getDurationRange(),
        getProgramTuitionFeeRange(),
        getAvailableCountries(),
      ]);

      final metadata = {
        'subjectAreas': results[0] as List<String>,
        'studyModes': results[1] as List<String>,
        'studyLevels': results[2] as List<String>,
        'intakeMonths': results[3] as List<String>,
        'universities': results[4] as List<Map<String, String>>,
        'rankingRange': results[5] as (int, int),
        'durationRange': results[6] as (double, double),
        'tuitionRange': results[7] as (double, double),
        'countries': results[8] as List<String>,
      };

      debugPrint('✅ Program filter metadata loaded');
      return metadata;
    } catch (e) {
      debugPrint('❌ Error loading program filter metadata: $e');
      return {};
    }
  }

  /// Search universities (for autocomplete)
  Future<List<String>> searchUniversities(String query, {int limit = 5}) async {
    if (query.isEmpty) return [];

    try {
      final universities = await _localDataSource.searchUniversities(query, limit: limit);
      return universities.map((u) => u.universityName).toList();
    } catch (e) {
      debugPrint('❌ Error searching universities: $e');
      return [];
    }
  }

  /// Search programs (for autocomplete)
  Future<List<String>> searchPrograms(String query, {int limit = 5}) async {
    if (query.isEmpty) return [];

    try {
      final programs = await _localDataSource.searchPrograms(query, limit: limit);
      return programs.map((p) => p.programName).toList();
    } catch (e) {
      debugPrint('❌ Error searching programs: $e');
      return [];
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all filter caches
  void clearCache() {
    _cachedCountries = null;
    _cachedCities.clear();
    _cachedSubjectAreas = null;
    _cachedStudyModes = null;
    _cachedStudyLevels = null;
    _cachedIntakeMonths = null;
    _cachedUniversities = null;
    _cachedStudentRange = null;
    _cachedRankingRange = null;
    _cachedSubjectRankingRange = null;
    _cachedDurationRange = null;
    _cachedTuitionRange = null;
    _cachedProgramTuitionRange = null;
    _cachedInstitutionTypes = null;
    _lastCacheTime = null;

    debugPrint('🧹 Filter cache cleared');
  }

  /// Refresh all filter data
  Future<void> refreshFilterData() async {
    debugPrint('🔄 Refreshing filter data...');
    clearCache();

    // Reload metadata
    await Future.wait([
      loadUniversityFilterMetadata(),
      loadProgramFilterMetadata(),
    ]);

    debugPrint('✅ Filter data refreshed');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'countries_cached': _cachedCountries != null,
      'countries_count': _cachedCountries?.length ?? 0,
      'cities_cached': _cachedCities.length,
      'subject_areas_cached': _cachedSubjectAreas != null,
      'subject_areas_count': _cachedSubjectAreas?.length ?? 0,
      'study_modes_cached': _cachedStudyModes != null,
      'study_modes_count': _cachedStudyModes?.length ?? 0,
      'study_levels_cached': _cachedStudyLevels != null,
      'study_levels_count': _cachedStudyLevels?.length ?? 0,
      'intake_months_cached': _cachedIntakeMonths != null,
      'intake_months_count': _cachedIntakeMonths?.length ?? 0,
      'universities_cached': _cachedUniversities != null,
      'universities_count': _cachedUniversities?.length ?? 0,
      'ranges_cached': _cachedStudentRange != null,
      'last_cache_time': _lastCacheTime?.toIso8601String(),
      'cache_valid': _isCacheValid,
    };
  }

  /// Warm up cache (preload all metadata)
  Future<void> warmUpCache() async {
    debugPrint('🔥 Warming up filter cache...');

    try {
      await Future.wait([
        loadUniversityFilterMetadata(),
        loadProgramFilterMetadata(),
      ]);

      debugPrint('✅ Cache warmed up successfully');
    } catch (e) {
      debugPrint('❌ Cache warm-up failed: $e');
    }
  }
}