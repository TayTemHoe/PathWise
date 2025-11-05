import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../utils/currency_utils.dart';

class FilterRepository {
  final FirebaseService _firebaseService = FirebaseService();

  // ==================== AGGRESSIVE CACHING ====================

  static List<String>? _cachedCountries;
  static Map<String, List<String>> _cachedCities = {};
  static (int, int)? _cachedStudentRange;
  static (double, double)? _cachedTuitionRange;
  static (int, int)? _cachedRankingRange;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidity = Duration(hours: 24);

  // Search cache with expiry
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
    _cachedCountries = null;
    _cachedCities.clear();
    _cachedStudentRange = null;
    _cachedTuitionRange = null;
    _cachedRankingRange = null;
    _searchCache.clear();
    _searchCacheTime.clear();
    _lastCacheTime = null;
  }

  /// OPTIMIZED: Get countries with extended caching
  Future<List<String>> getAvailableCountries() async {
    if (_isCacheValid && _cachedCountries != null) {
      if (kDebugMode) {
        print('📦 Cache HIT: Countries (${_cachedCountries!.length} items)');
      }
      return _cachedCountries!;
    }

    if (_activeRequests.contains('countries')) {
      if (kDebugMode) {
        print('⏸️ Request already in progress: countries');
      }
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedCountries ?? [];
    }

    _activeRequests.add('countries');

    try {
      if (kDebugMode) {
        print('🔥 Fetching countries from Firestore...');
      }

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('branches')
            .orderBy('country')
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) {
          throw Exception('No cache available');
        }
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('branches')
            .orderBy('country')
            .get(const GetOptions(source: Source.server));
      }

      Set<String> countries = {};
      for (var doc in snapshot.docs) {
        String country = (doc.data() as Map<String, dynamic>)['country']?.toString().trim() ?? '';
        country = country.replaceAll(RegExp(r'^,+|,+$'), '').trim();

        if (country.isNotEmpty && country != ',') {
          countries.add(country);
        }
      }

      List<String> sortedCountries = countries.toList()..sort();

      _cachedCountries = sortedCountries;
      _lastCacheTime = DateTime.now();

      if (kDebugMode) {
        print('✅ Fetched ${sortedCountries.length} countries');
      }

      return sortedCountries;
    } finally {
      _activeRequests.remove('countries');
    }
  }

  /// OPTIMIZED: Get cities with per-country caching
  Future<List<String>> getCitiesForCountry(String country) async {
    if (_isCacheValid && _cachedCities.containsKey(country)) {
      if (kDebugMode) {
        print('📦 Cache HIT: Cities for $country (${_cachedCities[country]!.length})');
      }
      return _cachedCities[country]!;
    }

    final requestKey = 'cities_$country';
    if (_activeRequests.contains(requestKey)) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedCities[country] ?? [];
    }

    _activeRequests.add(requestKey);

    try {
      if (kDebugMode) {
        print('🔥 Fetching cities for $country...');
      }

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('branches')
            .where('country', isEqualTo: country)
            .orderBy('city')
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) {
          throw Exception('No cache');
        }
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('branches')
            .where('country', isEqualTo: country)
            .orderBy('city')
            .get(const GetOptions(source: Source.server));
      }

      Set<String> cities = {};
      for (var doc in snapshot.docs) {
        String city = (doc.data() as Map<String, dynamic>)['city']?.toString().trim() ?? '';
        city = city.replaceAll(RegExp(r'^,+|,+$'), '').trim();

        if (city.isNotEmpty && city != ',') {
          cities.add(city);
        }
      }

      List<String> sortedCities = cities.toList()..sort();
      _cachedCities[country] = sortedCities;

      if (kDebugMode) {
        print('✅ Fetched ${sortedCities.length} cities for $country');
      }

      return sortedCities;
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  /// OPTIMIZED: Get student range with minimal queries
  Future<(int min, int max)> getStudentRange() async {
    if (_isCacheValid && _cachedStudentRange != null) {
      if (kDebugMode) {
        print('📦 Cache HIT: Student range');
      }
      return _cachedStudentRange!;
    }

    if (_activeRequests.contains('student_range')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedStudentRange ?? (0, 100000);
    }

    _activeRequests.add('student_range');

    try {
      if (kDebugMode) {
        print('🔥 Fetching student range...');
      }

      final collection = FirebaseFirestore.instance.collection('universities');

      Future<QuerySnapshot> getMinQuery() async {
        try {
          final cache = await collection
              .where('total_students', isGreaterThan: 0)
              .orderBy('total_students')
              .limit(1)
              .get(const GetOptions(source: Source.cache));
          if (cache.docs.isNotEmpty) return cache;
        } catch (e) {}

        return await collection
            .where('total_students', isGreaterThan: 0)
            .orderBy('total_students')
            .limit(1)
            .get(const GetOptions(source: Source.server));
      }

      Future<QuerySnapshot> getMaxQuery() async {
        try {
          final cache = await collection
              .orderBy('total_students', descending: true)
              .limit(1)
              .get(const GetOptions(source: Source.cache));
          if (cache.docs.isNotEmpty) return cache;
        } catch (e) {}

        return await collection
            .orderBy('total_students', descending: true)
            .limit(1)
            .get(const GetOptions(source: Source.server));
      }

      final results = await Future.wait([getMinQuery(), getMaxQuery()]);
      final minSnapshot = results[0];
      final maxSnapshot = results[1];

      int? rawMin;
      int? rawMax;

      if (minSnapshot.docs.isNotEmpty) {
        rawMin = (minSnapshot.docs.first.data() as Map<String, dynamic>)['total_students'] as int?;
      }

      if (maxSnapshot.docs.isNotEmpty) {
        rawMax = (maxSnapshot.docs.first.data() as Map<String, dynamic>)['total_students'] as int?;
      }

      int minStudents = (rawMin != null) ? (rawMin / 1000).floor() * 1000 : 0;
      int maxStudents = (rawMax != null && rawMax > 0)
          ? ((rawMax / 1000).ceil() * 1000)
          : 100000;

      if (maxStudents < minStudents) {
        maxStudents = ((minStudents / 1000).ceil() * 1000) + 10000;
      }

      _cachedStudentRange = (minStudents, maxStudents);

      if (kDebugMode) {
        print('✅ Student range: $minStudents - $maxStudents');
      }

      return _cachedStudentRange!;
    } finally {
      _activeRequests.remove('student_range');
    }
  }

  Future<List<String>> getInstitutionTypes() async {
    return [
      'Public',
      'Private',
      'Research',
      'Technical',
      'Community',
      'Liberal Arts',
    ];
  }

  /// OPTIMIZED: Get tuition range with batch processing
  Future<(double min, double max)> getTuitionFeeRange() async {
    if (_isCacheValid && _cachedTuitionRange != null) {
      if (kDebugMode) {
        print('📦 Cache HIT: Tuition range');
      }
      return _cachedTuitionRange!;
    }

    if (_activeRequests.contains('tuition_range')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedTuitionRange ?? (0.0, 500000.0);
    }

    _activeRequests.add('tuition_range');

    try {
      if (kDebugMode) {
        print('🔥 Fetching tuition range...');
      }

      await CurrencyUtils.fetchExchangeRates();

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('universities')
            .limit(100)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('universities')
            .limit(100)
            .get(const GetOptions(source: Source.server));
      }

      double minFee = double.infinity;
      double maxFee = 0.0;

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        if (data['domestic_tuition_fee'] != null) {
          double? fee = CurrencyUtils.convertToMYR(data['domestic_tuition_fee']);
          if (fee != null && fee > 0) {
            if (fee < minFee) minFee = fee;
            if (fee > maxFee) maxFee = fee;
          }
        }

        if (data['international_tuition_fee'] != null) {
          double? fee = CurrencyUtils.convertToMYR(data['international_tuition_fee']);
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

      if (kDebugMode) {
        print('✅ Tuition range: ${CurrencyUtils.formatMYR(minFee)} - ${CurrencyUtils.formatMYR(maxFee)}');
      }

      return _cachedTuitionRange!;
    } finally {
      _activeRequests.remove('tuition_range');
    }
  }

  /// COMPLETELY FIXED: Get ranking range by fetching ALL universities
  Future<(int min, int max)> getRankingRange() async {
    if (_isCacheValid && _cachedRankingRange != null) {
      if (kDebugMode) {
        print('📦 Cache HIT: Ranking range');
      }
      return _cachedRankingRange!;
    }

    if (_activeRequests.contains('ranking_range')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _cachedRankingRange ?? (1, 2000);
    }

    _activeRequests.add('ranking_range');

    try {
      if (kDebugMode) {
        print('🔥 Fetching ranking range from Firestore...');
      }

      final collection = FirebaseFirestore.instance.collection('universities');

      // OPTIMIZED: Use two targeted queries instead of fetching all data
      Future<QuerySnapshot> getMinQuery() async {
        return await collection
            .where('min_ranking', isGreaterThan: 0)
            .orderBy('min_ranking')
            .limit(1)
            .get(const GetOptions(source: Source.server));
      }

      Future<QuerySnapshot> getMaxQuery() async {
        return await collection
            .where('min_ranking', isGreaterThan: 0)
            .orderBy('min_ranking', descending: true)
            .limit(1)
            .get(const GetOptions(source: Source.server));
      }

      // Execute both queries in parallel
      final results = await Future.wait([getMinQuery(), getMaxQuery()]);
      final minSnapshot = results[0];
      final maxSnapshot = results[1];

      int minRank = 1; // Default
      int maxRank = 2000; // Default

      if (minSnapshot.docs.isNotEmpty) {
        final data = minSnapshot.docs.first.data() as Map<String, dynamic>;
        minRank = (data['min_ranking'] as int?) ?? 1;

        if (kDebugMode) {
          print('   📌 Found min ranking: #$minRank (${data['university_name']})');
        }
      }

      if (maxSnapshot.docs.isNotEmpty) {
        final data = maxSnapshot.docs.first.data() as Map<String, dynamic>;
        final foundMaxRank = (data['min_ranking'] as int?) ?? 2000;
        final maxRankFromMaxField = (data['max_ranking'] as int?);

        // Use the larger value between min_ranking and max_ranking
        maxRank = (maxRankFromMaxField != null && maxRankFromMaxField > foundMaxRank)
            ? maxRankFromMaxField
            : foundMaxRank;

        if (kDebugMode) {
          print('   📌 Found max ranking: #$maxRank (${data['university_name']})');
        }
      }

      // Validation
      if (minRank > maxRank) {
        if (kDebugMode) {
          print('⚠️ Invalid range detected, adjusting...');
        }
        maxRank = minRank + 1000;
      }

      _cachedRankingRange = (minRank, maxRank);
      _lastCacheTime = DateTime.now();

      if (kDebugMode) {
        print('✅ Ranking range: #$minRank - #$maxRank');
      }

      return _cachedRankingRange!;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching ranking range: $e');
      }
      return (1, 2000);
    } finally {
      _activeRequests.remove('ranking_range');
    }
  }

  /// OPTIMIZED: Search with aggressive caching
  Future<List<String>> searchUniversities(String query, {int limit = 5}) async {
    if (query.isEmpty) return [];

    final cacheKey = '${query.toLowerCase()}_$limit';

    if (_searchCache.containsKey(cacheKey)) {
      final cacheTime = _searchCacheTime[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _searchCacheValidity) {
        if (kDebugMode) {
          print('📦 Cache HIT: Search "$query"');
        }
        return _searchCache[cacheKey]!;
      }
    }

    if (_activeRequests.contains('search_$query')) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _searchCache[cacheKey] ?? [];
    }

    _activeRequests.add('search_$query');

    try {
      if (kDebugMode) {
        print('🔍 Searching for: "$query"');
      }

      final lowerQuery = query.toLowerCase();

      QuerySnapshot prefixSnapshot;
      try {
        prefixSnapshot = await FirebaseFirestore.instance
            .collection('universities')
            .orderBy('university_name')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(limit)
            .get(const GetOptions(source: Source.cache));

        if (prefixSnapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        prefixSnapshot = await FirebaseFirestore.instance
            .collection('universities')
            .orderBy('university_name')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(limit)
            .get(const GetOptions(source: Source.server));
      }

      List<String> suggestions = [];

      for (var doc in prefixSnapshot.docs) {
        String name = (doc.data() as Map<String, dynamic>)['university_name']?.toString() ?? '';
        if (name.isNotEmpty) {
          suggestions.add(name);
        }
      }

      _searchCache[cacheKey] = suggestions;
      _searchCacheTime[cacheKey] = DateTime.now();

      if (kDebugMode) {
        print('✅ Found ${suggestions.length} matches for "$query"');
      }

      return suggestions;
    } finally {
      _activeRequests.remove('search_$query');
    }
  }

  /// Debounced search
  Future<List<String>> searchUniversitiesDebounced(
      String query, {
        int limit = 5,
        Duration? debounce,
      }) async {
    _searchDebounceTimer?.cancel();

    final completer = Completer<List<String>>();

    _searchDebounceTimer = Timer(
      debounce ?? _searchDebounce,
          () async {
        final results = await searchUniversities(query, limit: limit);
        if (!completer.isCompleted) {
          completer.complete(results);
        }
      },
    );

    return completer.future;
  }

  /// OPTIMIZED: Load all in parallel with caching
  Future<Map<String, dynamic>> loadAllFilterMetadata() async {
    if (_isCacheValid &&
        _cachedCountries != null &&
        _cachedStudentRange != null &&
        _cachedTuitionRange != null &&
        _cachedRankingRange != null) {
      if (kDebugMode) {
        print('📦 Cache HIT: All filter metadata');
      }

      return {
        'countries': _cachedCountries!,
        'institutionTypes': await getInstitutionTypes(),
        'studentRange': _cachedStudentRange!,
        'tuitionRange': _cachedTuitionRange!,
        'rankingRange': _cachedRankingRange!,
      };
    }

    if (kDebugMode) {
      print('🔥 Loading all filter metadata...');
    }

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

    if (kDebugMode) {
      print('✅ Filter metadata loaded');
    }

    return metadata;
  }

  Future<void> refreshCache() async {
    if (kDebugMode) {
      print('🔄 Refreshing filter cache...');
    }

    clearCache();
    await CurrencyUtils.refreshRates();
    await loadAllFilterMetadata();

    if (kDebugMode) {
      print('✅ Cache refreshed');
    }
  }

  void dispose() {
    _searchDebounceTimer?.cancel();
  }
}