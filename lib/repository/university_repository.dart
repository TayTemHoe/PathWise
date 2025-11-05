import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_wise/services/firebase_service.dart';

import '../model/university_filter.dart';
import '../model/university.dart';
import '../utils/currency_utils.dart';

class UniversityRepository {
  final FirebaseService _firebaseService;

  // ==================== LOCAL CACHING ====================
  static final Map<String, (List<UniversityModel>, DocumentSnapshot?)> _queryCache = {};
  static final Map<String, DateTime> _queryCacheTime = {};
  static const Duration _queryCacheValidity = Duration(minutes: 30);

  // Cache for Malaysian university IDs (for default behavior)
  static Set<String>? _malaysianUniIds;
  static DateTime? _malaysianIdsCacheTime;

  UniversityRepository(this._firebaseService);

  /// CRITICAL FIX: Get universities with proper filter handling
  Future<(List<UniversityModel>, DocumentSnapshot?)> getUniversities({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    FilterModel? filter,
  }) async {
    final filterHash = filter?.hashCode ?? 0;
    final cacheKey = '${filterHash}_${limit}_${lastDocument?.id ?? 'start'}';

    // Check query cache
    if (_queryCache.containsKey(cacheKey)) {
      final cacheTime = _queryCacheTime[cacheKey];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _queryCacheValidity) {
        debugPrint('📦 Cache HIT: Query results');
        return _queryCache[cacheKey]!;
      }
    }

    try {
      // RULE 1: Default to Malaysian universities when no location/ranking filters
      if (filter == null || filter.shouldDefaultToMalaysia) {
        debugPrint('🇲🇾 Defaulting to Malaysian universities');
        return await _getMalaysianUniversitiesFiltered(
          limit: limit,
          lastDocument: lastDocument,
          filter: filter,
        );
      }

      // RULE 2 & 3: Apply filters independently or combined

      // Search query (highest priority)
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        return await _searchUniversitiesWithFilters(
          searchQuery: filter.searchQuery!,
          limit: limit,
          lastDocument: lastDocument,
          filter: filter,
        );
      }

      // Country/City filter
      if (filter.country != null) {
        return await _getUniversitiesByLocation(
          country: filter.country!,
          city: filter.city,
          limit: limit,
          lastDocument: lastDocument,
          filter: filter,
        );
      }

      // Ranking-based queries (range or sort)
      if (filter.minRanking != null || filter.maxRanking != null || filter.rankingSortOrder != null) {
        return await _getUniversitiesByRanking(
          limit: limit,
          lastDocument: lastDocument,
          filter: filter,
        );
      }

      // Fallback: Load all universities with filters
      return await _getAllUniversitiesWithFilters(
        limit: limit,
        lastDocument: lastDocument,
        filter: filter,
      );

    } catch (e) {
      debugPrint('❌ Error in getUniversities: $e');
      return (<UniversityModel>[], null);
    }
  }

  /// OPTIMIZED: Get Malaysian universities with optional filters
  Future<(List<UniversityModel>, DocumentSnapshot?)> _getMalaysianUniversitiesFiltered({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    FilterModel? filter,
  }) async {
    try {
      // Get Malaysian university IDs (cached)
      final malaysianIds = await _getMalaysianUniversityIds();

      if (malaysianIds.isEmpty) {
        return (<UniversityModel>[], null);
      }

      // Fetch universities in batches
      final allUniversities = await _firebaseService.getBatchUniversities(
        malaysianIds.toList(),
      );

      // Apply client-side filters
      List<UniversityModel> filtered = allUniversities;
      if (filter != null) {
        filtered = allUniversities.where((uni) => _matchesClientSideFilters(uni, filter, isMalaysianUniversity: true)).toList();
      }

      // Sort by ranking (best first)
      filtered.sort((a, b) => _compareByRanking(a, b, filter?.rankingSortOrder));

      // Paginate
      return _paginateResults(filtered, limit, lastDocument);
    } catch (e) {
      debugPrint('❌ Error in _getMalaysianUniversitiesFiltered: $e');
      return (<UniversityModel>[], null);
    }
  }

  /// OPTIMIZED: Cache Malaysian university IDs
  Future<Set<String>> _getMalaysianUniversityIds() async {
    // Check cache (valid for 24 hours)
    if (_malaysianUniIds != null && _malaysianIdsCacheTime != null) {
      final age = DateTime.now().difference(_malaysianIdsCacheTime!);
      if (age.inHours < 24) {
        debugPrint('📦 Cache HIT: Malaysian university IDs (${_malaysianUniIds!.length})');
        return _malaysianUniIds!;
      }
    }

    debugPrint('🔥 Fetching Malaysian university IDs...');

    try {
      // Try cache first
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('branches')
          .where('country', isEqualTo: 'Malaysia')
          .get(const GetOptions(source: Source.cache));

      if (snapshot.docs.isEmpty) {
        // Fallback to server
        snapshot = await FirebaseFirestore.instance
            .collection('branches')
            .where('country', isEqualTo: 'Malaysia')
            .get(const GetOptions(source: Source.server));
      }

      final ids = <String>{};
      for (var doc in snapshot.docs) {
        final uniId = (doc.data() as Map<String, dynamic>)['university_id'] as String?;
        if (uniId != null) ids.add(uniId);
      }

      _malaysianUniIds = ids;
      _malaysianIdsCacheTime = DateTime.now();

      debugPrint('✅ Cached ${ids.length} Malaysian university IDs');
      return ids;

    } catch (e) {
      debugPrint('❌ Error fetching Malaysian IDs: $e');
      return {};
    }
  }

  /// FIXED: Search with comprehensive filters
  Future<(List<UniversityModel>, DocumentSnapshot?)> _searchUniversitiesWithFilters({
    required String searchQuery,
    required int limit,
    DocumentSnapshot? lastDocument,
    FilterModel? filter,
  }) async {
    try {
      debugPrint('🔍 Searching: "$searchQuery"');

      // Use Firestore prefix search
      Query query = FirebaseFirestore.instance
          .collection('universities')
          .orderBy('university_name')
          .startAt([searchQuery])
          .endAt(['$searchQuery\uf8ff'])
          .limit(limit * 5);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot;
      try {
        snapshot = await query.get(const GetOptions(source: Source.cache));
        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await query.get(const GetOptions(source: Source.server));
      }

      // Parse and filter
      final universities = await _parseAndFilterUniversities(
          snapshot.docs,
          filter
      );

      // Sort if needed
      universities.sort((a, b) => _compareByRanking(a, b, filter?.rankingSortOrder));

      // Paginate
      return _paginateResults(universities, limit, lastDocument);

    } catch (e) {
      debugPrint('❌ Error in search: $e');
      return (<UniversityModel>[], null);
    }
  }

  /// FIXED: Get universities by location with filters
  Future<(List<UniversityModel>, DocumentSnapshot?)> _getUniversitiesByLocation({
    required String country,
    String? city,
    required int limit,
    DocumentSnapshot? lastDocument,
    FilterModel? filter,
  }) async {
    try {
      debugPrint('🌍 Loading: $country${city != null ? ", $city" : ""}');

      // Query branches for location
      Query branchQuery = FirebaseFirestore.instance
          .collection('branches')
          .where('country', isEqualTo: country);

      if (city != null && city.isNotEmpty) {
        branchQuery = branchQuery.where('city', isEqualTo: city);
      }

      QuerySnapshot snapshot;
      try {
        snapshot = await branchQuery.get(const GetOptions(source: Source.cache));
        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await branchQuery.get(const GetOptions(source: Source.server));
      }

      // Extract university IDs
      final Set<String> universityIds = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final uniId = data['university_id'] as String?;
        if (uniId != null) {
          universityIds.add(uniId);
        }
      }

      if (universityIds.isEmpty) {
        debugPrint('No universities found in $country');
        return (<UniversityModel>[], null);
      }

      // Fetch universities
      final allUniversities = await _firebaseService.getBatchUniversities(universityIds.toList());

      // Apply filters
      final bool isMalaysian = (country == 'Malaysia');

      // Apply filters
      List<UniversityModel> filteredUniversities = allUniversities;
      if (filter != null) {
        filteredUniversities = allUniversities
            .where((uni) => _matchesClientSideFilters(uni, filter, isMalaysianUniversity: isMalaysian))
            .toList();
      }

      // Sort by ranking
      filteredUniversities.sort((a, b) {
        final rankA = a.minRanking;
        final rankB = b.minRanking;

        if (rankA == null && rankB == null) return 0;
        if (rankA == null) return 1;
        if (rankB == null) return -1;

        if (filter?.rankingSortOrder == 'desc') {
          return rankB.compareTo(rankA);
        }
        return rankA.compareTo(rankB);
      });

      // Paginate
      return _paginateResults(filteredUniversities, limit, lastDocument);

    } catch (e) {
      debugPrint('❌ Error in location query: $e');
      return (<UniversityModel>[], null);
    }
  }

  /// FIXED: Get universities by ranking (range or sort)
  Future<(List<UniversityModel>, DocumentSnapshot?)> _getUniversitiesByRanking({
    required int limit,
    DocumentSnapshot? lastDocument,
    FilterModel? filter,
  }) async {
    try {
      debugPrint('🏆 Loading by ranking...');

      // Fetch ALL ranked universities (client-side filtering required)
      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('universities')
            .where('min_ranking', isNull: false)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('universities')
            .where('min_ranking', isNull: false)
            .get(const GetOptions(source: Source.server));
      }

      // Parse and filter
      final universities = await _parseAndFilterUniversities(
          snapshot.docs,
          filter
      );

      // Sort by ranking
      universities.sort((a, b) => _compareByRanking(a, b, filter?.rankingSortOrder));

      debugPrint('✅ Filtered to ${universities.length} ranked universities');

      // Paginate
      return _paginateResults(universities, limit, lastDocument);

    } catch (e) {
      debugPrint('❌ Error in ranking query: $e');
      return (<UniversityModel>[], null);
    }
  }

  /// Get all universities with filters (fallback)
  Future<(List<UniversityModel>, DocumentSnapshot?)> _getAllUniversitiesWithFilters({
    required int limit,
    DocumentSnapshot? lastDocument,
    FilterModel? filter,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('universities')
          .orderBy('university_name')
          .limit(limit * 3);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot;
      try {
        snapshot = await query.get(const GetOptions(source: Source.cache));
        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await query.get(const GetOptions(source: Source.server));
      }

      final universities = await _parseAndFilterUniversities(
          snapshot.docs,
          filter
      );

      return _paginateResults(universities, limit, lastDocument);

    } catch (e) {
      debugPrint('❌ Error in fallback query: $e');
      return (<UniversityModel>[], null);
    }
  }

  /// FIXED: Client-side filter matching with proper logic
  bool _matchesClientSideFilters(
      UniversityModel uni,
      FilterModel? filter, {
        required bool isMalaysianUniversity,
      }) {
    if (filter == null) return true;

    // Student count filter (RULE 1: Apply to Malaysian universities by default)
    if (filter.minStudents != null || filter.maxStudents != null) {
      final students = uni.totalStudents ?? 0;

      if (filter.minStudents != null && students < filter.minStudents!) {
        return false;
      }
      if (filter.maxStudents != null && students > filter.maxStudents!) {
        return false;
      }
    }

    // Ranking filter (RULE 3: Independent functionality)
    if (filter.minRanking != null || filter.maxRanking != null) {
      if (uni.minRanking == null) {
        return false; // Exclude unranked when ranking filter is active
      }

      // Use helper to check overlap
      if (!RankingParser.isInRange(
        uni.minRanking,
        uni.maxRanking,
        filter.minRanking,
        filter.maxRanking,
      )) {
        return false;
      }
    }

    // Tuition fee filter (RULE 1: Apply to Malaysian universities by default)
    if (filter.minTuitionFeeMYR != null || filter.maxTuitionFeeMYR != null) {
      double? feeToCheckMYR;

      if (isMalaysianUniversity) {
        // RULE: Malaysian uni, check domestic fee
        feeToCheckMYR = uni.domesticTuitionFee != null
            ? CurrencyUtils.convertToMYR(uni.domesticTuitionFee)
            : null;
      } else {
        // RULE: International uni, check international fee
        feeToCheckMYR = uni.internationalTuitionFee != null
            ? CurrencyUtils.convertToMYR(uni.internationalTuitionFee)
            : null;
      }

      // Check if the relevant fee exists and is in range
      if (feeToCheckMYR == null || feeToCheckMYR <= 0) {
        return false; // No relevant fee to check, so filter it out
      }

      bool inRange = (filter.minTuitionFeeMYR == null || feeToCheckMYR >= filter.minTuitionFeeMYR!) &&
          (filter.maxTuitionFeeMYR == null || feeToCheckMYR <= filter.maxTuitionFeeMYR!);

      if (!inRange) {
        return false;
      }
    }

    // Institution type filter
    if (filter.institutionType != null && uni.institutionType != filter.institutionType) {
      return false;
    }

    return true;
  }

  /// Helper: Compare universities by ranking
  int _compareByRanking(UniversityModel a, UniversityModel b, String? sortOrder) {
    // Unranked go to end
    if (a.minRanking == null && b.minRanking == null) return 0;
    if (a.minRanking == null) return 1;
    if (b.minRanking == null) return -1;

    if (sortOrder == 'desc') {
      return b.minRanking!.compareTo(a.minRanking!); // Worst first
    } else {
      return a.minRanking!.compareTo(b.minRanking!); // Best first (default)
    }
  }

  /// Helper: Parse documents and apply filters
  Future<List<UniversityModel>> _parseAndFilterUniversities(
      List<QueryDocumentSnapshot> docs,
      FilterModel? filter,
      ) async {
    final universities = <UniversityModel>[];

    // Get the set of Malaysian IDs to check against
    final malaysianIds = await _getMalaysianUniversityIds();

    for (var doc in docs) {
      try {
        final uni = UniversityModel.fromJson(doc.data() as Map<String, dynamic>);

        // Determine if this specific university is Malaysian
        final bool isMalaysian = malaysianIds.contains(uni.universityId);

        // Pass the explicit boolean
        if (!_matchesClientSideFilters(uni, filter, isMalaysianUniversity: isMalaysian)) {
          continue;
        }

        universities.add(uni);
      } catch (e) {
        debugPrint('⚠️ Error parsing ${doc.id}: $e');
      }
    }

    return universities;
  }

  /// Helper: Paginate results in memory
  Future<(List<UniversityModel>, DocumentSnapshot<Object?>?)> _paginateResults(
      List<UniversityModel> universities,
      int limit,
      DocumentSnapshot? lastDocument,
      ) async {
    int startIndex = 0;
    if (lastDocument != null) {
      final lastId = lastDocument.id;
      startIndex = universities.indexWhere((u) => u.universityId == lastId) + 1;
    }

    final endIndex = (startIndex + limit).clamp(0, universities.length);
    final paginatedList = universities.sublist(startIndex, endIndex);

    DocumentSnapshot? newLastDoc;
    if (endIndex < universities.length && paginatedList.isNotEmpty) {
      final lastUni = paginatedList.last;
      newLastDoc = await FirebaseFirestore.instance
          .collection('universities')
          .doc(lastUni.universityId)
          .get(const GetOptions(source: Source.cache));
    }

    return (paginatedList, newLastDoc);
  }

  /// Search universities (for autocomplete suggestions)
  Future<List<UniversityModel>> searchUniversities(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

    try {
      Query firestoreQuery = FirebaseFirestore.instance
          .collection('universities')
          .orderBy('university_name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(limit);

      QuerySnapshot snapshot;
      try {
        snapshot = await firestoreQuery.get(const GetOptions(source: Source.cache));
        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await firestoreQuery.get(const GetOptions(source: Source.server));
      }

      return snapshot.docs
          .map((doc) {
        try {
          return UniversityModel.fromJson(doc.data() as Map<String, dynamic>);
        } catch (e) {
          debugPrint('⚠️ Error parsing ${doc.id}: $e');
          return null;
        }
      })
          .whereType<UniversityModel>()
          .toList();
    } catch (e) {
      debugPrint('❌ Error in searchUniversities: $e');
      return [];
    }
  }

  /// Clear all caches
  static void clearCaches() {
    _queryCache.clear();
    _queryCacheTime.clear();
    _malaysianUniIds = null;
    _malaysianIdsCacheTime = null;
    debugPrint('🧹 University repository caches cleared');
  }
}