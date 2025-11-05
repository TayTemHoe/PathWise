import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/program.dart';
import '../model/program_filter.dart';
import '../model/branch.dart';
import '../model/university.dart';
import '../services/firebase_service.dart';
import '../utils/currency_utils.dart';

class ProgramRepository {
  final FirebaseService _firebaseService;

  // ==================== LOCAL CACHING ====================
  static final Map<String, (List<ProgramModel>, DocumentSnapshot?)> _queryCache = {};
  static final Map<String, DateTime> _queryCacheTime = {};
  static const Duration _queryCacheValidity = Duration(minutes: 30);

  // Cache for Malaysian branches
  static Set<String>? _malaysianBranchIds;
  static DateTime? _malaysianBranchesCacheTime;

  // Cache for program details
  static final Map<String, UniversityModel> _universityCache = {};
  static final Map<String, BranchModel> _branchCache = {};

  ProgramRepository(this._firebaseService);

  /// MAIN ENTRY POINT: Get programs with proper filter handling
  Future<(List<ProgramModel>, DocumentSnapshot?)> getPrograms({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    ProgramFilterModel? filter,
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
      // Search query (highest priority)
      if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
        return await _searchProgramsWithFilters(
          searchQuery: filter.searchQuery!,
          limit: limit,
          lastDocument: lastDocument,
          filter: filter,
        );
      }

      // Subject area filter
      if (filter?.subjectArea != null) {
        return await _getProgramsBySubjectArea(
          subjectArea: filter!.subjectArea!,
          limit: limit,
          lastDocument: lastDocument,
          filter: filter,
        );
      }

      // Ranking-based queries
      if (filter?.minSubjectRanking != null ||
          filter?.maxSubjectRanking != null ||
          filter?.rankingSortOrder != null) {
        return await _getProgramsByRanking(
          limit: limit,
          lastDocument: lastDocument,
          filter: filter,
        );
      }

      // Fallback: Load all programs with filters
      return await _getAllProgramsWithFilters(
        limit: limit,
        lastDocument: lastDocument,
        filter: filter,
      );
    } catch (e) {
      debugPrint('❌ Error in getPrograms: $e');
      return (<ProgramModel>[], null);
    }
  }

  /// Get Malaysian branch IDs (cached)
  Future<Set<String>> _getMalaysianBranchIds() async {
    if (_malaysianBranchIds != null && _malaysianBranchesCacheTime != null) {
      final age = DateTime.now().difference(_malaysianBranchesCacheTime!);
      if (age.inHours < 24) {
        debugPrint('📦 Cache HIT: Malaysian branch IDs (${_malaysianBranchIds!.length})');
        return _malaysianBranchIds!;
      }
    }

    debugPrint('🔥 Fetching Malaysian branch IDs...');

    try {
      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('branches')
            .where('country', isEqualTo: 'Malaysia')
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('branches')
            .where('country', isEqualTo: 'Malaysia')
            .get(const GetOptions(source: Source.server));
      }

      final ids = <String>{};
      for (var doc in snapshot.docs) {
        final branchId = (doc.data() as Map<String, dynamic>)['branch_id'] as String?;
        if (branchId != null) ids.add(branchId);
      }

      _malaysianBranchIds = ids;
      _malaysianBranchesCacheTime = DateTime.now();

      debugPrint('✅ Cached ${ids.length} Malaysian branch IDs');
      return ids;
    } catch (e) {
      debugPrint('❌ Error fetching Malaysian branch IDs: $e');
      return {};
    }
  }

  /// Search programs with filters
  Future<(List<ProgramModel>, DocumentSnapshot?)> _searchProgramsWithFilters({
    required String searchQuery,
    required int limit,
    DocumentSnapshot? lastDocument,
    ProgramFilterModel? filter,
  }) async {
    try {
      debugPrint('🔍 Searching: "$searchQuery"');

      Query query = FirebaseFirestore.instance
          .collection('programs')
          .orderBy('program_name')
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

      final programs = await _parseAndFilterPrograms(snapshot.docs, filter);
      programs.sort((a, b) => _compareByRanking(a, b, filter?.rankingSortOrder));

      return _paginateResults(programs, limit, lastDocument);
    } catch (e) {
      debugPrint('❌ Error in search: $e');
      return (<ProgramModel>[], null);
    }
  }

  /// Get programs by subject area
  Future<(List<ProgramModel>, DocumentSnapshot?)> _getProgramsBySubjectArea({
    required String subjectArea,
    required int limit,
    DocumentSnapshot? lastDocument,
    ProgramFilterModel? filter,
  }) async {
    try {
      debugPrint('📚 Loading: $subjectArea');

      Query query = FirebaseFirestore.instance
          .collection('programs')
          .where('subject_area', isEqualTo: subjectArea)
          .orderBy('program_name')
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

      final programs = await _parseAndFilterPrograms(snapshot.docs, filter);
      programs.sort((a, b) => _compareByRanking(a, b, filter?.rankingSortOrder));

      return _paginateResults(programs, limit, lastDocument);
    } catch (e) {
      debugPrint('❌ Error in subject area query: $e');
      return (<ProgramModel>[], null);
    }
  }

  /// Get programs by ranking
  Future<(List<ProgramModel>, DocumentSnapshot?)> _getProgramsByRanking({
    required int limit,
    DocumentSnapshot? lastDocument,
    ProgramFilterModel? filter,
  }) async {
    try {
      debugPrint('🏆 Loading by subject ranking...');

      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .where('min_subject_ranking', isNull: false)
            .limit(500)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .where('min_subject_ranking', isNull: false)
            .limit(500)
            .get(const GetOptions(source: Source.server));
      }

      final programs = await _parseAndFilterPrograms(snapshot.docs, filter);
      programs.sort((a, b) => _compareByRanking(a, b, filter?.rankingSortOrder));

      debugPrint('✅ Filtered to ${programs.length} ranked programs');
      return _paginateResults(programs, limit, lastDocument);
    } catch (e) {
      debugPrint('❌ Error in ranking query: $e');
      return (<ProgramModel>[], null);
    }
  }

  /// Get all programs with filters (fallback)
  Future<(List<ProgramModel>, DocumentSnapshot?)> _getAllProgramsWithFilters({
    required int limit,
    DocumentSnapshot? lastDocument,
    ProgramFilterModel? filter,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('programs')
          .orderBy('program_id')
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

      final programs = await _parseAndFilterPrograms(snapshot.docs, filter);
      return _paginateResults(programs, limit, lastDocument);
    } catch (e) {
      debugPrint('❌ Error in fallback query: $e');
      return (<ProgramModel>[], null);
    }
  }

  /// Client-side filter matching
  Future<bool> _matchesClientSideFilters(
      ProgramModel program,
      ProgramFilterModel? filter,
      ) async {
    if (filter == null) return true;

    // University filter
    if (filter.universityName != null) {
      // Search by university name (case-insensitive partial match)
      final uni = await getUniversityForProgram(program.universityId);
      if (uni == null) return false;

      if (!uni.universityName.toLowerCase().contains(filter.universityName!.toLowerCase())) {
        return false;
      }
    }

    // University IDs filter (for dropdown selection)
    if (filter.universityIds.isNotEmpty) {
      if (!filter.universityIds.contains(program.universityId)) {
        return false;
      }
    }

    // Study mode filter
    if (filter.studyModes.isNotEmpty) {
      if (program.studyMode == null ||
          !filter.studyModes.contains(program.studyMode)) {
        return false;
      }
    }

    // Study level filter
    if (filter.studyLevels.isNotEmpty) {
      if (program.studyLevel == null ||
          !filter.studyLevels.contains(program.studyLevel)) {
        return false;
      }
    }

    // Intake period filter
    if (filter.intakeMonths.isNotEmpty) {
      if (program.intakePeriod.isEmpty) return false;

      bool hasMatchingIntake = false;
      for (var month in filter.intakeMonths) {
        if (program.intakePeriod.contains(month)) {
          hasMatchingIntake = true;
          break;
        }
      }
      if (!hasMatchingIntake) return false;
    }

    // Duration filter (in years)
    if (filter.minDurationYears != null || filter.maxDurationYears != null) {
      final durationYears = program.durationYears;
      if (durationYears == null) return false;

      if (filter.minDurationYears != null && durationYears < filter.minDurationYears!) {
        return false;
      }
      if (filter.maxDurationYears != null && durationYears > filter.maxDurationYears!) {
        return false;
      }
    }

    // Ranking filter
    if (filter.minSubjectRanking != null || filter.maxSubjectRanking != null) {
      if (program.minSubjectRanking == null) return false;

      if (!_isRankingInRange(
        program.minSubjectRanking,
        program.maxSubjectRanking,
        filter.minSubjectRanking,
        filter.maxSubjectRanking,
      )) {
        return false;
      }
    }

    // Tuition fee filter
    if (filter.minTuitionFeeMYR != null || filter.maxTuitionFeeMYR != null) {
      // Determine if program is from Malaysian branch
      final malaysianBranchIds = await _getMalaysianBranchIds();
      final isMalaysianProgram = malaysianBranchIds.contains(program.branchId);

      double? feeToCheckMYR;

      if (isMalaysianProgram) {
        feeToCheckMYR = program.minDomesticTuitionFee != null
            ? CurrencyUtils.convertToMYR(program.minDomesticTuitionFee)
            : null;
      } else {
        feeToCheckMYR = program.minInternationalTuitionFee != null
            ? CurrencyUtils.convertToMYR(program.minInternationalTuitionFee)
            : null;
      }

      if (feeToCheckMYR == null || feeToCheckMYR <= 0) return false;

      bool inRange = (filter.minTuitionFeeMYR == null || feeToCheckMYR >= filter.minTuitionFeeMYR!) &&
          (filter.maxTuitionFeeMYR == null || feeToCheckMYR <= filter.maxTuitionFeeMYR!);

      if (!inRange) return false;
    }

    return true;
  }

  /// Check ranking overlap
  bool _isRankingInRange(int? minRanking, int? maxRanking, int? minRange, int? maxRange) {
    if (minRanking == null) return false;
    if (minRange == null && maxRange == null) return true;

    final effectiveMaxRanking = maxRanking ?? minRanking;

    if (maxRange != null && minRanking > maxRange) return false;
    if (minRange != null && effectiveMaxRanking < minRange) return false;

    return true;
  }

  /// Compare programs by ranking
  int _compareByRanking(ProgramModel a, ProgramModel b, String? sortOrder) {
    if (a.minSubjectRanking == null && b.minSubjectRanking == null) return 0;
    if (a.minSubjectRanking == null) return 1;
    if (b.minSubjectRanking == null) return -1;

    if (sortOrder == 'desc') {
      return b.minSubjectRanking!.compareTo(a.minSubjectRanking!);
    } else {
      return a.minSubjectRanking!.compareTo(b.minSubjectRanking!);
    }
  }

  /// Parse documents and apply filters
  Future<List<ProgramModel>> _parseAndFilterPrograms(
      List<QueryDocumentSnapshot> docs,
      ProgramFilterModel? filter,
      ) async {
    final programs = <ProgramModel>[];

    for (var doc in docs) {
      try {
        final program = ProgramModel.fromJson(doc.data() as Map<String, dynamic>);

        if (!await _matchesClientSideFilters(program, filter)) {
          continue;
        }

        programs.add(program);
      } catch (e) {
        debugPrint('⚠️ Error parsing ${doc.id}: $e');
      }
    }

    return programs;
  }

  /// Paginate results in memory
  Future<(List<ProgramModel>, DocumentSnapshot?)> _paginateResults(
      List<ProgramModel> programs,
      int limit,
      DocumentSnapshot? lastDocument,
      ) async {
    int startIndex = 0;
    if (lastDocument != null) {
      final lastId = lastDocument.id;
      startIndex = programs.indexWhere((p) => p.programId == lastId) + 1;
    }

    final endIndex = (startIndex + limit).clamp(0, programs.length);
    final paginatedList = programs.sublist(startIndex, endIndex);

    DocumentSnapshot? newLastDoc;
    if (endIndex < programs.length && paginatedList.isNotEmpty) {
      final lastProg = paginatedList.last;
      try {
        newLastDoc = await FirebaseFirestore.instance
            .collection('programs')
            .doc(lastProg.programId)
            .get(const GetOptions(source: Source.cache));
      } catch (e) {
        debugPrint('⚠️ Error getting last document: $e');
      }
    }

    return (paginatedList, newLastDoc);
  }

  /// Search programs (for autocomplete suggestions)
  Future<List<ProgramModel>> searchPrograms(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

    try {
      Query firestoreQuery = FirebaseFirestore.instance
          .collection('programs')
          .orderBy('program_name')
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
          return ProgramModel.fromJson(doc.data() as Map<String, dynamic>);
        } catch (e) {
          debugPrint('⚠️ Error parsing ${doc.id}: $e');
          return null;
        }
      })
          .whereType<ProgramModel>()
          .toList();
    } catch (e) {
      debugPrint('❌ Error in searchPrograms: $e');
      return [];
    }
  }

  /// Get program details (for detail screen)
  Future<ProgramModel?> getProgramDetails(String programId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('programs')
          .doc(programId)
          .get(const GetOptions(source: Source.cache));

      if (doc.exists && doc.data() != null) {
        return ProgramModel.fromJson(doc.data()!);
      }

      final serverDoc = await FirebaseFirestore.instance
          .collection('programs')
          .doc(programId)
          .get(const GetOptions(source: Source.server));

      if (serverDoc.exists && serverDoc.data() != null) {
        return ProgramModel.fromJson(serverDoc.data()!);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting program details: $e');
      return null;
    }
  }

  /// Get university for a program
  Future<UniversityModel?> getUniversityForProgram(String universityId) async {
    // Check cache first
    if (_universityCache.containsKey(universityId)) {
      debugPrint('📦 Cache HIT: University $universityId');
      return _universityCache[universityId];
    }

    try {
      final uni = await _firebaseService.getUniversity(universityId);
      if (uni != null) {
        _universityCache[universityId] = uni;
      }
      return uni;
    } catch (e) {
      debugPrint('❌ Error getting university: $e');
      return null;
    }
  }

  /// Get branch for a program
  Future<BranchModel?> getBranchForProgram(String branchId, String universityId) async {
    // Check cache first
    if (_branchCache.containsKey(branchId)) {
      debugPrint('📦 Cache HIT: Branch $branchId');
      return _branchCache[branchId];
    }

    try {
      final branches = await _firebaseService.getBranchesByUniversity(universityId);

      // Cache all branches
      for (var branch in branches) {
        _branchCache[branch.branchId] = branch;
      }

      return _branchCache[branchId];
    } catch (e) {
      debugPrint('❌ Error getting branch: $e');
      return null;
    }
  }

  /// Get programs by university (for university detail screen)
  Future<List<ProgramModel>> getProgramsByUniversity(String universityId, {int limit = 50}) async {
    try {
      // First get all branches for this university
      final branches = await _firebaseService.getBranchesByUniversity(universityId);
      final branchIds = branches.map((b) => b.branchId).toList();

      if (branchIds.isEmpty) return [];

      final programs = <ProgramModel>[];

      // Fetch programs in batches (Firestore 'in' limit is 10)
      for (int i = 0; i < branchIds.length; i += 10) {
        final batch = branchIds.skip(i).take(10).toList();

        QuerySnapshot snapshot;
        try {
          snapshot = await FirebaseFirestore.instance
              .collection('programs')
              .where('branch_id', whereIn: batch)
              .limit(limit)
              .get(const GetOptions(source: Source.cache));

          if (snapshot.docs.isEmpty) throw Exception('No cache');
        } catch (e) {
          snapshot = await FirebaseFirestore.instance
              .collection('programs')
              .where('branch_id', whereIn: batch)
              .limit(limit)
              .get(const GetOptions(source: Source.server));
        }

        for (var doc in snapshot.docs) {
          try {
            programs.add(ProgramModel.fromJson(doc.data() as Map<String, dynamic>));
          } catch (e) {
            debugPrint('⚠️ Error parsing program: $e');
          }
        }

        if (programs.length >= limit) break;
      }

      debugPrint('✅ Loaded ${programs.length} programs for university $universityId');
      return programs.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error getting programs by university: $e');
      return [];
    }
  }

  /// Get programs by branch (for branch detail screen)
  Future<List<ProgramModel>> getProgramsByBranch(String branchId, {int limit = 100}) async {
    try {
      QuerySnapshot snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .where('branch_id', isEqualTo: branchId)
            .limit(limit)
            .get(const GetOptions(source: Source.cache));

        if (snapshot.docs.isEmpty) throw Exception('No cache');
      } catch (e) {
        snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .where('branch_id', isEqualTo: branchId)
            .limit(limit)
            .get(const GetOptions(source: Source.server));
      }

      final programs = snapshot.docs
          .map((doc) {
        try {
          return ProgramModel.fromJson(doc.data() as Map<String, dynamic>);
        } catch (e) {
          debugPrint('⚠️ Error parsing program: $e');
          return null;
        }
      })
          .whereType<ProgramModel>()
          .toList();

      debugPrint('✅ Loaded ${programs.length} programs for branch $branchId');
      return programs;
    } catch (e) {
      debugPrint('❌ Error getting programs by branch: $e');
      return [];
    }
  }

  /// Get program count by university
  Future<int> getProgramCountByUniversity(String universityId) async {
    try {
      // Get branches first
      final branches = await _firebaseService.getBranchesByUniversity(universityId);
      final branchIds = branches.map((b) => b.branchId).toList();

      if (branchIds.isEmpty) return 0;

      int totalCount = 0;

      // Count programs in batches
      for (int i = 0; i < branchIds.length; i += 10) {
        final batch = branchIds.skip(i).take(10).toList();

        final snapshot = await FirebaseFirestore.instance
            .collection('programs')
            .where('branch_id', whereIn: batch)
            .count()
            .get();

        totalCount += snapshot.count ?? 0;
      }

      return totalCount;
    } catch (e) {
      debugPrint('❌ Error getting program count: $e');
      return 0;
    }
  }

  /// Clear all caches
  static void clearCaches() {
    _queryCache.clear();
    _queryCacheTime.clear();
    _malaysianBranchIds = null;
    _malaysianBranchesCacheTime = null;
    _universityCache.clear();
    _branchCache.clear();
    debugPrint('🧹 Program repository caches cleared');
  }

  /// Refresh cache for specific query
  void invalidateQueryCache(ProgramFilterModel? filter) {
    if (filter == null) {
      _queryCache.clear();
      _queryCacheTime.clear();
      debugPrint('🧹 All query caches cleared');
      return;
    }

    final filterHash = filter.hashCode;
    _queryCache.removeWhere((key, value) => key.startsWith('$filterHash'));
    _queryCacheTime.removeWhere((key, value) => key.startsWith('$filterHash'));
    debugPrint('🧹 Query cache cleared for filter: $filterHash');
  }

  /// Get cache statistics (for debug)
  Map<String, dynamic> getCacheStats() {
    return {
      'queryCacheSize': _queryCache.length,
      'malaysianBranchIds': _malaysianBranchIds?.length ?? 0,
      'universityCacheSize': _universityCache.length,
      'branchCacheSize': _branchCache.length,
      'lastCacheUpdate': _malaysianBranchesCacheTime?.toIso8601String() ?? 'Never',
    };
  }
}