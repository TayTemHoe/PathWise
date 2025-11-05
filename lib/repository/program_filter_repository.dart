import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../utils/currency_utils.dart';

class ProgramFilterRepository {
  final FirebaseService _firebaseService = FirebaseService();

  // ==================== AGGRESSIVE CACHING ====================
  static List<String>? _cachedSubjectAreas;
  static List<String>? _cachedStudyModes;
  static List<String>? _cachedStudyLevels;
  static List<String>? _cachedIntakeMonths;
  static List<Map<String, String>>? _cachedUniversities;
  static (int, int)? _cachedRankingRange;
  static (double, double)? _cachedDurationRange;
  static (double, double)? _cachedTuitionRange;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidity = Duration(hours: 24);

  // Search cache
  static final Map<String, List<String>> _searchCache = {};
  static final Map<String, DateTime> _searchCacheTime = {};
  static const Duration _searchCacheValidity = Duration(minutes: 30);

  Timer? _searchDebounceTimer;
  static const Duration _searchDebounce = Duration(milliseconds: 500);

  // Request deduplication
  static final Set<String> _activeRequests = {};

  bool get _isCacheValid {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheValidity;
  }

  static void clearCache() {
    _cachedSubjectAreas = null;
    _cachedStudyModes = null;
    _cachedStudyLevels = null;
    _cachedIntakeMonths = null;
    _cachedRankingRange = null;
    _cachedDurationRange = null;
    _cachedTuitionRange = null;
    _searchCache.clear();
    _searchCacheTime.clear();
    _lastCacheTime = null;
    _cachedUniversities = null;
  }

  /// Get available subject areas
  Future<List<String>> getAvailableSubjectAreas() async {
    if (_isCacheValid && _cachedSubjectAreas != null) {
      debugPrint('📦 Cache HIT: Subject areas');
      return _cachedSubjectAreas!;
    }

    if (_activeRequests.contains('subject_areas')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedSubjectAreas ?? [];
    }

    _activeRequests.add('subject_areas');

    try {
      debugPrint('🔥 Fetching subject areas...');

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .orderBy('subject_area')
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .orderBy('subject_area')
            .get(const GetOptions(source: Source.server));
      }

      Set<String> areas = {};
      for (var doc in snapshot.docs) {
        String? area = (doc.data() as Map<String, dynamic>)['subject_area']?.toString();
        if (area != null && area.isNotEmpty) {
          areas.add(area);
        }
      }

      _cachedSubjectAreas = areas.toList()..sort();
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Fetched ${_cachedSubjectAreas!.length} subject areas');
      return _cachedSubjectAreas!;
    } finally {
      _activeRequests.remove('subject_areas');
    }
  }

  Future<List<Map<String, String>>> getAvailableUniversities() async {
    if (_isCacheValid && _cachedUniversities != null) {
      debugPrint('📦 Cache HIT: Universities');
      return _cachedUniversities!;
    }

    if (_activeRequests.contains('universities')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedUniversities ?? [];
    }

    _activeRequests.add('universities');

    try {
      debugPrint('🔥 Fetching universities...');

      // Get all programs to extract unique university IDs
      QuerySnapshot programSnapshot;
      try {
        programSnapshot = await FirebaseFirestore.instance
            .collection('programs')
            .limit(500) // Sample to get university IDs
            .get(const GetOptions(source: Source.cache));

        if (programSnapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        programSnapshot = await FirebaseFirestore.instance
            .collection('programs')
            .limit(500)
            .get(const GetOptions(source: Source.server));
      }

      // Extract unique university IDs
      Set<String> universityIds = {};
      for (var doc in programSnapshot.docs) {
        String? uniId = (doc.data() as Map<String, dynamic>)['university_id']?.toString();
        if (uniId != null && uniId.isNotEmpty) {
          universityIds.add(uniId);
        }
      }

      // Fetch university names in batches
      List<Map<String, String>> universities = [];
      List<String> idList = universityIds.toList();

      for (int i = 0; i < idList.length; i += 10) {
        final batch = idList.skip(i).take(10).toList();

        QuerySnapshot uniSnapshot;
        try {
          uniSnapshot = await FirebaseFirestore.instance
              .collection('universities')
              .where(FieldPath.documentId, whereIn: batch)
              .get(const GetOptions(source: Source.cache));

          if (uniSnapshot.docs.isEmpty) throw Exception('No cache');
        } catch (e) {
          uniSnapshot = await FirebaseFirestore.instance
              .collection('universities')
              .where(FieldPath.documentId, whereIn: batch)
              .get(const GetOptions(source: Source.server));
        }

        for (var doc in uniSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          universities.add({
            'id': doc.id,
            'name': data['university_name']?.toString() ?? 'Unknown',
          });
        }
      }

      // Sort alphabetically
      universities.sort((a, b) => a['name']!.compareTo(b['name']!));
      _cachedUniversities = universities;
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Fetched ${universities.length} universities');
      return universities;
    } finally {
      _activeRequests.remove('universities');
    }
  }

  /// Get available study modes
  Future<List<String>> getAvailableStudyModes() async {
    if (_isCacheValid && _cachedStudyModes != null) {
      debugPrint('📦 Cache HIT: Study modes');
      return _cachedStudyModes!;
    }

    if (_activeRequests.contains('study_modes')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedStudyModes ?? [];
    }

    _activeRequests.add('study_modes');

    try {
      debugPrint('🔥 Fetching study modes...');

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .limit(1000)
            .get(const GetOptions(source: Source.server));
      }

      Set<String> modes = {};
      for (var doc in snapshot.docs) {
        String? mode = (doc.data() as Map<String, dynamic>)['study_mode']?.toString();
        if (mode != null && mode.isNotEmpty) {
          modes.add(mode);
        }
      }

      _cachedStudyModes = modes.toList()..sort();
      debugPrint('✅ Fetched ${_cachedStudyModes!.length} study modes');
      return _cachedStudyModes!;
    } finally {
      _activeRequests.remove('study_modes');
    }
  }

  /// Get available study levels
  Future<List<String>> getAvailableStudyLevels() async {
    if (_isCacheValid && _cachedStudyLevels != null) {
      debugPrint('📦 Cache HIT: Study levels');
      return _cachedStudyLevels!;
    }

    if (_activeRequests.contains('study_levels')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedStudyLevels ?? [];
    }

    _activeRequests.add('study_levels');

    try {
      debugPrint('🔥 Fetching study levels...');

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .limit(1000)
            .get(const GetOptions(source: Source.server));
      }

      Set<String> levels = {};
      for (var doc in snapshot.docs) {
        String? level = (doc.data() as Map<String, dynamic>)['study_level']?.toString();
        if (level != null && level.isNotEmpty) {
          levels.add(level);
        }
      }

      _cachedStudyLevels = levels.toList()..sort();
      debugPrint('✅ Fetched ${_cachedStudyLevels!.length} study levels');
      return _cachedStudyLevels!;
    } finally {
      _activeRequests.remove('study_levels');
    }
  }

  /// Get available intake months
  Future<List<String>> getAvailableIntakeMonths() async {
    if (_isCacheValid && _cachedIntakeMonths != null) {
      debugPrint('📦 Cache HIT: Intake months');
      return _cachedIntakeMonths!;
    }

    if (_activeRequests.contains('intake_months')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedIntakeMonths ?? [];
    }

    _activeRequests.add('intake_months');

    try {
      debugPrint('🔥 Fetching intake months...');

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .limit(1000)
            .get(const GetOptions(source: Source.server));
      }

      Set<String> months = {};
      for (var doc in snapshot.docs) {
        List<dynamic>? intakes = (doc.data() as Map<String, dynamic>)['intake_period'];
        if (intakes != null) {
          for (var month in intakes) {
            if (month != null && month.toString().isNotEmpty) {
              months.add(month.toString());
            }
          }
        }
      }

      // Sort months chronologically
      final monthOrder = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      _cachedIntakeMonths = months.toList()
        ..sort((a, b) {
          int indexA = monthOrder.indexOf(a);
          int indexB = monthOrder.indexOf(b);
          if (indexA == -1) indexA = 999;
          if (indexB == -1) indexB = 999;
          return indexA.compareTo(indexB);
        });

      debugPrint('✅ Fetched ${_cachedIntakeMonths!.length} intake months');
      return _cachedIntakeMonths!;
    } finally {
      _activeRequests.remove('intake_months');
    }
  }

  /// Get subject ranking range
  Future<(int min, int max)> getSubjectRankingRange() async {
    if (_isCacheValid && _cachedRankingRange != null) {
      debugPrint('📦 Cache HIT: Subject ranking range');
      return _cachedRankingRange!;
    }

    if (_activeRequests.contains('ranking_range')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedRankingRange ?? (1, 500);
    }

    _activeRequests.add('ranking_range');

    try {
      debugPrint('🔥 Fetching subject ranking range...');

      final collection = FirebaseFirestore.instance.collection('programs');

      Future<QuerySnapshot> getMinQuery() async {
        return await collection
            .where('min_subject_ranking', isGreaterThan: 0)
            .orderBy('min_subject_ranking')
            .limit(1)
            .get(const GetOptions(source: Source.server));
      }

      Future<QuerySnapshot> getMaxQuery() async {
        return await collection
            .where('min_subject_ranking', isGreaterThan: 0)
            .orderBy('min_subject_ranking', descending: true)
            .limit(1)
            .get(const GetOptions(source: Source.server));
      }

      final results = await Future.wait([getMinQuery(), getMaxQuery()]);
      final minSnapshot = results[0];
      final maxSnapshot = results[1];

      int minRank = 1;
      int maxRank = 500;

      if (minSnapshot.docs.isNotEmpty) {
        final data = minSnapshot.docs.first.data() as Map<String, dynamic>;
        minRank = (data['min_subject_ranking'] as int?) ?? 1;
      }

      if (maxSnapshot.docs.isNotEmpty) {
        final data = maxSnapshot.docs.first.data() as Map<String, dynamic>;
        final foundMaxRank = (data['min_subject_ranking'] as int?) ?? 500;
        final maxRankFromMaxField = (data['max_subject_ranking'] as int?);

        maxRank = (maxRankFromMaxField != null && maxRankFromMaxField > foundMaxRank)
            ? maxRankFromMaxField
            : foundMaxRank;
      }

      _cachedRankingRange = (minRank, maxRank);
      _lastCacheTime = DateTime.now();

      debugPrint('✅ Subject ranking range: #$minRank - #$maxRank');
      return _cachedRankingRange!;
    } catch (e) {
      debugPrint('❌ Error fetching ranking range: $e');
      return (1, 500);
    } finally {
      _activeRequests.remove('ranking_range');
    }
  }

  /// Get duration range (in years)
  Future<(double min, double max)> getDurationRange() async {
    if (_isCacheValid && _cachedDurationRange != null) {
      debugPrint('📦 Cache HIT: Duration range');
      return _cachedDurationRange!;
    }

    if (_activeRequests.contains('duration_range')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedDurationRange ?? (1.0, 6.0);
    }

    _activeRequests.add('duration_range');

    try {
      debugPrint('🔥 Fetching duration range...');

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .limit(500)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .limit(500)
            .get(const GetOptions(source: Source.server));
      }

      double minYears = 10.0;
      double maxYears = 0.0;

      for (var doc in snapshot.docs) {
        String? durationStr = (doc.data() as Map<String, dynamic>)['duration_months']?.toString();
        if (durationStr != null) {
          int? months = int.tryParse(durationStr);
          if (months != null && months > 0) {
            double years = months / 12.0;
            if (years < minYears) minYears = years;
            if (years > maxYears) maxYears = years;
          }
        }
      }

      if (minYears == 10.0) minYears = 1.0;
      if (maxYears == 0.0) maxYears = 6.0;

      _cachedDurationRange = (minYears, maxYears);
      debugPrint('✅ Duration range: $minYears - $maxYears years');
      return _cachedDurationRange!;
    } finally {
      _activeRequests.remove('duration_range');
    }
  }

  /// Get tuition fee range (in MYR)
  Future<(double min, double max)> getTuitionFeeRange() async {
    if (_isCacheValid && _cachedTuitionRange != null) {
      debugPrint('📦 Cache HIT: Tuition range');
      return _cachedTuitionRange!;
    }

    if (_activeRequests.contains('tuition_range')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedTuitionRange ?? (0.0, 500000.0);
    }

    _activeRequests.add('tuition_range');

    try {
      debugPrint('🔥 Fetching tuition range...');

      await CurrencyUtils.fetchExchangeRates();

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .limit(200)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .limit(200)
            .get(const GetOptions(source: Source.server));
      }

      double minFee = double.infinity;
      double maxFee = 0.0;

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        if (data['min_domestic_tuition_fee'] != null) {
          double? fee = CurrencyUtils.convertToMYR(data['min_domestic_tuition_fee']);
          if (fee != null && fee > 0) {
            if (fee < minFee) minFee = fee;
            if (fee > maxFee) maxFee = fee;
          }
        }

        if (data['min_international_tuition_fee'] != null) {
          double? fee = CurrencyUtils.convertToMYR(data['min_international_tuition_fee']);
          if (fee != null && fee > 0) {
            if (fee < minFee) minFee = fee;
            if (fee > maxFee) maxFee = fee;
          }
        }
      }

      if (minFee == double.infinity) minFee = 0;

      minFee = (minFee / 1000).floor() * 1000;
      maxFee = ((maxFee / 1000).ceil() * 1000);

      _cachedTuitionRange = (minFee, maxFee);
      debugPrint('✅ Tuition range: ${CurrencyUtils.formatMYR(minFee)} - ${CurrencyUtils.formatMYR(maxFee)}');
      return _cachedTuitionRange!;
    } finally {
      _activeRequests.remove('tuition_range');
    }
  }

  /// Search programs
  Future<List<String>> searchPrograms(String query, {int limit = 5}) async {
    if (query.isEmpty) return [];

    final cacheKey = '${query.toLowerCase()}_$limit';

    if (_searchCache.containsKey(cacheKey)) {
      final cacheTime = _searchCacheTime[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _searchCacheValidity) {
        debugPrint('📦 Cache HIT: Search "$query"');
        return _searchCache[cacheKey]!;
      }
    }

    if (_activeRequests.contains('search_$query')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _searchCache[cacheKey] ?? [];
    }

    _activeRequests.add('search_$query');

    try {
      debugPrint('🔍 Searching for: "$query"');

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .orderBy('program_name')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(limit)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .orderBy('program_name')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(limit)
            .get(const GetOptions(source: Source.server));
      }

      List<String> suggestions = [];
      for (var doc in snapshot.docs) {
        String name = (doc.data() as Map<String, dynamic>)['program_name']?.toString() ?? '';
        if (name.isNotEmpty) {
          suggestions.add(name);
        }
      }

      _searchCache[cacheKey] = suggestions;
      _searchCacheTime[cacheKey] = DateTime.now();

      debugPrint('✅ Found ${suggestions.length} matches for "$query"');
      return suggestions;
    } finally {
      _activeRequests.remove('search_$query');
    }
  }

  /// Load all filter metadata
  Future<Map<String, dynamic>> loadAllFilterMetadata() async {
    if (_isCacheValid &&
        _cachedSubjectAreas != null &&
        _cachedStudyModes != null &&
        _cachedStudyLevels != null &&
        _cachedIntakeMonths != null &&
        _cachedRankingRange != null &&
        _cachedDurationRange != null &&
        _cachedTuitionRange != null &&
        _cachedUniversities != null) {
      debugPrint('📦 Cache HIT: All filter metadata');

      return {
        'subjectAreas': _cachedSubjectAreas!,
        'studyModes': _cachedStudyModes!,
        'studyLevels': _cachedStudyLevels!,
        'intakeMonths': _cachedIntakeMonths!,
        'rankingRange': _cachedRankingRange!,
        'durationRange': _cachedDurationRange!,
        'tuitionRange': _cachedTuitionRange!,
        'universities': _cachedUniversities!,
      };
    }

    debugPrint('🔥 Loading all filter metadata...');

    final results = await Future.wait([
      getAvailableSubjectAreas(),
      getAvailableStudyModes(),
      getAvailableStudyLevels(),
      getAvailableIntakeMonths(),
      getSubjectRankingRange(),
      getDurationRange(),
      getTuitionFeeRange(),
      getAvailableUniversities(),
    ]);

    final metadata = {
      'subjectAreas': results[0] as List<String>,
      'studyModes': results[1] as List<String>,
      'studyLevels': results[2] as List<String>,
      'intakeMonths': results[3] as List<String>,
      'rankingRange': results[4] as (int, int),
      'durationRange': results[5] as (double, double),
      'tuitionRange': results[6] as (double, double),
      'universities': results[7] as List<Map<String, String>>,
    };

    debugPrint('✅ Filter metadata loaded');
    return metadata;
  }

  Future<void> refreshCache() async {
    debugPrint('🔄 Refreshing filter cache...');
    clearCache();
    await CurrencyUtils.refreshRates();
    await loadAllFilterMetadata();
    debugPrint('✅ Cache refreshed');
  }

  void dispose() {
    _searchDebounceTimer?.cancel();
  }
}